# Task 2.0: Implement Metrics Module (M)

**Status:** pending
**Complexity:** M _(S = <1h, M = 1-3h, L = 3h+)_
**Depends on:** Task 1
**Implements:** FR-004, FR-005, STORY-004, STORY-005

---

<critical>
Read the prd.md and techspec.md files in this folder BEFORE starting any work.
If you do not read these files, your task will be invalidated.
</critical>

<task_context>
<domain>metrics</domain>
<type>library</type>
<scope>Core metrics calculation and storage logic</scope>
<complexity>medium</complexity>
<dependencies>docs/canary-history.md schema (Task 1)</dependencies>
</task_context>

---

## Objective

Create `lib/memory/metrics.sh` containing core metrics calculation logic including schema validation, trailing average calculation, display formatting, and append function for new canary runs.

**Expected Outcome:** A new module `lib/memory/metrics.sh` exists with functions to read, validate, calculate, format, and append metrics data to `docs/canary-history.md`.

---

## Pre-Execution: Files to Read

_Read and understand these files before writing any code. This provides the context needed for accurate implementation._

| File                     | Why                                    | What to Look For                                         |
| ------------------------ | -------------------------------------- | -------------------------------------------------------- |
| `prd.md`                 | Understand FR-004, FR-005 requirements | Headline metric formula, diagnostic metrics definitions  |
| `techspec.md`            | See Component 4: MetricsModule         | Public interface, function signatures, internal behavior |
| `lib/memory/learning.sh` | Understand existing module patterns    | Module structure, error handling, logging patterns       |
| `lib/core/util.sh`       | Available utility functions            | err(), info(), log\_\*() functions                       |
| `docs/canary-history.md` | Schema to parse                        | Column order, data types, format                         |

---

## Subtasks

### 2.1: Create lib/memory/metrics.sh with boilerplate

**Action:** Create new module file with standard bash header
**File(s):** `lib/memory/metrics.sh`
**Details:**

- Add shebang and set -euo pipefail
- Add module description comment
- Source required dependencies (if any)

**Acceptance:**

- [ ] File exists at `lib/memory/metrics.sh`
- [ ] Has proper shebang: `#!/bin/bash`
- [ ] Has `set -euo pipefail` for error handling
- [ ] Has descriptive header comment

---

### 2.2: Implement schema validation function

**Action:** Create `_metrics_validate_schema` function
**File(s):** `lib/memory/metrics.sh`
**Details:**
Implement private function that:

- Reads canary-history.md
- Skips header and separator rows
- Validates each data row has exactly 6 pipe-delimited columns
- Validates date format (YYYY-MM-DD)
- Validates numeric fields (headline*%, tokens_avg, completion*%)
- Returns exit code 0 if valid, 2 if invalid

Reference techspec Component 4: MetricsModule for validation rules.

**Acceptance:**

- [ ] Function `_metrics_validate_schema` exists
- [ ] Validates column count (6 columns)
- [ ] Validates date format with regex
- [ ] Validates numeric fields
- [ ] Returns correct exit codes (0=valid, 2=invalid)

---

### 2.3: Implement row parsing and extraction

**Action:** Create `_metrics_extract_recent` and `_metrics_parse_row` functions
**File(s):** `lib/memory/metrics.sh`
**Details:**

- `_metrics_extract_recent <file> <n>`: Extract last N data rows, skip header
- `_metrics_parse_row <row>`: Parse pipe-delimited row into variables
- Handle edge case: fewer than N rows available

**Acceptance:**

- [ ] `_metrics_extract_recent` function exists
- [ ] Returns up to N rows (or fewer if insufficient data)
- [ ] Skips schema header and separator
- [ ] `_metrics_parse_row` correctly splits by pipe delimiter

---

### 2.4: Implement trailing average calculation

**Action:** Create `_metrics_calculate_trailing_average` function
**File(s):** `lib/memory/metrics.sh`
**Details:**

- Accept rows as input
- Extract headline\_% values
- Calculate arithmetic mean
- Handle edge cases: empty input, non-numeric values

**Acceptance:**

- [ ] Function `_metrics_calculate_trailing_average` exists
- [ ] Correctly sums headline\_% values
- [ ] Divides by count to get average
- [ ] Returns formatted percentage (e.g., "83.5")
- [ ] Handles edge case: no data (returns 0 or N/A)

---

### 2.5: Implement display formatting

**Action:** Create `metrics_display` public function
**File(s):** `lib/memory/metrics.sh`
**Details:**

- Validate schema first (call `_metrics_validate_schema`)
- Extract last 4 weeks of data
- Display formatted table with header
- Calculate and display 4-week trailing average
- Handle edge cases: empty history, fewer than 4 weeks

Reference techspec Component 4 for table format.

**Acceptance:**

- [ ] Function `metrics_display` exists (public API)
- [ ] Validates schema before displaying
- [ ] Displays human-readable table
- [ ] Shows 4-week trailing average
- [ ] Handles empty history gracefully

