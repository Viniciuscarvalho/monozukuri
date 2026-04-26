# Product Requirements Document (PRD)

**Project Name:** Monozukuri
**Feature:** Gap 5 - Measurable Learning + Canary Suite + MRP
**Version:** 1.0
**Date:** 2026-04-26
**Status:** Draft

---

## Prompt Context

### Original User Prompt

> Implement Gap 5 of the Monozukuri project — "Measurable learning + canary suite + MRP". This delivers L5 measurability infrastructure with canary benchmarks, headline metrics, diagnostic tracking, badge display, and automated weekly metric publication.

### Enriched Prompt

> Create the L5 measurability infrastructure for Monozukuri that establishes a fixed benchmark for measuring orchestration effectiveness across multiple tech stacks. The system must track CI-pass-rate-on-first-PR as the headline metric, record diagnostic metrics, publish results weekly via automated CI, and display a badge in README linking to historical data.

### CLAUDE.md Constraints Applied

- Follow conventional commit format (feat, fix, refactor, docs, test, chore, perf, ci)
- Use existing codebase patterns for module structure (cmd/, lib/, test/unit/)
- Maintain backward compatibility with existing Monozukuri commands

### Codebase Context

| Attribute             | Value                                                                      |
| --------------------- | -------------------------------------------------------------------------- |
| Stack                 | Shell scripting                                                            |
| Language(s)           | Bash                                                                       |
| Framework(s)          | bats-core (testing)                                                        |
| Package Manager       | N/A (shell scripts)                                                        |
| Test Framework        | bats-core                                                                  |
| Relevant Entry Points | orchestrate.sh, cmd/routing.sh, lib/run/routing.sh, lib/memory/learning.sh |

### Environment Manifest

| Tool / MCP Server | Available | Notes                         |
| ----------------- | --------- | ----------------------------- |
| git               | Yes       | Required for CI workflow      |
| GitHub Actions    | Yes       | For weekly canary runs        |
| bats-core         | Yes       | Test framework for validation |
| jq                | Yes       | JSON processing for metrics   |

---

## Executive Summary

**Problem Statement:**
Monozukuri currently lacks a fixed benchmark to measure its effectiveness at orchestrating feature development across different tech stacks. Without a constant benchmark, claims of "better than last run" are unverifiable, and there is no quantifiable way to track improvements or regressions over time.

**Proposed Solution:**
Implement L5 measurability infrastructure consisting of: (1) a canary benchmark setup with CI automation, (2) headline metric tracking (CI-pass-rate-on-first-PR stratified by stack), (3) diagnostic metrics for deeper analysis, (4) a README badge displaying current performance, and (5) automated weekly publication of results to docs/canary-history.md.

**Business Value:**

- Establishes objective, verifiable metrics for Monozukuri's orchestration effectiveness
- Provides transparency to users evaluating the tool
- Creates a feedback loop for continuous improvement
- Enables data-driven decisions about feature prioritization and optimization

**Success Metrics:**
| Metric | Baseline | Target | How to Measure |
|--------|----------|--------|----------------|
| Automated weekly updates | 0 | Weekly commits to canary-history.md | CI workflow execution logs |
| Schema validation | N/A | 100% pass rate | bats test validating canary-history.md format |
| Badge display | No | Yes | README contains badge linking to canary-history.md |
| Metrics command availability | No | Yes | `monozukuri metrics` returns 4-week trailing data |

---

## Project Overview

### Background

Monozukuri is a CLI orchestrator that automates feature development workflows. Gaps 1-4 established the core orchestration capabilities (routing, cost tracking, memory, execution). Gap 5 (L5) adds the measurability layer required to verify and improve Monozukuri's effectiveness.

### Current State

- No quantifiable metrics exist for measuring orchestration success
- No fixed benchmark for comparing runs across time
- No automated testing of Monozukuri's capabilities across different tech stacks
- Users cannot objectively evaluate Monozukuri's performance

### Desired State

