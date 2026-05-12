#!/usr/bin/env bash
# Prepares a clean demo project for the hero GIF recording.
# Run this before: vhs docs/assets/hero.tape
set -euo pipefail

DEMO_DIR="/tmp/mz-tape-fresh"
REMOTE_DIR="/tmp/mz-tape-fresh-remote"
MOCKS_DIR="/tmp/mz-hero-mocks"
MZ_FIXTURES="/Users/viniciuscarvalho/Documents/monozukuri/.qa/fixtures"

# ── 1. Clean up previous runs ────────────────────────────────────────────────
for d in "$DEMO_DIR" "$REMOTE_DIR"; do
  if [ -d "$d" ]; then
    chmod -R u+w "$d" 2>/dev/null || true
    find "$d" -type d -name ".git" -exec chmod -R u+w {} \; 2>/dev/null || true
    rm -rf "$d"
  fi
done
rm -f /tmp/mz-hero-prs.tsv

# ── 2. Create git repo + bare remote ────────────────────────────────────────
git init --bare "$REMOTE_DIR" > /dev/null 2>&1
git init "$DEMO_DIR" > /dev/null 2>&1
cd "$DEMO_DIR"
git config user.email "demo@example.com"
git config user.name "Demo User"
git remote add origin "$REMOTE_DIR"
printf "# demo-project\n\nA simple CLI project.\n" > README.md
git add README.md
git commit -m "initial" --quiet
git push -u origin master --quiet

# ── 3. Init monozukuri ───────────────────────────────────────────────────────
PATH="/tmp/mz-hero-mocks:/Users/viniciuscarvalho/Documents/monozukuri/.qa/fixtures/mocks/claude:$PATH" \
  monozukuri init --yes > /dev/null 2>&1

# ── 4. Write the 2-feature backlog ──────────────────────────────────────────
cat > features.md << 'EOF'
# Feature Backlog

## [FEAT] feat-001: Add --version flag
Print the semantic version to stdout and exit 0.
Expose via `src/cli.sh` with `--version` parsing.
- priority: high

## [FEAT] feat-002: Add --help flag
Print usage information and list available subcommands.
Expose via `src/cli.sh` with `--help` / `-h` parsing.
- priority: high
EOF

# ── 5. Fix base_branch to match repo ────────────────────────────────────────
sed -i '' 's/base_branch: main/base_branch: master/' .monozukuri/config.yaml

# ── 6. Ensure gh mock is executable ─────────────────────────────────────────
chmod +x "$MOCKS_DIR/gh"

echo "Demo ready at $DEMO_DIR"
echo "Run: vhs docs/assets/hero.tape"
