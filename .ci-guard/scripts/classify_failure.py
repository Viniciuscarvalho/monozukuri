#!/usr/bin/env python3
"""classify_failure.py — heuristic CI failure classifier.

Reads a failed-job log (from a file, a run id, or stdin) and emits a JSON
classification: branch_failure, infra_flake, test_flake, dependency_failure,
or unknown.

Patterns are intentionally conservative. When unsure, return 'unknown' so
the caller does a manual diagnosis pass instead of acting on a false signal.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from typing import Optional

# Each rule is (category, confidence, description, regex)
# Order matters: branch_failure rules run first so a real bug doesn't get
# masked by a coincidental network signal in the same log.
RULES: list[tuple[str, str, str, re.Pattern]] = [
    # ---------- branch_failure (real bugs in the change) ----------

    # Test runner output — check first so a failing test doesn't get masked
    # by a coincidental network line that appears later in the same log.
    ("branch_failure", "high", "TAP/BATS test failure (not ok N)",
     re.compile(r"^not ok \d+", re.M)),
    ("branch_failure", "high", "TAP bail-out (suite aborted)",
     re.compile(r"^Bail out!", re.M)),
    ("branch_failure", "high", "pytest FAILED line",
     re.compile(r"^FAILED ", re.M)),
    ("branch_failure", "high", "pytest FAILURES section",
     re.compile(r"^={3,} FAILURES ={3,}", re.M)),
    ("branch_failure", "high", "Jest / Vitest FAIL file line",
     re.compile(r"^\s*FAIL\s+\S+", re.M)),
    ("branch_failure", "high", "Jest / Vitest test count: N failed",
     re.compile(r"Tests?:\s+\d+ failed", re.I)),
    ("branch_failure", "high", "Mocha / tap N failing",
     re.compile(r"\b\d+ (failing|failed)\b", re.I)),
    ("branch_failure", "medium", "AssertionError (test assertion failed)",
     re.compile(r"\bAssertionError\b")),
    ("branch_failure", "medium", "RSpec / Ruby failure summary",
     re.compile(r"\d+ example[s]?,? \d+ failure", re.I)),
    ("branch_failure", "medium", "JUnit / Go test FAIL line",
     re.compile(r"^(FAIL\t|--- FAIL:)", re.M)),

    # Compiler / linter errors
    ("branch_failure", "high", "Python SyntaxError",
     re.compile(r"\bSyntaxError:", re.I)),
    ("branch_failure", "high", "TypeScript/Flow type error",
     re.compile(r"^.*?: error TS\d+:", re.M)),
    ("branch_failure", "high", "Go compile error",
     re.compile(r"^# .+\n.+\.go:\d+:\d+: ", re.M)),
    ("branch_failure", "high", "Rust compile error (rustc)",
     re.compile(r"error\[E\d{3,4}\]:", re.I)),
    ("branch_failure", "high", "Java/Kotlin compilation failure",
     re.compile(r"(error: )?compilation failed", re.I)),
    ("branch_failure", "high", "Snapshot mismatch",
     re.compile(r"snapshot (does not match|mismatch|doesn'?t match)", re.I)),
    ("branch_failure", "high", "Lint error in changed code",
     re.compile(r"\b(\d+) errors?, (\d+) warnings?", re.I)),
    ("branch_failure", "medium", "Module not found",
     re.compile(r"(Cannot find module|ModuleNotFoundError|No module named)", re.I)),
    ("branch_failure", "medium", "Missing import / undefined symbol",
     re.compile(r"(NameError|undefined reference to|cannot find symbol)", re.I)),

    # ---------- dependency_failure (registry / lockfile / 5xx from supply chain) ----------
    ("dependency_failure", "high", "npm registry 5xx/429",
     re.compile(r"npm (ERR! )?(429|5\d\d|registry returned)", re.I)),
    ("dependency_failure", "high", "yarn lockfile mismatch",
     re.compile(r"lockfile .* (out of date|mismatch)", re.I)),
    ("dependency_failure", "medium", "PyPI fetch error",
     re.compile(r"(could not fetch URL|HTTPSConnectionPool.*pypi)", re.I)),
    ("dependency_failure", "medium", "Cargo registry error",
     re.compile(r"error: failed to (fetch|download)", re.I)),
    ("dependency_failure", "medium", "Docker pull failure",
     re.compile(r"(error pulling image|failed to (pull|copy)|registry-1\.docker\.io)", re.I)),
    ("dependency_failure", "medium", "Go module proxy error",
     re.compile(r"proxy\.golang\.org.*\b5\d\d\b", re.I)),

    # ---------- infra_flake (runner / GH / network outside our control) ----------
    ("infra_flake", "high", "Runner shutdown",
     re.compile(r"the runner has received a shutdown signal", re.I)),
    ("infra_flake", "high", "Lost communication with runner",
     re.compile(r"lost communication with the server", re.I)),
    ("infra_flake", "high", "GitHub Actions infra error",
     re.compile(r"(GitHub Actions infrastructure|workflow run was canceled)", re.I)),
    ("infra_flake", "medium", "DNS failure",
     re.compile(r"(could not resolve host|getaddrinfo (failed|ENOTFOUND))", re.I)),
    ("infra_flake", "medium", "Network reset/timeout",
     re.compile(r"(connection reset by peer|i/o timeout|read: connection refused)", re.I)),
    ("infra_flake", "low", "Generic 503/502",
     re.compile(r"\b(502 Bad Gateway|503 Service Unavailable|504 Gateway Timeout)\b", re.I)),
    ("infra_flake", "low", "Out of disk on runner",
     re.compile(r"(no space left on device|disk quota exceeded)", re.I)),

    # ---------- test_flake (only fired by ci_watch when ledger matches; this rule
    #            is for when the log itself screams "race") ----------
    ("test_flake", "medium", "Race condition / timing pattern",
     re.compile(r"(timed? out waiting for|expected .* but got .* \(retried\)|"
                r"flaky test|known.{0,15}flaky)", re.I)),
]


def classify(log: str) -> dict:
    """Apply rules in order; return first match. If none, return unknown."""
    if not log.strip():
        return {"category": "unknown", "confidence": "low",
                "reason": "Empty log; cannot classify."}
    for category, confidence, description, pattern in RULES:
        m = pattern.search(log)
        if m:
            snippet = log[max(0, m.start() - 80): m.end() + 80].strip()
            snippet = " ".join(snippet.split())  # collapse whitespace
            if len(snippet) > 240:
                snippet = snippet[:240] + "…"
            return {
                "category": category,
                "confidence": confidence,
                "reason": description,
                "matched_pattern": pattern.pattern,
                "matched_snippet": snippet,
            }
    return {"category": "unknown", "confidence": "low",
            "reason": "No heuristic matched; manual diagnosis recommended."}


def fetch_log(run_id: str) -> str:
    try:
        r = subprocess.run(
            ["gh", "run", "view", run_id, "--log-failed"],
            capture_output=True, text=True, check=False,
        )
        return r.stdout
    except FileNotFoundError:
        sys.stderr.write("classify_failure: 'gh' CLI not found.\n")
        sys.exit(2)


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__.strip().splitlines()[0])
    src = p.add_mutually_exclusive_group(required=True)
    src.add_argument("--run-id", help="Fetch failed log for this run via gh CLI.")
    src.add_argument("--log-file", help="Path to a log file on disk.")
    src.add_argument("--stdin", action="store_true", help="Read log from stdin.")
    p.add_argument("--check-name", default=None,
                   help="Optional check name; included in the JSON output.")
    args = p.parse_args()

    if args.run_id:
        log = fetch_log(args.run_id)
    elif args.log_file:
        log = open(args.log_file, encoding="utf-8", errors="replace").read()
    else:
        log = sys.stdin.read()

    result = classify(log)
    if args.check_name:
        result["check_name"] = args.check_name
    print(json.dumps(result, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