- Weekly automated canary runs against a fixed benchmark suite (20 features across 8 stack slices)
- Headline metric (CI-pass-rate-on-first-PR) tracked and published with 4-week trailing average
- Diagnostic metrics (tokens, completion rate, retry rate, flake rate) recorded alongside headline
- README badge displaying current performance with link to historical data
- `monozukuri metrics` command for viewing recent performance trends

### Existing Codebase Patterns

_Patterns detected in the project that the implementation MUST follow:_

- **Naming conventions:** kebab-case for files/dirs, snake_case for bash variables, uppercase for env vars
- **File structure:** cmd/ for user-facing commands, lib/ for logic modules, test/unit/ for bats tests
- **Error handling:** set -euo pipefail at script start, trap ERR for cleanup, explicit exit codes
- **Logging:** source lib/core/logging.sh, use log_info/log_error/log_debug functions
- **Config management:** JSON files in .claude/monozukuri/, XDG_CONFIG_HOME compliance

---

## User Personas

### Primary Persona: Monozukuri Maintainer

| Attribute       | Detail                                                                           |
| --------------- | -------------------------------------------------------------------------------- |
| Role            | Open source maintainer                                                           |
| Technical Level | Expert (shell scripting, CI/CD, metrics)                                         |
| Primary Goal    | Track and improve Monozukuri's orchestration effectiveness over time             |
| Key Pain Point  | No objective way to measure whether changes improve or regress performance       |
| Usage Context   | Weekly review of canary results, investigating metric trends, debugging failures |

### Secondary Persona: Prospective User Evaluating Monozukuri

| Attribute       | Detail                                                                                |
| --------------- | ------------------------------------------------------------------------------------- |
| Role            | Developer or team lead evaluating orchestration tools                                 |
| Technical Level | Intermediate to advanced                                                              |
| Primary Goal    | Assess whether Monozukuri works reliably for their tech stack                         |
| Key Pain Point  | Lack of transparency about real-world performance data                                |
| Usage Context   | Reading README badge, reviewing canary-history.md to see stack-specific success rates |

---

## Functional Requirements

### FR-001: Canary History Template [MUST]

**Description:**
Create `docs/canary-history.md` as an empty template with a schema header defining the columns for recording canary run results.

**Acceptance Criteria (Given/When/Then):**

1. **Given** the Monozukuri repository, **When** Gap 5 is merged, **Then** `docs/canary-history.md` exists with schema header: `date | run_id | headline_% | tokens_avg | completion_% | stack_breakdown_json`
2. **Given** `docs/canary-history.md` exists, **When** a canary run completes, **Then** a new row is appended with pipe-delimited values matching the schema

**Negative Cases:**

1. **Given** `docs/canary-history.md` does not exist, **When** `monozukuri metrics` is run, **Then** it reports "No canary history found" and exits with code 1

**Priority:** MUST
**Traced to Epic:** EPIC-001
**Traced to Stories:** STORY-001

---

### FR-002: Weekly Canary CI Workflow [MUST]

**Description:**
Create `.github/workflows/canary.yml` that triggers a canary run weekly (cron schedule) and on manual dispatch, then commits updated `docs/canary-history.md`.

**Acceptance Criteria (Given/When/Then):**

1. **Given** the repository has `.github/workflows/canary.yml`, **When** the weekly cron triggers, **Then** the workflow runs the canary suite and commits results
2. **Given** a maintainer wants to run canaries on-demand, **When** they trigger `workflow_dispatch`, **Then** the workflow executes immediately
3. **Given** a canary run completes, **When** the workflow commits `docs/canary-history.md`, **Then** the commit message follows format: "chore: update canary metrics (run_id)"

**Negative Cases:**

1. **Given** the canary run fails, **When** the workflow attempts to commit, **Then** it logs the failure but does not commit partial results

**Priority:** MUST
**Traced to Epic:** EPIC-001
**Traced to Stories:** STORY-002

---

### FR-003: Metrics Command [MUST]

