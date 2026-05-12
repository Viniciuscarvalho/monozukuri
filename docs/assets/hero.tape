# docs/assets/hero.tape — VHS tape for the README hero GIF.
#
# Run via the wrapper (never directly):
#
#   docs/assets/record-hero.sh
#
# The wrapper creates ~/mz-hero-demo, injects the mock claude binary,
# and runs: vhs docs/assets/hero.tape   (from the monozukuri repo root)
#
# To install VHS: brew install vhs   https://github.com/charmbracelet/vhs

Output docs/assets/hero.gif

Set Theme "Catppuccin Mocha"
Set FontSize 14
Set Width 1200
Set Height 700
Set PlaybackSpeed 1.0
Set Shell "bash"

Sleep 600ms

# ── enter demo repo ───────────────────────────────────────────────────────────
Type "cd ~/mz-hero-demo" Sleep 300ms Enter
Sleep 400ms

# ── monozukuri init ───────────────────────────────────────────────────────────
Type "monozukuri init" Sleep 300ms Enter
Sleep 2500ms

Type "tree .monozukuri" Sleep 300ms Enter
Sleep 1500ms

# patch config to skip real PR creation (mock run — no GitHub remote needed)
Hide
Type "sed -i '' 's/strategy: draft/strategy: none/' .monozukuri/config.yaml" Sleep 100ms Enter
Sleep 300ms
Show

# ── dry run ───────────────────────────────────────────────────────────────────
Type "monozukuri run --dry-run" Sleep 300ms Enter
Sleep 3000ms

# ── checkpoint run ────────────────────────────────────────────────────────────
Type "monozukuri run --autonomy checkpoint" Sleep 300ms Enter

Hide
Sleep 7s    # mock completes PRD + TechSpec + Tasks off-camera (seconds with mock)
Show

Sleep 5s    # show Code + Tests + cycle-gate phases streaming

# ── result ────────────────────────────────────────────────────────────────────
Type "monozukuri status" Sleep 300ms Enter
Sleep 2500ms
