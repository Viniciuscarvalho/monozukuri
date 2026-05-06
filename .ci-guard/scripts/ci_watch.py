#!/usr/bin/env python3
"""ci_watch.py — snapshot CI state for a PR with classifications and a cost guard.

Outputs JSON (one object in --once mode, JSONL in --watch mode). Refuses to
retry failed jobs unless every failure classifies as something other than
branch_failure AND retry budgets are not exceeded.

Depends on: gh CLI (authenticated), python 3.9+, stdlib only.

Sister scripts:
    flaky_ledger.py        — persistent per-repo flaky-test ledger.
    classify_failure.py    — heuristics for log-based failure classification.

Both are invoked as subprocesses so they can be used standalone too.
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import time
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Any, Optional

# --------------------------------------------------------------------------- #
# Config
# --------------------------------------------------------------------------- #

DEFAULT_BUDGET = {
    "retries_per_job": 2,
    "retries_per_pr": 5,
    "minutes_per_pr": 90,
    "watch_interval_seconds": 60,
}

LEDGER_PATH_DEFAULT = ".ci-guard/flaky-ledger.json"
CONFIG_PATH_DEFAULT = ".ci-guard/config.yml"
STATE_PATH_DEFAULT = ".ci-guard/.watch-state.json"  # gitignored


# --------------------------------------------------------------------------- #
# Data shapes
# --------------------------------------------------------------------------- #


@dataclass
class CheckSnapshot:
    name: str
    workflow: str
    status: str  # queued / in_progress / completed
    conclusion: Optional[str]  # success / failure / cancelled / null
    run_id: Optional[str]
    duration_seconds: Optional[int]
    started_at: Optional[str]
    classification: dict = field(default_factory=dict)
    flaky_history: dict = field(default_factory=dict)
    recommendation: str = "wait"
    retries_used_job: int = 0


@dataclass
class Snapshot:
    pr_number: int
    head_sha: str
    head_sha_short: str
    pr_state: str  # OPEN / MERGED / CLOSED
    mergeable: Optional[str]
    checks: list[CheckSnapshot] = field(default_factory=list)
    actions: list[str] = field(default_factory=list)
    cost_summary: dict = field(default_factory=dict)
    quarantine_candidates: list[dict] = field(default_factory=list)
    timestamp: str = ""


# --------------------------------------------------------------------------- #
# gh wrappers
# --------------------------------------------------------------------------- #


def gh(*args: str, check: bool = True) -> str:
    """Run a gh command and return stdout, or raise on failure."""
    try:
        result = subprocess.run(
            ["gh", *args],
            capture_output=True,
            text=True,
            check=check,
        )
        return result.stdout
    except FileNotFoundError:
        sys.stderr.write(
            "ci-guard: 'gh' CLI not found. Install from https://cli.github.com.\n"
        )
        sys.exit(2)
    except subprocess.CalledProcessError as e:
        sys.stderr.write(f"ci-guard: gh failed: {e.stderr}\n")
        if check:
            sys.exit(2)
        return ""


def resolve_pr(arg: str) -> int:
    """Resolve --pr {auto|<n>|<url>} to an integer PR number."""
    if arg == "auto":
        out = gh("pr", "view", "--json", "number")
        return int(json.loads(out)["number"])
    if arg.isdigit():
        return int(arg)
    # URL form: parse trailing /pull/<n>
    parts = [p for p in arg.split("/") if p]
    if "pull" in parts:
        idx = parts.index("pull")
        if idx + 1 < len(parts):
            return int(parts[idx + 1])
    raise ValueError(f"Could not resolve PR from: {arg}")


def fetch_pr_state(pr: int) -> dict:
    fields = ",".join([
        "number", "state", "headRefOid", "mergeable", "mergeStateStatus",
        "headRefName", "baseRefName",
    ])
    return json.loads(gh("pr", "view", str(pr), "--json", fields))


def fetch_checks(pr: int) -> list[dict]:
    """Return the raw checks list for a PR (one entry per check)."""
    out = gh("pr", "checks", str(pr), "--json",
             "name,workflow,state,bucket,startedAt,completedAt,link")
    return json.loads(out) if out.strip() else []


def fetch_run_jobs(run_id: str) -> dict:
    return json.loads(gh(
        "run", "view", run_id,
        "--json", "jobs,conclusion,status,name,workflowName,headSha,createdAt,updatedAt",
    ))


def fetch_failed_log(run_id: str, max_chars: int = 20000) -> str:
    """Get the failed-portions of a run's log. Truncated to keep output bounded."""
    raw = gh("run", "view", run_id, "--log-failed", check=False)
    if len(raw) > max_chars:
        return raw[:max_chars // 2] + "\n...[truncated]...\n" + raw[-max_chars // 2:]
    return raw


# --------------------------------------------------------------------------- #
# Config / ledger / state
# --------------------------------------------------------------------------- #


def load_config(repo_root: Path) -> dict:
    cfg_path = repo_root / CONFIG_PATH_DEFAULT
    cfg = dict(DEFAULT_BUDGET)
    if not cfg_path.exists():
        return cfg
    # tiny YAML-ish parser (key: value only, to avoid pyyaml dep)
    for line in cfg_path.read_text().splitlines():
        line = line.split("#", 1)[0].strip()
        if not line or ":" not in line:
            continue
        k, v = line.split(":", 1)
        k, v = k.strip(), v.strip()
        if v.isdigit():
            cfg[k] = int(v)
        elif v.lower() in {"true", "false"}:
            cfg[k] = v.lower() == "true"
        else:
            cfg[k] = v
    return cfg


def load_ledger(repo_root: Path) -> dict:
    p = repo_root / LEDGER_PATH_DEFAULT
    if not p.exists():
        return {"version": 1, "tests": {}}
    try:
        return json.loads(p.read_text())
    except json.JSONDecodeError:
        sys.stderr.write(
            f"ci-guard: ledger at {p} is malformed; treating as empty. "
            "Run 'flaky_ledger.py repair' to investigate.\n"
        )
        return {"version": 1, "tests": {}}


def load_state(repo_root: Path) -> dict:
    p = repo_root / STATE_PATH_DEFAULT
    if not p.exists():
        return {"prs": {}}
    try:
        return json.loads(p.read_text())
    except json.JSONDecodeError:
        return {"prs": {}}


def save_state(repo_root: Path, state: dict) -> None:
    p = repo_root / STATE_PATH_DEFAULT
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(json.dumps(state, indent=2))


def repo_root() -> Path:
    """Find the git repo root, falling back to cwd."""
    try:
        out = subprocess.check_output(
            ["git", "rev-parse", "--show-toplevel"],
            text=True,
        ).strip()
        return Path(out)
    except Exception:
        return Path.cwd()


# --------------------------------------------------------------------------- #
# Classification (delegates to classify_failure.py for log heuristics)
# --------------------------------------------------------------------------- #


def classify_check(check: dict, ledger: dict, repo_root_path: Path) -> dict:
    """Decide which bucket a failed check falls into.

    Order matters: branch_failure dominates flake classifications because a
    real bug masquerading as a flake is the worst-case outcome.
    """
    if check.get("conclusion") not in {"failure", "cancelled", "timed_out"}:
        return {"category": "n/a", "confidence": "n/a", "reason": "Not a failure."}

    run_id = check.get("run_id")
    log = fetch_failed_log(run_id) if run_id else ""

    classifier = repo_root_path / ".ci-guard" / "scripts" / "classify_failure.py"
    if not classifier.exists():
        # fall back to inline minimal heuristics so the watcher still works
        # if the user only installed ci_watch.py
        return _inline_classify(log, check, ledger)

    proc = subprocess.run(
        ["python3", str(classifier), "--stdin", "--check-name", check["name"]],
        input=log, capture_output=True, text=True, check=False,
    )
    if proc.returncode != 0 or not proc.stdout.strip():
        return _inline_classify(log, check, ledger)

    try:
        result = json.loads(proc.stdout)
    except json.JSONDecodeError:
        return _inline_classify(log, check, ledger)

    # Augment with ledger lookup: if a known-flaky test is in the failed log,
    # prefer test_flake even if the heuristics said unknown.
    flake_hits = _ledger_hits_in_log(log, ledger)
    if flake_hits and result.get("category") in {"unknown", "test_flake"}:
        result["category"] = "test_flake"
        result["confidence"] = "high"
        result["reason"] = (
            f"Failed test(s) match ledger: {', '.join(flake_hits[:3])}"
            + (" and others" if len(flake_hits) > 3 else "")
        )
        result["matched_ledger_tests"] = flake_hits
    return result


def _inline_classify(log: str, check: dict, ledger: dict) -> dict:
    """Last-resort minimal classifier if classify_failure.py is missing."""
    log_l = log.lower()
    flake_hits = _ledger_hits_in_log(log, ledger)
    if flake_hits:
        return {
            "category": "test_flake",
            "confidence": "medium",
            "reason": "Ledger match (inline fallback).",
            "matched_ledger_tests": flake_hits,
        }
    infra_signals = [
        "the runner has received a shutdown signal",
        "lost communication with the server",
        "could not resolve host",
        "connection reset by peer",
        "i/o timeout",
        "503 service unavailable",
        "502 bad gateway",
    ]
    if any(s in log_l for s in infra_signals):
        return {
            "category": "infra_flake",
            "confidence": "medium",
            "reason": "Infra-signal match (inline fallback).",
        }
    dep_signals = [
        "npm err! 429",
        "npm err! 5",
        "could not get pypi",
        "error fetching crate",
        "registry-1.docker.io",
    ]
    if any(s in log_l for s in dep_signals):
        return {
            "category": "dependency_failure",
            "confidence": "medium",
            "reason": "Registry/dependency signal match (inline fallback).",
        }
    branch_signals = [
        "syntaxerror",
        "compilation failed",
        "type error",
        "no such file or directory",
        "snapshot does not match",
    ]
    if any(s in log_l for s in branch_signals):
        return {
            "category": "branch_failure",
            "confidence": "high",
            "reason": "Branch-signal match (inline fallback).",
        }
    return {"category": "unknown", "confidence": "low",
            "reason": "No matching heuristic; manual diagnosis required."}


def _ledger_hits_in_log(log: str, ledger: dict) -> list[str]:
    if not log or not ledger.get("tests"):
        return []
    hits = []
    for test_id in ledger["tests"]:
        # test ids are typically "::"-delimited; check both full and tail
        tail = test_id.split("::")[-1] if "::" in test_id else test_id
        if test_id in log or (tail and tail in log):
            hits.append(test_id)
    return hits


# --------------------------------------------------------------------------- #
# Cost guard
# --------------------------------------------------------------------------- #


def evaluate_budget(state: dict, pr: int, cfg: dict) -> dict:
    pr_key = str(pr)
    pr_state = state.setdefault("prs", {}).setdefault(pr_key, {
        "retries_used": 0,
        "retries_per_job": {},
        "minutes_spent": 0,
    })
    return {
        "retries_used_pr": pr_state["retries_used"],
        "retries_max_pr": cfg["retries_per_pr"],
        "retries_used_per_job": dict(pr_state["retries_per_job"]),
        "retries_max_per_job": cfg["retries_per_job"],
        "minutes_spent": pr_state["minutes_spent"],
        "minutes_max": cfg["minutes_per_pr"],
        "any_budget_exhausted": (
            pr_state["retries_used"] >= cfg["retries_per_pr"]
            or pr_state["minutes_spent"] >= cfg["minutes_per_pr"]
        ),
    }


def can_retry(check: CheckSnapshot, budget: dict) -> tuple[bool, str]:
    if check.classification.get("category") == "branch_failure":
        return False, "branch_failure: never retry; patch code instead."
    if budget["any_budget_exhausted"]:
        return False, "PR-level budget exhausted."
    used_for_job = budget["retries_used_per_job"].get(check.name, 0)
    if used_for_job >= budget["retries_max_per_job"]:
        return False, f"Per-job retry budget exhausted ({used_for_job}/{budget['retries_max_per_job']})."
    if check.classification.get("category") == "unknown":
        return False, "unknown classification: diagnose before retry."
    return True, "ok"


# --------------------------------------------------------------------------- #
# Snapshot assembly
# --------------------------------------------------------------------------- #


def _check_to_snapshot(c: dict, ledger: dict, repo_root_path: Path,
                       state: dict, pr: int) -> CheckSnapshot:
    # `gh pr checks` doesn't expose run_id directly; the link does.
    link = c.get("link", "") or ""
    run_id = ""
    if "/runs/" in link:
        run_id = link.split("/runs/")[1].split("/")[0]
    elif "/actions/runs/" in link:
        run_id = link.split("/actions/runs/")[1].split("/")[0]

    bucket = (c.get("bucket") or "").lower()
    state_field = (c.get("state") or "").lower()
    status = "completed" if bucket in {"pass", "fail", "cancel", "skipping"} else state_field or "in_progress"
    conclusion = None
    if bucket == "pass":
        conclusion = "success"
    elif bucket == "fail":
        conclusion = "failure"
    elif bucket == "cancel":
        conclusion = "cancelled"
    elif bucket == "skipping":
        conclusion = "skipped"

    duration_seconds = None
    if c.get("startedAt") and c.get("completedAt"):
        from datetime import datetime
        try:
            s = datetime.fromisoformat(c["startedAt"].replace("Z", "+00:00"))
            e = datetime.fromisoformat(c["completedAt"].replace("Z", "+00:00"))
            duration_seconds = int((e - s).total_seconds())
        except Exception:
            pass

    snap = CheckSnapshot(
        name=c.get("name", "unknown"),
        workflow=c.get("workflow", ""),
        status=status,
        conclusion=conclusion,
        run_id=run_id or None,
        duration_seconds=duration_seconds,
        started_at=c.get("startedAt"),
        retries_used_job=state.get("prs", {}).get(str(pr), {}).get(
            "retries_per_job", {}).get(c.get("name", ""), 0),
    )

    if conclusion in {"failure", "cancelled", "timed_out"}:
        # only spend tokens classifying actual failures
        snap.classification = classify_check(
            {"conclusion": conclusion, "name": snap.name, "run_id": run_id},
            ledger, repo_root_path,
        )
        snap.flaky_history = _flaky_history_for_check(snap.classification, ledger)

    return snap


def _flaky_history_for_check(classification: dict, ledger: dict) -> dict:
    matched = classification.get("matched_ledger_tests", []) if isinstance(classification, dict) else []
    if not matched:
        return {}
    summary = {}
    for tid in matched:
        entry = ledger.get("tests", {}).get(tid)
        if entry:
            summary[tid] = {
                "failure_count_30d": entry.get("failure_count_30d", 0),
                "flake_rate": entry.get("flake_rate", 0.0),
                "last_failure": entry.get("last_failure"),
                "status": entry.get("status", "watched"),
            }
    return summary


def derive_actions(snap: Snapshot, budget: dict) -> list[str]:
    actions: list[str] = []
    if snap.pr_state in {"MERGED", "CLOSED"}:
        return ["stop_pr_closed"]
    has_failure = any(c.conclusion in {"failure", "cancelled", "timed_out"} for c in snap.checks)
    has_pending = any(c.status in {"queued", "in_progress", "pending"} for c in snap.checks)
    has_unknown = any(c.classification.get("category") == "unknown" for c in snap.checks)
    has_branch = any(c.classification.get("category") == "branch_failure" for c in snap.checks)
    has_retryable = any(
        c.classification.get("category") in {"infra_flake", "test_flake", "dependency_failure"}
        and c.conclusion == "failure"
        for c in snap.checks
    )
    flaky_greens = any(
        c.conclusion == "success" and c.flaky_history
        for c in snap.checks
    )

    if has_branch:
        actions.append("patch_branch_failure")
    if has_unknown:
        actions.append("diagnose_unknown")
    if flaky_greens:
        actions.append("verify_flaky_green")
    if has_retryable and not budget["any_budget_exhausted"] and not has_branch:
        actions.append("retry_with_budget")
    if budget["any_budget_exhausted"] and (has_failure or has_pending):
        actions.append("budget_exhausted_surface")
    if not actions and has_pending:
        actions.append("idle_wait")
    if not actions and not has_failure and not has_pending:
        actions.append("all_green")
    return actions


def assemble_snapshot(pr: int, repo_root_path: Path) -> Snapshot:
    cfg = load_config(repo_root_path)
    ledger = load_ledger(repo_root_path)
    state = load_state(repo_root_path)

    pr_state = fetch_pr_state(pr)
    raw_checks = fetch_checks(pr)
    snaps = [_check_to_snapshot(c, ledger, repo_root_path, state, pr)
             for c in raw_checks]
    budget = evaluate_budget(state, pr, cfg)

    snapshot = Snapshot(
        pr_number=pr,
        head_sha=pr_state.get("headRefOid", ""),
        head_sha_short=(pr_state.get("headRefOid", "") or "")[:7],
        pr_state=pr_state.get("state", "UNKNOWN"),
        mergeable=pr_state.get("mergeable"),
        checks=snaps,
        cost_summary=budget,
        timestamp=time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
    )

    # quarantine candidates from current ledger (cheap to compute)
    snapshot.quarantine_candidates = _quarantine_candidates(ledger)
    snapshot.actions = derive_actions(snapshot, budget)
    return snapshot


def _quarantine_candidates(ledger: dict) -> list[dict]:
    out = []
    for tid, entry in ledger.get("tests", {}).items():
        if entry.get("status") == "quarantined":
            continue
        if entry.get("failure_count_30d", 0) >= 3 and entry.get("flake_rate", 0) >= 0.05:
            out.append({
                "test": tid,
                "failure_count_30d": entry["failure_count_30d"],
                "flake_rate": entry["flake_rate"],
                "last_failure": entry.get("last_failure"),
            })
    return out


# --------------------------------------------------------------------------- #
# Retry orchestration
# --------------------------------------------------------------------------- #


def retry_failed_now(pr: int, repo_root_path: Path) -> int:
    cfg = load_config(repo_root_path)
    state = load_state(repo_root_path)
    snap = assemble_snapshot(pr, repo_root_path)
    budget = snap.cost_summary

    blockers = []
    retryable: list[CheckSnapshot] = []

    for c in snap.checks:
        if c.conclusion not in {"failure", "cancelled", "timed_out"}:
            continue
        ok, reason = can_retry(c, budget)
        if ok:
            retryable.append(c)
        else:
            blockers.append({"check": c.name, "reason": reason,
                             "category": c.classification.get("category")})

    if blockers:
        sys.stderr.write(
            "ci-guard: retry refused. Blockers:\n"
            + "\n".join(f"  - {b['check']}: {b['reason']}" for b in blockers)
            + "\n"
        )
        print(json.dumps({"action": "retry_refused", "blockers": blockers,
                          "would_retry": [c.name for c in retryable]},
                         indent=2))
        return 1

    if not retryable:
        print(json.dumps({"action": "noop", "reason": "no failed checks eligible"}, indent=2))
        return 0

    triggered = []
    for c in retryable:
        if c.run_id:
            gh("run", "rerun", c.run_id, "--failed", check=False)
            triggered.append(c.name)

            # update budget state
            pr_key = str(pr)
            pr_state = state["prs"].setdefault(pr_key, {
                "retries_used": 0, "retries_per_job": {}, "minutes_spent": 0,
            })
            pr_state["retries_used"] += 1
            pr_state["retries_per_job"][c.name] = pr_state["retries_per_job"].get(c.name, 0) + 1

    save_state(repo_root_path, state)
    print(json.dumps({"action": "retried", "checks": triggered,
                      "retries_used_pr": state["prs"][str(pr)]["retries_used"],
                      "retries_max_pr": cfg["retries_per_pr"]}, indent=2))
    return 0


# --------------------------------------------------------------------------- #
# CLI
# --------------------------------------------------------------------------- #


def emit(snap: Snapshot) -> None:
    payload = asdict(snap)
    print(json.dumps(payload, indent=2, default=str))
    sys.stdout.flush()


def cmd_once(pr: int, repo_root_path: Path) -> int:
    emit(assemble_snapshot(pr, repo_root_path))
    return 0


def cmd_watch(pr: int, repo_root_path: Path) -> int:
    cfg = load_config(repo_root_path)
    interval = int(cfg.get("watch_interval_seconds", 60))
    while True:
        snap = assemble_snapshot(pr, repo_root_path)
        # JSONL: one object per line
        print(json.dumps(asdict(snap), default=str))
        sys.stdout.flush()
        if "stop_pr_closed" in snap.actions:
            return 0
        time.sleep(interval)


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__.strip().splitlines()[0])
    p.add_argument("--pr", default="auto",
                   help="PR number, URL, or 'auto' to infer from current branch.")
    mode = p.add_mutually_exclusive_group()
    mode.add_argument("--once", action="store_true", default=True,
                      help="Single snapshot (default).")
    mode.add_argument("--watch", action="store_true",
                      help="Continuous JSONL stream until PR closes.")
    mode.add_argument("--retry-failed-now", action="store_true",
                      help="Trigger budget-aware reruns of failed checks.")
    mode.add_argument("--verify-flaky-green", action="store_true",
                      help="Re-run checks that flipped green but match the flaky ledger.")
    args = p.parse_args()

    pr = resolve_pr(args.pr)
    root = repo_root()

    if args.retry_failed_now:
        return retry_failed_now(pr, root)
    if args.verify_flaky_green:
        # Implemented as a targeted retry of greens that have ledger matches.
        snap = assemble_snapshot(pr, root)
        targets = [c for c in snap.checks
                   if c.conclusion == "success" and c.flaky_history and c.run_id]
        if not targets:
            print(json.dumps({"action": "noop",
                              "reason": "no flaky greens to verify"}, indent=2))
            return 0
        for c in targets:
            gh("run", "rerun", c.run_id, check=False)
        print(json.dumps({"action": "verifying", "checks": [c.name for c in targets]},
                         indent=2))
        return 0
    if args.watch:
        return cmd_watch(pr, root)
    return cmd_once(pr, root)


if __name__ == "__main__":
    sys.exit(main())
