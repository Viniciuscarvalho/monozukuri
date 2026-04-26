# Task 4.0: Add README Badge (S)

**Status:** pending
**Complexity:** S _(S = <1h, M = 1-3h, L = 3h+)_
**Depends on:** Task 1
**Implements:** FR-006, STORY-006

---

<critical>
Read the prd.md and techspec.md files in this folder BEFORE starting any work.
If you do not read these files, your task will be invalidated.
</critical>

<task_context>
<domain>documentation</domain>
<type>badge</type>
<scope>Add L5 performance badge to README</scope>
<complexity>low</complexity>
<dependencies>docs/canary-history.md (Task 1)</dependencies>
</task_context>

---

## Objective

Update `README.md` with an L5 badge linking to `docs/canary-history.md` for performance transparency. The badge provides at-a-glance visibility of Monozukuri's measurability status.

**Expected Outcome:** README.md contains a badge showing "L5: See History" that links to the canary history file.

---

## Pre-Execution: Files to Read

_Read and understand these files before writing any code. This provides the context needed for accurate implementation._

| File          | Why                            | What to Look For                   |
| ------------- | ------------------------------ | ---------------------------------- |
| `prd.md`      | Understand FR-006 requirements | Badge format, link target          |
| `techspec.md` | See Component 6: ReadmeBadge   | Badge markdown syntax, placement   |
| `README.md`   | Understand current structure   | Where to place badge (top section) |

---

## Subtasks

### 4.1: Add L5 badge to README

**Action:** Add shields.io badge linking to canary history
**File(s):** `README.md`
**Details:**
Add the following badge near the top of README.md (after title, before description):

```markdown
[![L5 Metrics](https://img.shields.io/badge/L5-See%20History-blue)](docs/canary-history.md)
```

Place it with other badges if present, or create a new badge section.

**Acceptance:**

- [ ] Badge added to README.md
- [ ] Badge uses shields.io format
- [ ] Badge text is "L5" with "See History" label
- [ ] Badge links to `docs/canary-history.md`
- [ ] Badge is in top section (visible without scrolling)

---

### 4.2: Verify badge rendering

**Action:** Manual verification of badge appearance
**File(s):** `README.md`
**Details:**

- Preview README locally or on GitHub
- Verify badge renders correctly
- Verify link navigates to canary-history.md

**Acceptance:**

- [ ] Badge renders as blue shield
- [ ] Clicking badge opens docs/canary-history.md
- [ ] Markdown is valid

---

## Implementation Constraints

_Rules from CLAUDE.md and project conventions that MUST be followed during this task._

- Use shields.io badge format (standard for GitHub projects)
- Place badge in visible location (top section of README)
- Do not modify existing badges or documentation structure unnecessarily
- Keep badge text concise ("L5: See History")

---

## Edge Cases to Handle

| Scenario                         | Expected Behavior                                  | Subtask |
| -------------------------------- | -------------------------------------------------- | ------- |
| README has existing badges       | Add L5 badge to badge row                          | 4.1     |
| README has no badges yet         | Create new badge section                           | 4.1     |
| Badge link broken (file missing) | Badge still renders, link 404s (acceptable for v1) | 4.2     |

---

## Files to Create / Modify

### New Files

_None_

### Modified Files

| File Path   | What Changes | Lines/Section to Modify           |
| ----------- | ------------ | --------------------------------- |
| `README.md` | Add L5 badge | Top section, after title/subtitle |

---

## Test Requirements

### Tests to Write

_No automated tests for this task (manual verification only)_

### Test Scenarios

**Happy Path:**

1. Given updated README.md, when viewed on GitHub, then L5 badge is visible and clickable

**Edge Cases:**

1. Given missing canary-history.md, when badge is clicked, then GitHub shows 404 (acceptable until first canary run)

---

## Success Criteria

_All criteria must pass for this task to be marked as completed._

- [ ] All subtask acceptance criteria are met
- [ ] Badge added to README.md
- [ ] Badge renders correctly (preview locally or on GitHub)
- [ ] Badge link points to docs/canary-history.md
- [ ] Markdown is valid

---

## Validation Commands

_Run these commands after implementation to verify the task is complete._

```bash
# Verify README contains badge
grep -q 'L5 Metrics' README.md && echo "✓ Badge added" || echo "✗ Badge missing"

# Verify link target
grep -q 'docs/canary-history.md' README.md && echo "✓ Link correct" || echo "✗ Link incorrect"

# Validate markdown syntax
if command -v mdl &>/dev/null; then
  mdl README.md
else
  echo "mdl not installed; manual markdown verification needed"
fi

# Preview README (if using GitHub CLI)
if command -v gh &>/dev/null; then
  gh repo view --web
fi
```

**Expected output:** Badge present, link correct, markdown valid.

---

## Rollback Plan

_If this task introduces breaking changes, how to undo:_

```bash
# Revert README changes
git checkout README.md
```

---

## Notes

- This is a simple documentation task with no code dependencies
- The badge will show "N/A (pending first run)" in initial state (no canary data yet)
- Future enhancement (Phase 2): dynamic badge showing actual percentage via shields.io endpoint
- Badge placement should be prominent but not disruptive
