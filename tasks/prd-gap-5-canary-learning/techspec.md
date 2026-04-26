# Technical Specification

**Project Name:** Monozukuri
**Feature:** Gap 5 - Measurable Learning + Canary Suite + MRP
**Version:** 1.0
**Date:** 2026-04-26
**Status:** Draft
**PRD Reference:** `./prd.md`

---

## Overview

### Problem Statement

Monozukuri currently lacks a fixed benchmark to measure its effectiveness at orchestrating feature development across different tech stacks. Without a constant benchmark, claims of "better than last run" are unverifiable, and there is no quantifiable way to track improvements or regressions over time.

_(Sourced from PRD Executive Summary)_

### Proposed Solution

Implement L5 measurability infrastructure consisting of: (1) a canary benchmark setup with CI automation via GitHub Actions, (2) headline metric tracking (CI-pass-rate-on-first-PR) with per-stack stratification using jq for JSON processing, (3) four diagnostic metrics for deeper analysis, (4) a README badge displaying current performance, and (5) automated weekly publication of results to `docs/canary-history.md` via CI commit workflow.

### Goals

- Establish a fixed benchmark for measuring Monozukuri's orchestration effectiveness
- Provide transparent, verifiable metrics accessible to maintainers and prospective users
- Enable data-driven decision-making for Monozukuri development prioritization
- Create an automated, low-maintenance measurability system that scales with project growth

### PRD Requirements Coverage

| PRD Requirement                     | Covered in Section                 | Implementation Approach                                           |
| ----------------------------------- | ---------------------------------- | ----------------------------------------------------------------- |
| FR-001: Canary History Template     | Components → CanaryHistoryTemplate | Create `docs/canary-history.md` with pipe-delimited schema header |
| FR-002: Weekly Canary CI Workflow   | Components → CanaryWorkflow        | GitHub Actions workflow with cron schedule + workflow_dispatch    |
| FR-003: Metrics Command             | Components → MetricsCommand        | `cmd/metrics.sh` reads history file, calculates trailing average  |
| FR-004: Headline Metric Calculation | Components → MetricsModule         | `lib/memory/metrics.sh` calculates CI-pass-rate with jq           |
| FR-005: Diagnostic Metrics Tracking | Components → MetricsModule         | Track tokens, completion %, retry rate, flake rate in JSON        |
| FR-006: README Badge                | Components → ReadmeBadge           | Markdown badge linking to `docs/canary-history.md`                |
| FR-007: Schema Validation Test      | Testing Strategy → Unit Tests      | Bats test validates column count, date format, numeric fields     |
| FR-008: Canary Run Orchestration    | Components → CanaryOrchestrator    | `lib/run/canary.sh` executes benchmark suite, records metrics     |
| NFR-001: Performance                | Implementation Considerations      | Canary runs optimized to complete within 2-hour CI limit          |
| NFR-002: Schema Stability           | Implementation Considerations      | Schema locked in v1, only append-only changes allowed             |
| NFR-004: Code Quality               | Testing Strategy                   | 80% coverage target for new modules, shellcheck compliance        |

---

## Scope

### In Scope

- Create `docs/canary-history.md` with schema header _(FR-001)_
- Implement `.github/workflows/canary.yml` with weekly cron and workflow*dispatch *(FR-002)\_
- Implement `monozukuri metrics` subcommand _(FR-003)_
- Calculate headline metric (CI-pass-rate-on-first-PR) with per-stack JSON breakdown _(FR-004)_
- Track diagnostic metrics (tokens, completion %, retry rate, flake rate) _(FR-005)_
- Add README badge with link to canary history _(FR-006)_
- Create bats test for schema validation _(FR-007)_
- Implement canary orchestration logic in `lib/run/canary.sh` _(FR-008)_

### Out of Scope

- Trend arrows on badge (↑↓) _(deferred to Phase 2 per PRD)_
- Cross-run learning using past results _(deferred to L6+ per PRD)_
- Dashboards or visualizations beyond badge _(deferred to Phase 2 per PRD)_
- Content of `monozukuri-canaries` repository (external, created manually by maintainer)

---

## Existing Codebase Analysis

### Project Structure (Relevant Paths)

```
/Users/viniciuscarvalho/Documents/monozukuri/
├── orchestrate.sh                         # Entry point, sets MONOZUKURI_HOME
├── cmd/                                   # User-facing subcommands
│   ├── routing.sh                         # Gap 4 routing command (pattern reference)
│   ├── learning.sh                        # Learning store management commands
│   └── [metrics.sh]                       # NEW: Gap 5 metrics command
├── lib/                                   # Logic modules
│   ├── core/
│   │   ├── modules.sh                     # Module loader
│   │   ├── util.sh                        # Utilities (err, info, log_*)
│   │   ├── cost.sh                        # Cost tracking
│   │   └── stack-detector.sh              # Platform detection
│   ├── memory/
│   │   ├── learning.sh                    # Learning store (DO NOT MODIFY)
│   │   ├── memory.sh                      # Memory module
│   │   └── [metrics.sh]                   # NEW: Gap 5 metrics logic
│   └── run/
│       ├── routing.sh                     # Gap 4 routing logic
│       └── [canary.sh]                    # NEW: Gap 5 canary orchestration
├── test/unit/                             # Bats test files
│   ├── cmd_routing.bats                   # Pattern reference for cmd tests
│   ├── [cmd_metrics.bats]                 # NEW: Metrics command tests
│   └── [lib_memory_metrics.bats]          # NEW: Metrics module tests
├── docs/
│   └── [canary-history.md]                # NEW: Canary run results history
├── .github/workflows/
│   └── [canary.yml]                       # NEW: Weekly canary CI workflow
└── README.md                              # Modified: Add L5 badge
```

### Existing Patterns to Follow

**Code Organization:**

- User-facing commands in `cmd/` source logic from `lib/` modules via `source "$LIB_DIR/..."`
- All `cmd/` scripts define a `sub_<command>` function (e.g., `sub_routing`, `sub_metrics`)
- Top-level `orchestrate.sh` dispatches to `cmd/` based on subcommand argument

