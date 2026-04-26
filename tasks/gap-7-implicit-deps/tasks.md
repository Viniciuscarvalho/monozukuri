# Implementation Tasks: Gap 7 - Implicit-Dep Detection + Ingestion Validator

## Task 1: Create lib/run/dep-check.sh

**Objective:** Implement explicit dependency validation for backlog ingestion

**Steps:**

1. Create `lib/run/dep-check.sh` with header comments
2. Implement `dep_check_explicit()` function:
   - Accept backlog file path as argument
   - Extract all feature IDs from backlog (regex: `feat-[0-9]+`)
   - Parse `depends_on:` fields (handle both markdown and JSON formats)
   - Validate each reference exists in feature ID set
   - Emit errors with file:line on stderr for bad refs
3. Handle edge cases: self-reference, empty array, malformed input
4. Export function for use by ingest.sh

**Success Criteria:**

- Function returns 0 for valid backlog, 1 for invalid
- Error messages include file path and line number
- Lists known feature IDs in error message for easy correction

**Estimated Time:** 1 hour

---

## Task 2: Create test/unit/lib_run_dep_check.bats

**Objective:** Comprehensive unit tests for dependency validation

**Steps:**

1. Create test file with bats structure
2. Implement setup/teardown with temp directories
3. Test cases:
   - Valid backlog with correct depends_on refs → passes
   - Invalid reference to non-existent feature → fails with line number
   - Self-reference (feat-A depends on feat-A) → fails
   - Empty depends_on array → passes
   - Multiple invalid refs → reports all errors
   - Malformed backlog → graceful failure
4. Verify error message format matches spec

**Success Criteria:**

- All test cases pass
- Test coverage includes edge cases
- Error messages validated for correct format

**Estimated Time:** 1 hour

---

## Task 3: Create lib/run/implicit-dep.sh

**Objective:** Implement file-overlap detection and actual files capture

**Steps:**

1. Create `lib/run/implicit-dep.sh` with header comments
2. Implement `overlap_check()` function:
   - Accept feat_id and files_array (JSON) as arguments
   - Scan `.monozukuri/worktrees/*/state.json` for in_progress features
   - Read files_likely_touched from each worktree state
   - Compute file-set intersection
   - Return space-separated list of overlapping feature IDs
3. Implement `capture_actual_files()` function:
   - Accept feat_id and base_sha as arguments
   - Run `git diff --name-only base_sha HEAD` in worktree
   - Parse output into JSON array
   - Write to state.json as files_actually_touched
   - Compare with files_likely_touched and compute stats
4. Handle edge cases: missing state.json, git failures, empty file lists

**Success Criteria:**

- overlap_check returns empty string when no overlaps
- overlap_check returns feat IDs when files overlap
- capture_actual_files populates state.json correctly
- Prediction stats calculated accurately

**Estimated Time:** 2 hours

---

## Task 4: Create test/unit/lib_run_implicit_dep.bats

**Objective:** Comprehensive unit tests for overlap detection

**Steps:**

1. Create test file with bats structure
2. Implement setup with mock worktrees and state.json files
3. Test cases for overlap_check:
   - No in-flight features → empty result
   - Overlapping files → returns feature IDs
   - Disjoint files → empty result
   - Multiple overlapping features → returns all IDs
   - Missing state.json → treats as no files
4. Test cases for capture_actual_files:
   - Successful git diff → populates state.json
   - Comparison with files_likely_touched → correct stats
   - Git failure → logs error but doesn't crash
5. Verify JSON output format

**Success Criteria:**

- All test cases pass
- Mock worktrees properly simulated
- State.json mutations verified

**Estimated Time:** 1.5 hours

---

## Task 5: Integrate dep_check_explicit into lib/run/ingest.sh

**Objective:** Add explicit dependency validation to ingestion pipeline

**Steps:**

1. Read existing `lib/run/ingest.sh` to understand integration point
2. Source `lib/run/dep-check.sh` at top of ingest.sh
3. Add validation call after backlog parse, before topo-sort:
   ```bash
   if ! dep_check_explicit "$backlog_file"; then
     err "Dependency validation failed — fix backlog and re-run"
     exit 1
   fi
   ```
