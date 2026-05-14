# ADR-022: TechSpec-Driven Implicit Dependency Conflict Predictor

**Status:** Proposed
**Date:** 2026-05-14
**Related:** ADR-015 (Implicit Dependency Detection), ADR-016 (Thirteen-Week Plan)

---

`lib/run/implicit-dep.sh` already detects file-overlap at Phase C time by scanning in-flight worktrees' `state.json`. That is a runtime check — it fires after Phases A and B have already run for both colliding features, making backtracking expensive. There is no static pre-pipeline analysis that can reorder the feature queue before any phase runs.

**Decision:** `lib/run/implicit-dep.sh` gains `dep_predict_conflicts(techspec_dir)`, a pre-pipeline gate that fires before Phase A of any multi-feature batch. It reads the `## File Layout` / `## Files Touched` section from every TechSpec found under `techspec_dir`, cross-references file lists across all queued features, and produces two outputs: a topologically sorted feature queue (when ordering can resolve the collision) and a JSON collision map at `$STATE_DIR/conflict-map.json`.

**Gate placement:** `pipeline.sh` calls `dep_predict_conflicts` immediately after `dep_check_explicit` at the backlog-load stage, before any feature's Phase A is invoked. Single-feature runs skip the gate (nothing to collide with). If `techspec_dir` is empty or no feature in the queue has a pre-written TechSpec, the gate completes silently with an empty collision map and the queue is unchanged.

**Ordering vs. hard collision:** When the file graph is a DAG (feature A writes a file that feature B reads), the queue is reordered automatically so A runs first — no pause raised, no `dep.conflict` event. When the graph contains a cycle or two features claim the same file with no resolvable ordering, the gate emits `dep.conflict` via `monozukuri_emit` and exits `EXIT_CYCLE_GATE`. The collision map names every colliding pair and the shared file(s), so the operator can manually split or sequence the run.

**TechSpec section parsing:** The same heading aliases accepted by the schema validator are recognised: `## File Layout`, `## Files`, `## Files Touched`, `## Implementation Files`, `files_likely_touched`. If a TechSpec has none of these sections, that feature is treated as claiming no files and proceeds without contributing to the collision map — this matches FR-005's negative case.

**Relationship to existing runtime check:** `overlap_check` in `lib/run/implicit-dep.sh` remains in place. The static predictor eliminates the most expensive class of runtime collisions (those detectable from pre-written TechSpecs) while the runtime check handles files that emerge from actual code changes and were not in the TechSpec's file list. The two mechanisms are complementary.

**Why not extend `dep_check_explicit`?** `dep_check_explicit` validates `depends_on` references (explicit, declared deps) and lives in `lib/run/dep-check.sh`. The conflict predictor infers implicit deps from file overlap — a different data source and different failure mode. Merging them would mix two unrelated validation concerns into one function.
