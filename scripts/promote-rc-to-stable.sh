#!/usr/bin/env bash
# Promotes an RC to stable by creating a chore PR that sets release-as + clears prerelease mode.
# Usage: scripts/promote-rc-to-stable.sh <stable-version>   e.g. 1.47.0
#
# After merging the chore PR, release-please will open a release PR for vX.Y.Z (stable).
# Once that release PR auto-merges, run scripts/finalize-rc-promotion.sh to restore RC mode.
set -euo pipefail

VERSION="${1:-}"
if [[ -z "$VERSION" ]]; then
  echo "Usage: $0 <stable-version>  (e.g. 1.47.0)" >&2
  exit 2
fi

# Strip leading 'v' if provided
VERSION="${VERSION#v}"

BRANCH="chore/promote-v${VERSION}"
CONFIG="release-please-config.json"

if ! command -v gh &>/dev/null; then
  echo "gh CLI not found — install GitHub CLI first" >&2
  exit 1
fi

git checkout main
git pull --ff-only

if git ls-remote --exit-code --heads origin "$BRANCH" &>/dev/null; then
  echo "Branch $BRANCH already exists on origin. Remove it or choose a different version." >&2
  exit 1
fi

git checkout -b "$BRANCH"

# Patch release-please-config.json: add release-as, set prerelease: false
node - "$CONFIG" "$VERSION" <<'NODEEOF'
const fs = require('fs');
const [,, configPath, version] = process.argv;
const cfg = JSON.parse(fs.readFileSync(configPath, 'utf8'));
const pkg = cfg.packages['.'];
pkg['release-as'] = version;
pkg['prerelease'] = false;
fs.writeFileSync(configPath, JSON.stringify(cfg, null, 2) + '\n');
NODEEOF

git add "$CONFIG"
git commit -m "chore(release): promote RC to stable v${VERSION}

Sets release-as: ${VERSION} and disables prerelease mode so release-please
creates vX.Y.Z (no -rc suffix) on next push to main.
After the release PR auto-merges, run scripts/finalize-rc-promotion.sh."

git push -u origin "$BRANCH"

gh pr create \
  --base main \
  --head "$BRANCH" \
  --title "chore: promote RC to stable v${VERSION}" \
  --body "## RC → Stable promotion

Sets \`release-as: ${VERSION}\` and \`prerelease: false\` in \`release-please-config.json\`.

### Steps after this PR merges
1. release-please will open a release PR for \`v${VERSION}\`
2. Auto-merge will publish to npm \`@latest\` and update \`Formula/monozukuri.rb\`
3. Run \`scripts/finalize-rc-promotion.sh\` to restore RC mode for the next cycle"

echo ""
echo "PR created. After it merges:"
echo "  1. Wait for the release PR to auto-merge and publish"
echo "  2. Run: scripts/finalize-rc-promotion.sh"
