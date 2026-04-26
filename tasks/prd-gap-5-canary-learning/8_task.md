# Task 8.0: Integration Testing & Documentation (M)

**Status:** pending
**Complexity:** M _(S = <1h, M = 1-3h, L = 3h+)_
**Depends on:** Task 7
**Implements:** Final validation and documentation

---

<critical>
Read the prd.md and techspec.md files in this folder BEFORE starting any work.
If you do not read these files, your task will be invalidated.
</critical>

<task_context>
<domain>testing, documentation</domain>
<type>integration</type>
<scope>End-to-end validation and user documentation</scope>
<complexity>medium</complexity>
<dependencies>All previous tasks (1-7)</dependencies>
</task_context>

---

## Objective

Perform end-to-end integration testing of the complete Gap 5 system (canary run → metrics display), verify CI workflow configuration, and create comprehensive documentation including usage examples.

**Expected Outcome:** Full system tested and validated, documentation complete, example config provided, ready for merge.

---

## Pre-Execution: Files to Read

_Read and understand these files before writing any code. This provides the context needed for accurate implementation._

| File                 | Why                               | What to Look For                         |
| -------------------- | --------------------------------- | ---------------------------------------- |
| `prd.md`             | Understand success metrics        | Final acceptance criteria, success gates |
| `techspec.md`        | Review all components             | Integration points, end-to-end flow      |
| All task files (1-7) | Verify all deliverables completed | Success criteria from each task          |

---

## Subtasks

### 8.1: End-to-end manual test - canary run

**Action:** Execute full canary run manually and verify results
**File(s):** All implemented files
**Details:**

1. Setup: Ensure example canary config exists with 2-3 features
2. Run: Execute `bash lib/run/canary.sh` manually
3. Verify: Check docs/canary-history.md updated with new row
4. Verify: Check row has 6 columns, valid date, numeric metrics
5. Verify: Check stack_breakdown_json is valid JSON

**Acceptance:**

- [ ] Canary run executes without errors
- [ ] docs/canary-history.md updated with new row
- [ ] Row format matches schema (6 columns)
- [ ] All data fields valid (date, numbers, JSON)

---

### 8.2: End-to-end manual test - metrics display

**Action:** Test monozukuri metrics command with real data
**File(s):** cmd/metrics.sh, lib/memory/metrics.sh, docs/canary-history.md
**Details:**

1. Run: `./orchestrate.sh metrics`
2. Verify: Command displays formatted table
3. Verify: Table shows recent canary runs
4. Verify: 4-week trailing average displayed
5. Verify: Exit code 0

**Acceptance:**

- [ ] Command executes successfully
- [ ] Displays human-readable table
- [ ] Shows trailing average
- [ ] Exit code 0
- [ ] No errors or warnings

---

### 8.3: Test error handling scenarios

**Action:** Verify error cases work correctly
**File(s):** All implemented files
**Details:**
Test scenarios:

1. Missing history file: `./orchestrate.sh metrics` → exit 1, error message
2. Corrupted history (invalid schema): exit 2, error message
3. Missing canary config: canary run → exit 1, error message

**Acceptance:**

- [ ] Missing history file handled (exit 1)
- [ ] Corrupted schema detected (exit 2)
- [ ] Missing config handled (exit 1)
- [ ] Error messages are descriptive

---

### 8.4: Verify CI workflow syntax

**Action:** Validate GitHub Actions workflow file
**File(s):** `.github/workflows/canary.yml`
**Details:**

- Check YAML syntax is valid
- Verify all steps are properly defined
- Verify environment variables set correctly
- Verify conditional logic (if: steps.canary_run.outcome == 'success')
- Use GitHub CLI or online validator

**Acceptance:**

- [ ] YAML syntax valid
- [ ] All steps defined correctly
- [ ] Environment variables present
- [ ] Conditional commit step configured
- [ ] Workflow ready for CI execution

---

### 8.5: Create comprehensive usage documentation

**Action:** Document how to use Gap 5 features
**File(s):** Create or update documentation (README section or docs/)
**Details:**
Document:

1. How to view metrics: `monozukuri metrics`
2. How to interpret the output (table columns, trailing average)
3. How to trigger manual canary run (workflow_dispatch)
4. How to configure canary features (canary-config.json format)
5. How to read canary-history.md directly
6. Badge meaning and link

**Acceptance:**

- [ ] Usage documentation exists
- [ ] Command examples provided
- [ ] Config format documented
- [ ] Workflow trigger instructions included
- [ ] Clear and concise

---

### 8.6: Update .monozukuri/canary-config.json with realistic examples

**Action:** Enhance example config with detailed comments and examples
**File(s):** `.monozukuri/canary-config.json`
**Details:**
Update example config to include:

- Comments explaining each field (use .example or separate doc)
- Example features for each stack type
- Clear instructions for adding new features
- Reference to monozukuri-canaries repo (when created)

**Acceptance:**

- [ ] Config has detailed examples
- [ ] All stack types represented
- [ ] Comments/documentation explain fields
- [ ] Valid JSON (or .example file with comments)

---

### 8.7: Run full test suite

