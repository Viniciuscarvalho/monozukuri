#!/usr/bin/env python3
"""ci_watch.py — snapshot CI state for a PR with classifications and a cost guard.

Outputs JSON (one object in --once mode, JSONL in --watch mode). Refuses to
retry failed jobs unless every failure classifies as something other than
branch_failure AND retry budgets are not exceeded.

Depends on: gh CLI (authenticated), python 3.9+, stdlib only.

Sister scripts:
    flaky_ledger.py        — persistent per-repo flaky-test ledger.
    classify_failure.py    — heuristics for log-based failure classification.
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import time
from dataclasses import asdict, dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Any, Optional

_sleep = time.sleep  # replaced in tests via unittest.mock.patch

sys.path.insert(0, str(Path(__file__).parent))
from classify_failure import classify  # noqa: E402
from config import (  # noqa: E402
    DEFAULT_BUDGET,
    LEDGER_PATH,
    QUARANTINE_FAIL_THRESHOLD,
    QUARANTINE_RATE_THRESHOLD,
    STATE_PATH,
    check_script_freshness,
    load_config,
)
from flaky_ledger import record_failure, record_pass  # noqa: E402

_freshness_warning = check_script_freshness()
if _freshness_warning:
    print(_freshness_warning, file=sys.stderr)

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
    mergeable: Optional[str]  # MERGEABLE / CONFLICTING / UNKNOWN
    checks: list[CheckSnapshot] = field(default_factory=list)
    actions: list[dict] = field(default_factory=list)
    terminal: Optional[str] = None  # pr_merged / pr_closed / needs_help / budget_exhausted
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


def _gh_returncode(*args: str) -> int:
    """Run a gh command and return its exit code without raising."""
    try:
        return subprocess.run(["gh", *args], capture_output=True, text=True).returncode
    except FileNotFoundError:
        sys.stderr.write("ci-guard: 'gh' CLI not found. Install from https://cli.github.com.\n")
        sys.exit(2)


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


def load_ledger(repo_root: Path) -> dict:
    p = repo_root / LEDGER_PATH
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
    p = repo_root / STATE_PATH
    if not p.exists():
        return {"state_version": 1, "prs": {}}
    try:
        data = json.loads(p.read_text())
        if "state_version" not in data:  # migrate v0 files
            data["state_version"] = 1
        return data
    except json.JSONDecodeError:
        return {"state_version": 1, "prs": {}}


def save_state(repo_root: Path, state: dict) -> None:
    state["state_version"] = 1
    p = repo_root / STATE_PATH
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
    """Decide which bucket a failed check falls into."""
    if check.get("conclusion") not in {"failure", "cancelled", "timed_out"}:
        return {"category": "n/a", "confidence": "n/a", "reason": "Not a failure."}

    run_id = check.get("run_id")
    log = fetch_failed_log(run_id) if run_id else ""

    result = classify(log)

    # Ledger lookup: if a known-flaky test appears in the log, prefer test_flake.
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


def _extract_run_id(link: str) -> str:
    """Parse the GitHub Actions run ID from a check link URL."""
    if "/runs/" in link:
        return link.split("/runs/")[1].split("/")[0]
    return ""


def _normalize_check(c: dict) -> tuple[str, Optional[str], Optional[int]]:
    """Map gh pr checks fields to (status, conclusion, duration_seconds)."""
    bucket = (c.get("bucket") or "").lower()
    status = (
        "completed" if bucket in {"pass", "fail", "cancel", "skipping"}
        else (c.get("state") or "").lower() or "in_progress"
    )
    conclusion = {"pass": "success", "fail": "failure",
                  "cancel": "cancelled", "skipping": "skipped"}.get(bucket)
    duration_seconds = None
    if c.get("startedAt") and c.get("completedAt"):
        try:
            s = datetime.fromisoformat(c["startedAt"].replace("Z", "+00:00"))
            e = datetime.fromisoformat(c["completedAt"].replace("Z", "+00:00"))
            duration_seconds = int((e - s).total_seconds())
        except Exception:
            pass
    return status, conclusion, duration_seconds


def _enrich_check(snap: CheckSnapshot, ledger: dict, repo_root_path: Path) -> None:
    """Attach classification and flaky history for failed checks (mutates snap)."""
    if snap.conclusion not in {"failure", "cancelled", "timed_out"}:
        return
    snap.classification = classify_check(
        {"conclusion": snap.conclusion, "name": snap.name, "run_id": snap.run_id},
        ledger, repo_root_path,
    )
    snap.flaky_history = _flaky_history_for_check(snap.classification, ledger)


def _check_to_snapshot(c: dict, ledger: dict, repo_root_path: Path,
                       state: dict, pr: int) -> CheckSnapshot:
    run_id = _extract_run_id(c.get("link", "") or "")
    status, conclusion, duration_seconds = _normalize_check(c)
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
    _enrich_check(snap, ledger, repo_root_path)
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


def decide_actions(
    snap: Snapshot, budget: dict
) -> tuple[list[dict], Optional[str]]:
    """Pure function — no I/O. Returns (actions, terminal).

    terminal is None while the loop should continue, or one of:
      pr_merged, pr_closed, needs_help, budget_exhausted.
    """
    state = (snap.pr_state or "").upper()
    if state == "MERGED":
        return [{"action": "stop", "reason": "pr_merged"}], "pr_merged"
    if state == "CLOSED":
        return [{"action": "stop", "reason": "pr_closed"}], "pr_closed"

    actions: list[dict] = []

    branch_checks = [
        c.name for c in snap.checks
        if c.classification.get("category") == "branch_failure"
        and c.conclusion in {"failure", "cancelled", "timed_out"}
    ]
    unknown_checks = [
        c.name for c in snap.checks
        if c.classification.get("category") == "unknown"
        and c.conclusion in {"failure", "cancelled", "timed_out"}
    ]
    retryable_checks = [
        c.name for c in snap.checks
        if c.classification.get("category") in {"infra_flake", "test_flake", "dependency_failure"}
        and c.conclusion in {"failure", "cancelled", "timed_out"}
    ]
    flaky_green_checks = [
        c.name for c in snap.checks
        if c.conclusion == "success" and c.flaky_history
    ]
    has_failure = any(
        c.conclusion in {"failure", "cancelled", "timed_out"} for c in snap.checks
    )

    if branch_checks:
        actions.append({"action": "diagnose_branch_failure", "checks": branch_checks})
    if unknown_checks:
        actions.append({"action": "diagnose_unknown", "checks": unknown_checks})
    if flaky_green_checks:
        actions.append({"action": "verify_flaky_green", "checks": flaky_green_checks})
    if retryable_checks and not budget["any_budget_exhausted"] and not branch_checks:
        actions.append({"action": "retry_failed_now"})

    terminal: Optional[str] = None
    if budget["any_budget_exhausted"] and has_failure:
        terminal = "needs_help" if snap.quarantine_candidates else "budget_exhausted"

    if terminal:
        actions.append({"action": "stop", "reason": terminal})
    elif not actions:
        actions.append({"action": "idle"})

    return actions, terminal


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

    snapshot.quarantine_candidates = _quarantine_candidates(ledger)
    snapshot.actions, snapshot.terminal = decide_actions(snapshot, budget)
    return snapshot


def _quarantine_candidates(ledger: dict) -> list[dict]:
    out = []
    for tid, entry in ledger.get("tests", {}).items():
        if entry.get("status") == "quarantined":
            continue
        if entry.get("failure_count_30d", 0) >= QUARANTINE_FAIL_THRESHOLD and entry.get("flake_rate", 0) >= QUARANTINE_RATE_THRESHOLD:
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


def _gate_retry(
    checks: list[CheckSnapshot], budget: dict
) -> tuple[list[CheckSnapshot], list[dict]]:
    """Split failed checks into retryable and blocked lists."""
    retryable: list[CheckSnapshot] = []
    blockers: list[dict] = []
    for c in checks:
        if c.conclusion not in {"failure", "cancelled", "timed_out"}:
            continue
        ok, reason = can_retry(c, budget)
        if ok:
            retryable.append(c)
        else:
            blockers.append({"check": c.name, "reason": reason,
                             "category": c.classification.get("category")})
    return retryable, blockers


def retry_failed_now(pr: int, repo_root_path: Path) -> int:
    cfg = load_config(repo_root_path)
    state = load_state(repo_root_path)
    snap = assemble_snapshot(pr, repo_root_path)

    retryable, blockers = _gate_retry(snap.checks, snap.cost_summary)

    if blockers:
        sys.stderr.write(
            "ci-guard: retry refused. Blockers:\n"
            + "\n".join(f"  - {b['check']}: {b['reason']}" for b in blockers)
            + "\n"
        )
        print(json.dumps({"action": "retry_refused", "blockers": blockers,
                          "would_retry": [c.name for c in retryable]}, indent=2))
        return 1

    if not retryable:
        print(json.dumps({"action": "noop", "reason": "no failed checks eligible"}, indent=2))
        return 0

    pr_key = str(pr)
    pr_state = state["prs"].setdefault(pr_key, {
        "retries_used": 0, "retries_per_job": {}, "minutes_spent": 0,
    })
    triggered = []
    for c in retryable:
        if not c.run_id:
            continue
        if _gh_returncode("run", "rerun", c.run_id, "--failed") == 0:
            triggered.append(c.name)
            pr_state["retries_used"] += 1
            pr_state["retries_per_job"][c.name] = pr_state["retries_per_job"].get(c.name, 0) + 1
        else:
            sys.stderr.write(f"ci-guard: rerun of {c.run_id} failed; budget unchanged.\n")

    save_state(repo_root_path, state)
    print(json.dumps({"action": "retried", "checks": triggered,
                      "retries_used_pr": pr_state["retries_used"],
                      "retries_max_pr": cfg["retries_per_pr"]}, indent=2))
    return 0


# --------------------------------------------------------------------------- #
# Ledger auto-recording
# --------------------------------------------------------------------------- #


def _auto_record_events(snap: Snapshot, repo_root_path: Path, state: dict) -> None:
    """Record test_flake failures and passes for ledger-tracked checks.

    Deduplicates by run_id:check_name so repeated --once calls on the
    same SHA don't double-count events.
    """
    ledger = load_ledger(repo_root_path)
    ledger_path = repo_root_path / LEDGER_PATH
    pr_key = str(snap.pr_number)
    pr_state = state["prs"].setdefault(pr_key, {
        "retries_used": 0, "retries_per_job": {}, "minutes_spent": 0,
    })
    recorded: set[str] = set(pr_state.setdefault("recorded_events", []))

    for c in snap.checks:
        if not c.run_id:
            continue
        event_key = f"{c.run_id}:{c.name}"
        if event_key in recorded:
            continue
        if (c.conclusion in {"failure", "cancelled", "timed_out"}
                and c.classification.get("category") == "test_flake"):
            record_failure(c.name, sha=snap.head_sha, run_id=c.run_id,
                           ledger_path=ledger_path)
            recorded.add(event_key)
        elif c.conclusion == "success" and c.name in ledger.get("tests", {}):
            record_pass(c.name, sha=snap.head_sha, run_id=c.run_id,
                        ledger_path=ledger_path)
            recorded.add(event_key)

    pr_state["recorded_events"] = list(recorded)
    save_state(repo_root_path, state)


# --------------------------------------------------------------------------- #
# CLI
# --------------------------------------------------------------------------- #


def emit(snap: Snapshot) -> None:
    payload = asdict(snap)
    print(json.dumps(payload, indent=2, default=str))
    sys.stdout.flush()


def _terminal_exit_code(terminal: str) -> int:
    return {"pr_merged": 0, "pr_closed": 0, "needs_help": 2, "budget_exhausted": 3}.get(
        terminal, 0
    )


def cmd_once(pr: int, repo_root_path: Path) -> int:
    snap = assemble_snapshot(pr, repo_root_path)
    emit(snap)
    _auto_record_events(snap, repo_root_path, load_state(repo_root_path))
    return 0


def cmd_watch(pr: int, repo_root_path: Path) -> int:
    cfg = load_config(repo_root_path)
    interval = int(cfg.get("watch_interval_seconds", DEFAULT_BUDGET["watch_interval_seconds"]))
    pr_key = str(pr)

    init_state = load_state(repo_root_path)
    pr_entry = init_state.get("prs", {}).get(pr_key, {})

    # Fast-path: already reached a terminal state in a previous run.
    last_terminal = pr_entry.get("last_terminal")
    if last_terminal:
        sys.stderr.write(
            f"ci-guard: PR #{pr} previously reached terminal '{last_terminal}'; exiting.\n"
        )
        return _terminal_exit_code(last_terminal)

    # Seed cadence tracking from persisted state so restarts don't miss changes.
    prev_sha: Optional[str] = pr_entry.get("last_seen_sha")
    prev_check_states: dict = pr_entry.get("last_seen_check_states", {})

    while True:
        snap = assemble_snapshot(pr, repo_root_path)

        cur_check_states = {c.name: c.conclusion for c in snap.checks}
        changed = snap.head_sha != prev_sha or cur_check_states != prev_check_states
        prev_sha = snap.head_sha
        prev_check_states = cur_check_states

        print(json.dumps(asdict(snap), default=str))
        sys.stdout.flush()

        # Mutate + save state: recorded_events, then tracking fields.
        state = load_state(repo_root_path)
        _auto_record_events(snap, repo_root_path, state)
        _pr = state.setdefault("prs", {}).setdefault(pr_key, {
            "retries_used": 0, "retries_per_job": {}, "minutes_spent": 0,
        })
        _pr["last_seen_sha"] = prev_sha
        _pr["last_seen_check_states"] = prev_check_states
        if snap.terminal:
            _pr["last_terminal"] = snap.terminal
        save_state(repo_root_path, state)

        if snap.terminal:
            return _terminal_exit_code(snap.terminal)

        if not changed:
            _sleep(interval)


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
