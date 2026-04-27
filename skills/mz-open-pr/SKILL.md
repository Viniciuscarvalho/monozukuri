---
name: mz-open-pr
description: Open a GitHub pull request via gh pr create with a body summarizing PRD goals, code changes, and test results. Use when the orchestrator routes the pr phase. Do not use for editing existing PRs or non-GitHub remotes.
---

You are executing the **pr** phase of monozukuri's autonomous feature loop.

## Inputs available

- PRD at `$MONOZUKURI_RUN_DIR/$MONOZUKURI_FEATURE_ID/prd.md`
- TechSpec at `$MONOZUKURI_RUN_DIR/$MONOZUKURI_FEATURE_ID/techspec.md`
- Code summary at `$MONOZUKURI_RUN_DIR/$MONOZUKURI_FEATURE_ID/code.md`
- Test summary at `$MONOZUKURI_RUN_DIR/$MONOZUKURI_FEATURE_ID/tests.md`
- PR body template at `references/pr-body-template.md`
- Worktree at `$MONOZUKURI_WORKTREE`

## Output contract

Write `$MONOZUKURI_RUN_DIR/$MONOZUKURI_FEATURE_ID/pr.md` with:

- PR URL
- PR number
- base branch
- head branch

## Hard rules

- PR title: the feature title verbatim (`$MONOZUKURI_FEATURE_TITLE`).
- PR body: follow the structure in `references/pr-body-template.md`.
- Use `gh pr create` — no other method.
- Push the worktree branch before creating the PR.
- In autonomous mode, pass `--body` inline — never leave `gh` in an interactive prompt.

## Workflow

1. Read `references/pr-body-template.md`.
2. Populate each section from the PRD, code summary, and test summary.
3. Push the worktree branch: `git push -u origin HEAD`
4. Run `gh pr create --title "$MONOZUKURI_FEATURE_TITLE" --body "<rendered body>"`
5. Write `pr.md` with the PR URL, number, and branches.

## Workflow memory

Before starting, read `$MONOZUKURI_MEMORY_DIR/MEMORY.md` for any cross-phase notes worth including in the PR body (e.g., deferred decisions, reviewer callouts). After writing `pr.md`, update `$MONOZUKURI_TASK_MEMORY` with the PR URL and branch names for any downstream reference. If `$MONOZUKURI_NEEDS_COMPACTION` is non-empty and not `none`, run the `mz-workflow-memory` skill to compact memory files before continuing.
