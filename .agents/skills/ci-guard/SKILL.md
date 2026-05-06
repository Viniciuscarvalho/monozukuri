---
name: ci-guard
description: Monitor, classify, and budget-safely retry GitHub Actions CI for a PR. Use when the user wants to snapshot CI state, retry failed checks, verify a flaky green, or classify a specific run failure. Requires gh CLI authenticated against the repo's GitHub account.
---

Guard CI using the scripts in `.ci-guard/scripts/`. All retries go through `ci_watch.py --retry-failed-now` — never call `gh run rerun` directly so budget counters and the flaky ledger stay in sync.

## Prerequisite

Before any ci-guard command, confirm `gh auth status` shows the correct GitHub account. If it fails or shows the wrong account, tell the user to run `gh auth login` and stop.

## Determine the user's intent

Ask or infer one of these modes:

| Mode                   | When to use                                             |
| ---------------------- | ------------------------------------------------------- |
| **snapshot**           | User wants to see current CI state / what's failing     |
| **retry**              | User wants to re-run failed checks (budget-aware)       |
| **verify-flaky-green** | User wants to re-confirm a green that has flaky history |
| **classify**           | User wants to understand why a specific run failed      |
| **quarantine-check**   | User wants to see which tests are quarantine candidates |

If still unclear, default to **snapshot**.

## Running each mode

All commands run from the repo root.

**snapshot** — single JSON dump of all checks with classifications:

```
python3 .ci-guard/scripts/ci_watch.py --pr auto --once
# or for a specific PR:
python3 .ci-guard/scripts/ci_watch.py --pr <number> --once
```

**retry** — budget-safe rerun (refuses if branch_failure or budget exceeded):

```
python3 .ci-guard/scripts/ci_watch.py --pr auto --retry-failed-now
```

**verify-flaky-green** — re-run checks that went green but match the flaky ledger:

```
python3 .ci-guard/scripts/ci_watch.py --pr auto --verify-flaky-green
```

**classify** — heuristic analysis of a specific run log:

```
python3 .ci-guard/scripts/classify_failure.py --run-id <run-id>
```

**quarantine-check** — surface tests that have ≥3 failures in 30d and ≥5% flake rate:

```
python3 .ci-guard/scripts/flaky_ledger.py quarantine-candidates
```

## Interpreting the output

After running, parse and summarize the JSON for the user:

- **actions: ["all_green"]** → CI is clean, safe to merge.
- **actions: ["branch_failure"]** → A real bug in the branch. Never retry; the user must fix the code. Show `classification.reason` and `matched_snippet`.
- **actions: ["retry_with_budget"]** → Infra/test/dependency flake. Show which checks and then run `--retry-failed-now` if the user confirms.
- **actions: ["diagnose_unknown"]** → No heuristic matched; show the raw log excerpt and suggest the user investigate before retrying.
- **actions: ["verify_flaky_green"]** → A green check has ledger matches; run `--verify-flaky-green` to confirm it wasn't a lucky pass.
- **actions: ["budget_exhausted_surface"]** → Retry budget spent; surface to the user that manual intervention is needed.
- **cost_summary.any_budget_exhausted: true** → Always tell the user budget is exhausted when present, regardless of other actions.

## Budget defaults (from `.ci-guard/config.yml`)

| Limit           | Default |
| --------------- | ------- |
| Retries per job | 2       |
| Retries per PR  | 5       |
| Minutes per PR  | 90      |

Overrides live in `.ci-guard/config.yml` (uncomment lines to change).

## GitHub Actions wiring (optional)

If the user asks to wire ci-guard into the workflow, add two steps to the test workflow YAML.

**Record failures to the ledger** (paste into any test job, `if: always()`):

```yaml
- name: Update flaky ledger
  if: always()
  run: |
    python3 .ci-guard/scripts/flaky_ledger.py record-failure \
      --test "${TEST_ID}" --sha "${{ github.sha }}" --run-id "${{ github.run_id }}" || true
```

**Warn on quarantine candidates** (add as a required status check):

```yaml
- name: Quarantine guard
  run: |
    candidates=$(python3 .ci-guard/scripts/flaky_ledger.py quarantine-candidates)
    if [ -n "$(echo "$candidates" | jq -r '.[]' 2>/dev/null)" ]; then
      echo "::warning::Quarantine candidates exist; review before merging."
      echo "$candidates"
    fi
```

When recommending the wiring, always show both steps together and remind the user to replace `${TEST_ID}` with the actual test identifier their framework exposes.
