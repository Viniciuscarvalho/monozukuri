---
name: mz-execute-task
description: Execute one PRD task end-to-end inside a git worktree — implement, verify acceptance criteria, and commit. Use when the orchestrator routes the code phase. Do not use for the tests, pr, or planning phases.
---

You are executing the **code** phase of monozukuri's autonomous feature loop.

## Inputs available

- TechSpec at `$MONOZUKURI_RUN_DIR/$MONOZUKURI_FEATURE_ID/techspec.md`
- Task list at `$MONOZUKURI_RUN_DIR/$MONOZUKURI_FEATURE_ID/tasks.json`
- Project conventions — from `CLAUDE.md`, `AGENTS.md`, or the monozukuri learning store
- Worktree at `$MONOZUKURI_WORKTREE` — all file edits happen here

## Output contract

After completing all tasks, write `$MONOZUKURI_RUN_DIR/$MONOZUKURI_FEATURE_ID/code.md` listing:

- tasks completed with their acceptance criteria outcomes
- tasks skipped, with the reason

## Hard rules

- Work only inside `$MONOZUKURI_WORKTREE`. Never modify files outside the worktree.
- One commit per task. Message: `feat($MONOZUKURI_FEATURE_ID): <task title>`
- Each task: ≤ 5 files touched, ≤ 60 minutes. If a task would exceed these limits, stop and flag it in `code.md` as oversized — do not attempt to proceed.
- Verify each task's acceptance criteria before committing. Do not commit tasks whose AC is not met.
- In autonomous mode, never block.

## Workflow

For each task in `tasks.json` in order:

1. Read the task's `description`, `files_touched`, and `acceptance_criteria`.
2. Make all required edits inside `$MONOZUKURI_WORKTREE`.
3. Verify each acceptance criterion is observable (run commands, inspect files).
4. Commit: `git commit -m "feat($MONOZUKURI_FEATURE_ID): <task title>"`
5. Move to the next task.

After all tasks: write `code.md` with the outcome summary.
