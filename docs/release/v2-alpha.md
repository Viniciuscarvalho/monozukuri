# v2.0.0-alpha Release Readiness

This page prepares the alpha release without publishing from a stacked feature
branch. The release branch must be created from `main` only after the v2 PR stack
is merged.

## Branches not synced with main

Refresh the view before cutting the release:

```bash
git fetch origin --prune
for branch in origin/codex/mem-* origin/codex/vrf-* origin/codex/doc-*; do
  git rev-parse --verify --quiet "$branch" >/dev/null || continue
  counts="$(git rev-list --left-right --count origin/main..."$branch")"
  behind="${counts%%[[:space:]]*}"
  ahead="${counts##*[[:space:]]}"
  printf '%s behind=%s ahead=%s\n' "$branch" "$behind" "$ahead"
done
```

Snapshot from 2026-05-26 after `git fetch origin --prune`:

| Branch | Behind main | Ahead of main |
| --- | ---: | ---: |
| `origin/codex/mem-03-memory-injection-tracking` | 6 | 10 |
| `origin/codex/mem-04-memory-why` | 6 | 9 |
| `origin/codex/mem-05-sufficiency-router-design` | 6 | 11 |
| `origin/codex/mem-06-memory-compactor` | 6 | 12 |
| `origin/codex/mem-07-memory-escalation-marker` | 6 | 13 |
| `origin/codex/mem-08-memory-trace` | 6 | 14 |
| `origin/codex/mem-09-10-memory-compaction` | 6 | 15 |
| `origin/codex/mem-11-agent-specific-learnings` | 6 | 16 |
| `origin/codex/vrf-01-02-v2-verification` | 6 | 17 |
| `origin/codex/vrf-03-live-canary` | 6 | 17 |

Treat any non-zero `behind` value as a rebase or merge-main requirement before
release. Treat any non-zero `ahead` value as work that must be merged or
explicitly deferred.

## Release gate

1. Confirm every SEL, LOOP, MEM, VRF, and DOC PR intended for the alpha is
   merged into `main`.
2. Create the release branch from updated main:

   ```bash
   git switch main
   git pull --ff-only
   git switch -c release/v2.0.0-alpha
   ```

3. Run the v1 release gate with live-cost skips unless intentionally validating
   live layers:

   ```bash
   MONOZUKURI_SKIP_LIVE_CANARY=1 \
   MONOZUKURI_SKIP_SCALE_SOAK_LIVE=1 \
   MONOZUKURI_SKIP_CONFORMANCE=1 \
   .qa/release-gate.sh v2.0.0-alpha.1
   ```

4. Run the live canary separately when ready to spend the capped budget:

   ```bash
   scripts/verification/live-canary.sh --live --agents claude-code,codex,gemini --tasks 2 --max-cost 5
   ```

## Publish checklist

- Tag: `v2.0.0-alpha.1`
- npm channel: publish with the `next` dist-tag.
- brew tap: publish to the `next` tap channel.
- Fresh install tests: one macOS machine and one Linux environment.
- CHANGELOG includes the full new-command list.
- Invite 5 to 10 early testers and ask for structured feedback on `pick`,
  `loop --resume`, Memory v2 traceability, and install friction.

Example commands, to be run only from the release branch after the gate passes:

```bash
git tag v2.0.0-alpha.1
git push origin release/v2.0.0-alpha v2.0.0-alpha.1
npm publish --tag next
brew update && brew install viniciuscarvalho/tap-next/monozukuri
```

Do not tag or publish from a stacked feature branch.
