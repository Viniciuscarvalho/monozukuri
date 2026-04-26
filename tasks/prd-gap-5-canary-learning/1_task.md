# Task 1.0: Create Canary History Template (S)

**Status:** pending
**Complexity:** S _(S = <1h, M = 1-3h, L = 3h+)_
**Depends on:** None
**Implements:** FR-001, STORY-001

---

<critical>
Read the prd.md and techspec.md files in this folder BEFORE starting any work.
If you do not read these files, your task will be invalidated.
</critical>

<task_context>
<domain>metrics</domain>
<type>infrastructure</type>
<scope>Create schema template for canary run history</scope>
<complexity>low</complexity>
<dependencies>none</dependencies>
</task_context>

---

## Objective

Create `docs/canary-history.md` with a schema header defining the 6-column pipe-delimited format for recording canary benchmark run results. This file serves as the foundational data store for all L5 metrics.

**Expected Outcome:** A new file `docs/canary-history.md` exists with a clear schema definition, documentation, and an empty data section ready to receive canary run results.

---

## Pre-Execution: Files to Read

_Read and understand these files before writing any code. This provides the context needed for accurate implementation._

| File          | Why                                    | What to Look For                                     |
| ------------- | -------------------------------------- | ---------------------------------------------------- |
| `prd.md`      | Understand FR-001 requirements         | Schema column definitions, acceptance criteria       |
| `techspec.md` | See Component 1: CanaryHistoryTemplate | Public interface, schema format, column descriptions |

---

## Subtasks

### 1.1: Create docs directory if needed

**Action:** Ensure `docs/` directory exists in project root
**File(s):** `docs/` (directory)
**Details:**
Check if `docs/` directory exists at project root. Create it if missing using `mkdir -p`.

**Acceptance:**

- [ ] `docs/` directory exists
- [ ] Directory has proper permissions (755)

---

### 1.2: Create canary-history.md with schema header

**Action:** Create the canary history file with complete schema documentation
**File(s):** `docs/canary-history.md`
**Details:**
Create file with:

- Title and description
- Schema table documenting all 6 columns (date, run*id, headline*%, tokens*avg, completion*%, stack_breakdown_json)
- History section with pipe-delimited table header
- Table separator row

Reference techspec.md Component 1: CanaryHistoryTemplate for exact format.

**Acceptance:**

- [ ] File exists at `docs/canary-history.md`
- [ ] Schema documentation table is present and complete
- [ ] Pipe-delimited table header has exactly 6 columns
- [ ] Table separator row matches header format
- [ ] File is valid markdown

---

### 1.3: Verify schema format

**Action:** Manual verification that schema matches specification
**File(s):** `docs/canary-history.md`
**Details:**
Verify:

- Column order: date | run*id | headline*% | tokens*avg | completion*% | stack_breakdown_json
- Pipe delimiters are consistent
- Schema documentation explains each column type and purpose

**Acceptance:**

- [ ] All 6 columns documented with types
- [ ] Column order matches techspec
- [ ] Markdown renders correctly

---

## Implementation Constraints

_Rules from CLAUDE.md and project conventions that MUST be followed during this task._

- Use kebab-case for file and directory names
- File must be valid markdown (`.md` extension)
- Follow existing documentation patterns in the project
- Use pipe-delimited format (not CSV or other formats)

---

## Edge Cases to Handle

| Scenario                       | Expected Behavior              | Subtask |
| ------------------------------ | ------------------------------ | ------- |
| docs/ directory already exists | No error, continue             | 1.1     |
| File created but empty         | Create with full schema header | 1.2     |

---

## Files to Create / Modify

### New Files

| File Path                | Purpose                                   |
| ------------------------ | ----------------------------------------- |
| `docs/canary-history.md` | Canary run results log with schema header |

### Modified Files

_None_

---

## Test Requirements

### Tests to Write

_No automated tests for this task (manual verification only)_

### Test Scenarios

**Happy Path:**

1. Given project root, when task completes, then `docs/canary-history.md` exists with valid schema

**Edge Cases:**

1. Given existing `docs/` directory, when task runs, then file is created without errors

---

## Success Criteria

_All criteria must pass for this task to be marked as completed._

- [ ] All subtask acceptance criteria are met
- [ ] File `docs/canary-history.md` exists at project root
- [ ] Schema header has exactly 6 columns in correct order
- [ ] File is valid markdown and renders correctly
- [ ] Schema documentation table is complete and accurate

---

## Validation Commands

_Run these commands after implementation to verify the task is complete._

```bash
# Verify file exists
test -f docs/canary-history.md && echo "✓ File exists" || echo "✗ File missing"

# Count columns in table header (should be 6)
grep -E '^date \|' docs/canary-history.md | grep -o '|' | wc -l

# Verify markdown syntax
if command -v mdl &>/dev/null; then
  mdl docs/canary-history.md
else
  echo "mdl not installed; manual markdown verification needed"
fi

# Preview file
cat docs/canary-history.md
```

**Expected output:** File exists, has 6 columns (5 pipes), markdown is valid.

---

## Rollback Plan

_If this task introduces breaking changes, how to undo:_

```bash
# Remove created file
rm -f docs/canary-history.md

# Remove docs/ directory if it was created and is empty
rmdir docs/ 2>/dev/null || true
```

---

## Notes

- This is a foundational task with no code dependencies
- The schema format must exactly match techspec Component 1 to ensure compatibility with Task 2 (Metrics Module)
- This file will be committed to git and should be human-readable
- Future canary runs will append rows to this file (append-only pattern)