**Naming Conventions:**

- Files: `kebab-case.sh` (e.g., `cmd/metrics.sh`, `lib/memory/metrics.sh`)
- Functions: `snake_case` (e.g., `_metrics_calculate_headline`, `sub_metrics`)
- Private/internal functions: prefixed with `_` (e.g., `_metrics_parse_row`)
- Variables: `snake_case` for locals, `SCREAMING_SNAKE_CASE` for env vars
- Constants: `_CONSTANT_NAME` for file-scoped constants (e.g., `_CANARY_HISTORY_PATH`)

**Error Handling Pattern:**

```bash
#!/bin/bash
set -euo pipefail  # Exit on error, undefined var, pipe failure

# Source utilities
source "$LIB_DIR/core/modules.sh"
modules_init "$LIB_DIR"
module_require core/util  # Provides err(), info(), log_*()

# Explicit error handling
if [ ! -f "$file_path" ]; then
  err "File not found: $file_path"
  exit 1
fi
```

**Logging Pattern:**

```bash
# Source logging utilities from lib/core/util.sh
info "Starting canary run..."
log_debug "Processing feature: $feat_id"
err "Canary run failed: $error_msg"
```

**Test Pattern:**

```bash
# test/unit/cmd_metrics.bats
@test "metrics command exits with code 1 when history file missing" {
  run "$CMD_DIR/metrics.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"No canary history found"* ]]
}

@test "metrics command displays 4-week trailing average" {
  # Setup: create mock canary-history.md
  cat > "$DOCS_DIR/canary-history.md" <<EOF
date | run_id | headline_% | tokens_avg | completion_% | stack_breakdown_json
2026-04-19 | run-001 | 85 | 45000 | 92 | {"backend":90,"frontend":80}
2026-04-12 | run-002 | 82 | 48000 | 88 | {"backend":85,"frontend":79}
EOF

  run "$CMD_DIR/metrics.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"4-week trailing average"* ]]
  [[ "$output" == *"83.5"* ]]  # (85+82)/2
}
```

### Existing Dependencies (Relevant)

| Package / Module | Version | Used For                         | Important Notes                       |
| ---------------- | ------- | -------------------------------- | ------------------------------------- |
| bash             | >=4.3   | Shell scripting                  | Associative arrays require bash 4+    |
| jq               | >=1.5   | JSON processing                  | Used for stack_breakdown_json parsing |
| node             | >=14    | JSON manipulation in learning.sh | Already a declared runtime dependency |
| bats-core        | latest  | Test framework                   | Installed for existing tests          |
| git              | >=2.23  | Version control, CI              | Required for GitHub Actions           |

### Existing Interfaces / Contracts to Respect

```bash
# lib/core/util.sh provides these logging functions
err() { printf 'ERROR: %s\n' "$*" >&2; }
info() { printf 'INFO: %s\n' "$*"; }
log_debug() { [ "${DEBUG:-}" = "1" ] && printf 'DEBUG: %s\n' "$*" >&2 || true; }
log_info() { printf '[%s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*"; }
log_error() { printf '[%s] ERROR: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*" >&2; }

# Module loading contract (from lib/core/modules.sh)
modules_init "$LIB_DIR"
module_require core/util
module_require cli/output
module_require memory/metrics  # NEW module

# Env vars available in all cmd/*.sh scripts (sourced by orchestrate.sh)
# SCRIPT_DIR, LIB_DIR, CMD_DIR, SCRIPTS_DIR, TEMPLATES_DIR, PROJECT_ROOT,
# ROOT_DIR, CONFIG_DIR, STATE_DIR, RESULTS_DIR, and all OPT_* variables
```

---

## Technical Approach

### Architecture Overview

Gap 5 introduces a **metrics layer** on top of Monozukuri's existing orchestration infrastructure. The architecture follows a three-tier design:

1. **Data Collection Layer** (`lib/run/canary.sh`): Orchestrates canary runs, captures results (CI pass/fail, tokens, completion status, retries, flakes), and writes raw data to `docs/canary-history.md`.

2. **Metrics Processing Layer** (`lib/memory/metrics.sh`): Reads `docs/canary-history.md`, calculates headline metric (CI-pass-rate-on-first-PR) and diagnostic metrics (tokens*avg, completion*%, phase_retry_rate, ci_flake_rate), and formats output for display.

3. **User Interface Layer** (`cmd/metrics.sh`, README badge, CI workflow): Exposes metrics via CLI command, displays badge in README, and automates weekly publication via GitHub Actions.

**Key design principle**: Metrics are stored in a **human-readable, append-only log file** (`docs/canary-history.md`) rather than a database. This ensures transparency, version control tracking, and simplicity for a CLI-first tool.

### Key Design Decisions

| Decision                      | Chosen Option                                                     | Alternatives Considered                   | Rationale                                                                                                                                    |
| ----------------------------- | ----------------------------------------------------------------- | ----------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| Metrics storage format        | Pipe-delimited markdown table in `docs/canary-history.md`         | SQLite database, JSON file, CSV           | Markdown is human-readable, version-controlled, and aligns with CLI-first philosophy. Pipe-delimited is parseable with standard shell tools. |
| Stack breakdown encoding      | JSON object in single column (`stack_breakdown_json`)             | Multiple columns per stack                | Single JSON column keeps schema stable (NFR-002). New stacks can be added without schema changes.                                            |
| Metrics calculation location  | `lib/memory/metrics.sh` (new module, separate from `learning.sh`) | Extend `lib/memory/learning.sh`           | PRD constraint: do not modify `learning.sh`. Learning store is for qualitative patterns; metrics are quantitative.                           |
| Canary execution trigger      | GitHub Actions cron + workflow_dispatch                           | Jenkins, cron job on maintainer's machine | GitHub Actions is already used, free for public repos, and provides audit logs.                                                              |
| Metrics command output format | Human-readable table                                              | Raw CSV, JSON                             | CLI users expect formatted output. Power users can parse `canary-history.md` directly.                                                       |
| Badge implementation          | Static markdown badge linking to `docs/canary-history.md`         | shields.io API dynamic badge              | Static badge is simpler for v1. Dynamic badge requires external service and adds complexity.                                                 |

