#!/usr/bin/env bash
# Restores RC mode after a stable release has been published.
# Run this after promote-rc-to-stable.sh's release PR has auto-merged and published.
#
# Creates a chore PR that removes release-as and re-enables prerelease: true,
# so the next feat:/fix: commit on main opens a new RC cycle.
set -euo pipefail

CONFIG="release-please-config.json"
BRANCH="chore/restore-rc-mode-$(date +%Y%m%d)"

if ! command -v gh &>/dev/null; then
  echo "gh CLI not found — install GitHub CLI first" >&2
  exit 1
fi

git checkout main
git pull --ff-only

if git ls-remote --exit-code --heads origin "$BRANCH" &>/dev/null; then
  BRANCH="${BRANCH}-$(date +%H%M%S)"
fi

git checkout -b "$BRANCH"

# Remove release-as, restore prerelease: true
node - "$CONFIG" <<'NODEEOF'
const fs = require('fs');
const [,, configPath] = process.argv;
const cfg = JSON.parse(fs.readFileSync(configPath, 'utf8'));
const pkg = cfg.packages['.'];
delete pkg['release-as'];
pkg['prerelease'] = true;
fs.writeFileSync(configPath, JSON.stringify(cfg, null, 2) + '\n');
NODEEOF

git add "$CONFIG"
git commit -m "chore(release): restore RC mode after stable publish

Removes release-as and re-enables prerelease: true so the next
feat:/fix: commit on main opens a new -rc.1 cycle."

git push -u origin "$BRANCH"

gh pr create \
  --base main \
  --head "$BRANCH" \
  --title "chore: restore RC mode after stable publish" \
  --body "## Restore RC release mode

Removes \`release-as\` override and re-enables \`prerelease: true\` in
\`release-please-config.json\`.

Without this PR, the next \`feat:\`/\`fix:\` commit on main would open
another stable release PR instead of starting a new RC cycle."

echo ""
echo "PR created. Merge it to resume RC mode."
