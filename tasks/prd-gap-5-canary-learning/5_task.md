# Task 5.0: Schema Validation Tests (M)

**Status:** pending
**Complexity:** M _(S = <1h, M = 1-3h, L = 3h+)_
**Depends on:** Task 2
**Implements:** FR-007, STORY-007

---

<critical>
Read the prd.md and techspec.md files in this folder BEFORE starting any work.
If you do not read these files, your task will be invalidated.
</critical>

<task_context>
<domain>testing</domain>
<type>validation</type>
<scope>Schema validation and metrics calculation tests</scope>
<complexity>medium</complexity>
<dependencies>lib/memory/metrics.sh (Task 2)</dependencies>
</task_context>

---

## Objective

Create comprehensive bats tests for `lib/memory/metrics.sh` and `cmd/metrics.sh` to validate schema format, metrics calculations, and command behavior. Ensure MRP verification via automated testing.

**Expected Outcome:** Two test files exist with comprehensive coverage: `test/unit/lib_memory_metrics.bats` and `test/unit/cmd_metrics.bats`, all tests passing.

---

## Pre-Execution: Files to Read

_Read and understand these files before writing any code. This provides the context needed for accurate implementation._

| File                         | Why                                   | What to Look For                              |
| ---------------------------- | ------------------------------------- | --------------------------------------------- |
| `prd.md`                     | Understand FR-007 requirements        | Schema validation criteria, test requirements |
| `techspec.md`                | See Component 7: SchemaValidationTest | Test scenarios, edge cases                    |
| `test/unit/cmd_routing.bats` | Pattern reference for command tests   | Test structure, setup/teardown patterns       |
| `lib/memory/metrics.sh`      | Functions to test                     | Function signatures, expected behavior        |
| `cmd/metrics.sh`             | Command to test                       | Exit codes, error messages                    |

---

## Subtasks

### 5.1: Create test/unit/lib_memory_metrics.bats with setup/teardown

**Action:** Create test file with bats boilerplate
**File(s):** `test/unit/lib_memory_metrics.bats`
**Details:**

- Add bats shebang
- Define setup() to create test fixtures (temp directory, sample history files)
- Define teardown() to clean up test fixtures
- Source lib/memory/metrics.sh in setup

**Acceptance:**

- [ ] File exists at `test/unit/lib_memory_metrics.bats`
- [ ] Has proper bats shebang
- [ ] setup() creates temp test directory
- [ ] teardown() removes temp files
- [ ] Sources lib/memory/metrics.sh

---

### 5.2: Write schema validation tests

**Action:** Test \_metrics_validate_schema function
**File(s):** `test/unit/lib_memory_metrics.bats`
**Details:**
Test cases:

1. Valid schema with 6 columns passes (exit 0)
2. Invalid column count (5 columns) fails (exit 2)
3. Invalid date format (MM/DD/YYYY) fails (exit 2)
4. Non-numeric headline\_% fails (exit 2)
5. Valid JSON in stack_breakdown_json passes
6. Empty history (header only) passes

**Acceptance:**

- [ ] @test "schema validation passes for valid history"
- [ ] @test "schema validation fails for invalid column count"
- [ ] @test "schema validation fails for invalid date format"
- [ ] @test "schema validation fails for non-numeric fields"
- [ ] @test "schema validation passes for empty history"

---

### 5.3: Write trailing average calculation tests

**Action:** Test \_metrics_calculate_trailing_average function
**File(s):** `test/unit/lib_memory_metrics.bats`
**Details:**
Test cases:

1. Calculate average of 4 weeks (85, 82, 88, 90) = 86.25
2. Calculate average of 2 weeks (85, 80) = 82.5
3. Handle empty input (return 0 or N/A)
4. Handle non-numeric values gracefully

**Acceptance:**

- [ ] @test "trailing average calculation for 4 weeks"
- [ ] @test "trailing average calculation for fewer than 4 weeks"
- [ ] @test "trailing average handles empty input"

---

### 5.4: Write metrics_append tests

**Action:** Test metrics_append function
**File(s):** `test/unit/lib_memory_metrics.bats`
**Details:**
Test cases:

1. Append creates file if missing (with header)
2. Append adds row to existing file
3. Appended row has correct format (6 columns)
4. Date stamp is current date (YYYY-MM-DD)

**Acceptance:**

- [ ] @test "metrics_append creates file if missing"
- [ ] @test "metrics_append adds row to existing file"
- [ ] @test "appended row has 6 columns"
- [ ] @test "appended date is current date"

---

### 5.5: Write metrics_display tests

**Action:** Test metrics_display function
**File(s):** `test/unit/lib_memory_metrics.bats`
**Details:**
Test cases:

1. Display shows table for valid history
2. Display shows trailing average
3. Display handles empty history (message shown)
4. Display handles fewer than 4 weeks