### Components

#### Component 1: CanaryHistoryTemplate

**Purpose:** Provide a schema header for recording canary run results
**Location:** `docs/canary-history.md`
**Implements PRD:** FR-001, STORY-001

**Responsibilities:**

- Define the schema for canary history with 6 columns: date, run*id, headline*%, tokens*avg, completion*%, stack_breakdown_json
- Serve as a human-readable log of all canary runs
- Provide parseable data for the metrics command and schema validation test

**Public Interface:**

```markdown
# Canary Run History

This file records the results of weekly canary benchmark runs. Each row represents one run.

## Schema

| Column               | Type       | Description                                   |
| -------------------- | ---------- | --------------------------------------------- |
| date                 | YYYY-MM-DD | Date of canary run                            |
| run_id               | string     | Unique identifier (e.g., run-20260426-123456) |
| headline\_%          | number     | CI-pass-rate-on-first-PR (0-100)              |
| tokens_avg           | number     | Average tokens per feature                    |
| completion\_%        | number     | Feature completion rate (0-100)               |
| stack_breakdown_json | JSON       | Per-stack metrics                             |

## History

| date | run_id | headline\_% | tokens_avg | completion\_% | stack_breakdown_json |
| ---- | ------ | ----------- | ---------- | ------------- | -------------------- |
```

**Internal Behavior:**

1. File is created with schema header during Gap 5 implementation
2. Canary runs append new rows to the table after the header
3. Metrics command reads all rows, parses pipe-delimited format, and calculates trailing averages

**Error States:**
| Error Condition | Handling | User-Facing Message |
|-----------------|----------|---------------------|
| File does not exist | Metrics command exits with code 1 | "No canary history found. Run canary benchmarks to collect data." |
| Malformed row (wrong column count) | Schema validation test fails | "Invalid schema: expected 6 columns, found N" |
| Invalid date format | Schema validation test fails | "Invalid date format in row N: expected YYYY-MM-DD" |

---

#### Component 2: CanaryWorkflow

**Purpose:** Automate weekly canary runs and commit results to `docs/canary-history.md`
**Location:** `.github/workflows/canary.yml`
**Implements PRD:** FR-002, STORY-002

**Responsibilities:**

- Trigger canary runs weekly (Sunday 00:00 UTC) via cron schedule
- Allow manual on-demand execution via workflow_dispatch
- Invoke `lib/run/canary.sh` to execute the benchmark suite
- Commit updated `docs/canary-history.md` with conventional commit message
- Log errors without committing partial results if canary run fails

**Public Interface:**

```yaml
name: Weekly Canary Benchmark

on:
  schedule:
    - cron: "0 0 * * 0" # Weekly on Sunday at 00:00 UTC
  workflow_dispatch: # Manual trigger

jobs:
  canary:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: "18"

      - name: Install dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y jq

      - name: Run canary benchmark
        id: canary_run
        run: |
          bash lib/run/canary.sh
        env:
          MONOZUKURI_HOME: ${{ github.workspace }}

      - name: Commit canary results
        if: steps.canary_run.outcome == 'success'
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git add docs/canary-history.md
          RUN_ID=$(grep -o 'run-[0-9-]*' docs/canary-history.md | tail -1)
          git commit -m "chore: update canary metrics ($RUN_ID)"
          git push
```

**Internal Behavior:**

1. GitHub Actions cron triggers workflow on schedule
2. Checkout repository and setup runtime environment (Node.js, jq)
3. Invoke `lib/run/canary.sh` which executes all canary features
4. On success, commit updated `docs/canary-history.md` with run_id in message
5. On failure, log error details but do not commit

**Error States:**
| Error Condition | Handling | User-Facing Message |
|-----------------|----------|---------------------|
| Canary run fails mid-execution | Workflow logs error, does not commit | "Canary run failed: <error details>" (in CI logs) |
| Git push fails (merge conflict) | Workflow fails, maintainer notified | "Failed to push canary results: merge conflict" |
| Runtime dependency missing (jq) | Workflow fails in setup step | "Failed to install jq" |

---

#### Component 3: MetricsCommand

**Purpose:** User-facing CLI command to view recent canary performance trends
**Location:** `cmd/metrics.sh`
**Implements PRD:** FR-003, STORY-003

**Responsibilities:**

- Parse command-line arguments (none required, future: `--format json`)
- Source `lib/memory/metrics.sh` for metrics calculation logic
- Display last 4 weeks of canary data in human-readable table format
- Show 4-week trailing average for headline metric
- Exit with code 1 if `docs/canary-history.md` does not exist
- Exit with code 2 if schema is corrupted

**Public Interface:**

```bash
#!/bin/bash
# cmd/metrics.sh — metrics subcommand (Gap 5)
# Invoked via: monozukuri metrics

set -euo pipefail

# Sourced by orchestrate.sh; inherits SCRIPT_DIR, LIB_DIR, CMD_DIR, etc.

sub_metrics() {
  source "$LIB_DIR/core/modules.sh"
  modules_init "$LIB_DIR"
  module_require core/util
  module_require memory/metrics

  local history_file="${PROJECT_ROOT}/docs/canary-history.md"

  if [ ! -f "$history_file" ]; then
    err "No canary history found. Run canary benchmarks to collect data."
    exit 1
  fi

  metrics_display "$history_file"
}
```

**Internal Behavior:**

1. Check if `docs/canary-history.md` exists
2. Call `metrics_display` from `lib/memory/metrics.sh`
3. Display formatted output to stdout
4. Exit with appropriate code based on success/failure

**Error States:**
| Error Condition | Handling | User-Facing Message |
|-----------------|----------|---------------------|
| History file missing | Exit 1 | "No canary history found. Run canary benchmarks to collect data." |
| Corrupted schema | Exit 2 | "Invalid canary history format. Expected 6 columns per row." |
| Empty history (header only) | Display warning | "No canary runs recorded yet." |

---

#### Component 4: MetricsModule