**Description:**
Implement `monozukuri metrics` subcommand that reads `docs/canary-history.md` and displays the last 4 weeks of data plus the trailing mean for the headline metric.

**Acceptance Criteria (Given/When/Then):**

1. **Given** `docs/canary-history.md` contains at least 4 weeks of data, **When** a user runs `monozukuri metrics`, **Then** it displays the last 4 rows and the 4-week trailing average for headline\_%
2. **Given** `docs/canary-history.md` contains fewer than 4 weeks, **When** a user runs `monozukuri metrics`, **Then** it displays all available rows and the average of available data
3. **Given** `docs/canary-history.md` does not exist, **When** a user runs `monozukuri metrics`, **Then** it exits with code 1 and message "No canary history found"

**Negative Cases:**

1. **Given** `docs/canary-history.md` is corrupted (invalid schema), **When** `monozukuri metrics` is run, **Then** it exits with code 2 and message "Invalid canary history format"

**Priority:** MUST
**Traced to Epic:** EPIC-002
**Traced to Stories:** STORY-003

---

### FR-004: Headline Metric Calculation [MUST]

**Description:**
Calculate CI-pass-rate-on-first-PR as the percentage of canary features where the first PR attempt has passing CI, stratified by stack slice (backend, frontend, mobile, infra, data).

**Acceptance Criteria (Given/When/Then):**

1. **Given** a canary run completes, **When** metrics are calculated, **Then** headline\_% = (features_with_ci_green_on_first_pr / total_features_attempted) \* 100
2. **Given** a canary run completes, **When** stack breakdown is calculated, **Then** stack_breakdown_json contains per-stack headline percentages as JSON object

**Negative Cases:**

1. **Given** no features were attempted in a canary run, **When** metrics are calculated, **Then** headline\_% is recorded as "N/A"

**Priority:** MUST
**Traced to Epic:** EPIC-002
**Traced to Stories:** STORY-004

---

### FR-005: Diagnostic Metrics Tracking [MUST]

**Description:**
Track four diagnostic metrics alongside the headline metric: tokens_per_feature (average), feature_completion_rate (%), phase_retry_rate (%), ci_flake_rate (%).

**Acceptance Criteria (Given/When/Then):**

1. **Given** a canary run completes, **When** metrics are recorded, **Then** tokens_avg is the mean token count across all features
2. **Given** a canary run completes, **When** metrics are recorded, **Then** completion\_% = (features_fully_completed / total_features_attempted) \* 100
3. **Given** a canary run completes, **When** metrics are recorded, **Then** phase_retry_rate and ci_flake_rate are calculated and stored in stack_breakdown_json

**Negative Cases:**

1. **Given** token data is unavailable for a feature, **When** tokens_avg is calculated, **Then** that feature is excluded from the average

**Priority:** MUST
**Traced to Epic:** EPIC-002
**Traced to Stories:** STORY-005

---

### FR-006: README Badge [MUST]

**Description:**
Add a badge to README.md displaying the 4-week trailing headline metric with a link to `docs/canary-history.md`.

**Acceptance Criteria (Given/When/Then):**

1. **Given** README.md exists, **When** Gap 5 is merged, **Then** it contains a badge with format: "monozukuri L5: NN% (4-wk trailing, 20-canary benchmark)"
2. **Given** the badge is clicked, **When** a user navigates, **Then** it links to `docs/canary-history.md`

**Negative Cases:**

1. **Given** no canary history exists, **When** the badge is rendered, **Then** it displays "N/A" instead of a percentage

**Priority:** MUST
**Traced to Epic:** EPIC-001
**Traced to Stories:** STORY-006

---

### FR-007: Schema Validation Test [MUST]

**Description:**
Create a bats test that validates `docs/canary-history.md` schema (column count, date format, numeric fields) to ensure MRP verification.

**Acceptance Criteria (Given/When/Then):**

