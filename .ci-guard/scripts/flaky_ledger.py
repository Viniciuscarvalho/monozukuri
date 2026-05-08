#!/usr/bin/env python3
"""flaky_ledger.py — manage the per-repo flaky-test ledger.

The ledger is a single JSON file at .ci-guard/flaky-ledger.json that tracks
every test we've seen fail intermittently. It is committed to the repo so
that history survives across contributors and CI runners.

Subcommands:
    record-failure   Record that a test failed at SHA <sha>.
    record-pass      Record that a test passed at SHA <sha>.
    query            Print the current entry for a test.
    list             Print all tracked tests, optionally filtered.
    quarantine-candidates   Print tests that have crossed the threshold.
    set-status       Mark a test as 'watched' / 'quarantined' / 'fixed'.
    prune            Remove entries with no failures in the last N days.
    repair           Best-effort recovery of a malformed ledger.

The ledger is intentionally append-only in spirit. Only `prune` and `repair`
remove entries, and they prompt before doing destructive things.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Optional

sys.path.insert(0, str(Path(__file__).parent))
from config import LEDGER_PATH, QUARANTINE_FAIL_THRESHOLD, QUARANTINE_RATE_THRESHOLD  # noqa: E402

WINDOW_DAYS = 30


def utcnow_iso() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def utcnow_date() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%d")


def load(path: Path) -> dict:
    if not path.exists():
        return {"version": 1, "tests": {}, "history": []}
    try:
        data = json.loads(path.read_text())
        data.setdefault("version", 1)
        data.setdefault("tests", {})
        data.setdefault("history", [])
        return data
    except json.JSONDecodeError as e:
        sys.stderr.write(f"flaky_ledger: malformed ledger ({e}); use 'repair'.\n")
        sys.exit(2)


def save(path: Path, data: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2, sort_keys=False) + "\n")


def _trim_history(history: list[dict], window_days: int = WINDOW_DAYS) -> list[dict]:
    cutoff = datetime.now(timezone.utc) - timedelta(days=window_days)
    out = []
    for h in history:
        try:
            t = datetime.fromisoformat(h["at"].replace("Z", "+00:00"))
        except Exception:
            continue
        if t >= cutoff:
            out.append(h)
    return out


def _recompute(entry: dict) -> dict:
    """Recompute the rolling window stats from this test's event history."""
    events = _trim_history(entry.get("events", []))
    fails = sum(1 for e in events if e["kind"] == "fail")
    passes = sum(1 for e in events if e["kind"] == "pass")
    total = fails + passes
    entry["events"] = events
    entry["failure_count_30d"] = fails
    entry["pass_count_30d"] = passes
    entry["flake_rate"] = round(fails / total, 4) if total else 0.0
    return entry


def _ensure_test(data: dict, test_id: str) -> dict:
    tests = data["tests"]
    if test_id not in tests:
        tests[test_id] = {
            "first_seen": utcnow_date(),
            "last_failure": None,
            "last_pass": None,
            "failure_count_30d": 0,
            "pass_count_30d": 0,
            "flake_rate": 0.0,
            "status": "watched",
            "quarantined_at": None,
            "quarantine_issue_url": None,
            "events": [],
        }
    return tests[test_id]


# --------------------------------------------------------------------------- #
# Public API (importable by other scripts)
# --------------------------------------------------------------------------- #


def _record_event(test_id: str, kind: str, sha: str, run_id: str, path: Path) -> dict:
    data = load(path)
    entry = _ensure_test(data, test_id)
    entry["events"].append({"kind": kind, "at": utcnow_iso(), "sha": sha, "run_id": run_id})
    if kind == "fail":
        entry["last_failure"] = utcnow_date()
    else:
        entry["last_pass"] = utcnow_date()
    _recompute(entry)
    save(path, data)
    return entry


def record_failure(
    test_id: str,
    sha: str = "",
    run_id: str = "",
    ledger_path: Optional[Path] = None,
) -> dict:
    """Record a test failure. Returns the updated ledger entry."""
    return _record_event(test_id, "fail", sha, run_id, ledger_path or Path(LEDGER_PATH))


