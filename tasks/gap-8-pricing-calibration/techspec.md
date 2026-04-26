# Tech Spec: Gap 8 — Pricing & Calibration

## Architecture Overview

Gap 8 adds a pricing layer on top of the existing token estimation system, converting token counts to USD costs using a versioned pricing table. The calibration system learns from actual usage patterns to improve estimates.

```
┌─────────────────────────────────────────────────────────┐
│ config/pricing.yaml                                      │
│ - Versioned pricing (input/output per 1M tokens)         │
│ - Calibration coefficients (per agent/model/phase)       │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│ lib/core/pricing.sh                                      │
│ - pricing_load()                                         │
│ - pricing_cost_usd(agent, model, input, output)          │
│ - pricing_calibration_factor(agent, model, phase)        │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│ lib/core/cost.sh (upgraded)                              │
│ - cost_record() now logs USD cost                        │
│ - cost_calibrate() reads canary-history.md               │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│ lib/run/calibrate.sh                                     │
│ - Analyzes $STATE_DIR/*/cost.json                        │
│ - Computes actual-vs-estimated ratios                    │
│ - Updates config/pricing.yaml calibration section        │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│ cmd/calibrate.sh                                         │
│ - monozukuri calibrate [--sample N]                      │
│ - Displays calibration report                            │
└─────────────────────────────────────────────────────────┘
```

## Data Model

### pricing.yaml Structure

```yaml
version: "1.0.0"
updated_at: "2026-04-27"
providers:
  claude-code:
    models:
      claude-opus-4-7:
        input_per_1m: 15.00
        output_per_1m: 75.00
      claude-sonnet-4-6:
        input_per_1m: 3.00
        output_per_1m: 15.00
      claude-haiku-4-5:
        input_per_1m: 0.80
        output_per_1m: 4.00
  aider:
    models:
      gpt-4o:
        input_per_1m: 5.00
        output_per_1m: 15.00
      gpt-4o-mini:
        input_per_1m: 0.15
        output_per_1m: 0.60
calibration:
  claude-code:
    claude-sonnet-4-6:
      prd: 1.0
      techspec: 1.0
      tasks: 1.0
      code: 1.0
      tests: 1.0
      pr: 1.0
  aider:
    gpt-4o:
      prd: 1.0
      techspec: 1.0
      tasks: 1.0
      code: 1.0
      tests: 1.0
      pr: 1.0
```

### cost.json Enhancement

Existing format (per feature):

```json
{
  "prd": { "estimated_tokens": 25000, "actual_tokens": null },
  "techspec": { "estimated_tokens": 15000, "actual_tokens": null },
  ...
}
```

New format (adds USD cost):

```json
{
  "prd": {
    "estimated_tokens": 25000,
    "estimated_usd": 0.12,
    "actual_tokens": 18432,
    "actual_usd": 0.09
  },
  "techspec": {
    "estimated_tokens": 15000,
    "estimated_usd": 0.07,
    "actual_tokens": null,
    "actual_usd": null
  },
  ...
}
```

## Component Design

### 1. `lib/core/pricing.sh`

**Functions:**

```bash
pricing_load() {
  # Read config/pricing.yaml
  # Populate env vars:
  #   PRICING_VERSION
  #   PRICING_UPDATED_AT
  #   PRICING_<PROVIDER>_<MODEL>_INPUT_PER_1M
  #   PRICING_<PROVIDER>_<MODEL>_OUTPUT_PER_1M
  #   CALIBRATION_<PROVIDER>_<MODEL>_<PHASE>
}

pricing_cost_usd() {
  # Args: agent model input_tokens output_tokens
  # Returns: USD cost as float (e.g., "0.12")
  local agent=$1 model=$2 input=$3 output=$4

  # If output is empty (token-only estimate), split 70/30
  if [[ -z "$output" ]]; then
    input=$(echo "$input * 0.7" | bc)
    output=$(echo "$input * 0.3" | bc)
  fi

  # Lookup pricing from env vars
  local input_price="${PRICING_${agent^^}_${model//[-.]/_}_INPUT_PER_1M}"
  local output_price="${PRICING_${agent^^}_${model//[-.]/_}_OUTPUT_PER_1M}"

  # Calculate: (input / 1M * input_price) + (output / 1M * output_price)
  echo "scale=4; ($input / 1000000 * $input_price) + ($output / 1000000 * $output_price)" | bc
}

pricing_calibration_factor() {
  # Args: agent model phase
  # Returns: calibration multiplier (default 1.0)
  local agent=$1 model=$2 phase=$3
  local key="CALIBRATION_${agent^^}_${model//[-.]/_}_${phase^^}"
  echo "${!key:-1.0}"
}
```

**Dependencies:**

- yq (YAML parsing) — already used in Monozukuri
- bc (floating point math) — standard on macOS/Linux

### 2. `lib/core/cost.sh` Upgrade

**Changes:**

1. Replace `cost_calibrate()` placeholder (line 149) with real implementation:
   - Parse `docs/canary-history.md` for canary feature cost data
   - Read `$STATE_DIR/*/cost.json` for all completed features
   - This is called by `calibrate.sh`, not during normal execution

2. Upgrade `cost_record()` to log USD cost:
   ```bash
   cost_record() {
     local phase=$1 estimated_tokens=$2

     # Existing token recording...

     # NEW: Calculate USD cost
     local agent="${MODEL_AGENT:-claude-code}"
     local model="${MODEL_PRIMARY:-claude-sonnet-4-6}"
     local calibration=$(pricing_calibration_factor "$agent" "$model" "$phase")
     local calibrated_tokens=$(echo "$estimated_tokens * $calibration" | bc)
     local usd=$(pricing_cost_usd "$agent" "$model" "$calibrated_tokens" "")

     # Store in cost.json
     jq --arg phase "$phase" \
        --argjson est_tokens "$estimated_tokens" \
        --arg est_usd "$usd" \
        '.[$phase].estimated_tokens = $est_tokens | .[$phase].estimated_usd = $est_usd' \
        "$COST_FILE" > "$COST_FILE.tmp"
     mv "$COST_FILE.tmp" "$COST_FILE"
   }
   ```

