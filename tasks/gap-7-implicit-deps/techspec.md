# Technical Specification: Implicit-Dep Detection + Ingestion Validator

## Overview

This spec implements two interlocked safety mechanisms from ADR-015 Gap 7:

1. **Explicit-dep validation** at ingestion (catches bad `depends_on` refs)
2. **Implicit-dep detection** via file-overlap analysis (prevents merge conflicts)

Both mechanisms integrate into the existing orchestrator pipeline with minimal disruption.

## Architecture

### Component Diagram

```
┌─────────────────────────────────────────────────────────────┐
│ lib/run/ingest.sh (backlog ingestion)                       │
│   ├─ Parse features.md → JSON                               │
│   ├─ NEW: dep_check_explicit(backlog_file) ──────┐          │
│   └─ Topo-sort by depends_on                     │          │
└───────────────────────────────────────────────────┼──────────┘
                                                    │
                                                    ▼
                                        ┌─────────────────────┐
                                        │ lib/run/dep-check.sh│
                                        │ • validates refs    │
                                        │ • fails w/ file:line│
                                        └─────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ lib/run/pipeline.sh (phase executor)                        │
│   ├─ Pre-Code gate: overlap_check(feat, files) ──┐          │
│   ├─ Code phase execution                        │          │
│   └─ Post-Code: capture actual files ────────────┼──────┐   │
└───────────────────────────────────────────────────┼──────┼───┘
                                                    │      │
                                                    ▼      ▼
                                        ┌─────────────────────┐
                                        │ lib/run/implicit-   │
                                        │      dep.sh         │
                                        │ • overlap_check()   │
                                        │ • capture_actual()  │
                                        └─────────────────────┘
```

### Data Flow

**Ingestion phase:**

```
features.md → parse → extract all feat IDs → validate each depends_on → fail or proceed
```

**Pre-Code gate:**

```
feat-012 ready → read files_likely_touched from state.json
              → scan all in_progress worktrees
              → find overlap → mark deferred OR proceed
```

**Post-Code verification:**

```
Code phase done → git diff --name-only base..HEAD
                → store as files_actually_touched
                → compare with files_likely_touched
                → log delta to run report
```

## Implementation Details

### 1. lib/run/dep-check.sh

**Public API:**

```bash
dep_check_explicit BACKLOG_FILE
# Returns: 0 if all depends_on refs valid, 1 otherwise
# Output: error messages with file:line on stderr
```

**Algorithm:**

1. Read backlog file (markdown or JSON)
2. Extract all feature IDs using grep/awk pattern matching
3. For each feature with `depends_on:` field:
   - Extract referenced feature IDs
   - Check if each exists in the full feature set
   - If not found: emit `error: <file>:<line>: depends_on references unknown feature "<id>"`
4. Exit with non-zero status if any bad references found

**Edge cases:**

- Empty depends_on array → valid, no-op
- Self-reference (feat-A depends on feat-A) → error
- Circular deps (feat-A → feat-B → feat-A) → not detected here (topo-sort handles it)
- Malformed backlog → fail gracefully with parse error

### 2. lib/run/implicit-dep.sh

**Public API:**

```bash
overlap_check FEAT_ID FILES_ARRAY
# Returns: space-separated list of overlapping feature IDs (empty if none)

capture_actual_files FEAT_ID BASE_SHA
# Stores files_actually_touched in state.json
# Returns: 0 on success
```

**overlap_check algorithm:**