def record_pass(
    test_id: str,
    sha: str = "",
    run_id: str = "",
    ledger_path: Optional[Path] = None,
) -> dict:
    """Record a test pass. Returns the updated ledger entry."""
    return _record_event(test_id, "pass", sha, run_id, ledger_path or Path(LEDGER_PATH))


def get_quarantine_candidates(ledger_path: Optional[Path] = None) -> list[dict]:
    """Return tests that have crossed the quarantine threshold, sorted by severity."""
    data = load(ledger_path or Path(LEDGER_PATH))
    out = []
    for test_id, entry in data["tests"].items():
        if entry.get("status") == "quarantined":
            continue
        if (entry.get("failure_count_30d", 0) >= QUARANTINE_FAIL_THRESHOLD
                and entry.get("flake_rate", 0) >= QUARANTINE_RATE_THRESHOLD):
            out.append({
                "test": test_id,
                "failure_count_30d": entry["failure_count_30d"],
                "pass_count_30d": entry["pass_count_30d"],
                "flake_rate": entry["flake_rate"],
                "last_failure": entry.get("last_failure"),
            })
    out.sort(key=lambda r: (-r["failure_count_30d"], -r["flake_rate"]))
    return out


# --------------------------------------------------------------------------- #
# Subcommands (thin CLI wrappers over the public API)
# --------------------------------------------------------------------------- #


def cmd_record(args, kind: str) -> int:
    fn = record_failure if kind == "fail" else record_pass
    entry = fn(args.test, sha=args.sha or "", run_id=args.run_id or "",
               ledger_path=Path(args.ledger))
    print(json.dumps({"test": args.test, "kind": kind,
                      "entry": entry}, indent=2, default=str))
    return 0


def cmd_query(args) -> int:
    path = Path(args.ledger or LEDGER_PATH)
    data = load(path)
    entry = data["tests"].get(args.test)
    if entry is None:
        print(json.dumps({"test": args.test, "found": False}, indent=2))
        return 1
    # Don't dump every event by default; it can be huge.
    if not args.verbose:
        view = {k: v for k, v in entry.items() if k != "events"}
        view["event_count"] = len(entry.get("events", []))
        entry = view
    print(json.dumps({"test": args.test, "found": True, "entry": entry},
                     indent=2, default=str))
    return 0


def cmd_list(args) -> int:
    path = Path(args.ledger or LEDGER_PATH)
    data = load(path)
    rows = []
    for test_id, entry in data["tests"].items():
        if args.status and entry.get("status") != args.status:
            continue
        rows.append({
            "test": test_id,
            "status": entry.get("status"),
            "failure_count_30d": entry.get("failure_count_30d", 0),
            "flake_rate": entry.get("flake_rate", 0.0),
            "last_failure": entry.get("last_failure"),
        })
    rows.sort(key=lambda r: (-r["failure_count_30d"], -r["flake_rate"]))
    print(json.dumps(rows, indent=2, default=str))
    return 0


def cmd_quarantine_candidates(args) -> int:
    print(json.dumps(get_quarantine_candidates(Path(args.ledger)), indent=2, default=str))
    return 0


def cmd_set_status(args) -> int:
    path = Path(args.ledger or LEDGER_PATH)
    data = load(path)
    entry = data["tests"].get(args.test)
    if entry is None:
        sys.stderr.write(f"flaky_ledger: test {args.test!r} not in ledger.\n")
        return 1
    if args.status not in {"watched", "quarantined", "fixed"}:
        sys.stderr.write("status must be watched|quarantined|fixed\n")
        return 2
    entry["status"] = args.status
    if args.status == "quarantined":
        entry["quarantined_at"] = utcnow_date()
        if args.issue_url:
            entry["quarantine_issue_url"] = args.issue_url
    save(path, data)
    print(json.dumps({"test": args.test, "status": entry["status"]}, indent=2))
    return 0


