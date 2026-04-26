# Tasks: Gap 5 - Measurable Learning + Canary Suite + MRP

**Feature:** Gap 5 - L5 Measurability Infrastructure
**Total Tasks:** 8
**Estimated Effort:** ~10 hours
**Status:** pending

---

## Task Overview

| #   | Task                                | Complexity | Depends On | Status  |
| --- | ----------------------------------- | ---------- | ---------- | ------- |
| 1   | Create Canary History Template      | S          | None       | pending |
| 2   | Implement Metrics Module            | M          | Task 1     | pending |
| 3   | Implement Metrics Command           | S          | Task 2     | pending |
| 4   | Add README Badge                    | S          | Task 1     | pending |
| 5   | Schema Validation Tests             | M          | Task 2     | pending |
| 6   | Implement Canary Orchestrator       | L          | Tasks 2, 5 | pending |
| 7   | Create Weekly Canary CI Workflow    | M          | Task 6     | pending |
| 8   | Integration Testing & Documentation | M          | Task 7     | pending |

---

## Phase Breakdown

### Phase 1: Foundation

- **Task 1:** Create Canary History Template (S, no deps)
- **Task 2:** Implement Metrics Module (M, depends on Task 1)

### Phase 2: User Interface & Documentation

- **Task 3:** Implement Metrics Command (S, depends on Task 2)
- **Task 4:** Add README Badge (S, depends on Task 1)

### Phase 3: Validation

- **Task 5:** Schema Validation Tests (M, depends on Task 2)

### Phase 4: Canary Orchestration

- **Task 6:** Implement Canary Orchestrator (L, depends on Tasks 2, 5)

### Phase 5: CI Automation

- **Task 7:** Create Weekly Canary CI Workflow (M, depends on Task 6)

### Phase 6: Integration & Documentation

- **Task 8:** Integration Testing & Documentation (M, depends on Task 7)

---

## Task Details

### Task 1: Create Canary History Template

**File:** `1_task.md`
**Description:** Create `docs/canary-history.md` with schema header defining the 6-column pipe-delimited format for recording canary run results.
**Delivers:** FR-001, STORY-001

### Task 2: Implement Metrics Module

**File:** `2_task.md`
**Description:** Create `lib/memory/metrics.sh` with core metrics calculation logic including schema validation, trailing average calculation, display formatting, and append function.
**Delivers:** FR-004, FR-005, STORY-004, STORY-005

### Task 3: Implement Metrics Command

**File:** `3_task.md`
**Description:** Create `cmd/metrics.sh` user-facing command that reads canary history and displays recent performance trends.
**Delivers:** FR-003, STORY-003

### Task 4: Add README Badge

**File:** `4_task.md`
**Description:** Update `README.md` with L5 badge linking to `docs/canary-history.md` for performance transparency.
**Delivers:** FR-006, STORY-006

### Task 5: Schema Validation Tests

**File:** `5_task.md`
**Description:** Create `test/unit/lib_memory_metrics.bats` and `test/unit/cmd_metrics.bats` to validate schema format and command behavior.
**Delivers:** FR-007, STORY-007

### Task 6: Implement Canary Orchestrator

**File:** `6_task.md`
**Description:** Create `lib/run/canary.sh` to orchestrate canary benchmark suite execution, track metrics, and update history.
**Delivers:** FR-008, STORY-008

### Task 7: Create Weekly Canary CI Workflow

**File:** `7_task.md`
**Description:** Create `.github/workflows/canary.yml` to automate weekly canary runs and commit results.
**Delivers:** FR-002, STORY-002

### Task 8: Integration Testing & Documentation

**File:** `8_task.md`
**Description:** End-to-end testing, CI verification, and documentation updates including example canary config.
**Delivers:** Final validation and documentation

---

## Critical Path

```
Task 1 (Foundation)
    ↓
Task 2 (Metrics Module)
    ↓
    ├──→ Task 3 (Metrics Command)
    ├──→ Task 4 (README Badge)
    └──→ Task 5 (Validation Tests)
         ↓
    Task 6 (Canary Orchestrator)
         ↓
    Task 7 (CI Workflow)
         ↓
    Task 8 (Integration & Docs)
```

**Parallelization Opportunities:**

- After Task 2: Tasks 3, 4, 5 can run in parallel
- Tasks 3 and 4 are quick wins (15-45 min each)

---

## Success Metrics

- [ ] All 8 tasks completed
- [ ] `monozukuri metrics` command functional
- [ ] Badge visible in README
- [ ] Schema validation tests passing
- [ ] CI workflow configured (ready for first run)
- [ ] Documentation complete

---

## Notes

- Task 6 (Canary Orchestrator) is the most complex and critical component
- Task 7 (CI Workflow) requires GitHub Actions access for testing
- Task 8 should include example `.monozukuri/canary-config.json` for users
