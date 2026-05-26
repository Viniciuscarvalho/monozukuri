---
name: monozukuri-codex-readiness
description: Verify whether Monozukuri can run with Codex in loop or full-auto workflows by checking agent availability, skill discovery, dry-run behavior, and the targeted Bats validation path. Use for Monozukuri Codex readiness, loop, agent doctor, or skill availability questions. Do not use for unrelated repositories or generic CI triage.
---

# Monozukuri Codex Readiness

Verify current behavior with commands before answering whether Codex, skills, agents, or loop/full-auto workflows are usable.

## Preflight

Run from the Monozukuri repository root.

1. Capture worktree state with `git status --short`; do not stage broad paths in dirty checkouts.
2. Check Codex availability:
   ```bash
   ./orchestrate.sh agent doctor codex
   codex --version
   ```
3. Check agent selection and setup state:
   ```bash
   ./orchestrate.sh agent list
   ./orchestrate.sh setup status --agent codex
   ```
4. Check skill discovery if the question mentions skills:
   ```bash
   scripts/skill-discovery.sh
   ```
   If that script is unavailable or its interface has changed, use the repository's current discovery command and state the substitution.

## Dry Run

Use a non-interactive dry run to verify orchestration without spending model calls:

```bash
SKILL_TIMEOUT_SECONDS=180 ./orchestrate.sh run --dry-run --non-interactive --no-ui
```

Report exact failures. Do not soften shell errors as "environment issues" until the blocking command and stderr are identified.

## Known Failure Checks

When readiness fails, check these common regressions before proposing a new path:

- macOS Bash 3.2 incompatibility such as `${var^^}`; prefer `tr '[:lower:]' '[:upper:]'`.
- `set -u` failures from empty arrays such as `${flags[@]}`.
- Adapter output piping that loses error-envelope writes; temp-file capture is safer for fallback `adapter_tee`.
- Tests that accidentally read the user's global Claude configuration; isolate `CLAUDE_CONFIG_DIR` when testing Claude adapter behavior.
- `make test` wrappers that hide the true Bats exit code; prefer direct `bats ...` when a trustworthy result matters.

## Validation

Choose the narrowest validation path that proves the claim:

- Syntax/static checks for shell edits:
  ```bash
  bash -n cmd/run.sh cmd/setup.sh lib/agent/adapter-codex.sh lib/agent/thin-shell-base.sh scripts/agent-discovery.sh
  shellcheck --severity=error <changed-shell-files>
  git diff --check
  ```
- Loop command behavior:
  ```bash
  bats test/integration/loop_command.bats
  ```
- Full local confidence:
  ```bash
  bats test/unit test/integration test/conformance test/properties
  ```

Keep local validation separate from remote PR checks. If GitHub status is relevant, inspect it separately and report pending checks distinctly from local test results.

## Output

Return:

- Readiness verdict: `ready`, `partially ready`, or `blocked`.
- Evidence from each command, including versions, discovered skills count if available, and dry-run result.
- Fixes applied or the smallest next fix needed.
- Exact validation commands and outcomes.
- Any assumptions made for `MONOZUKURI_AUTONOMY=full_auto`.

In `full_auto`, never ask for human input. Make a defensible default, record it under open questions or assumptions, and continue.
