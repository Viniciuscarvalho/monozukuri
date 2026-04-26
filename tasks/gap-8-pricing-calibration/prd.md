# PRD: Gap 8 — Pricing & Calibration (L5 Cost Honesty)

## Overview

Gap 8 is the final gap in the Monozukuri roadmap, delivering L5 cost honesty: real USD cost tracking driven by a versioned pricing table, per-phase calibration from canary data, and a new `monozukuri calibrate` subcommand.

## Problem Statement

Currently, Monozukuri estimates token usage but doesn't translate that to real USD costs. Users cannot answer "How much does this feature cost to build?" in dollars. Additionally, token estimates are uncalibrated — they don't learn from actual usage patterns across features.

## Goals

1. **Real USD cost tracking**: Every phase records both token estimate AND actual USD cost
2. **Versioned pricing table**: `config/pricing.yaml` with per-model pricing (input/output tokens)
3. **Calibration system**: Per-(agent, model, phase) multipliers that learn from actual usage
4. **Calibrate subcommand**: `monozukuri calibrate` analyzes past features and updates calibration coefficients
5. **Deferred feature UI state**: Fix missing `'deferred'` status in UI types (Gap 7 added deferral but type wasn't updated)

## Non-Goals

- Real-time cost tracking during execution (just post-phase recording)
- Multi-currency support (USD only)
- Cost budgets or alerts (future Gap)

## Requirements

### Functional

1. **Pricing Table** (`config/pricing.yaml`)
   - Version field (semantic versioning)
   - Updated timestamp
   - Per-provider, per-model pricing (input_per_1m, output_per_1m in USD)
   - Calibration section with per-(agent, model, phase) multipliers
   - Default multipliers: 1.0 (use token estimate as-is)

2. **Pricing Module** (`lib/core/pricing.sh`)
   - `pricing_load()`: Load pricing.yaml into environment variables
   - `pricing_cost_usd(agent, model, input_tokens, output_tokens)`: Calculate USD cost
   - `pricing_calibration_factor(agent, model, phase)`: Get calibration multiplier
   - Support token-only estimates (70% input / 30% output split)

3. **Cost Module Upgrade** (`lib/core/cost.sh`)
   - Replace placeholder `cost_calibrate()` with real implementation
   - Read `docs/canary-history.md` and per-feature `cost.json` files
   - Wire `pricing_cost_usd()` into `cost_record()` to log USD cost
   - Store both token estimate AND USD cost in phase records

4. **Calibrate Command** (`lib/run/calibrate.sh`, `cmd/calibrate.sh`)
   - Read last N runs from `$STATE_DIR/*/cost.json` and canary-history.md
   - Compute per-(agent, model, phase) actual-vs-estimated ratios
   - Write updated calibration multipliers to `config/pricing.yaml`
   - Support `--sample N` flag (default: 20)
   - Generate human-readable calibration report

5. **UI Type Completeness** (`ui/src/types.ts`, `reducer.ts`, `FeatureCard.tsx`)
   - Add `'deferred'` to `FeatureStatus` type
   - Add `FeatureDeferredEvent` interface
   - Handle `feature.deferred` event in reducer
   - Render deferred features with yellow/amber color and "⏸ deferred" label

### Non-Functional

- Pricing table must be version-controlled and easy to update
- Calibration command should run in <5 seconds for 20 samples
- USD cost precision: 2 decimal places

## Success Criteria

- [ ] `config/pricing.yaml` exists with versioned pricing for Claude Code and Aider models
- [ ] `pricing_cost_usd()` returns accurate USD cost for token inputs
- [ ] `cost_record()` logs both token estimate AND USD cost
- [ ] `monozukuri calibrate` generates calibration report and updates pricing.yaml
- [ ] UI renders deferred features distinctly (yellow, "⏸ deferred")
- [ ] All tests pass (unit tests for pricing.sh and calibrate.sh)

## Dependencies

- Gap 5 (metrics.sh, canary-history.md) — for canary data parsing
- Gap 7 (deferral system) — UI needs to render deferred status
- Existing cost.sh module (cost_record, cost_calibrate placeholder)

## Timeline

Single phase implementation (all deliverables together).

## Open Questions

None (all clarified in briefing).
