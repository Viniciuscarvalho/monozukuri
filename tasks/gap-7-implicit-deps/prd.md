# PRD: Implicit-Dep Detection + Ingestion Validator (Gap 7)

## Problem Statement

Monozukuri currently has two critical gaps that lead to silent failures and merge conflicts:

1. **Dangling dependency references**: When a feature references a non-existent feature via `depends_on`, the topo-sort silently corrupts, leading to unpredictable execution order
2. **Parallel merge conflicts**: Two features touching the same files can run simultaneously and produce merge conflicts when both try to merge to the base branch

These issues violate the "fail loud" principle and create trust erosion in autonomous multi-feature runs.

## Goals

1. Validate all `depends_on` references at backlog ingestion time before any feature execution
2. Detect file-set overlap between in-flight features to prevent merge conflicts
3. Provide learning signals for prediction accuracy (files_likely_touched vs files_actually_touched)
4. Enable data-driven improvements to overlap detection heuristics

## Non-Goals

- Function-level overlap detection (file-level granularity is sufficient initially)
- Automatic feature re-ordering based on overlap (manual `depends_on` is the user's intent)
- Real-time conflict resolution (deferral is sufficient)

## Success Metrics

- 100% of invalid `depends_on` references caught at ingestion (before any feature runs)
- 0 merge conflicts due to parallel file modifications in multi-feature runs
- Overlap prediction accuracy tracked per run (false positives rate < 20%)

## User Stories

### Story 1: Catching bad dependency references early

**As a** backlog author  
**I want** immediate feedback on invalid `depends_on` references  
**So that** I don't waste time debugging topo-sort issues after features start running

**Acceptance:**

- Running `monozukuri run` with a backlog containing `depends_on: feat-999` (non-existent) fails immediately
- Error message shows file and line number: `error: features.md:47: depends_on references unknown feature "feat-999"`
- Error lists all known feature IDs for easy correction

### Story 2: Preventing merge conflicts automatically

**As a** parallel run user  
**I want** features touching the same files to be automatically serialized  
**So that** I don't get merge conflicts when both features complete

**Acceptance:**

- Feature A (modifying `auth.ts`) starts first
- Feature B (also modifying `auth.ts`) is queued but deferred with message: `feat-B deferred: overlaps feat-A on src/auth.ts`
- Feature B starts automatically once Feature A completes
- Both features merge successfully without conflicts

### Story 3: Learning from prediction mismatches

**As a** monozukuri maintainer  
**I want** to see when `files_likely_touched` predictions were wrong  
**So that** I can improve the overlap detection heuristic

**Acceptance:**

- After each feature's Code phase, actual files touched are captured via `git diff --name-only`
- Run report shows: `8 features serialized; 6 overlaps confirmed; 2 false positives`
- Data enables future refinement of overlap prediction

## Technical Constraints

1. Must integrate with existing `lib/run/ingest.sh` pipeline (before topo-sort)
2. Must integrate with existing `lib/run/pipeline.sh` phase executor (pre-Code gate)
3. File paths are project-relative (not absolute)
4. Worktree state stored in `.monozukuri/worktrees/<feat-id>/state.json`
5. No new dependencies beyond existing Node.js and git

## Scope

### In Scope

- Explicit dependency validation at ingestion
- File-overlap detection before Code phase starts
- Post-code actual files capture
- Overlap statistics in run report
- Integration with existing state management

### Out of Scope

- Automatic conflict resolution
- Smart merge strategies
- Cross-feature diff analysis
- Overlap detection for tests or docs (Code phase only)

## Open Questions

None — all design decisions resolved in ADR-015.

## References

- ADR-015: Per-Phase Routing, Implicit-Dep Detection & Run Review Surface
- ADR-013: Failure Handling & Feature State Machine
- Gap 6: Run review surface (provides report.json for overlap stats)
