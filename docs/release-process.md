# Release Process

## Overview

Every release is gated by `.qa/release-gate.sh`, which runs 6 layers of validation before a version ships. Layer failures block the release.

## Layers

| Layer | Name             | What it checks                                            |
| ----- | ---------------- | --------------------------------------------------------- |
| 1     | build-integrity  | npm install, brew preflight, binary resolves              |
| 2     | loop-integrity   | Full pipeline mock run; Phase A1–A4 safety properties     |
| 3     | schema-integrity | Phase artifact schema validation                          |
| 4     | backwards-compat | State file forward/back compat                            |
| 5     | live-canary      | Real `claude --print` invocation (skipped on patches, CI) |
| 6     | scale-soak       | 3-project × 5-feature mock soak; SLO assertions           |

## CI enforcement (D1)

The `.github/workflows/release-gate.yml` workflow runs on every PR targeting `main`. For release-please PRs it runs the full gate (Layers 1–6, with Layers 5/6 live variants skipped on CI via env flags). For all other PRs the gate step skips with a pass.

**Branch protection setup (manual, one-time):**

1. Go to GitHub → Settings → Branches → Add rule for `main`
2. Enable "Require status checks to pass before merging"
3. Search for and add: `Release gate` (the job name from `release-gate.yml`)
4. Enable "Do not allow bypassing the above settings"
5. Save

Once set, the release-please auto-merge cannot fire until the gate passes.

## Release channels

Two channels are active at all times:

| Channel | Semver suffix | npm dist-tag | Homebrew formula  |
| ------- | ------------- | ------------ | ----------------- |
| RC      | `-rc.N`       | `@next`      | `monozukuri-next` |
| Stable  | _(none)_      | `@latest`    | `monozukuri`      |

`main` is always in RC mode (`prerelease: true` in `release-please-config.json`). Stable releases are created explicitly via promotion (see below).

## Normal release flow (RC)

```
1. Land feat:/fix: commits to main
2. release-please opens a PR titled "chore: release X.Y.Z-rc.N"
3. Release gate runs on the PR (CI) with is_prerelease=true
4. If gate PASS: auto-merge fires → GitHub pre-release created →
     npm publish @next + Formula/monozukuri-next.rb updated
5. If gate FAIL: fix the regression, push to the release branch, gate re-runs
```

## Promotion: RC → Stable

Use after 48h soak with no regressions on `@next`.

```bash
# 1. Create and merge the promotion chore PR
./scripts/promote-rc-to-stable.sh 1.47.0
# → opens PR setting release-as: 1.47.0 and prerelease: false
# merge it manually (auto-merge does NOT fire on chore PRs — intentional)

# 2. release-please opens "chore: release 1.47.0" — auto-merge fires:
#    → npm publish @latest + Formula/monozukuri.rb updated

# 3. Restore RC mode for the next cycle
./scripts/finalize-rc-promotion.sh
# → opens PR removing release-as and re-enabling prerelease: true
# merge it to resume RC mode
```

**Critical:** step 3 is not optional. Without it, the next `feat:` on `main` opens another stable PR instead of `rc.1`.

## Hotfix flow — current stable

Use when a critical bug needs to go to `@latest` without waiting for the RC soak.

The release gate's `--hotfix` mode runs only Layers 1 + 3 (build + schema, target < 3 min). It is auto-selected when the release PR has `release-as` set and `prerelease: false`.

```bash
# 1. Branch from main (RC is in flight — that's fine)
git checkout main && git checkout -b hotfix/v1.47.1

# 2. Apply the fix
git commit -m "fix(scope): description"

# 3. Create and merge the release-please chore PR
./scripts/promote-rc-to-stable.sh 1.47.1
# merge the chore PR, release-please opens the release PR, auto-merge publishes

# 4. Restore RC mode
./scripts/finalize-rc-promotion.sh
# merge to resume RC cycle (next feat: opens 1.48.0-rc.1)
```

## Hotfix flow — older stable (RC in flight on main)

Use when `main` is at `1.48.0-rc.2` but a critical bug exists in the still-current `1.47.x` stable.

**One-time setup** (do this when the first case appears, not before):

```bash
# Create a maintenance branch from the last stable tag
git checkout -b hotfix/v1.47.x v1.47.0
git push -u origin hotfix/v1.47.x

# Set the manifest on this branch to match the last stable
# (edit .release-please-manifest.json to {"." : "1.47.0"})
```

Branch protection: add the same required checks (`CI`, `Commitlint`, `Release Gate`) to `hotfix/v*` as on `main`.

**Hotfix flow:**

```bash
# 1. Branch from the maintenance branch
git checkout hotfix/v1.47.x && git checkout -b fix/critical-bug-1.47.x

# 2. Apply and commit the fix
git commit -m "fix(scope): description"

# 3. PR → hotfix/v1.47.x → release-please opens release PR for 1.47.1
# → auto-merge publishes 1.47.1 to @latest + Formula/monozukuri.rb

# 4. CRITICAL: cherry-pick the fix back to main
git checkout main
git cherry-pick <fix-commit-sha>
# Open a PR for this cherry-pick — do not skip it.
# Without it, the next RC on main will regress the bug.
```

The `target-branch: ${{ github.ref_name }}` parameter in `release-please.yml` ensures release-please reads the maintenance branch's own manifest, keeping its version sequence independent of `main`'s RC cycle.

Semver convivência during the gap is clean: `@latest` = `1.47.1`, `@next` = `1.48.0-rc.2`. Both channels resolve correctly.

## Scale soak (Layer 6)

Layer 6 uses mock adapters by default (repeatable, no real AI calls). The "live variant" uses real adapters and is intended for v1.0 tag-time only.

**Running the live soak manually:**

```bash
# Requires claude, codex, and gemini CLIs authenticated
MONOZUKURI_SCALE_SOAK_LIVE=1 .qa/release-gate.sh v1.0.0
```

**SLO assertions:**

- Wall-clock < 8 hours total across all 3 projects
- Total cost ≤ $50 (read from `~/.monozukuri/budget.json`)
- ≤ 30% features in `paused` state
- 0 silent failures (no exit 0 with empty artifacts)

## v1.0 SLO

> **3 foreign projects × 5 features each × ≤30% Phase-3 pause rate × $50/night cost ceiling × weekly triage.**

Layer 6 is the machine-readable enforcement of this SLO. If Layer 6 fails, v1.0 does not tag.