---

### 2.6: Implement append function

**Action:** Create `metrics_append` public function
**File(s):** `lib/memory/metrics.sh`
**Details:**

- Accept parameters: run*id, headline*%, tokens*avg, completion*%, stack_json
- Generate date stamp (YYYY-MM-DD format)
- Append pipe-delimited row to canary-history.md
- Create file if missing (with schema header from Task 1 template)

**Acceptance:**

- [ ] Function `metrics_append` exists (public API)
- [ ] Accepts 5 parameters (run_id through stack_json)
- [ ] Generates ISO 8601 date (YYYY-MM-DD)
- [ ] Appends formatted row to file
- [ ] Creates file with header if missing

---

## Implementation Constraints

_Rules from CLAUDE.md and project conventions that MUST be followed during this task._

- Use `set -euo pipefail` at script start
- Follow naming conventions: snake*case for functions, `*` prefix for private functions
- Use existing logging functions from `lib/core/util.sh` (err, info, log_debug)
- Do NOT modify `lib/memory/learning.sh` (per PRD constraint)
- All functions must have descriptive comments
- Exit codes: 0 (success), 1 (file not found), 2 (invalid schema)

---

## Edge Cases to Handle

| Scenario                           | Expected Behavior                                                 | Subtask  |
| ---------------------------------- | ----------------------------------------------------------------- | -------- |
| Empty history (header only)        | metrics_display shows "No canary runs recorded yet"               | 2.5      |
| Fewer than 4 weeks of data         | Display all available rows, calculate average with available data | 2.4, 2.5 |
| Malformed row (wrong column count) | Validation fails with exit code 2                                 | 2.2      |
| Invalid date format (04/26/2026)   | Validation fails with descriptive error                           | 2.2      |
| Non-numeric headline\_%            | Skip row with warning, continue                                   | 2.3      |
| History file doesn't exist         | metrics_append creates it with header                             | 2.6      |

---

## Files to Create / Modify

### New Files

| File Path               | Purpose                                    |
| ----------------------- | ------------------------------------------ |
| `lib/memory/metrics.sh` | Core metrics calculation and storage logic |

### Modified Files

_None_

---

## Test Requirements

### Tests to Write

_Tests will be created in Task 5 (Schema Validation Tests)_

For this task, perform manual testing:

### Test Scenarios

**Happy Path:**

1. Given valid canary-history.md with 4 weeks of data, when metrics_display is called, then table displays correctly with trailing average

**Error Cases:**

1. Given canary-history.md with invalid schema (5 columns), when \_metrics_validate_schema is called, then exit code 2
2. Given non-existent file, when metrics_display is called, then error message shown

**Edge Cases:**

1. Given canary-history.md with 2 weeks of data, when metrics_display is called, then both rows shown with 2-week average
2. Given empty history (header only), when metrics_display is called, then "No canary runs recorded yet" message

---

## Success Criteria

_All criteria must pass for this task to be marked as completed._

- [ ] All subtask acceptance criteria are met
- [ ] File `lib/memory/metrics.sh` exists with all required functions
- [ ] Public API functions: `metrics_display`, `metrics_append`
- [ ] Private functions: `_metrics_validate_schema`, `_metrics_extract_recent`, `_metrics_parse_row`, `_metrics_calculate_trailing_average`
- [ ] All functions have descriptive comments
- [ ] Code follows project conventions (error handling, logging, naming)
- [ ] Manual testing passes for all test scenarios

---

## Validation Commands

_Run these commands after implementation to verify the task is complete._

```bash
# Verify file exists
test -f lib/memory/metrics.sh && echo "✓ File exists" || echo "✗ File missing"

# Check syntax
bash -n lib/memory/metrics.sh && echo "✓ Syntax valid" || echo "✗ Syntax error"

# Shellcheck (lint)
shellcheck lib/memory/metrics.sh || echo "Shellcheck warnings (review and fix)"

# Manual test: source module and call functions
bash -c "
  source lib/memory/metrics.sh

  # Test append function
  metrics_append '/tmp/test-history.md' 'run-001' 85 45000 92 '{\"backend\":90}'

  # Test display function
  metrics_display '/tmp/test-history.md'

  # Cleanup
  rm -f /tmp/test-history.md
"
```

**Expected output:** All syntax checks pass, manual test creates file and displays data.

---

## Rollback Plan

_If this task introduces breaking changes, how to undo:_

```bash
# Remove created module
rm -f lib/memory/metrics.sh
```

---

## Notes

- This is a core module that will be used by Tasks 3, 5, 6, and 7
- The public API (`metrics_display`, `metrics_append`) must match techspec exactly
- Private functions (prefixed with `_`) are internal implementation details
- Use `awk` for calculations, `grep` for parsing, standard bash string manipulation
- JSON parsing (stack_breakdown_json) will use `jq` in later tasks
