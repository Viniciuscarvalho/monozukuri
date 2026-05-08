#!/usr/bin/env python3
"""action_runner.py — consume ci_watch --watch JSONL and execute action directives.

Pipe ci_watch --watch output into this script:
    python3 .ci-guard/scripts/ci_watch.py --pr auto --watch | \
    python3 .ci-guard/scripts/action_runner.py

Exit codes mirror ci_watch terminal values:
    0 — pr_merged or pr_closed
    2 — needs_help (human or agent must intervene)
    3 — budget_exhausted (reliability problem to investigate)
"""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

_SCRIPTS_DIR = Path(__file__).resolve().parent
_CI_WATCH = _SCRIPTS_DIR / "ci_watch.py"

_EXIT_CODES: dict[str, int] = {
    "pr_merged": 0,
    "pr_closed": 0,
    "needs_help": 2,
    "budget_exhausted": 3,
}


def _annotation(level: str, message: str) -> None:
    print(f"::{level}::{message}", flush=True)


def _run_ci_watch(pr_number: int, *args: str) -> None:
    subprocess.run(
        [sys.executable, str(_CI_WATCH), "--pr", str(pr_number), *args],
        check=False,
    )


def run(stream=None) -> int:
    if stream is None:
        stream = sys.stdin

    pr_number: int | None = None

    for raw in stream:
        raw = raw.strip()
        if not raw:
            continue

        try:
            snap = json.loads(raw)
        except json.JSONDecodeError:
            print(f"[action_runner] skipping non-JSON line: {raw}", file=sys.stderr, flush=True)
            continue

        if pr_number is None:
            pr_number = snap.get("pr_number")

        print(raw, flush=True)  # pass-through so the caller still sees the stream

        for act in snap.get("actions", []):
            action = act.get("action")

            if action == "idle":
                continue

            elif action == "retry_failed_now":
                if pr_number is not None:
                    _run_ci_watch(pr_number, "--retry-failed-now")

            elif action == "verify_flaky_green":
                if pr_number is not None:
                    _run_ci_watch(pr_number, "--verify-flaky-green")

            elif action == "diagnose_branch_failure":
                checks = ", ".join(act.get("checks", []))
                _annotation(
                    "error",
                    f"ci-guard: branch_failure — patch code before retrying: {checks}",
                )

            elif action == "diagnose_unknown":
                checks = ", ".join(act.get("checks", []))
                _annotation(
                    "warning",
                    f"ci-guard: unknown failure — read logs before retrying: {checks}",
                )

            elif action == "stop":
                reason = act.get("reason", "")
                code = _EXIT_CODES.get(reason, 0)
                _annotation(
                    "notice" if code == 0 else "warning",
                    f"ci-guard: terminal={reason} exit={code}",
                )
                return code

    return 0


if __name__ == "__main__":
    sys.exit(run())
