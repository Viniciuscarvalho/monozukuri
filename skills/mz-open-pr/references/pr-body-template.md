You are executing the **pr** phase for feature `{{MONOZUKURI_FEATURE_ID}}`.

Autonomy level: **{{MONOZUKURI_AUTONOMY}}**
Worktree: `{{MONOZUKURI_WORKTREE}}`

## Feature

{{FEATURE_TITLE}}

## Inputs

- PRD: `{{MONOZUKURI_WORKTREE}}/tasks/prd-{{MONOZUKURI_FEATURE_ID}}/prd.md`
- TechSpec: `{{MONOZUKURI_WORKTREE}}/tasks/prd-{{MONOZUKURI_FEATURE_ID}}/techspec.md`
- Code summary: `{{MONOZUKURI_WORKTREE}}/tasks/prd-{{MONOZUKURI_FEATURE_ID}}/code.md`
- Test summary: `{{MONOZUKURI_WORKTREE}}/tasks/prd-{{MONOZUKURI_FEATURE_ID}}/tests.md`

## Instructions

Open a pull request from the worktree branch against the base branch.

PR title: the feature title verbatim.

PR body must include:

- **Summary**: 2–4 bullet points from the PRD Goal
- **Changes**: what was built (from code.md)
- **Tests**: results summary (from tests.md)
- **Artifacts**: links to prd.md, techspec.md in `tasks/prd-{{MONOZUKURI_FEATURE_ID}}/`

Use `gh pr create` — no other method.

**Non-interactive contract** (`MONOZUKURI_INTERACTIVE=0`): never leave `gh` waiting on `$EDITOR` or stdin. Write the PR body to `pr-body.md` first, then run:

```
gh pr create --title "<title>" --body-file pr-body.md
```

Never pass `--body` with a long inline string — shell-escape failures silently open `$EDITOR` and hang the run. If the base branch is ambiguous, query it with `gh repo view --json defaultBranchRef -q .defaultBranchRef.name` and proceed without prompting.

## Output contract

Write `pr.md` to `{{MONOZUKURI_WORKTREE}}/tasks/prd-{{MONOZUKURI_FEATURE_ID}}/pr.md` with:

- PR URL
- PR number
- base branch
- head branch
