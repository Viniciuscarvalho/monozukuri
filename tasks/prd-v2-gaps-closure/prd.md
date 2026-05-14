# PRD — v2-gaps-closure: Close Six "Room to Grow" Gaps

**Feature:** v2-gaps-closure
**Source:** https://github.com/Viniciuscarvalho/monozukuri/issues/215
**Date:** 2026-05-14
**Status:** Draft

---

## Context

**Stack:** Bash 4+ · Node 18+ · Ink/React · Homebrew / npm
**Test framework:** Bats (`test/unit/`, `test/integration/`, `test/conformance/`, `test/properties/`)
**Entry points relevant to this feature:** `lib/core/cost.sh`, `lib/cli/emit.sh`, `lib/agent/adapter-codex.sh`, `lib/agent/adapter-gemini.sh`, `lib/run/implicit-dep.sh`, `lib/agent/contract.sh`

### Project conventions to follow

- `set -euo pipefail` in every script; `${VAR:-default}` for optionals
- Use `monozukuri_emit`, never raw `echo` JSON; use `monozukuri_error` for errors
- Named exit constants from `lib/core/exit-codes.sh`, never bare numbers
- New modules go under `lib/`; adapters under `lib/agent/`; tests under `test/unit/`
- `shellcheck --severity=error` clean; `shfmt -w -i 2` formatted

### Original request

> Close the six v1.0 "room to grow" gaps to define the v2.0 scope: real cost parsing, tier-2 fixture re-recording, portable skill injection, Codex/Gemini session continuity, TechSpec-driven conflict prediction, and opt-in telemetry.

---

## Problem

Six precision gaps survive v1.0 ship: the $50/night SLO gate operates on estimated tokens (not billed values), Codex/Gemini conformance fixtures are Claude-seeded so Layer 7 detects no real drift, `mz-*` skills are Claude Code only, tier-2 adapters lose session context on interruption, implicit file-level dependency collisions are undetected until merge time, and telemetry events never leave the local machine.

---

## Solution

Six targeted additive modules close each gap: a `cost_from_usage()` parser reads real Claude billing data; a `make rerecord-fixtures AGENT=` workflow captures real tier-2 outputs; a `skill_inject()` module enables prompt-prefixing for any adapter declaring `skill_injection: true`; Codex/Gemini adapters gain conversation-ID wiring; a `dep_predict_conflicts()` pre-pipeline gate parses TechSpec file lists and reorders features; and a `telemetry_flush()` module batches local events to an opt-in HTTPS endpoint.

---

## Success criteria

| Criterion                                            | How verified                                                                               |
| ---------------------------------------------------- | ------------------------------------------------------------------------------------------ |
| Real billed tokens recorded for Claude runs          | `cost_record` output JSON contains `usage.input_tokens` from stream-json                   |
| Layer 7 passes with real Codex/Gemini fixtures       | `make conformance` green after `make rerecord-fixtures AGENT=codex`                        |
| Codex runs receive skill-prefixed prompts            | `MOCK_CLAUDE_MODE=normal make test-properties` — skill content present in adapter call log |
| Codex adapter resumes interrupted session            | `adapter-codex.sh` emits `session.resume_missed` on lost session ID                        |
| Conflict predictor reorders colliding features       | Unit test: two overlapping TechSpec fixtures → sorted queue + collision JSON               |
| Telemetry consent gate blocks forwarding when absent | Unit test: no-consent path → zero events flushed                                           |

---

## Functional requirements

### FR-001: Real cost parser [MUST]

**Behavior:** Parse `usage.input_tokens`, `usage.output_tokens`, `usage.cache_read_input_tokens` from Claude stream-json artifacts into `cost_record`. Fall back to existing estimate when field absent.

**Acceptance criteria:**

1. Given a Claude stream-json with `usage` present, when `cost_record` runs, then the recorded cost uses real token counts.
2. Given a tier-2 stream-json without `usage`, when `cost_record` runs, then it falls back to character-count estimate without error.

**Negative cases:**

1. Given malformed `usage` JSON, when parsing, then emit `monozukuri_error` and fall back to estimate; do not abort the run.

### FR-002: Tier-2 fixture re-recording [MUST]

**Behavior:** `make rerecord-fixtures AGENT=codex` (and `AGENT=gemini`) invokes the real CLI, captures output to `.qa/fixtures/recordings/<agent>/`, and writes `captured_with: "real"` in `metadata.json`.

**Acceptance criteria:**

1. Given Codex CLI installed and authenticated, when `make rerecord-fixtures AGENT=codex` runs, then `.qa/fixtures/recordings/codex/*.{md,stream-json}` reflect real responses and `metadata.json` has `captured_with: "real"`.
2. Given fixtures re-recorded from real Codex, when `make conformance` runs, then Layer 7 passes without seeded-data bypass.

**Negative cases:**