1. **Given** `docs/canary-history.md` exists, **When** `bats test/unit/lib_memory_metrics.bats` runs, **Then** it validates schema and passes if format is correct
2. **Given** `docs/canary-history.md` has a malformed row, **When** the test runs, **Then** it fails with a descriptive error message

**Negative Cases:**

1. **Given** `docs/canary-history.md` does not exist, **When** the test runs, **Then** it skips validation with a warning

**Priority:** MUST
**Traced to Epic:** EPIC-002
**Traced to Stories:** STORY-007

---

### FR-008: Canary Run Orchestration [MUST]

**Description:**
Implement `lib/run/canary.sh` that orchestrates a full Monozukuri run against a canary config, tracking metrics and updating `docs/canary-history.md`.

**Acceptance Criteria (Given/When/Then):**

1. **Given** a canary config is provided, **When** `lib/run/canary.sh` is invoked, **Then** it runs all features in the config and records results
2. **Given** a canary run completes, **When** metrics are calculated, **Then** they are appended to `docs/canary-history.md`

**Negative Cases:**

1. **Given** a canary feature fails to complete, **When** the run finishes, **Then** it is marked as incomplete in metrics

**Priority:** MUST
**Traced to Epic:** EPIC-002
**Traced to Stories:** STORY-008

---

## Non-Functional Requirements

### NFR-001: Performance [MUST]

**Requirement:** Canary runs must complete within 2 hours to fit within CI time limits.
**Target:** <120 minutes for 20-feature benchmark suite
**Measurement:** CI workflow execution time
**Validation Command:** Check GitHub Actions run duration

### NFR-002: Schema Stability [MUST]

**Requirement:** The `docs/canary-history.md` schema must remain backward-compatible.
**Constraints:** New columns can be appended, but existing columns cannot be removed or reordered.
**Validation:** Schema validation test in bats

### NFR-003: Compatibility [MUST]

**Backward Compatibility:** The `monozukuri metrics` command is a new addition and does not break existing commands.
**Breaking Changes Allowed:** No
**Migration Path (if breaking):** N/A

### NFR-004: Code Quality [MUST]

**Test Coverage Target:** 80% for new modules (cmd/metrics.sh, lib/memory/metrics.sh, lib/run/canary.sh)
**Lint Rules:** Follow existing shellcheck rules
**Documentation:** Inline comments for complex metric calculations, usage examples in README

---

## Epics and User Stories

### EPIC-001: Canary Infrastructure Setup

**Business Value:** Establishes the foundation for automated weekly benchmarking
**Related Requirements:** FR-001, FR-002, FR-006

#### STORY-001: Create Canary History Template

```
As a Monozukuri maintainer,
I want a standardized schema for recording canary metrics,
So that historical data is consistent and parseable.
```

**Acceptance Criteria:**

1. Given the repository, when I navigate to `docs/canary-history.md`, then it exists with schema header
2. Given the schema header, when I parse it, then it defines 6 columns: date, run*id, headline*%, tokens*avg, completion*%, stack_breakdown_json

**Edge Cases:**

- Empty file (no data rows yet): Expected behavior is schema header only
- First data row added: Should follow pipe-delimited format matching schema

**Priority:** MUST
**Complexity Estimate:** S
**Traced to FR:** FR-001

---

#### STORY-002: Implement Weekly Canary CI Workflow

```
As a Monozukuri maintainer,
I want canary runs to execute automatically every week,
So that I have continuous performance data without manual intervention.
```

**Acceptance Criteria:**

1. Given the repository has `.github/workflows/canary.yml`, when Sunday at 00:00 UTC occurs, then the workflow triggers
2. Given the workflow runs, when it completes successfully, then it commits updated `docs/canary-history.md`

**Edge Cases:**

- Workflow fails mid-run: Should not commit partial results, should log error for investigation
- Manual dispatch trigger: Should execute immediately regardless of schedule

**Priority:** MUST
**Complexity Estimate:** M
**Traced to FR:** FR-002

---

#### STORY-006: Add README Badge