**Action:** Execute all bats tests to ensure nothing is broken
**File(s):** test/unit/
**Details:**

- Run: `bats test/unit/lib_memory_metrics.bats`
- Run: `bats test/unit/cmd_metrics.bats`
- Run: `bats test/unit/` (all tests)
- Verify: All tests pass, no regressions

**Acceptance:**

- [ ] All Gap 5 tests pass (lib_memory_metrics, cmd_metrics)
- [ ] All existing tests still pass (no regressions)
- [ ] Test coverage meets 80% target

---

### 8.8: Final validation checklist

**Action:** Verify all PRD success criteria are met
**File(s):** All implemented files, prd.md
**Details:**
Review PRD Success Metrics:

- [ ] Automated weekly updates: CI workflow configured (will run post-merge)
- [ ] Schema validation: 100% pass rate (bats tests pass)
- [ ] Badge display: README contains badge linking to canary-history.md
- [ ] Metrics command availability: `monozukuri metrics` works

Review all FR acceptance criteria from PRD.

**Acceptance:**

- [ ] All PRD success metrics met
- [ ] All FR acceptance criteria satisfied
- [ ] All task success criteria from Tasks 1-7 met

---

## Implementation Constraints

_Rules from CLAUDE.md and project conventions that MUST be followed during this task._

- Documentation must be clear and concise
- Examples must be realistic and helpful
- Tests must cover all edge cases
- No existing functionality broken
- All code follows project conventions
- Conventional commit format for final commit

---

## Edge Cases to Handle

| Scenario                          | Expected Behavior                | Subtask |
| --------------------------------- | -------------------------------- | ------- |
| First canary run (no history yet) | Creates history file with header | 8.1     |
| Multiple canary runs              | Each appends new row             | 8.1     |
| Workflow not yet triggered        | Badge shows "pending" state      | 8.8     |

---

## Files to Create / Modify

### New Files

| File Path                               | Purpose                   |
| --------------------------------------- | ------------------------- |
| `docs/gap-5-usage.md` or README section | Gap 5 usage documentation |

### Modified Files

| File Path                        | What Changes                        | Lines/Section to Modify        |
| -------------------------------- | ----------------------------------- | ------------------------------ |
| `.monozukuri/canary-config.json` | Enhanced examples and documentation | Entire file                    |
| `README.md` (optional)           | Add usage section for Gap 5         | New section or update existing |

---

## Test Requirements

### Tests to Write

_All tests already created in Task 5_

### Test Scenarios

**Integration Tests:**

1. Full flow: canary run → metrics display → verify output
2. Error flow: missing file → metrics command → verify exit 1
3. CI workflow: validate syntax → verify triggers

**Acceptance:**
All integration scenarios pass manual testing.

---

## Success Criteria

_All criteria must pass for this task to be marked as completed._

- [ ] All subtask acceptance criteria are met
- [ ] End-to-end manual tests pass
- [ ] Error scenarios handled correctly
- [ ] CI workflow syntax validated
- [ ] Usage documentation complete
- [ ] Example config enhanced
- [ ] All bats tests pass (no regressions)
- [ ] All PRD success metrics verified
- [ ] All 8 tasks completed successfully

---

## Validation Commands

_Run these commands after implementation to verify the task is complete._

```bash
# Full test suite
bats test/unit/

# End-to-end test
echo "=== Running end-to-end test ==="
bash lib/run/canary.sh
./orchestrate.sh metrics
echo "=== Verifying canary-history.md ==="
tail -1 docs/canary-history.md

# Verify all deliverables exist
test -f docs/canary-history.md && echo "✓ History file exists"
test -f lib/memory/metrics.sh && echo "✓ Metrics module exists"
test -f cmd/metrics.sh && echo "✓ Metrics command exists"
test -f lib/run/canary.sh && echo "✓ Canary orchestrator exists"
test -f .github/workflows/canary.yml && echo "✓ CI workflow exists"
test -f test/unit/lib_memory_metrics.bats && echo "✓ Metrics tests exist"
test -f test/unit/cmd_metrics.bats && echo "✓ Command tests exist"
grep -q 'L5 Metrics' README.md && echo "✓ Badge in README"

# Validate workflow YAML
if command -v yamllint &>/dev/null; then
  yamllint .github/workflows/canary.yml && echo "✓ Workflow YAML valid"
fi

# Verify documentation
test -f docs/gap-5-usage.md && echo "✓ Usage docs exist" || echo "⚠ Consider adding usage docs"

echo "=== All Gap 5 deliverables verified ==="
```

**Expected output:** All checks pass, deliverables present, tests passing.

---

## Rollback Plan

_If this task introduces breaking changes, how to undo:_

```bash
# Rollback all Gap 5 changes (revert entire feature)
git revert <commit-sha-range>

# Or reset to before Gap 5
git reset --hard <commit-before-gap-5>
```

---

## Notes

- This is the final validation task before creating PR
- Ensures all components work together as a system
- Documentation is critical for user adoption
- Consider creating a demo video or GIF showing metrics command output
- After this task, Gap 5 is ready for PR and merge
- CI workflow will not run until merged to main branch
- First canary run will occur on the next Sunday at 00:00 UTC post-merge
