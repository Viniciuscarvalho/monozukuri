# Task 6.0: Implement Canary Orchestrator (L)

**Status:** pending
**Complexity:** L _(S = <1h, M = 1-3h, L = 3h+)_
**Depends on:** Tasks 2, 5
**Implements:** FR-008, STORY-008

---

<critical>
Read the prd.md and techspec.md files in this folder BEFORE starting any work.
If you do not read these files, your task will be invalidated.
</critical>

<task_context>
<domain>orchestration</domain>
<type>canary-execution</type>
<scope>Execute canary benchmark suite and record metrics</scope>
<complexity>high</complexity>
<dependencies>lib/memory/metrics.sh (Task 2), schema validation tests (Task 5)</dependencies>
</task_context>

---

## Objective

Create `lib/run/canary.sh` to orchestrate canary benchmark suite execution, track CI pass/fail status, token counts, completion status, retries, and flakes, then append results to `docs/canary-history.md`.

**Expected Outcome:** A new module `lib/run/canary.sh` exists that can execute a canary suite, calculate headline and diagnostic metrics, and record results.

---

## Pre-Execution: Files to Read

_Read and understand these files before writing any code. This provides the context needed for accurate implementation._

| File                    | Why                                 | What to Look For                                         |
| ----------------------- | ----------------------------------- | -------------------------------------------------------- |
| `prd.md`                | Understand FR-008 requirements      | Canary execution, metric tracking, error handling        |
| `techspec.md`           | See Component 5: CanaryOrchestrator | Public interface, internal behavior, metric calculations |
| `lib/run/routing.sh`    | Pattern reference for run modules   | Module structure, orchestration patterns                 |
| `lib/memory/metrics.sh` | API to use                          | metrics_append function signature                        |
| `lib/core/cost.sh`      | Cost tracking integration           | How to read token counts from cost.json                  |

---

## Subtasks

### 6.1: Create lib/run/canary.sh with boilerplate

**Action:** Create new module file with standard structure
**File(s):** `lib/run/canary.sh`
**Details:**

- Add shebang and set -euo pipefail
- Add module description comment
- Source required dependencies (modules, util, metrics)

**Acceptance:**

- [ ] File exists at `lib/run/canary.sh`
- [ ] Has proper shebang: `#!/bin/bash`
- [ ] Has `set -euo pipefail`
- [ ] Has descriptive header comment
- [ ] Sources required modules

---

### 6.2: Implement canary config loading

**Action:** Create function to load and validate canary config
**File(s):** `lib/run/canary.sh`
**Details:**

- Load `.monozukuri/canary-config.json`
- Validate JSON structure (features array, stacks array)
- Return feature list and stack mappings

Config format (reference techspec Entity 2: CanaryConfig):

```json
{
  "features": [
    {
      "id": "feat-001",
      "stack": "backend",
      "repo": "monozukuri-canaries",
      "path": "..."
    }
  ],
  "stacks": ["backend", "frontend", "mobile", "infra", "data"]
}
```

**Acceptance:**

- [ ] Function `_canary_load_config` exists
- [ ] Validates config file exists
- [ ] Parses JSON using jq or node
- [ ] Returns feature list
- [ ] Exits with error if config invalid

---

### 6.3: Implement feature execution tracking

**Action:** Create function to execute a single canary feature and track results
**File(s):** `lib/run/canary.sh`
**Details:**

- Execute feature via monozukuri run workflow (placeholder for v1)
- Track CI pass/fail status (check PR CI status)
- Track token count (read from `$STATE_DIR/<feature_id>/cost.json`)
- Track completion status (check checkpoint for completion)
- Track retries (phase retry count)
- Track flakes (CI re-run count)
- Return results as structured data

**Acceptance:**

- [ ] Function `_canary_execute_feature` exists
- [ ] Executes feature (stub/placeholder OK for v1)
- [ ] Tracks CI status (pass=1, fail=0)
- [ ] Reads token count from cost.json
- [ ] Tracks completion status
- [ ] Returns structured result (exit code + output)

---

### 6.4: Implement metric aggregation by stack

**Action:** Aggregate results by stack slice
**File(s):** `lib/run/canary.sh`
**Details:**

- Group feature results by stack (backend, frontend, mobile, etc.)
- Calculate per-stack headline % (CI pass rate)
- Calculate per-stack diagnostic metrics
- Build JSON object with stack breakdown

Example output:

```json
{ "backend": 90, "frontend": 80, "mobile": 85, "infra": 88, "data": 82 }
```

**Acceptance:**

- [ ] Function `_canary_aggregate_by_stack` exists
- [ ] Groups results by stack
- [ ] Calculates per-stack percentages
- [ ] Returns valid JSON object

---

### 6.5: Implement headline metric calculation

**Action:** Calculate overall CI-pass-rate-on-first-PR
**File(s):** `lib/run/canary.sh`
**Details:**

- Count features with CI pass on first PR attempt
- Calculate percentage: (pass_count / total_count) \* 100
- Handle edge case: zero features attempted (return "N/A")

Formula from PRD FR-004:
`headline_% = (features_with_ci_green_on_first_pr / total_features_attempted) * 100`

**Acceptance:**

- [ ] Function `_canary_calculate_headline` exists
- [ ] Calculates CI pass rate correctly
- [ ] Returns integer 0-100
- [ ] Handles zero features (returns "N/A")

---

### 6.6: Implement diagnostic metrics calculation

**Action:** Calculate tokens*avg, completion*%, phase_retry_rate, ci_flake_rate
**File(s):** `lib/run/canary.sh`
**Details:**

- `tokens_avg`: mean token count across all features
- `completion_%`: (features_fully_completed / total) \* 100
- `phase_retry_rate`: average phase retries per feature
- `ci_flake_rate`: (features_with_ci_flakes / total) \* 100