**Purpose:** Calculate headline and diagnostic metrics from `docs/canary-history.md`
**Location:** `lib/memory/metrics.sh`
**Implements PRD:** FR-004, FR-005, STORY-004, STORY-005

**Responsibilities:**

- Parse `docs/canary-history.md` pipe-delimited rows
- Calculate headline metric (CI-pass-rate-on-first-PR) as percentage
- Extract diagnostic metrics (tokens*avg, completion*%, phase_retry_rate, ci_flake_rate)
- Parse JSON stack_breakdown_json column using jq
- Calculate 4-week trailing average for headline metric
- Format output as human-readable table

**Public Interface:**

```bash
# lib/memory/metrics.sh

# Display last 4 weeks of canary data and trailing average
# Usage: metrics_display <history_file_path>
metrics_display() {
  local history_file="$1"

  # Validate schema
  if ! _metrics_validate_schema "$history_file"; then
    err "Invalid canary history format. Expected 6 columns per row."
    exit 2
  fi

  # Extract last 4 weeks (or fewer if not enough data)
  local rows
  rows=$(_metrics_extract_recent "$history_file" 4)

  if [ -z "$rows" ]; then
    info "No canary runs recorded yet."
    return 0
  fi

  # Display table header
  printf '\n%-12s | %-18s | %-10s | %-12s | %-12s\n' \
    "Date" "Run ID" "Headline %" "Tokens Avg" "Completion %"
  printf '%s\n' "-------------|--------------------|-----------|--------------|--------------"

  # Display rows
  echo "$rows" | while IFS= read -r row; do
    _metrics_format_row "$row"
  done

  # Calculate and display trailing average
  local avg
  avg=$(_metrics_calculate_trailing_average "$rows")
  printf '\n4-week trailing average: %.1f%%\n\n' "$avg"
}

# Append new canary run results to history file
# Usage: metrics_append <history_file> <run_id> <headline_%> <tokens_avg> <completion_%> <stack_json>
metrics_append() {
  local history_file="$1"
  local run_id="$2"
  local headline="$3"
  local tokens="$4"
  local completion="$5"
  local stack_json="$6"

  local date
  date=$(date -u +%Y-%m-%d)

  printf '%s | %s | %s | %s | %s | %s\n' \
    "$date" "$run_id" "$headline" "$tokens" "$completion" "$stack_json" \
    >> "$history_file"
}
```

**Internal Behavior:**

1. Validate schema: check that each row has exactly 6 pipe-delimited columns
2. Extract last N weeks of data (skip schema header, reverse order)
3. Parse each row: split by pipe, trim whitespace
4. Calculate trailing average: sum headline\_% values, divide by count
5. Format output: align columns, format numbers

**Error States:**
| Error Condition | Handling | User-Facing Message |
|-----------------|----------|---------------------|
| Invalid column count | Exit 2 | "Invalid schema: expected 6 columns, found N in row M" |
| Non-numeric headline*% | Skip row, log warning | "Warning: skipping row with non-numeric headline*%" |
| Malformed JSON in stack_breakdown | Skip row, log warning | "Warning: skipping row with invalid JSON" |

---

#### Component 5: CanaryOrchestrator

**Purpose:** Execute canary benchmark suite and record metrics
**Location:** `lib/run/canary.sh`
**Implements PRD:** FR-008, STORY-008

**Responsibilities:**

- Load canary configuration (feature list, stack mappings)
- Execute each canary feature via Monozukuri's standard run workflow
- Track CI pass/fail status, token counts, completion status, retries, flakes
- Calculate headline metric and diagnostic metrics
- Append results to `docs/canary-history.md` via `metrics_append`

**Public Interface:**

```bash
#!/bin/bash
# lib/run/canary.sh — canary benchmark orchestration (Gap 5)

set -euo pipefail

# Execute canary benchmark suite
# Expects: MONOZUKURI_HOME set, canary config at .monozukuri/canary-config.json
# Outputs: Appends results to docs/canary-history.md
canary_run() {
  source "$LIB_DIR/core/modules.sh"
  modules_init "$LIB_DIR"
  module_require core/util
  module_require memory/metrics

  local config_file="${CONFIG_DIR}/canary-config.json"
  local history_file="${PROJECT_ROOT}/docs/canary-history.md"

  if [ ! -f "$config_file" ]; then
    err "Canary config not found: $config_file"
    exit 1
  fi

  info "Starting canary benchmark run..."

  # Generate unique run ID
  local run_id
  run_id="run-$(date -u +%Y%m%d-%H%M%S)"

  # Execute features and collect results
  local total=0 ci_pass=0 tokens_sum=0 completed=0
  local stack_results="{}"

  # (Feature execution loop - see Internal Behavior)

  # Calculate metrics
  local headline_pct
  headline_pct=$(awk -v p="$ci_pass" -v t="$total" 'BEGIN {printf "%.0f", t>0 ? (p/t)*100 : 0}')

  local tokens_avg
  tokens_avg=$(awk -v s="$tokens_sum" -v t="$total" 'BEGIN {printf "%.0f", t>0 ? s/t : 0}')

  local completion_pct
  completion_pct=$(awk -v c="$completed" -v t="$total" 'BEGIN {printf "%.0f", t>0 ? (c/t)*100 : 0}')

  # Append to history
  metrics_append "$history_file" "$run_id" "$headline_pct" "$tokens_avg" "$completion_pct" "$stack_results"

  info "Canary run complete: $run_id"
  info "Headline metric: ${headline_pct}%"
}
```

**Internal Behavior:**

1. Load canary configuration from `.monozukuri/canary-config.json` (feature list, stack mappings)
2. Generate unique run_id: `run-YYYYMMDD-HHMMSS`
3. For each feature in config:
   a. Execute feature via `monozukuri run <feature_id>`
   b. Track CI pass/fail status (check PR CI status)
   c. Track token count (read from `$STATE_DIR/<feature_id>/cost.json`)
   d. Track completion status (check if all tasks completed)
   e. Track retries (phase retry count from checkpoint)
   f. Track flakes (CI flake count from logs)