```
As a prospective user,
I want to see Monozukuri's performance at a glance in the README,
So that I can quickly assess whether it meets my reliability requirements.
```

**Acceptance Criteria:**

1. Given README.md, when I view it, then I see a badge showing "monozukuri L5: NN% (4-wk trailing, 20-canary benchmark)"
2. Given the badge, when I click it, then I navigate to `docs/canary-history.md`

**Edge Cases:**

- No canary data yet: Badge should display "N/A" instead of percentage
- Badge link broken: Should be validated in PR review

**Priority:** MUST
**Complexity Estimate:** S
**Traced to FR:** FR-006

---

### EPIC-002: Metrics Calculation and Reporting

**Business Value:** Provides actionable insights into Monozukuri's performance
**Related Requirements:** FR-003, FR-004, FR-005, FR-007, FR-008

#### STORY-003: Implement Metrics Command

```
As a Monozukuri maintainer,
I want to view recent canary performance trends,
So that I can identify regressions or improvements.
```

**Acceptance Criteria:**

1. Given `docs/canary-history.md` contains data, when I run `monozukuri metrics`, then it displays the last 4 weeks and trailing average
2. Given fewer than 4 weeks of data, when I run `monozukuri metrics`, then it displays all available data

**Edge Cases:**

- No canary history file: Should exit with code 1 and helpful error message
- Corrupted schema: Should exit with code 2 and suggest re-running canary

**Priority:** MUST
**Complexity Estimate:** M
**Traced to FR:** FR-003

---

#### STORY-004: Calculate Headline Metric

```
As a Monozukuri maintainer,
I want to know the percentage of features that pass CI on the first PR attempt,
So that I can measure orchestration quality.
```

**Acceptance Criteria:**

1. Given a canary run completes, when metrics are calculated, then headline\_% = (ci_green_on_first_pr / total_features) \* 100
2. Given stack breakdown is calculated, when I view it, then I see per-stack percentages

**Edge Cases:**

- Zero features attempted: Should record "N/A" instead of division by zero error
- All features pass: Should record 100%

**Priority:** MUST
**Complexity Estimate:** M
**Traced to FR:** FR-004

---

#### STORY-005: Track Diagnostic Metrics

```
As a Monozukuri maintainer,
I want to track tokens, completion rate, retries, and flake rate,
So that I can diagnose the root causes of metric changes.
```

**Acceptance Criteria:**

1. Given a canary run, when I view metrics, then I see tokens*avg, completion*%, phase_retry_rate, ci_flake_rate
2. Given token data is missing for a feature, when tokens_avg is calculated, then that feature is excluded

**Edge Cases:**

- Missing data fields: Should handle gracefully without crashing
- Outlier token counts: Should be included (no filtering)

**Priority:** MUST
**Complexity Estimate:** L
**Traced to FR:** FR-005

---

#### STORY-007: Validate Canary History Schema

```
As a Monozukuri maintainer,
I want automated tests to verify the canary history format,
So that I can catch schema violations before they break the metrics command.
```

**Acceptance Criteria:**

1. Given `docs/canary-history.md` exists, when the bats test runs, then it validates column count, date format, and numeric fields
2. Given a malformed row, when the test runs, then it fails with a descriptive error

**Edge Cases:**

- File does not exist: Test should skip with warning
- Extra whitespace in fields: Should be tolerated

**Priority:** MUST
**Complexity Estimate:** M
**Traced to FR:** FR-007

---

#### STORY-008: Orchestrate Canary Runs

```
As a Monozukuri maintainer,
I want a module that runs all canary features and records results,
So that I can execute the benchmark suite reliably.
```

**Acceptance Criteria:**

1. Given a canary config, when `lib/run/canary.sh` is invoked, then it runs all features and tracks metrics
2. Given a run completes, when metrics are calculated, then they are appended to `docs/canary-history.md`

**Edge Cases:**

- Feature fails mid-run: Should mark as incomplete and continue
- All features fail: Should still record metrics (0% headline)