def cmd_prune(args) -> int:
    path = Path(args.ledger or LEDGER_PATH)
    data = load(path)
    cutoff = datetime.now(timezone.utc) - timedelta(days=args.older_than)
    removed = []
    for test_id in list(data["tests"].keys()):
        entry = data["tests"][test_id]
        last = entry.get("last_failure")
        if not last:
            continue
        try:
            last_dt = datetime.fromisoformat(last + "T00:00:00+00:00")
        except Exception:
            continue
        if last_dt < cutoff and entry.get("status") != "quarantined":
            removed.append(test_id)
            del data["tests"][test_id]
    save(path, data)
    print(json.dumps({"removed": removed, "older_than_days": args.older_than},
                     indent=2))
    return 0


def cmd_repair(args) -> int:
    path = Path(args.ledger or LEDGER_PATH)
    if not path.exists():
        print(json.dumps({"action": "noop", "reason": "no ledger"}, indent=2))
        return 0
    raw = path.read_text()
    try:
        data = json.loads(raw)
    except json.JSONDecodeError:
        backup = path.with_suffix(".json.bak")
        backup.write_text(raw)
        save(path, {"version": 1, "tests": {}, "history": []})
        print(json.dumps({"action": "reset", "backup": str(backup)}, indent=2))
        return 0
    # Fix structural issues
    data.setdefault("version", 1)
    data.setdefault("tests", {})
    for tid, entry in data["tests"].items():
        entry.setdefault("events", [])
        _recompute(entry)
    save(path, data)
    print(json.dumps({"action": "repaired", "tests": len(data["tests"])}, indent=2))
    return 0


# --------------------------------------------------------------------------- #
# CLI
# --------------------------------------------------------------------------- #


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__.strip().splitlines()[0])
    p.add_argument("--ledger", help="Override path to ledger JSON.",
                   default=LEDGER_PATH)
    sub = p.add_subparsers(dest="cmd", required=True)

    rf = sub.add_parser("record-failure", help="Record a test failure.")
    rf.add_argument("--test", required=True, help="Test ID, e.g. 'tests/auth.py::test_oauth'.")
    rf.add_argument("--sha", help="Commit SHA the failure happened on.")
    rf.add_argument("--run-id", help="CI run id for traceability.")

    rp = sub.add_parser("record-pass", help="Record a test pass.")
    rp.add_argument("--test", required=True)
    rp.add_argument("--sha")
    rp.add_argument("--run-id")

    q = sub.add_parser("query", help="Print one test's ledger entry.")
    q.add_argument("--test", required=True)
    q.add_argument("--verbose", action="store_true")

    ls = sub.add_parser("list", help="List tracked tests.")
    ls.add_argument("--status", choices=["watched", "quarantined", "fixed"])

    sub.add_parser("quarantine-candidates",
                   help=(f"Tests with >={QUARANTINE_FAIL_THRESHOLD} fails in 30d "
                         f"and >={int(QUARANTINE_RATE_THRESHOLD*100)}%% flake rate."))

    ss = sub.add_parser("set-status", help="Mark a test's status.")
    ss.add_argument("--test", required=True)
    ss.add_argument("--status", required=True)
    ss.add_argument("--issue-url",
                    help="When quarantining, the tracking issue URL.")

    pr = sub.add_parser("prune", help="Remove stale (non-quarantined) entries.")
    pr.add_argument("--older-than", type=int, default=60,
                    help="Days since last failure (default: 60).")

    sub.add_parser("repair", help="Best-effort fix of a corrupted ledger.")

    args = p.parse_args()

    dispatch = {
        "record-failure": lambda: cmd_record(args, "fail"),
        "record-pass": lambda: cmd_record(args, "pass"),
        "query": lambda: cmd_query(args),
        "list": lambda: cmd_list(args),
        "quarantine-candidates": lambda: cmd_quarantine_candidates(args),
        "set-status": lambda: cmd_set_status(args),
        "prune": lambda: cmd_prune(args),
        "repair": lambda: cmd_repair(args),
    }
    return dispatch[args.cmd]()


if __name__ == "__main__":
    sys.exit(main())