4. Aggregate results by stack slice (backend, frontend, mobile, infra, data)
5. Calculate headline\_% = (features with CI pass on first PR / total features) \* 100
6. Calculate diagnostic metrics (tokens*avg, completion*%, retry rate, flake rate)
7. Encode stack breakdown as JSON: `{"backend": 90, "frontend": 80, ...}`
8. Append row to `docs/canary-history.md` via `metrics_append`

**Error States:**
| Error Condition | Handling | User-Facing Message |
|-----------------|----------|---------------------|
| Canary config missing | Exit 1 | "Canary config not found: .monozukuri/canary-config.json" |
| Feature execution fails | Mark as incomplete, continue | "Feature <id> failed: <error>; marking incomplete" |
| All features fail | Record 0% headline, commit result | "All canary features failed; headline: 0%" |
| Cannot write to history file | Exit 1 | "Failed to write to docs/canary-history.md" |

---

#### Component 6: ReadmeBadge

**Purpose:** Display current L5 performance in README
**Location:** `README.md` (modified)
**Implements PRD:** FR-006, STORY-006

**Responsibilities:**

- Display a badge showing "monozukuri L5: NN% (4-wk trailing, 20-canary benchmark)"
- Link to `docs/canary-history.md` for full historical data

**Public Interface:**

```markdown
# Monozukuri

[![L5 Metrics](https://img.shields.io/badge/L5-See%20History-blue)](docs/canary-history.md)

<!-- Or static text badge until first canary run: -->

[![L5 Metrics](<https://img.shields.io/badge/L5-N%2FA%20(pending%20first%20run)-lightgrey>)](docs/canary-history.md)

Monozukuri is a terminal orchestrator that automates feature development workflows...
```

**Internal Behavior:**

1. Badge is a static markdown image linking to `docs/canary-history.md`
2. Initial badge shows "N/A (pending first run)" until first canary completes
3. After first canary run, badge is manually updated to show latest 4-week average (future: automate via GitHub Actions)

**Error States:**
| Error Condition | Handling | User-Facing Message |
|-----------------|----------|---------------------|
| Badge link broken (canary-history.md missing) | 404 error when clicked | (User sees 404 page) |

---

#### Component 7: SchemaValidationTest

**Purpose:** Validate `docs/canary-history.md` schema in CI
**Location:** `test/unit/lib_memory_metrics.bats`
**Implements PRD:** FR-007, STORY-007

**Responsibilities:**

- Validate that each data row has exactly 6 pipe-delimited columns
- Validate date format (YYYY-MM-DD)
- Validate numeric fields (headline*%, tokens_avg, completion*%)
- Validate JSON format of stack_breakdown_json column

**Public Interface:**

```bash
# test/unit/lib_memory_metrics.bats

@test "canary-history.md has correct schema (6 columns)" {
  # Setup: create mock history file
  cat > "$DOCS_DIR/canary-history.md" <<EOF
date | run_id | headline_% | tokens_avg | completion_% | stack_breakdown_json
-----|--------|------------|------------|--------------|---------------------
2026-04-26 | run-001 | 85 | 45000 | 92 | {"backend":90,"frontend":80}
EOF

  # Validate schema
  run bash -c "source $LIB_DIR/memory/metrics.sh && _metrics_validate_schema $DOCS_DIR/canary-history.md"
  [ "$status" -eq 0 ]
}

@test "canary-history.md schema validation catches invalid column count" {
  cat > "$DOCS_DIR/canary-history.md" <<EOF
date | run_id | headline_%
2026-04-26 | run-001 | 85
EOF

  run bash -c "source $LIB_DIR/memory/metrics.sh && _metrics_validate_schema $DOCS_DIR/canary-history.md"
  [ "$status" -eq 2 ]
  [[ "$output" == *"expected 6 columns"* ]]
}

@test "canary-history.md schema validation catches invalid date format" {
  cat > "$DOCS_DIR/canary-history.md" <<EOF
date | run_id | headline_% | tokens_avg | completion_% | stack_breakdown_json
04/26/2026 | run-001 | 85 | 45000 | 92 | {}
EOF

  run bash -c "source $LIB_DIR/memory/metrics.sh && _metrics_validate_schema $DOCS_DIR/canary-history.md"
  [ "$status" -eq 2 ]
  [[ "$output" == *"invalid date format"* ]]
}
```

**Internal Behavior:**

1. Read `docs/canary-history.md`
2. Skip schema header and separator rows
3. For each data row:
   a. Split by pipe (`|`), count columns
   b. Validate date column matches `YYYY-MM-DD`
   c. Validate numeric columns are numbers
   d. Validate JSON column with `jq`
4. Exit 0 if all rows valid, exit 2 if any validation fails

**Error States:**
| Error Condition | Handling | User-Facing Message |
|-----------------|----------|---------------------|
| File does not exist | Skip test with warning | "SKIP: canary-history.md not found (expected for new projects)" |
| Invalid schema | Test fails | "FAIL: Invalid schema at line N: <details>" |

---

### Component Interaction

```
[GitHub Actions: .github/workflows/canary.yml]
    |
    | (weekly cron or manual dispatch)
    v
[CanaryOrchestrator: lib/run/canary.sh]
    |
    | reads config: .monozukuri/canary-config.json
    | executes features, tracks metrics
    v
[MetricsModule: lib/memory/metrics.sh]
    |
    | metrics_append(...)
    v
[CanaryHistory: docs/canary-history.md]
    |
    | (CI commits updated file)
    |
    +--> [MetricsCommand: cmd/metrics.sh] <-- User invokes `monozukuri metrics`
    |         |
    |         | metrics_display(...)
    |         v
    |    [Terminal: formatted table output]
    |
    +--> [SchemaValidationTest: test/unit/lib_memory_metrics.bats]
    |         |
    |         | _metrics_validate_schema(...)
    |         v
    |    [CI: bats test passes/fails]
    |
    +--> [ReadmeBadge: README.md]
              |
              | (user clicks badge)
              v
         [Browser: view canary-history.md on GitHub]
```

---

### Data Model

#### Entity 1: CanaryRun

**Location:** `docs/canary-history.md` (each row is a CanaryRun)