**Priority:** MUST
**Complexity Estimate:** L
**Traced to FR:** FR-008

---

## User Flows

### Flow 1: Weekly Automated Canary Run (Happy Path)

```
[Sunday 00:00 UTC: GitHub Actions cron triggers]
    ↓
[CI: Checkout repository]
    ↓
[CI: Run lib/run/canary.sh with canary config]
    ↓
[CI: Calculate metrics (headline, diagnostics)]
    ↓
[CI: Append results to docs/canary-history.md]
    ↓
[CI: Commit updated canary-history.md]
    ↓
[CI: Push commit to main → Done]
```

**Entry Point:** GitHub Actions cron schedule
**Exit Point:** Committed metrics in `docs/canary-history.md`
**Error States:** If canary run fails, CI logs error but does not commit

---

### Flow 2: Maintainer Views Metrics (Happy Path)

```
[Maintainer: Run `monozukuri metrics`]
    ↓
[cmd/metrics.sh: Source lib/memory/metrics.sh]
    ↓
[lib/memory/metrics.sh: Read docs/canary-history.md]
    ↓
[lib/memory/metrics.sh: Parse last 4 weeks of data]
    ↓
[lib/memory/metrics.sh: Calculate 4-week trailing average]
    ↓
[cmd/metrics.sh: Display formatted results → Done]
```

**Entry Point:** `monozukuri metrics` command
**Exit Point:** Terminal output showing recent metrics and trailing average
**Error States:** If `docs/canary-history.md` missing, exit with code 1 and error message

---

## Assumptions and Dependencies

### Assumptions

1. The `monozukuri-canaries` repository will be created manually by the maintainer (out of scope for this PR)
2. Canary features are representative of real-world usage across different tech stacks
3. Weekly canary runs are sufficient frequency for L5 measurability (not daily or hourly)
4. GitHub Actions has sufficient runner minutes for weekly 2-hour canary runs

### Dependencies

| Dependency               | Type     | Required Before            | Risk if Unavailable               |
| ------------------------ | -------- | -------------------------- | --------------------------------- |
| monozukuri-canaries repo | External | Phase 2 (first canary run) | Cannot execute canary suite       |
| GitHub Actions           | External | Phase 1 (CI setup)         | No automated runs                 |
| bats-core                | Internal | Phase 1 (tests)            | Cannot validate schema            |
| jq                       | Internal | Phase 1 (metrics parsing)  | Cannot parse JSON stack breakdown |

---

## Constraints

### Hard Constraints (Non-Negotiable)

- Schema in `docs/canary-history.md` must not change after initial version (backward compatibility)
- Canary runs must complete within 2 hours to fit CI limits
- The `lib/memory/metrics.sh` module must be separate from `lib/memory/learning.sh` (no modification to learning.sh)
- Metrics stored only in `docs/canary-history.md`, not in the learning store

### Soft Constraints (Preferred)

- Badge should use GitHub's shields.io or similar for consistent styling
- Metrics command output should be human-readable (formatted table, not raw CSV)
- CI workflow should be reusable for manual testing (workflow_dispatch)

---

## Out of Scope

| Feature / Capability                                           | Reason                                                                         | Future Phase?       |
| -------------------------------------------------------------- | ------------------------------------------------------------------------------ | ------------------- |
| Trend arrows on badge (↑↓)                                     | Complexity for v1; requires comparing to previous week                         | Yes (Phase 2 / L5+) |
| Cross-run learning (using past results to improve future runs) | Requires ML or heuristic engine beyond L5 scope                                | Yes (L6+)           |
| Comparison with other orchestration tools                      | Focus is internal benchmarking, not competitive analysis                       | No                  |
| Dashboards or visualizations beyond badge                      | Adds complexity; `docs/canary-history.md` provides raw data for external tools | Maybe (Phase 2)     |
| External monitoring integrations (Datadog, Grafana)            | Out of scope for CLI-first tool                                                | No                  |
| Per-stack canary configs                                       | v1 uses single unified config; stack stratification is in metrics only         | Maybe (Phase 2)     |

