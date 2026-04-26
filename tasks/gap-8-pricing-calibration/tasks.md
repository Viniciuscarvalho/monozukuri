# Tasks: Gap 8 — Pricing & Calibration

## Task 1: Create Versioned Pricing Table

**File:** `config/pricing.yaml`

**Acceptance Criteria:**

- [ ] YAML file created with version 1.0.0
- [ ] Contains pricing for claude-code models (opus-4-7, sonnet-4-6, haiku-4-5)
- [ ] Contains pricing for aider models (gpt-4o, gpt-4o-mini)
- [ ] Includes calibration section with default 1.0 multipliers for all (agent, model, phase) combinations
- [ ] Updated timestamp in ISO format
- [ ] Valid YAML syntax (test with `yq . config/pricing.yaml`)

**Implementation Notes:**

- Use pricing from tech spec
- Create calibration entries for phases: prd, techspec, tasks, code, tests, pr

---

## Task 2: Implement Pricing Module

**File:** `lib/core/pricing.sh`

**Acceptance Criteria:**

- [ ] `pricing_load()` reads pricing.yaml and populates env vars
- [ ] `pricing_cost_usd()` calculates USD cost from token counts
- [ ] `pricing_calibration_factor()` returns calibration multiplier (default 1.0)
- [ ] Token-only estimates use 70/30 input/output split
- [ ] Handles missing pricing gracefully (returns 0.0 with warning)
- [ ] Uses yq for YAML parsing, bc for float math

**Implementation Notes:**

- Normalize model names for env var keys (replace hyphens/dots with underscores)
- Cache parsed YAML to avoid re-reading on every call
- Export all functions for external use

---

## Task 3: Upgrade Cost Module

**File:** `lib/core/cost.sh`

**Acceptance Criteria:**

- [ ] Replace `cost_calibrate()` placeholder with real implementation
- [ ] `cost_calibrate()` reads canary-history.md and cost.json files
- [ ] `cost_record()` calls `pricing_cost_usd()` and logs USD cost
- [ ] cost.json now includes `estimated_usd` field for each phase
- [ ] Maintains backward compatibility with existing cost.json format
- [ ] Sources pricing.sh module

**Implementation Notes:**

- Reference `lib/memory/metrics.sh` for canary-history.md parsing patterns
- cost_calibrate() is called by calibrate.sh, not during normal workflow
- USD cost precision: 2 decimal places

---

## Task 4: Implement Calibrate Command

**Files:** `lib/run/calibrate.sh`, `cmd/calibrate.sh`

**Acceptance Criteria:**

- [ ] `lib/run/calibrate.sh` implements `calibrate_run()` function
- [ ] Reads last N cost.json files (default 20)
- [ ] Computes actual-vs-estimated ratios per (agent, model, phase)
- [ ] Writes updated calibration coefficients to pricing.yaml
- [ ] Generates human-readable calibration report
- [ ] `cmd/calibrate.sh` provides CLI interface with `--sample N` flag
- [ ] Reports "Insufficient data" if <5 features available

**Implementation Notes:**

- Use jq to parse cost.json files
- Use yq to update pricing.yaml in-place
- Report format: table with columns (Phase, Est tokens, Act tokens, Ratio, Guidance)
- Guidance: "↓ reduce baseline" if ratio < 0.9, "↑ raise baseline" if ratio > 1.1, "✓ baseline accurate" otherwise

---

## Task 5: Route Calibrate Subcommand

**File:** `cmd/orchestrate.sh`

**Acceptance Criteria:**

- [ ] Add routing case for `calibrate` subcommand
- [ ] Calls `cmd/calibrate.sh` with passed arguments
- [ ] Updates help text to include `calibrate [--sample N]`

**Implementation Notes:**

- Follow pattern from existing subcommands (metrics, routing)

---

## Task 6: Fix UI Type Completeness

**Files:** `ui/src/types.ts`, `ui/src/reducer.ts`, `ui/src/components/FeatureCard.tsx`

**Acceptance Criteria:**

- [ ] `FeatureStatus` type includes `'deferred'`
- [ ] `FeatureDeferredEvent` interface defined with type, feature_id, reason, blocked_by
- [ ] `MonozukuriEvent` union includes `FeatureDeferredEvent`
- [ ] Reducer handles `feature.deferred` event (sets status to 'deferred', stores reason in error field)
- [ ] FeatureCard renders deferred features with yellow/amber color and "⏸ deferred" label
- [ ] Visual style matches existing failed state but uses yellow instead of red

**Implementation Notes:**

- Use Ink's `<Text color="yellow">` for deferred state
- Display reason and blocked_by information
- Add dimColor text for "blocked by" line

---

## Task 7: Write Unit Tests for Pricing

**File:** `test/unit/lib_core_pricing.bats`

**Acceptance Criteria:**

- [ ] Test `pricing_load()` populates env vars correctly
- [ ] Test `pricing_cost_usd()` calculates USD accurately
- [ ] Test 70/30 split for token-only estimates
- [ ] Test `pricing_calibration_factor()` returns correct multipliers
- [ ] Test graceful handling of missing pricing data
- [ ] All tests pass

**Implementation Notes:**

- Create fixture pricing.yaml for tests
- Use bats test framework (already in Monozukuri)
- Follow pattern from existing test files in test/unit/

---

## Task 8: Write Unit Tests for Calibrate

**File:** `test/unit/cmd_calibrate.bats`

**Acceptance Criteria:**

- [ ] Test calibrate command with sample cost.json files
- [ ] Test ratio calculation (actual / estimated)
- [ ] Test pricing.yaml update with new coefficients
- [ ] Test "insufficient data" warning (<5 features)
- [ ] Test --sample flag parsing
- [ ] All tests pass

**Implementation Notes:**

- Create fixture cost.json files with known actual/estimated values
- Verify pricing.yaml calibration section updated correctly
- Test both success and edge cases

---

## Task 9: Update Documentation

**Files:** `docs/CHANGELOG.md`, `README.md`

**Acceptance Criteria:**

- [ ] Add Gap 8 entry to CHANGELOG under "Unreleased"
- [ ] Document new `monozukuri calibrate` command in README
- [ ] Add pricing.yaml configuration docs
- [ ] Include example calibration report output

**Implementation Notes:**

- Link to ADR-008 in CHANGELOG
- Add calibrate to command reference table
- Explain calibration coefficient concept

---

## Task 10: Integration Test

**File:** `test/integration/test_gap8_pricing.bats`

**Acceptance Criteria:**

- [ ] Full workflow test: init project → create feature → record costs → calibrate
- [ ] Verify pricing.yaml created with defaults
- [ ] Verify cost.json includes estimated_usd fields
- [ ] Verify calibrate command updates pricing.yaml
- [ ] Test passes in CI

**Implementation Notes:**

- Use temporary test project
- Mock feature execution with known token counts
- Verify USD calculations match expected values