```bash
# Schema (pipe-delimited markdown table)
date | run_id | headline_% | tokens_avg | completion_% | stack_breakdown_json

# Example row
2026-04-26 | run-20260426-123456 | 85 | 45000 | 92 | {"backend":90,"frontend":80,"mobile":85,"infra":88,"data":82}
```

**Constraints:**

- `date`: YYYY-MM-DD format (ISO 8601 date only, no time)
- `run_id`: Unique identifier, format `run-YYYYMMDD-HHMMSS`
- `headline_%`: Integer 0-100 (or "N/A" if no features attempted)
- `tokens_avg`: Integer >= 0
- `completion_%`: Integer 0-100
- `stack_breakdown_json`: Valid JSON object with stack names as keys, percentages as values

**Migrations Required:** No (new file, not modifying existing data structures)
**Migration Details:** N/A

---

#### Entity 2: CanaryConfig

**Location:** `.monozukuri/canary-config.json`

```json
{
  "features": [
    {
      "id": "feat-001-node-api-endpoint",
      "stack": "backend",
      "repo": "monozukuri-canaries",
      "path": "backend/node-api-endpoint"
    },
    {
      "id": "feat-002-react-component",
      "stack": "frontend",
      "repo": "monozukuri-canaries",
      "path": "frontend/react-component"
    }
  ],
  "stacks": [
    "backend",
    "frontend",
    "mobile",
    "infra",
    "data",
    "go",
    "swift",
    "dbt"
  ]
}
```

**Constraints:**

- `features`: Array of objects, each with `id`, `stack`, `repo`, `path`
- `id`: Unique feature identifier (used in worktree and state directories)
- `stack`: Must be one of the values in `stacks` array
- `repo`: Repository name (e.g., "monozukuri-canaries")
- `path`: Path within repo to feature definition

**Migrations Required:** No (new file, created manually by maintainer)
**Migration Details:** N/A

---

## File Change Map

_Exact files to be created or modified. This is the primary input for task generation._

### New Files

| File Path                           | Purpose                       | Component             | Size Estimate |
| ----------------------------------- | ----------------------------- | --------------------- | ------------- |
| `cmd/metrics.sh`                    | User-facing metrics command   | MetricsCommand        | S             |
| `lib/memory/metrics.sh`             | Metrics calculation logic     | MetricsModule         | M             |
| `lib/run/canary.sh`                 | Canary orchestration          | CanaryOrchestrator    | L             |
| `docs/canary-history.md`            | Canary run results log        | CanaryHistoryTemplate | S             |
| `.github/workflows/canary.yml`      | Weekly CI workflow            | CanaryWorkflow        | M             |
| `test/unit/cmd_metrics.bats`        | Metrics command tests         | SchemaValidationTest  | M             |
| `test/unit/lib_memory_metrics.bats` | Metrics module tests          | SchemaValidationTest  | M             |
| `.monozukuri/canary-config.json`    | Canary feature list (example) | CanaryConfig          | S             |

### Modified Files

| File Path        | Change Description                               | Risk Level | Component      |
| ---------------- | ------------------------------------------------ | ---------- | -------------- |
| `README.md`      | Add L5 badge linking to `docs/canary-history.md` | Low        | ReadmeBadge    |
| `orchestrate.sh` | Add routing for `metrics` subcommand             | Low        | MetricsCommand |

### Files to Read (Context Only)

| File Path                    | Why It Matters                                              |
| ---------------------------- | ----------------------------------------------------------- |
| `cmd/routing.sh`             | Pattern reference for command structure, argument parsing   |
| `lib/memory/learning.sh`     | Understand existing memory module patterns, avoid conflicts |
| `lib/core/util.sh`           | Logging and error handling utilities                        |
| `test/unit/cmd_routing.bats` | Pattern reference for command tests                         |

---

## Implementation Considerations

### Design Patterns Used

- **Append-Only Log:** `docs/canary-history.md` is never edited, only appended. Ensures data integrity and version control auditability.
- **Module Separation:** Metrics module (`lib/memory/metrics.sh`) is separate from learning module (`lib/memory/learning.sh`) to respect PRD constraint and maintain single responsibility.
- **Schema Validation:** Bats tests validate schema before CI accepts changes, preventing bad data from being committed.

### Edge Cases and Boundary Conditions

| Scenario                                     | Expected Behavior                                                      | Implementation Note                            |
| -------------------------------------------- | ---------------------------------------------------------------------- | ---------------------------------------------- |
| First canary run (no history yet)            | Create `docs/canary-history.md` with header, append first row          | `metrics_append` creates file if missing       |
| Fewer than 4 weeks of data                   | Display all available rows, calculate average with available data      | `_metrics_extract_recent` returns up to N rows |
| Zero features attempted in run               | Record `headline_%` as "N/A"                                           | Special case in `canary_run` calculation       |
| All features pass (100% headline)            | Record `100` without overflow                                          | No special handling needed                     |
| Stack breakdown has new stack                | JSON format allows arbitrary keys; no schema change needed             | `jq` parses flexibly                           |
| History file becomes very large (1000+ rows) | `metrics_display` only reads last N lines (use `tail`) for performance | Optimize parsing in `_metrics_extract_recent`  |

### Performance Considerations

- **Canary run duration:** Must complete within 2 hours. Optimization: run features in parallel where possible (future enhancement).
- **Metrics command latency:** Parse only last N rows of `canary-history.md` using `tail` to avoid reading entire file.
- **CI workflow efficiency:** Cache dependencies (Node.js, jq) to reduce setup time.

### Security Considerations

- **GitHub Actions secrets:** No secrets required for canary runs (public repo). If private repo, use `GITHUB_TOKEN` for git push.
- **Input validation:** Validate all user inputs in `metrics_append` to prevent injection attacks (though file is append-only, not executed).

### Backward Compatibility

**Breaking Changes:** No
**Details:** The `monozukuri metrics` command is a new addition. No existing commands are modified. The canary workflow is opt-in (requires manual setup of `.monozukuri/canary-config.json`).
**Migration Strategy:** N/A

### Configuration

