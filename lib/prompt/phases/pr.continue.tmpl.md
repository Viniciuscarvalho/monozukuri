Now open a pull request for **{{FEATURE_ID}}: {{FEATURE_TITLE}}**.

From `{{MONOZUKURI_WORKTREE}}`:

1. Write the PR body to `pr-body.md` (summary bullets + test plan checklist).
2. Run: `gh pr create --title "feat({{FEATURE_ID}}): {{FEATURE_TITLE}}" --body-file pr-body.md`

Autonomy: {{MONOZUKURI_AUTONOMY}}. Do not block on human input — `MONOZUKURI_INTERACTIVE=0` is set.