4. Ensure error messages propagate to user
5. Test with valid and invalid backlogs

**Success Criteria:**

- Invalid backlog fails ingestion immediately
- Error message displayed to user with file:line
- Valid backlog continues normally
- No regression in existing ingestion logic

**Estimated Time:** 30 minutes

---

## Task 6: Integrate overlap_check into lib/run/pipeline.sh (pre-Code gate)

**Objective:** Add file-overlap detection before Code phase starts

**Steps:**

1. Read existing `lib/run/pipeline.sh` to find Code phase entry point
2. Source `lib/run/implicit-dep.sh` at top of pipeline.sh
3. Before Code phase invocation:
   - Read files_likely_touched from feature's state.json
   - Call overlap_check with feat_id and files array
   - If overlaps found:
     - Update feature status to "deferred" in manifest
     - Log deferral reason with overlapping feature IDs
     - Return 0 (skip Code phase for now)
   - If no overlaps: proceed normally
4. Test with two features touching same file

**Success Criteria:**

- Overlapping feature gets deferred with clear message
- Non-overlapping features proceed immediately
- Deferred feature can be retried later (scheduler handles this)
- Manifest updated with deferral reason

**Estimated Time:** 1 hour

---

## Task 7: Integrate capture_actual_files into lib/run/pipeline.sh (post-Code)

**Objective:** Capture actual files touched after Code phase completes

**Steps:**

1. Find Code phase completion handler in pipeline.sh
2. After successful Code phase commit:
   - Get base_sha from worktree state or manifest
   - Call capture_actual_files with feat_id and base_sha
   - Verify state.json updated with files_actually_touched
3. Add error handling for git diff failures (log but don't block)
4. Test with various commit patterns

**Success Criteria:**

- files_actually_touched populated after every Code phase
- Comparison stats calculated correctly
- Git failures logged but don't crash pipeline
- State.json contains overlap_stats object

**Estimated Time:** 45 minutes

---

## Task 8: Run full integration test

**Objective:** Validate end-to-end workflow with overlap detection

**Steps:**

1. Create test backlog with:
   - feat-A: modifies src/auth.ts
   - feat-B: also modifies src/auth.ts
   - feat-C: modifies src/profile.ts (no overlap)
2. Run `monozukuri run` on test backlog
3. Verify:
   - feat-A and feat-C start immediately (parallel)
   - feat-B deferred with message about overlap with feat-A
   - After feat-A completes, feat-B starts automatically
   - All features complete without merge conflicts
4. Check run report for overlap_stats
5. Verify state.json files have correct overlap data

**Success Criteria:**

- No merge conflicts occur
- Overlap detection works as designed
- Deferred features resume correctly
- Report contains accurate statistics

**Estimated Time:** 1 hour

---

## Task 9: Update documentation

**Objective:** Document new functionality in README and ADR

**Steps:**

1. Update main README.md with:
   - Dependency validation behavior
   - File-overlap detection explanation
   - Deferral mechanism description
2. Verify ADR-015 is referenced correctly
3. Add troubleshooting section for common issues:
   - How to fix invalid depends_on refs
   - Understanding deferral messages
   - Interpreting overlap statistics

**Success Criteria:**

- README clearly explains Gap 7 features
- Examples provided for common scenarios
- Links to ADR-015 for detailed design

**Estimated Time:** 30 minutes

---

## Summary

**Total Estimated Time:** 9.25 hours

**Dependency Order:**

1. Tasks 1-2 (dep-check module + tests) can run in parallel
2. Tasks 3-4 (implicit-dep module + tests) can run in parallel
3. Task 5 depends on Task 1
4. Tasks 6-7 depend on Task 3
5. Task 8 depends on Tasks 5, 6, 7
6. Task 9 can run anytime after Task 8

**Critical Path:** Task 1 → Task 5, Task 3 → Task 6 → Task 7 → Task 8 → Task 9
