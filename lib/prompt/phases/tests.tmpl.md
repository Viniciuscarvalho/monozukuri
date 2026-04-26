You are executing the **tests** phase for feature `{{MONOZUKURI_FEATURE_ID}}`.

Autonomy level: **{{MONOZUKURI_AUTONOMY}}**
Worktree: `{{MONOZUKURI_WORKTREE}}`

## Feature

{{FEATURE_TITLE}}

## Inputs

- TechSpec test plan: `{{MONOZUKURI_RUN_DIR}}/{{MONOZUKURI_FEATURE_ID}}/techspec.md` (§ Test Plan)
- Code summary: `{{MONOZUKURI_RUN_DIR}}/{{MONOZUKURI_FEATURE_ID}}/code.md`

## Project conventions (learned from prior runs)

{{LEARNINGS_BLOCK}}

## Instructions

1. Run the existing test suite and confirm it is green before adding new tests
2. Write tests for each acceptance criterion in `tasks.json`
3. Run the full suite again — all tests must pass
4. Commit: `test({{MONOZUKURI_FEATURE_ID}}): add tests for <short description>`

Work in the worktree at `{{MONOZUKURI_WORKTREE}}`.

## Output contract

Write `tests.md` to `{{MONOZUKURI_RUN_DIR}}/{{MONOZUKURI_FEATURE_ID}}/tests.md` with:

- total tests run
- tests added in this phase
- pass/fail counts
- any flaky or skipped tests with reasons