| Config Key                       | Type      | Default                                | Description                                        |
| -------------------------------- | --------- | -------------------------------------- | -------------------------------------------------- |
| `.monozukuri/canary-config.json` | JSON file | (none, created manually)               | Defines canary features and stack mappings         |
| `CANARY_HISTORY_PATH`            | Env var   | `$PROJECT_ROOT/docs/canary-history.md` | Path to canary history file (override for testing) |

---

## Testing Strategy

### Unit Tests

**Coverage Target:** 80%
**Framework:** bats-core

| Test Suite                | File                                     | Covers Component   | Key Scenarios                                                                |
| ------------------------- | ---------------------------------------- | ------------------ | ---------------------------------------------------------------------------- |
| Metrics Command Tests     | `test/unit/cmd_metrics.bats`             | MetricsCommand     | Missing history file (exit 1), corrupted schema (exit 2), display formatting |
| Metrics Module Tests      | `test/unit/lib_memory_metrics.bats`      | MetricsModule      | Schema validation, trailing average calculation, row parsing, JSON handling  |
| Canary Orchestrator Tests | (future) `test/unit/lib_run_canary.bats` | CanaryOrchestrator | Feature execution tracking, metric aggregation, stack breakdown generation   |

**Sample Test Cases:**

```bash
# test/unit/cmd_metrics.bats

@test "metrics command exits 1 when history file missing" {
  run "$CMD_DIR/metrics.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"No canary history found"* ]]
}

@test "metrics command displays 4-week trailing average" {
  cat > "$DOCS_DIR/canary-history.md" <<EOF
date | run_id | headline_% | tokens_avg | completion_% | stack_breakdown_json
-----|--------|------------|------------|--------------|---------------------
2026-04-26 | run-001 | 85 | 45000 | 92 | {"backend":90}
2026-04-19 | run-002 | 82 | 48000 | 88 | {"backend":85}
EOF

  run "$CMD_DIR/metrics.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"4-week trailing average: 83.5%"* ]]
}

@test "metrics command handles empty history (header only)" {
  cat > "$DOCS_DIR/canary-history.md" <<EOF
date | run_id | headline_% | tokens_avg | completion_% | stack_breakdown_json
-----|--------|------------|------------|--------------|---------------------
EOF

  run "$CMD_DIR/metrics.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"No canary runs recorded yet"* ]]
}

# test/unit/lib_memory_metrics.bats

@test "schema validation passes for valid history file" {
  cat > "$DOCS_DIR/canary-history.md" <<EOF
date | run_id | headline_% | tokens_avg | completion_% | stack_breakdown_json
-----|--------|------------|------------|--------------|---------------------
2026-04-26 | run-001 | 85 | 45000 | 92 | {"backend":90,"frontend":80}
EOF

  run bash -c "source $LIB_DIR/memory/metrics.sh && _metrics_validate_schema $DOCS_DIR/canary-history.md"
  [ "$status" -eq 0 ]
}

@test "schema validation fails for invalid column count" {
  cat > "$DOCS_DIR/canary-history.md" <<EOF
date | run_id | headline_%
2026-04-26 | run-001 | 85
EOF

  run bash -c "source $LIB_DIR/memory/metrics.sh && _metrics_validate_schema $DOCS_DIR/canary-history.md"
  [ "$status" -eq 2 ]
  [[ "$output" == *"expected 6 columns"* ]]
}

@test "metrics_append creates file if missing and appends row" {
  local history_file="$DOCS_DIR/canary-history.md"
  rm -f "$history_file"

  run bash -c "source $LIB_DIR/memory/metrics.sh && metrics_append '$history_file' 'run-001' 85 45000 92 '{\"backend\":90}'"
  [ "$status" -eq 0 ]
  [ -f "$history_file" ]

  local row_count
  row_count=$(grep -c '^[0-9]' "$history_file")
  [ "$row_count" -eq 1 ]
}

@test "trailing average calculation handles fewer than 4 weeks" {
  cat > "$DOCS_DIR/canary-history.md" <<EOF
date | run_id | headline_% | tokens_avg | completion_% | stack_breakdown_json
-----|--------|------------|------------|--------------|---------------------
2026-04-26 | run-001 | 85 | 45000 | 92 | {}
2026-04-19 | run-002 | 80 | 48000 | 88 | {}
EOF

  run bash -c "source $LIB_DIR/memory/metrics.sh && metrics_display $DOCS_DIR/canary-history.md"
  [ "$status" -eq 0 ]
  [[ "$output" == *"82.5"* ]]  # (85+80)/2
}
```

### Integration Tests

| Scenario                           | Components Involved                               | Setup Required                     | Expected Outcome                                                                |
| ---------------------------------- | ------------------------------------------------- | ---------------------------------- | ------------------------------------------------------------------------------- |
| Full canary run → metrics display  | CanaryOrchestrator, MetricsModule, MetricsCommand | Mock canary config with 2 features | Canary run completes, appends to history, `monozukuri metrics` displays results |
| CI workflow executes and commits   | CanaryWorkflow, CanaryOrchestrator                | GitHub Actions test environment    | Workflow triggers, runs canaries, commits updated history                       |
| Schema validation catches bad data | CanaryOrchestrator, SchemaValidationTest          | Inject malformed row into history  | Bats test fails with descriptive error                                          |

### Validation Commands

```bash
# Run all tests for this feature
bats test/unit/cmd_metrics.bats test/unit/lib_memory_metrics.bats

# Lint check
shellcheck cmd/metrics.sh lib/memory/metrics.sh lib/run/canary.sh

# Build verification (N/A for shell scripts, but validate syntax)
bash -n cmd/metrics.sh
bash -n lib/memory/metrics.sh
bash -n lib/run/canary.sh

# Manual canary run (for testing)
MONOZUKURI_HOME=/path/to/monozukuri bash lib/run/canary.sh
```

---

## Deployment

### Strategy

Gap 5 is deployed via standard PR merge to `main` branch. GitHub Actions workflow (`.github/workflows/canary.yml`) is automatically active after merge and will trigger on the next weekly schedule.

### Environment Requirements