1. Given Codex CLI absent, when `make rerecord-fixtures AGENT=codex` runs, then fail with `EXIT_DEPENDENCY_MISSING` and clear error.

### FR-003: Portable skill injection [MUST]

**Behavior:** New `lib/agent/skill-inject.sh` exports `skill_inject(skill_dir, prompt)`. All adapters that declare `skill_injection: true` in `agent_capabilities` call it before each phase prompt. Adapters returning `false` skip it (no-op).

**Acceptance criteria:**

1. Given `adapter-codex.sh` declares `skill_injection: true`, when a phase runs, then the phase prompt is prefixed with the relevant SKILL.md content.
2. Given `adapter-aider.sh` declares `skill_injection: false`, when a phase runs, then the prompt is unchanged.

**Negative cases:**

1. Given SKILL.md missing for a phase, when `skill_inject` is called, then warn and return the original prompt unmodified.

### FR-004: Codex/Gemini session continuity [MUST]

**Behavior:** `adapter-codex.sh` accepts `--conversation-id` from the pipeline's session state and passes it to the Codex CLI. On interruption, emits `session.resume_missed`. Flip `session_continuity: true` in capabilities. Gemini adapter follows same pattern with its provider flag.

**Acceptance criteria:**

1. Given a persisted Codex session ID, when the adapter runs the next phase, then `--conversation-id <id>` appears in the CLI invocation.
2. Given session ID lost mid-run, when adapter detects absence, then emits `session.resume_missed` event.

**Negative cases:**

1. Given Codex version without `--conversation-id` support, when `monozukuri doctor` runs, then surfaces a warning and sets `session_continuity: false` for that installation.

### FR-005: TechSpec conflict predictor [MUST]

**Behavior:** `lib/run/implicit-dep.sh` gains `dep_predict_conflicts(techspec_dir)` which reads `## File Layout` / `## Files Touched` sections from all queued TechSpecs, cross-references file lists, and outputs a sorted feature queue + JSON collision map. Runs as a pre-pipeline gate before Phase A of any feature batch.

**Acceptance criteria:**

1. Given two features whose TechSpecs list the same file, when the gate runs, then the collision JSON names both features and the colliding file.
2. Given unambiguous ordering (feature A depends on B's output file), when the gate runs, then the queue is reordered automatically and no pause is raised.
3. Given unavoidable collision, when the gate runs, then emits `dep.conflict` and exits `EXIT_CYCLE_GATE`.

**Negative cases:**

1. Given a TechSpec with no file-list section, when parsing, then treat that feature as having no file claims and proceed.

### FR-006: Opt-in telemetry backend [MUST]

**Behavior:** New `lib/cli/telemetry.sh` exposes `telemetry_flush(events_jsonl, endpoint)` and `telemetry_consent_check()`. `monozukuri init`/`setup` adds a one-time consent prompt. When consented, `monozukuri_emit` events are buffered under `.monozukuri/telemetry/` and batch-flushed to the configured HTTPS endpoint at run exit.

**Acceptance criteria:**

1. Given consent absent, when any event is emitted, then `.monozukuri/telemetry/` is not written and no network call is made.
2. Given consent present, when a run completes, then buffered events are flushed as a JSONL POST and the buffer is cleared.

**Negative cases:**

1. Given network unreachable during flush, when `telemetry_flush` is called, then log the failure locally and leave the buffer intact for the next run; do not abort the run.

---

## Non-functional requirements

| ID      | Type            | Requirement                                                               | Validation                                                                 |
| ------- | --------------- | ------------------------------------------------------------------------- | -------------------------------------------------------------------------- |
| NFR-001 | Backward compat | All six changes are additive; no existing config, fixture, or test breaks | `make test` green on unchanged projects                                    |
| NFR-002 | Cost ceiling    | v1.0 $50/night SLO gate unaffected by real-cost parser                    | Layer 6 passes with real-value path active                                 |
| NFR-003 | CI cost         | No new workflow calls live agent CLI                                      | `.github/workflows/` contains no new `claude`/`codex`/`gemini` invocations |

---

## Hard constraints

- No new npm or shell runtime dependencies without explicit justification in the implementing ADR.
- No writes to `.claude/` (Claude Code territory) or outside the active worktree during a phase.
- Telemetry consent gate must be strict opt-in — no data sent unless the user explicitly consented via `monozukuri init`/`setup`.
- Fixture re-recording target (`make rerecord-fixtures`) must remain LOCAL ONLY — must not be added to any CI workflow.

---

## Out of scope

- Bidirectional Linear/GitHub sync (write-back on phase completion).
- ACP integration, daemon model, JSON-RPC SDK.
- Kiro and Aider session continuity (Codex and Gemini only for v2.0).
- Public telemetry dashboard UI (ships in v2.1).
- Automatic conflict resolution beyond queue reordering (merge/rebase automation).
- Three-tier semantic memory beyond the current learning store.
