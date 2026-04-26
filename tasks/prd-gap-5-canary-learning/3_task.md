# Task 3.0: Implement Metrics Command (S)

**Status:** pending
**Complexity:** S _(S = <1h, M = 1-3h, L = 3h+)_
**Depends on:** Task 2
**Implements:** FR-003, STORY-003

---

<critical>
Read the prd.md and techspec.md files in this folder BEFORE starting any work.
If you do not read these files, your task will be invalidated.
</critical>

<task_context>
<domain>cli</domain>
<type>command</type>
<scope>User-facing metrics command</scope>
<complexity>low</complexity>
<dependencies>lib/memory/metrics.sh (Task 2)</dependencies>
</task_context>

---

## Objective

Create `cmd/metrics.sh` as a user-facing CLI command that reads `docs/canary-history.md` and displays recent performance trends. Add command routing in `orchestrate.sh`.

**Expected Outcome:** Users can run `monozukuri metrics` to view the last 4 weeks of canary data and the trailing average.

---

## Pre-Execution: Files to Read

_Read and understand these files before writing any code. This provides the context needed for accurate implementation._

| File                    | Why                                     | What to Look For                                 |
| ----------------------- | --------------------------------------- | ------------------------------------------------ |
| `prd.md`                | Understand FR-003 requirements          | Command behavior, exit codes, error messages     |
| `techspec.md`           | See Component 3: MetricsCommand         | Public interface, sub_metrics function signature |
| `cmd/routing.sh`        | Pattern reference for command structure | How sub_routing is structured, module sourcing   |
| `orchestrate.sh`        | Understand command dispatch             | How subcommands are routed                       |
| `lib/memory/metrics.sh` | API to use                              | metrics_display function signature               |

---

## Subtasks

### 3.1: Create cmd/metrics.sh with sub_metrics function

**Action:** Create new command file following existing patterns
**File(s):** `cmd/metrics.sh`
**Details:**

- Add bash header with set -euo pipefail
- Add descriptive comment explaining the command
- Define `sub_metrics` function (called by orchestrate.sh)
- Source required modules (core/modules, core/util, memory/metrics)
- Check if history file exists, exit 1 if missing
- Call metrics_display from lib/memory/metrics.sh

Reference techspec Component 3 for exact implementation.

**Acceptance:**

- [ ] File exists at `cmd/metrics.sh`
- [ ] Has proper shebang and error handling
- [ ] Defines `sub_metrics` function
- [ ] Sources lib/memory/metrics.sh
- [ ] Checks file existence before calling metrics_display
- [ ] Exits with code 1 if history file missing

---

### 3.2: Add command routing in orchestrate.sh

**Action:** Modify orchestrate.sh to recognize `metrics` subcommand
**File(s):** `orchestrate.sh`
**Details:**
Add routing for `metrics` subcommand following the pattern of existing commands (e.g., `routing`, `learning`).

Find the case statement in orchestrate.sh and add:

```bash
metrics)
  source "$CMD_DIR/metrics.sh"
  sub_metrics
  ;;
```

**Acceptance:**

- [ ] orchestrate.sh recognizes `metrics` subcommand
- [ ] Sources cmd/metrics.sh when metrics is invoked
- [ ] Calls sub_metrics function
- [ ] Follows existing command routing pattern

---

### 3.3: Add usage help text

**Action:** Add metrics to help/usage output
**File(s):** `orchestrate.sh`
**Details:**
Add metrics command to the usage/help text in orchestrate.sh:

```
  metrics                  View recent canary metrics and trends
```

**Acceptance:**

- [ ] Help text includes metrics command
- [ ] Description is concise and clear
- [ ] Follows formatting of other commands

---

## Implementation Constraints

_Rules from CLAUDE.md and project conventions that MUST be followed during this task._

- Use `set -euo pipefail` at script start
- Follow existing command structure (see cmd/routing.sh)
- Function name must be `sub_metrics` (convention for all commands)
- Use module_require pattern for dependencies
- Use err() and info() from lib/core/util.sh for messages
- Exit codes: 0 (success), 1 (file not found), 2 (invalid schema)

---

## Edge Cases to Handle

| Scenario                         | Expected Behavior                                | Subtask |
| -------------------------------- | ------------------------------------------------ | ------- |
| History file missing             | Exit 1 with error message                        | 3.1     |
| History file corrupted           | Exit 2 with error message (from metrics_display) | 3.1     |
| Empty history (header only)      | Display "No canary runs recorded yet"            | 3.1     |
| Command called without arguments | Display metrics (no arguments needed)            | 3.1     |

---

## Files to Create / Modify

### New Files

| File Path        | Purpose                     |
| ---------------- | --------------------------- |
| `cmd/metrics.sh` | User-facing metrics command |

### Modified Files

| File Path        | What Changes        | Lines/Section to Modify                         |
| ---------------- | ------------------- | ----------------------------------------------- |
| `orchestrate.sh` | Add metrics routing | Case statement for subcommands, usage/help text |

---

## Test Requirements

### Tests to Write

| Test File                    | Test Description       | Covers Subtask |
| ---------------------------- | ---------------------- | -------------- |
| `test/unit/cmd_metrics.bats` | Command behavior tests | 3.1            |

### Test Scenarios

**Happy Path:**

1. Given valid canary-history.md, when `monozukuri metrics` is run, then metrics display correctly

**Error Cases:**

1. Given missing history file, when `monozukuri metrics` is run, then exit code 1 with error message
2. Given corrupted history file, when `monozukuri metrics` is run, then exit code 2 with error message

**Edge Cases:**

1. Given empty history (header only), when `monozukuri metrics` is run, then "No canary runs recorded yet" message

---

## Success Criteria

_All criteria must pass for this task to be marked as completed._

- [ ] All subtask acceptance criteria are met
- [ ] File `cmd/metrics.sh` exists with `sub_metrics` function
- [ ] orchestrate.sh routes `metrics` subcommand correctly
- [ ] Help text includes metrics command
- [ ] Tests written in test/unit/cmd_metrics.bats
- [ ] All tests passing
- [ ] Shellcheck passes

---

## Validation Commands

_Run these commands after implementation to verify the task is complete._

```bash
# Verify file exists
test -f cmd/metrics.sh && echo "✓ cmd/metrics.sh exists" || echo "✗ File missing"

# Check syntax
bash -n cmd/metrics.sh && echo "✓ Syntax valid" || echo "✗ Syntax error"

# Shellcheck
shellcheck cmd/metrics.sh

# Test command with missing history file
./orchestrate.sh metrics
# Expected: exit 1, error message "No canary history found"

# Test command with valid history file (manual setup)
# 1. Ensure docs/canary-history.md exists with sample data
# 2. Run: ./orchestrate.sh metrics
# Expected: exit 0, table display with metrics

# Run unit tests
bats test/unit/cmd_metrics.bats
```

**Expected output:** Syntax valid, shellcheck passes, tests pass.

---

## Rollback Plan

_If this task introduces breaking changes, how to undo:_

```bash
# Remove created command file
rm -f cmd/metrics.sh

# Revert orchestrate.sh changes
git checkout orchestrate.sh
```

---

## Notes

- This is a thin wrapper around lib/memory/metrics.sh
- The command should be simple: validate file exists, call metrics_display
- Error handling is delegated to lib/memory/metrics.sh (metrics_display validates schema)
- The command takes no arguments in v1 (future: --format json, --weeks N)