| Environment         | Requirement                                | Notes                                                     |
| ------------------- | ------------------------------------------ | --------------------------------------------------------- |
| Development         | bash >=4.3, jq >=1.5, node >=14, bats-core | Local testing of metrics command and canary orchestration |
| CI (GitHub Actions) | ubuntu-latest, jq, node 18                 | Automated canary runs and schema validation               |
| Production (N/A)    | N/A                                        | CLI tool, no production deployment                        |

### Feature Flags (if applicable)

| Flag Name | Default | Controls                           |
| --------- | ------- | ---------------------------------- |
| (none)    | N/A     | Gap 5 is always active once merged |

### Rollback Procedure

If canary workflow causes issues:

1. Disable workflow: Edit `.github/workflows/canary.yml`, comment out `schedule` trigger
2. Revert PR: `git revert <commit-sha>` and push to `main`
3. Clean up state: Remove `docs/canary-history.md` if data is corrupted

---

## Dependencies

### New Dependencies Required

| Package       | Version | Purpose                                   | License | Size Impact                    |
| ------------- | ------- | ----------------------------------------- | ------- | ------------------------------ |
| jq            | >=1.5   | JSON parsing for stack_breakdown_json     | MIT     | ~1MB (already used in project) |
| (none others) | N/A     | All other dependencies already in project | N/A     | N/A                            |

### External Service Dependencies

| Service        | Endpoint       | Auth Method                  | Fallback                            |
| -------------- | -------------- | ---------------------------- | ----------------------------------- |
| GitHub Actions | github.com API | GITHUB_TOKEN (auto-provided) | Manual canary runs via local script |
| (none others)  | N/A            | N/A                          | N/A                                 |

---

## Risks and Mitigations

| Risk                                    | Impact (H/M/L) | Probability (H/M/L) | Mitigation                                                         | Contingency                                                    |
| --------------------------------------- | -------------- | ------------------- | ------------------------------------------------------------------ | -------------------------------------------------------------- |
| Canary runs exceed 2-hour CI limit      | H              | M                   | Optimize feature set (20 features max), parallelize where possible | Reduce feature count, split into multiple workflows            |
| Schema changes break backward compat    | H              | L                   | Lock schema in v1 (NFR-002), only allow append-only columns        | Document schema versioning, provide migration script if needed |
| GitHub Actions runner availability      | M              | L                   | Add retry logic, monitor GitHub status page                        | Manual canary runs via local script                            |
| Incomplete canary repo (missing stacks) | M              | M                   | Document canary repo requirements, provide examples                | Start with partial stack coverage, expand incrementally        |
| Metrics command slow with large history | L              | M                   | Optimize to read only last N lines (use `tail -n 100`)             | Archive old history to separate file                           |

---

## Task Generation Guide

_Instructions for breaking this TechSpec into executable tasks._

### Suggested Task Order

1. **Create canary history template** — Low-risk foundation, no dependencies
2. **Implement metrics module** — Core logic, required by other components
3. **Implement metrics command** — User-facing command, depends on metrics module
4. **Add README badge** — Simple documentation update
5. **Create schema validation tests** — Ensure data quality before CI automation
6. **Implement canary orchestrator** — Complex component, depends on metrics module
7. **Create CI workflow** — Automates canary runs, final integration piece

### Task Dependency Graph

```
[Task 1: Create canary-history.md template]
    ↓
[Task 2: Implement lib/memory/metrics.sh] → [Task 5: Schema validation tests]
    ↓
[Task 3: Implement cmd/metrics.sh]
    |
    +--> [Task 4: Add README badge]
    |
    +--> [Task 6: Implement lib/run/canary.sh]
             ↓
         [Task 7: Create .github/workflows/canary.yml]
             ↓
         [Task 8: Integration testing and documentation]
```

### Complexity Distribution

| Task                              | Complexity | Estimated Effort | Critical Path |
| --------------------------------- | ---------- | ---------------- | ------------- |
| Create canary-history.md template | S          | 15 min           | Yes           |
| Implement lib/memory/metrics.sh   | M          | 2 hours          | Yes           |
| Implement cmd/metrics.sh          | S          | 45 min           | Yes           |
| Add README badge                  | S          | 15 min           | No            |
| Schema validation tests           | M          | 1.5 hours        | Yes           |
| Implement lib/run/canary.sh       | L          | 3 hours          | Yes           |
| Create canary CI workflow         | M          | 1 hour           | Yes           |
| Integration testing and docs      | M          | 1 hour           | Yes           |

---

## TechSpec Validation Checklist

_This section MUST be verified against the actual codebase before the document is considered complete._

- [x] Every PRD FR has a corresponding component or section
- [x] File Change Map reflects actual project structure (paths verified)
- [x] Existing patterns section matches real codebase conventions
- [x] All interfaces/contracts are compatible with existing code
- [x] No new dependency conflicts with existing dependencies (jq already used)
- [x] Test strategy covers all acceptance criteria from PRD
- [x] Validation commands are runnable in the project
- [x] Backward compatibility is assessed and documented (no breaking changes)
- [x] Task Generation Guide provides a viable execution order
- [x] Edge cases from PRD are addressed in components

---

## Glossary

| Term              | Definition                                                                               |
| ----------------- | ---------------------------------------------------------------------------------------- | ---------------------------------------------------- |
| L5                | Maturity level 5 in Monozukuri's capability model (measurable results published)         |
| MRP               | Measurable Results Published — automated weekly update of canary metrics via CI          |
| Headline Metric   | CI-pass-rate-on-first-PR (primary performance indicator for orchestration quality)       |
| Canary Suite      | Fixed set of 20 benchmark features across 8 tech stack slices for consistent measurement |
| Stack Slice       | Technology category (backend, frontend, mobile, infra, data, go, swift, dbt)             |
| Trailing Average  | Mean of headline metric over last 4 weeks (or fewer if insufficient data)                |
| workflow_dispatch | GitHub Actions trigger for manual workflow execution (on-demand canary runs)             |
| Pipe-Delimited    | Text format using `                                                                      | `as field separator, used in`docs/canary-history.md` |
| Append-Only Log   | Data structure where new entries are only added, never modified or deleted               |

---

**Document End**
