# Gap 5: L5 Measurability Usage Guide

## Overview

Gap 5 adds L5 measurability infrastructure to Monozukuri, providing quantifiable metrics for orchestration effectiveness through automated canary benchmarks.

## Commands

### View Metrics

```bash
monozukuri metrics
```

Displays the last 4 weeks of canary benchmark data and the trailing average for the headline metric (CI-pass-rate-on-first-PR).

Example output:

```
Date         | Run ID              | Headline % | Tokens Avg   | Completion %
-------------|---------------------|-----------|--------------|--------------
2026-04-26   | run-20260426-183854 |        100 |        42516 |          100

4-week trailing average: 100.0%
```

### Manual Canary Run

```bash
# Ensure environment variables are set
export MONOZUKURI_HOME=$(pwd)
export PROJECT_ROOT=$(pwd)
export CONFIG_DIR=$(pwd)/.monozukuri
export LIB_DIR=$(pwd)/lib

# Run canary
bash lib/run/canary.sh
```

## Configuration

### Canary Config

Create `.monozukuri/canary-config.json` with your benchmark features:

```json
{
  "features": [
    {
      "id": "feat-001-node-api-endpoint",
      "stack": "backend",
      "repo": "monozukuri-canaries",
      "path": "backend/node-api-endpoint"
    }
  ],
  "stacks": ["backend", "frontend", "mobile", "infra", "data"]
}
```

## Automated Weekly Runs

The GitHub Actions workflow `.github/workflows/canary.yml` runs automatically every Sunday at 00:00 UTC and commits results to `docs/canary-history.md`.

### Manual Trigger

1. Go to GitHub Actions tab
2. Select "Weekly Canary Benchmark" workflow
3. Click "Run workflow"

## Metrics

### Headline Metric

- **CI-pass-rate-on-first-PR**: Percentage of features that pass CI on the first PR attempt
- Stratified by stack (backend, frontend, mobile, infra, data)

### Diagnostic Metrics

- **tokens_avg**: Average tokens per feature
- **completion\_%**: Feature completion rate
- **phase_retry_rate**: Average phase retries
- **ci_flake_rate**: CI flake rate

## Badge

The README badge links to `docs/canary-history.md` and shows the current L5 status.

## Troubleshooting

### No canary history found

- Run a canary benchmark to generate the first data point
- The history file is created automatically on first run

### Corrupted schema

- Check `docs/canary-history.md` has 6 columns
- Verify date format is YYYY-MM-DD
- Ensure numeric fields are valid numbers