**Acceptance:**

- [ ] @test "metrics_display shows table for valid history"
- [ ] @test "metrics_display shows 4-week trailing average"
- [ ] @test "metrics_display handles empty history gracefully"

---

### 5.6: Create test/unit/cmd_metrics.bats for command tests

**Action:** Create command test file
**File(s):** `test/unit/cmd_metrics.bats`
**Details:**

- Setup/teardown for test fixtures
- Source cmd/metrics.sh
- Mock PROJECT_ROOT, LIB_DIR, etc.

**Acceptance:**

- [ ] File exists at `test/unit/cmd_metrics.bats`
- [ ] setup() creates test environment
- [ ] teardown() cleans up

---

### 5.7: Write command behavior tests

**Action:** Test monozukuri metrics command
**File(s):** `test/unit/cmd_metrics.bats`
**Details:**
Test cases:

1. Exit 1 when history file missing
2. Exit 0 when history file valid
3. Display output includes table and trailing average
4. Error message for missing file

**Acceptance:**

- [ ] @test "metrics command exits 1 when history missing"
- [ ] @test "metrics command exits 0 with valid history"
- [ ] @test "metrics command displays formatted output"
- [ ] @test "metrics command shows error for missing file"

---

## Implementation Constraints

_Rules from CLAUDE.md and project conventions that MUST be followed during this task._

- Use bats-core test framework (existing pattern)
- Follow existing test file structure (see test/unit/cmd_routing.bats)
- Use setup/teardown for fixture management
- Clean up all temp files in teardown
- Test both happy path and error cases
- Use descriptive test names with @test "description"

---

## Edge Cases to Handle

| Scenario                          | Expected Behavior                               | Subtask |
| --------------------------------- | ----------------------------------------------- | ------- |
| File doesn't exist                | Test skips with warning (for schema validation) | 5.2     |
| Extra whitespace in fields        | Tolerated (trimmed)                             | 5.2     |
| Malformed JSON in stack_breakdown | Validation catches it                           | 5.2     |
| Zero weeks of data                | Display "No canary runs recorded yet"           | 5.5     |

---

## Files to Create / Modify

### New Files

| File Path                           | Purpose               |
| ----------------------------------- | --------------------- |
| `test/unit/lib_memory_metrics.bats` | Metrics module tests  |
| `test/unit/cmd_metrics.bats`        | Metrics command tests |

### Modified Files

_None_

---

## Test Requirements

### Tests to Write

All tests are created in this task.

### Test Scenarios

**Happy Path:**

1. Valid schema passes validation
2. Trailing average calculates correctly
3. Display shows formatted table
4. Command exits 0 with valid data

**Error Cases:**

1. Invalid schema fails validation (exit 2)
2. Missing file causes exit 1
3. Corrupted data handled gracefully

**Edge Cases:**

1. Empty history handled
2. Fewer than 4 weeks of data handled
3. Extra whitespace tolerated

---

## Success Criteria

_All criteria must pass for this task to be marked as completed._

- [ ] All subtask acceptance criteria are met
- [ ] File `test/unit/lib_memory_metrics.bats` exists with comprehensive tests
- [ ] File `test/unit/cmd_metrics.bats` exists with command tests
- [ ] All tests passing (exit 0)
- [ ] Test coverage >= 80% for lib/memory/metrics.sh
- [ ] Edge cases covered (empty history, invalid schema, etc.)
- [ ] Tests follow project conventions (setup/teardown, descriptive names)

---

## Validation Commands

_Run these commands after implementation to verify the task is complete._

```bash
# Verify test files exist
test -f test/unit/lib_memory_metrics.bats && echo "✓ lib tests exist" || echo "✗ Missing"
test -f test/unit/cmd_metrics.bats && echo "✓ cmd tests exist" || echo "✗ Missing"

# Run tests
bats test/unit/lib_memory_metrics.bats
bats test/unit/cmd_metrics.bats

# Run all tests to ensure nothing is broken
bats test/unit/

# Count test cases
echo "lib_memory_metrics.bats test count:"
grep -c '@test' test/unit/lib_memory_metrics.bats

echo "cmd_metrics.bats test count:"
grep -c '@test' test/unit/cmd_metrics.bats
```

**Expected output:** All tests pass, at least 15 total test cases across both files.

---

## Rollback Plan

_If this task introduces breaking changes, how to undo:_

```bash
# Remove test files
rm -f test/unit/lib_memory_metrics.bats
rm -f test/unit/cmd_metrics.bats
```

---

## Notes

- This is a critical validation task for MRP (Measurable Results Published)
- Tests ensure schema stability (NFR-002) and data quality
- Use temporary files in /tmp for test fixtures to avoid polluting project
- Reference test/unit/cmd_routing.bats for patterns (setup/teardown, mocking)
- Aim for at least 8-10 tests per file (15-20 total)
