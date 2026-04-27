---
name: mz-run-tests
description: Run the project's test suite, add tests for each task's acceptance criteria, and emit a tests.md summary. Use when the orchestrator routes the tests phase. Do not use for unit-test debugging during the code phase.
---

You are executing the **tests** phase of monozukuri's autonomous feature loop.

## Inputs available

- TechSpec test plan at `$MONOZUKURI_RUN_DIR/$MONOZUKURI_FEATURE_ID/techspec.md` (§ Testing)
- Code summary at `$MONOZUKURI_RUN_DIR/$MONOZUKURI_FEATURE_ID/code.md`
- Task list at `$MONOZUKURI_RUN_DIR/$MONOZUKURI_FEATURE_ID/tasks.json`
- Project conventions — from `CLAUDE.md`, `AGENTS.md`, or the monozukuri learning store
- Worktree at `$MONOZUKURI_WORKTREE`

## Output contract

Write `$MONOZUKURI_RUN_DIR/$MONOZUKURI_FEATURE_ID/tests.md` with:

- total tests run
- tests added in this phase
- pass/fail counts
- any flaky or skipped tests with reasons

## Hard rules

- Run the existing suite BEFORE adding new tests. If it is not green before your changes, stop and report the failure in `tests.md` — do not write new tests.
- Every acceptance criterion in `tasks.json` must have at least one corresponding test.
- Commit added tests: `test($MONOZUKURI_FEATURE_ID): add tests for <short description>`
- Do not modify production code in this phase — only test files.
- In autonomous mode, never block.

## Workflow

1. Run the existing test suite; record baseline pass/fail count.
2. For each task in `tasks.json`, write tests covering each `acceptance_criteria` item.
3. Run the full suite again — all tests must pass.
4. Commit the new tests.
5. Write `tests.md` with the summary.