### 3. `lib/run/calibrate.sh`

**Algorithm:**

```bash
calibrate_run() {
  local sample_size=${1:-20}

  # 1. Load pricing table
  pricing_load

  # 2. Find last N completed features
  local features=($(find "$STATE_DIR" -name "cost.json" -type f | \
                    xargs ls -t | head -n "$sample_size"))

  # 3. Aggregate actual-vs-estimated by (agent, model, phase)
  # Data structure: RATIO_<agent>_<model>_<phase>=sum
  #                 COUNT_<agent>_<model>_<phase>=count

  for cost_file in "${features[@]}"; do
    # Parse cost.json
    # Extract agent, model from feature metadata
    # For each phase with actual_tokens:
    #   ratio = actual_tokens / estimated_tokens
    #   RATIO_... += ratio
    #   COUNT_... += 1
  done

  # 4. Compute averages and write to pricing.yaml
  for key in $(compgen -v | grep "^RATIO_"); do
    local count_key="${key/RATIO_/COUNT_}"
    local avg=$(echo "${!key} / ${!count_key}" | bc -l)
    local agent model phase
    # Parse key to extract agent, model, phase
    # Update pricing.yaml calibration section via yq
  done

  # 5. Generate human-readable report
  calibrate_report
}
```

**Output Example:**

```
Calibration report (last 20 features):
  Agent: claude-code / Model: claude-sonnet-4-6
  Phase     Est tokens   Act tokens   Ratio   Guidance
  ─────────────────────────────────────────────────────
  prd          25 000       18 432    0.74    ↓ reduce baseline
  code         12 000       15 891    1.32    ↑ raise baseline
  tests         8 000        7 821    0.98    ✓ baseline accurate
  ...

  Avg USD/feature: $0.89  (budget: $2.00)

  → Updated calibration coefficients written to config/pricing.yaml
```

### 4. `cmd/calibrate.sh`

**Interface:**

```bash
#!/usr/bin/env bash
# monozukuri calibrate [--sample N]

source "$(dirname "$0")/../lib/run/calibrate.sh"

# Parse args
sample_size=20
while [[ $# -gt 0 ]]; do
  case $1 in
    --sample) sample_size=$2; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

calibrate_run "$sample_size"
```

### 5. UI Type Completeness

**ui/src/types.ts:**

```typescript
export type FeatureStatus =
  | "pending"
  | "in_progress"
  | "completed"
  | "failed"
  | "deferred"; // NEW

export interface FeatureDeferredEvent {
  // NEW
  type: "feature.deferred";
  feature_id: string;
  reason: string;
  blocked_by: string;
}

export type MonozukuriEvent =
  | FeatureCreatedEvent
  | FeatureStartedEvent
  | PhaseStartedEvent
  | PhaseCompletedEvent
  | FeatureCompletedEvent
  | FeatureFailedEvent
  | FeatureDeferredEvent // NEW
  | StateChangeEvent;
```

**ui/src/reducer.ts:**

```typescript
case 'feature.deferred':
  const deferredFeature = state.features.find(f => f.id === event.feature_id);
  if (deferredFeature) {
    deferredFeature.status = 'deferred';
    deferredFeature.error = event.reason;  // Store reason in error field
  }
  break;
```

**ui/src/components/FeatureCard.tsx:**

```typescript
// In render function, add case for deferred status
if (feature.status === 'deferred') {
  return (
    <Box borderStyle="round" borderColor="yellow" paddingX={1}>
      <Text color="yellow">⏸ deferred: {feature.error}</Text>
      <Text dimColor> blocked by: {/* parse blocked_by from metadata */}</Text>
    </Box>
  );
}
```

## Error Handling

| Error                    | Handling                                               |
| ------------------------ | ------------------------------------------------------ |
| pricing.yaml missing     | Use defaults (all 1.0 calibration, warn user)          |
| Invalid YAML syntax      | Fail with clear error message                          |
| Missing model pricing    | Warn and skip USD calculation for that model           |
| No features to calibrate | Report "Insufficient data (need 5+ features)"          |
| yq not installed         | Graceful degradation (skip YAML parsing, use defaults) |

## Testing Strategy

### Unit Tests

1. **test/unit/lib_core_pricing.bats**
   - `pricing_load()` reads YAML correctly
   - `pricing_cost_usd()` calculates USD accurately
   - `pricing_calibration_factor()` returns correct multipliers
   - Token-only split (70/30) works correctly

2. **test/unit/cmd_calibrate.bats**
   - Calibrate command parses cost.json files
   - Ratios computed correctly
   - pricing.yaml updated with new coefficients
   - Report generation works

### Integration Tests

- Full workflow test: create feature → record costs → calibrate → verify pricing.yaml updated

## Migration Path

1. Create `config/pricing.yaml` with current pricing (as of 2026-04-27)
2. Upgrade `lib/core/cost.sh` to log USD costs
3. Existing features without USD data continue working (graceful degradation)
4. Run `monozukuri calibrate` after 5+ features to start learning

## Performance Considerations

- `pricing_load()` should cache parsed YAML (don't re-parse on every call)
- Calibrate command should process cost.json files in parallel (if >50 features)
- YAML updates should be atomic (write to temp file, then mv)

## Security Considerations

None (pricing.yaml is version-controlled, no sensitive data).

## Open Issues

None.