---

## Release Planning

### Phase 1: MVP

**Scope:** FR-001, FR-002, FR-003, FR-006
**Success Gate:** Weekly CI workflow runs successfully, badge displays in README, metrics command returns 4-week data

### Phase 2: Full Diagnostic Suite

**Scope:** FR-004, FR-005, FR-007, FR-008
**Success Gate:** All diagnostic metrics tracked, schema validation test passes, canary orchestration logic complete

---

## Risks and Mitigations

| Risk                                                       | Impact (H/M/L) | Probability (H/M/L) | Mitigation                                                  | Owner      |
| ---------------------------------------------------------- | -------------- | ------------------- | ----------------------------------------------------------- | ---------- |
| Canary runs exceed 2-hour CI limit                         | H              | M                   | Optimize canary feature set; run in parallel where possible | Maintainer |
| Schema changes break backward compat                       | H              | L                   | Lock schema in v1; only allow appending new columns         | Maintainer |
| GitHub Actions runner availability issues                  | M              | L                   | Add retry logic in CI workflow; monitor GitHub status       | Maintainer |
| Incomplete canary repo (missing stack slices)              | M              | M                   | Clearly document canary repo requirements; provide examples | Maintainer |
| Metrics command performance degradation with large history | L              | M                   | Optimize parsing to only read last N lines, not full file   | Maintainer |

---

## Traceability Matrix

| FR ID  | Business Goal                 | Epic     | Stories   | NFR Dependencies | Test Scenarios                 |
| ------ | ----------------------------- | -------- | --------- | ---------------- | ------------------------------ |
| FR-001 | Standardized metrics storage  | EPIC-001 | STORY-001 | NFR-002          | Schema validation test         |
| FR-002 | Automated weekly benchmarking | EPIC-001 | STORY-002 | NFR-001          | CI workflow execution test     |
| FR-003 | Metrics visibility            | EPIC-002 | STORY-003 | NFR-003, NFR-004 | Metrics command unit tests     |
| FR-004 | Headline metric tracking      | EPIC-002 | STORY-004 | NFR-002          | Calculation accuracy tests     |
| FR-005 | Diagnostic insights           | EPIC-002 | STORY-005 | NFR-002          | Diagnostic metrics tests       |
| FR-006 | User transparency             | EPIC-001 | STORY-006 | NFR-003          | Manual badge link verification |
| FR-007 | Schema verification           | EPIC-002 | STORY-007 | NFR-002, NFR-004 | Bats test suite                |
| FR-008 | Canary execution              | EPIC-002 | STORY-008 | NFR-001, NFR-004 | Integration tests              |

---

## PRD Validation Checklist

- [x] All FRs have Given/When/Then acceptance criteria
- [x] All FRs have at least one negative/edge case
- [x] Every Story traces back to at least one FR
- [x] Codebase patterns section reflects actual project conventions
- [x] No FR contradicts existing CLAUDE.md constraints
- [x] Out of scope items are explicit and justified
- [x] NFRs have measurable targets with validation methods
- [x] Backward compatibility impact is assessed
- [x] Dependencies are verified as available in the environment

---

## Glossary

| Term              | Definition                                                               |
| ----------------- | ------------------------------------------------------------------------ |
| L5                | Maturity level 5 in Monozukuri's capability model (measurable results)   |
| MRP               | Measurable Results Published — automated weekly update of canary metrics |
| Headline Metric   | CI-pass-rate-on-first-PR (primary performance indicator)                 |
| Canary Suite      | Fixed set of 20 benchmark features across 8 tech stack slices            |
| Stack Slice       | Technology category (backend, frontend, mobile, infra, data, etc.)       |
| Trailing Average  | Mean of headline metric over last 4 weeks                                |
| workflow_dispatch | GitHub Actions trigger for manual workflow execution                     |

---

**Document End**