1. Parse FILES_ARRAY (JSON array from TechSpec's files_likely_touched)
2. Scan `.monozukuri/worktrees/*/state.json` for all in_progress features (exclude FEAT_ID)
3. For each in-flight feature:
   - Read its files_likely_touched from state.json
   - Compute intersection with FILES_ARRAY
   - If non-empty: add to overlap list
4. Return overlap list (space-separated feat IDs)

**capture_actual_files algorithm:**

1. Run `git diff --name-only ${BASE_SHA} HEAD` in worktree
2. Parse output into JSON array
3. Write to `.monozukuri/worktrees/${FEAT_ID}/state.json` as `files_actually_touched`
4. Compare with `files_likely_touched`:
   - Count matches (confirmed predictions)
   - Count misses (false positives)
   - Store deltas for learning signal

### 3. Integration Points

**lib/run/ingest.sh modification:**

```bash
# After backlog parse, before topo-sort
if ! dep_check_explicit "$BACKLOG_FILE"; then
  err "Dependency validation failed — fix backlog and re-run"
  exit 1
fi
```

**lib/run/pipeline.sh modification (pre-Code gate):**

```bash
# Before invoking Code phase adapter
local files_likely_touched
files_likely_touched=$(json_read_path "$STATE_JSON" "files_likely_touched")

local overlaps
overlaps=$(overlap_check "$FEAT_ID" "$files_likely_touched")

if [ -n "$overlaps" ]; then
  info "Deferring $FEAT_ID: overlaps with $overlaps"
  json_set_entry "$MANIFEST" "$FEAT_ID" status "deferred" overlaps "$overlaps"
  return 0  # Skip Code phase, will retry later
fi
```

**lib/run/pipeline.sh modification (post-Code):**

```bash
# After Code phase commits successfully
capture_actual_files "$FEAT_ID" "$BASE_SHA"
```

## State Schema

**Worktree state.json additions:**

```json
{
  "feat_id": "feat-012",
  "status": "in_progress",
  "files_likely_touched": ["src/auth/service.ts", "src/auth/types.ts"],
  "files_actually_touched": [
    "src/auth/service.ts",
    "src/auth/types.ts",
    "src/auth/index.ts" // TechSpec didn't predict this
  ],
  "overlap_stats": {
    "predicted": 2,
    "actual": 3,
    "confirmed": 2,
    "false_positives": 0,
    "false_negatives": 1
  }
}
```

**Run manifest.json additions:**

```json
{
  "features": {
    "feat-012": {
      "status": "deferred",
      "deferred_reason": "file_overlap",
      "overlaps_with": ["feat-008"]
    }
  }
}
```

**Run report.json additions:**

```json
{
  "overlap_stats": {
    "serialised_count": 8,
    "confirmed_overlaps": 6,
    "false_positives": 2,
    "false_negative_rate": 0.12
  }
}
```

## Error Handling

| Error Scenario                 | Behavior                                              |
| ------------------------------ | ----------------------------------------------------- |
| Bad depends_on reference       | Fail loud at ingestion with file:line error           |
| Circular dependency            | Let topo-sort detect and fail (not this module's job) |
| Missing state.json             | Treat as no files_likely_touched (empty array)        |
| Malformed files_likely_touched | Fail safe: treat as empty array, log warning          |
| Git diff failure               | Log error but don't block feature completion          |
| Overlap check timeout          | After 5s, proceed (fail open, not fail closed)        |

## Testing Strategy

**Unit tests (bats):**

- `test/unit/lib_run_dep_check.bats`
  - Valid backlog with correct depends_on → passes
  - Invalid reference → fails with file:line
  - Self-reference → fails
  - Empty depends_on → passes
  - Malformed backlog → fails gracefully

- `test/unit/lib_run_implicit_dep.bats`
  - No in-flight features → no overlap
  - Overlapping files → returns feature IDs
  - Disjoint files → no overlap
  - capture_actual_files → populates state.json
  - Prediction accuracy calculation

**Integration test:**

- Two features touching same file run in parallel
- Second feature gets deferred
- First feature completes
- Second feature auto-resumes and completes
- No merge conflicts occur

## Performance Considerations

- Overlap check scans O(N) worktrees where N = in-flight features (typically < 10)
- File comparison is O(M × K) where M = files in this feature, K = files in other feature (typically < 50 each)
- Total overhead: < 100ms for typical backlog sizes
- No network calls, all local file I/O

## Rollout Plan

1. Implement lib/run/dep-check.sh with tests
2. Implement lib/run/implicit-dep.sh with tests
3. Integrate dep_check_explicit into ingest.sh
4. Integrate overlap_check into pipeline.sh (pre-Code gate)
5. Integrate capture_actual_files into pipeline.sh (post-Code)
6. Add overlap_stats to report generation (Gap 6)
7. Validate with multi-feature test run
8. Document in main README

## Files Likely Touched

- `lib/run/dep-check.sh` (new)
- `lib/run/implicit-dep.sh` (new)
- `lib/run/ingest.sh` (modification)
- `lib/run/pipeline.sh` (modifications)
- `test/unit/lib_run_dep_check.bats` (new)
- `test/unit/lib_run_implicit_dep.bats` (new)
- `docs/adr/015-routing-implicit-deps-review-surface.md` (reference)