Store retry/flake rates in stack_breakdown_json (not separate columns).

**Acceptance:**

- [ ] Function `_canary_calculate_diagnostics` exists
- [ ] Calculates tokens_avg (mean)
- [ ] Calculates completion\_%
- [ ] Calculates retry and flake rates
- [ ] Returns all metrics as variables

---

### 6.7: Implement canary_run main function

**Action:** Create public canary_run function that orchestrates entire flow
**File(s):** `lib/run/canary.sh`
**Details:**

1. Load canary config
2. Generate unique run_id: `run-YYYYMMDD-HHMMSS`
3. Loop through features, execute each, track results
4. Calculate headline metric
5. Calculate diagnostic metrics
6. Aggregate by stack
7. Append results to docs/canary-history.md via metrics_append
8. Log completion with run_id and headline%

**Acceptance:**

- [ ] Function `canary_run` exists (public API)
- [ ] Generates unique run_id
- [ ] Executes all features in config
- [ ] Calculates all metrics
- [ ] Appends to canary-history.md
- [ ] Logs completion message

---

### 6.8: Create example canary config

**Action:** Create example `.monozukuri/canary-config.json` for reference
**File(s):** `.monozukuri/canary-config.json`
**Details:**
Create example config with 2-3 sample features across different stacks.
Include comments (via JSON with // prefix, or separate .example file).

**Acceptance:**

- [ ] Example config file exists
- [ ] Contains features array with sample entries
- [ ] Contains stacks array
- [ ] Valid JSON format
- [ ] Includes inline documentation

---

## Implementation Constraints

_Rules from CLAUDE.md and project conventions that MUST be followed during this task._

- Use `set -euo pipefail` at script start
- Follow naming conventions: public `canary_run`, private `_canary_*`
- Use module_require pattern for dependencies
- Use err(), info(), log_info() for logging
- Exit codes: 0 (success), 1 (config missing/invalid)
- JSON parsing must use jq (already available per PRD)
- For v1, feature execution can be stubbed (placeholder)

---

## Edge Cases to Handle

| Scenario                       | Expected Behavior                    | Subtask |
| ------------------------------ | ------------------------------------ | ------- |
| Canary config missing          | Exit 1 with error message            | 6.2     |
| Feature execution fails        | Mark as incomplete, continue to next | 6.3     |
| All features fail              | Record 0% headline, commit result    | 6.7     |
| Zero features in config        | Exit 1 with error                    | 6.2     |
| Missing token data for feature | Exclude from tokens_avg              | 6.6     |
| Cannot write to history file   | Exit 1 with error                    | 6.7     |

---

## Files to Create / Modify

### New Files

| File Path                        | Purpose                    |
| -------------------------------- | -------------------------- |
| `lib/run/canary.sh`              | Canary orchestration logic |
| `.monozukuri/canary-config.json` | Example canary config      |

### Modified Files

_None_

---

## Test Requirements

### Tests to Write

_Integration tests will be created in Task 8_

For this task, perform manual testing with example config.

### Test Scenarios

**Happy Path:**

1. Given valid canary config with 2 features, when canary_run executes, then both features run and metrics recorded

**Error Cases:**

1. Given missing canary config, when canary_run executes, then exit 1 with error
2. Given invalid JSON config, when canary_run executes, then exit 1 with parse error

**Edge Cases:**

1. Given config with all failing features, when canary_run executes, then 0% headline recorded
2. Given feature with missing token data, when metrics calculated, then tokens_avg excludes that feature

---

## Success Criteria

_All criteria must pass for this task to be marked as completed._

- [ ] All subtask acceptance criteria are met
- [ ] File `lib/run/canary.sh` exists with canary_run function
- [ ] All private functions implemented (\_canary_load_config, \_canary_execute_feature, etc.)
- [ ] Example config `.monozukuri/canary-config.json` exists
- [ ] Manual testing passes with example config
- [ ] Metrics correctly appended to canary-history.md
- [ ] Shellcheck passes
- [ ] Code follows project conventions

---

## Validation Commands

_Run these commands after implementation to verify the task is complete._

```bash
# Verify file exists
test -f lib/run/canary.sh && echo "✓ File exists" || echo "✗ File missing"

# Check syntax
bash -n lib/run/canary.sh && echo "✓ Syntax valid" || echo "✗ Syntax error"

# Shellcheck
shellcheck lib/run/canary.sh

# Verify example config exists and is valid JSON
test -f .monozukuri/canary-config.json && jq . .monozukuri/canary-config.json > /dev/null && echo "✓ Valid JSON config" || echo "✗ Invalid config"

# Manual test: run canary with example config (stub execution)
bash -c "
  export PROJECT_ROOT=$(pwd)
  export LIB_DIR=$(pwd)/lib
  export STATE_DIR=$(pwd)/.monozukuri/state
  export CONFIG_DIR=$(pwd)/.monozukuri

  source lib/run/canary.sh
  canary_run
"

# Check that canary-history.md was updated
tail -1 docs/canary-history.md
```

**Expected output:** Syntax valid, shellcheck passes, canary_run executes and appends result.

---

## Rollback Plan

_If this task introduces breaking changes, how to undo:_

```bash
# Remove created files
rm -f lib/run/canary.sh
rm -f .monozukuri/canary-config.json
```

---

## Notes

- This is the most complex component in Gap 5 (Large task, 3+ hours)
- Feature execution can be stubbed for v1 (placeholder that returns mock results)
- Real feature execution will be implemented when monozukuri-canaries repo is ready
- Focus on metric calculation accuracy and data pipeline correctness
- JSON manipulation uses jq (per PRD Environment Manifest)
- Token reading from cost.json follows existing pattern in lib/core/cost.sh
