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

## Normal release flow

```
1. Land commits to main → release-please opens a release PR
2. Release gate runs on the PR (CI)
3. If gate PASS: auto-merge fires → release tag created → npm publish + homebrew update
4. If gate FAIL: fix the regression, push to the release branch, gate re-runs
```

## Hotfix flow (< 30 min target)

Use when a critical bug needs production within 30 minutes of decision.

```bash
# 1. Branch from the current release tag
git checkout v1.0.0
git checkout -b hotfix/v1.0.1

# 2. Apply the fix
# ... edit files ...

# 3. Run only Layers 1 + 3 (build + schema) — skip the slow layers
.qa/release-gate.sh --hotfix v1.0.1

# 4. Tag and push
git add -A
git commit -m "fix: <description>"
git tag v1.0.1
git push origin hotfix/v1.0.1 --tags

# 5. Publish
npm publish --access public
# Open a PR to tap: brew bump-formula-pr monozukuri --tag v1.0.1
```

`--hotfix` runs only Layers 1 and 3. It skips the loop (Layer 2), backwards-compat (Layer 4), live-canary (Layer 5), and scale-soak (Layer 6). Use it only for critical patches where the fix is isolated and tested manually.

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
