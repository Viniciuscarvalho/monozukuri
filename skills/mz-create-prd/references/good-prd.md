# PRD — feat-042: Add --verbose flag to status command

> **Token budget for this document: 600 words max.**

**Feature:** feat-042
**Source:** github-issue-88
**Date:** 2026-04-27
**Status:** draft

---

## Context

**Stack:** bash · shell · bats
**Test framework:** bats
**Entry points relevant to this feature:** `cmd/status.sh`, `lib/cli/output.sh`

### Project conventions to follow

- All output goes through `lib/cli/output.sh` helpers — never raw `echo`
- Feature flags use `MONOZUKURI_*` env var pattern

### Original request

> Running `monozukuri status` shows one-line summaries. I need a way to see full run logs without digging into .monozukuri/ by hand.

---

## Problem

`monozukuri status` shows per-feature summary lines but has no way to surface detailed run logs. Diagnosing failures currently requires manually opening `.monozukuri/runs/<id>/` directories, which is slow and error-prone.

---

## Solution

Add a `--verbose` flag to `monozukuri status` that appends the last 20 log lines from each run's `code.md` and `tests.md` artifacts below the existing summary line. No new files, no new dependencies.

---

## Success criteria

| Criterion                                                                 | How verified                                                           |
| ------------------------------------------------------------------------- | ---------------------------------------------------------------------- |
| `monozukuri status --verbose` prints log lines under each feature summary | `monozukuri status --verbose \| grep -A5 "feat-001"` shows log content |
| `monozukuri status` (without flag) is unchanged                           | output diff against baseline fixture                                   |

---

## Functional requirements

### FR-001: --verbose flag prints run logs [MUST]

**Behavior:** When `--verbose` is passed, append up to 20 lines from `code.md` and `tests.md` (if present) under each feature's summary line, indented with two spaces.

**Acceptance criteria:**

1. Given a completed run for feat-001, when `monozukuri status --verbose` is run, then lines from `code.md` appear indented under the feat-001 summary.
2. Given a run with no `tests.md`, when `--verbose` is run, then only `code.md` lines appear (no error).

**Negative cases:**

1. Given `--verbose` without any completed runs, then only the existing "no runs" message appears.

### FR-002: Flag is ignored if status has no runs [SHOULD]

**Behavior:** `--verbose` on an empty backlog exits 0 with the normal "nothing to show" message.

---

## Hard constraints

- No new runtime dependencies
- Must not change the non-verbose output format — existing tests must pass unchanged

---

## Out of scope

- Paging/scrolling long output
- Filtering by feature or date
- Color highlighting of log lines

---

**Handoff to TechSpec:** FR-001 and FR-002 must be addressed by a component, file change, and test in the TechSpec.
