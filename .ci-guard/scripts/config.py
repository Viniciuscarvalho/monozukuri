#!/usr/bin/env python3
"""config.py — shared paths, defaults, and config loader for ci-guard scripts.

Import from a sibling script:
    import sys
    from pathlib import Path
    sys.path.insert(0, str(Path(__file__).parent))
    from config import LEDGER_PATH, CONFIG_PATH, STATE_PATH, load_config
"""

from __future__ import annotations

from pathlib import Path

# Bump this whenever scripts/*.py change in a way that affects behaviour.
# Must match the `version:` field in SKILL.md.
SCRIPT_VERSION = "0.4.0"

_SKILL_SEARCH_PATHS = [
    Path.home() / ".claude" / "skills" / "ci-guard" / "SKILL.md",
    Path.home() / ".codex" / "skills" / "ci-guard" / "SKILL.md",
    Path.home() / ".opencode" / "skills" / "ci-guard" / "SKILL.md",
]

# --------------------------------------------------------------------------- #
# Paths (relative to repo root)
# --------------------------------------------------------------------------- #

LEDGER_PATH = ".ci-guard/flaky-ledger.json"
CONFIG_PATH = ".ci-guard/config.yml"
STATE_PATH = ".ci-guard/.watch-state.json"  # gitignored

# --------------------------------------------------------------------------- #
# Budget defaults
# --------------------------------------------------------------------------- #

DEFAULT_BUDGET: dict = {
    "retries_per_job": 2,
    "retries_per_pr": 5,
    "minutes_per_pr": 90,
    "watch_interval_seconds": 60,
}

# --------------------------------------------------------------------------- #
# Quarantine thresholds — single source of truth for ci_watch and flaky_ledger
# --------------------------------------------------------------------------- #

QUARANTINE_FAIL_THRESHOLD: int = 3
QUARANTINE_RATE_THRESHOLD: float = 0.05


# --------------------------------------------------------------------------- #
# Config loading
# --------------------------------------------------------------------------- #

def _parse_skill_version(skill_md: Path) -> str | None:
    """Return the version string from SKILL.md frontmatter, or None if absent."""
    try:
        in_front = False
        for line in skill_md.read_text().splitlines():
            if line.strip() == "---":
                if not in_front:
                    in_front = True
                    continue
                break  # closing ---
            if in_front and line.startswith("version:"):
                return line.split(":", 1)[1].strip()
    except OSError:
        pass
    return None


def _version_tuple(v: str) -> tuple[int, ...]:
    try:
        return tuple(int(x) for x in v.split("."))
    except ValueError:
        return (0,)


def check_script_freshness() -> str | None:
    """Return a warning string if the local scripts are older than the installed skill.

    Returns None when scripts are current, the skill is not installed, or the
    version cannot be determined — so callers can treat None as 'no action needed'.
    """
    skill_version: str | None = None
    for candidate in _SKILL_SEARCH_PATHS:
        v = _parse_skill_version(candidate)
        if v is not None:
            skill_version = v
            break

    if skill_version is None:
        return None

    if _version_tuple(skill_version) > _version_tuple(SCRIPT_VERSION):
        return (
            f"[ci-guard] scripts are stale (local {SCRIPT_VERSION}, "
            f"skill {skill_version}). Re-run bootstrap from the repo root:\n"
            f"  python3 /path/to/ci-guard/scripts/bootstrap.py"
        )
    return None


def load_config(repo_root: Path) -> dict:
    """Load .ci-guard/config.yml, falling back to DEFAULT_BUDGET for missing keys."""
    cfg_path = repo_root / CONFIG_PATH
    cfg = dict(DEFAULT_BUDGET)
    if not cfg_path.exists():
        return cfg
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
