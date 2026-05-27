Output docs/assets/pick-loop.gif

Set Theme "Catppuccin Mocha"
Set FontSize 14
Set Width 1200
Set Height 700
Set PlaybackSpeed 1.0

Env MOCK_CLAUDE_MODE normal
Env PATH "/tmp/mz-hero-mocks:/Users/viniciuscarvalho/Documents/monozukuri/.qa/fixtures/mocks/claude:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"

# ── Navigate to the demo project ────────────────────────────────────────────
Type "cd /tmp/mz-tape-fresh" Enter
Sleep 300ms
Type "clear" Enter
Sleep 200ms

# ── Show the feature backlog ─────────────────────────────────────────────────
Type "cat features.md" Sleep 200ms Enter
Sleep 2500ms
Type "clear" Enter
Sleep 200ms

# ── Autonomous run (no human prompts) ───────────────────────────────────────
Type "monozukuri run --autonomy full_auto" Sleep 200ms Enter
Hide
Sleep 5s
Show
Sleep 60s

# ── Confirm the two PRs were opened ─────────────────────────────────────────
Type "gh pr list" Sleep 200ms Enter
Sleep 5s
