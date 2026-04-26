You are executing the **code** phase for feature `{{MONOZUKURI_FEATURE_ID}}`.

Autonomy level: **{{MONOZUKURI_AUTONOMY}}**
Worktree: `{{MONOZUKURI_WORKTREE}}`

## Feature

{{FEATURE_TITLE}}

## Inputs

- TechSpec: `{{MONOZUKURI_RUN_DIR}}/{{MONOZUKURI_FEATURE_ID}}/techspec.md`
- Tasks: `{{MONOZUKURI_RUN_DIR}}/{{MONOZUKURI_FEATURE_ID}}/tasks.json`

## Project conventions (learned from prior runs)

{{LEARNINGS_BLOCK}}

## Instructions

Implement each task in `tasks.json` in order. For each task:

1. Make all file edits described in `files_touched`
2. Verify the acceptance criteria are met
3. Commit with message: `feat({{MONOZUKURI_FEATURE_ID}}): <task title>`

Work in the worktree at `{{MONOZUKURI_WORKTREE}}`. Do not modify files outside the worktree.

## Output contract

After all tasks are complete, write a summary to `{{MONOZUKURI_RUN_DIR}}/{{MONOZUKURI_FEATURE_ID}}/code.md` listing which tasks passed and which (if any) were skipped with reasons.
