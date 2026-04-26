# Task 7.0: Create Weekly Canary CI Workflow (M)

**Status:** pending
**Complexity:** M _(S = <1h, M = 1-3h, L = 3h+)_
**Depends on:** Task 6
**Implements:** FR-002, STORY-002

---

<critical>
Read the prd.md and techspec.md files in this folder BEFORE starting any work.
If you do not read these files, your task will be invalidated.
</critical>

<task_context>
<domain>ci/cd</domain>
<type>automation</type>
<scope>Automate weekly canary runs and commit results</scope>
<complexity>medium</complexity>
<dependencies>lib/run/canary.sh (Task 6)</dependencies>
</task_context>

---

## Objective

Create `.github/workflows/canary.yml` to automate weekly canary benchmark runs (Sunday 00:00 UTC) and manual on-demand execution, then commit updated `docs/canary-history.md` with conventional commit message.

**Expected Outcome:** A GitHub Actions workflow exists that runs weekly, executes canary suite, and commits results automatically.

---

## Pre-Execution: Files to Read

_Read and understand these files before writing any code. This provides the context needed for accurate implementation._

| File                            | Why                             | What to Look For                                         |
| ------------------------------- | ------------------------------- | -------------------------------------------------------- |
| `prd.md`                        | Understand FR-002 requirements  | Workflow triggers, commit message format, error handling |
| `techspec.md`                   | See Component 2: CanaryWorkflow | Workflow structure, steps, environment setup             |
| `.github/workflows/` (existing) | Pattern reference for workflows | Existing workflow patterns, setup steps                  |
| `lib/run/canary.sh`             | Script to invoke                | Entry point, environment variables needed                |

---

## Subtasks

### 7.1: Create .github/workflows directory if needed

**Action:** Ensure .github/workflows/ directory exists
**File(s):** `.github/workflows/` (directory)
**Details:**
Check if `.github/workflows/` exists. Create with `mkdir -p` if missing.

**Acceptance:**

- [ ] `.github/workflows/` directory exists
- [ ] Directory has proper permissions

---

### 7.2: Create canary.yml workflow file

**Action:** Create workflow with triggers and job definition
**File(s):** `.github/workflows/canary.yml`
**Details:**
Create workflow with:

- Name: "Weekly Canary Benchmark"
- Triggers:
  - `schedule`: cron `'0 0 * * 0'` (Sunday 00:00 UTC)
  - `workflow_dispatch`: manual trigger
- Job runs on: `ubuntu-latest`

**Acceptance:**

- [ ] File exists at `.github/workflows/canary.yml`
- [ ] Has descriptive name
- [ ] Has schedule trigger (weekly Sunday)
- [ ] Has workflow_dispatch for manual runs
- [ ] Runs on ubuntu-latest

---

### 7.3: Add repository checkout step

**Action:** Add step to checkout repository code
**File(s):** `.github/workflows/canary.yml`
**Details:**
Use `actions/checkout@v3` to checkout code with full history.

**Acceptance:**

- [ ] Checkout step exists
- [ ] Uses actions/checkout@v3
- [ ] Checks out full git history (for commits)

---

### 7.4: Add environment setup steps

**Action:** Add steps to setup Node.js and install dependencies
**File(s):** `.github/workflows/canary.yml`
**Details:**

- Setup Node.js 18 (using actions/setup-node@v3)
- Install system dependencies: jq
- Verify installations

**Acceptance:**

- [ ] Node.js setup step exists
- [ ] jq installation step exists
- [ ] Node version is 18 (LTS)

---

### 7.5: Add canary run execution step

**Action:** Add step to execute canary benchmark
**File(s):** `.github/workflows/canary.yml`
**Details:**

- Step ID: `canary_run`
- Run: `bash lib/run/canary.sh`
- Environment variables:
  - `MONOZUKURI_HOME`: `${{ github.workspace }}`
  - `PROJECT_ROOT`: `${{ github.workspace }}`
  - `CONFIG_DIR`: `${{ github.workspace }}/.monozukuri`
  - `STATE_DIR`: `${{ github.workspace }}/.monozukuri/state`
  - `LIB_DIR`: `${{ github.workspace }}/lib`

**Acceptance:**

- [ ] Canary run step exists with ID
- [ ] Invokes lib/run/canary.sh
- [ ] Sets required environment variables
- [ ] Step can be referenced by ID in later steps

---

### 7.6: Add commit and push step

**Action:** Add step to commit updated canary-history.md
**File(s):** `.github/workflows/canary.yml`
**Details:**

- Conditional: `if: steps.canary_run.outcome == 'success'`
- Configure git user: `github-actions[bot]`
- Stage: `docs/canary-history.md`
- Extract run_id from last row for commit message
- Commit message: `"chore: update canary metrics (run_id)"`
- Push to main branch

**Acceptance:**

- [ ] Commit step is conditional on canary_run success
- [ ] Git user configured as github-actions[bot]
- [ ] Stages only docs/canary-history.md
- [ ] Commit message follows conventional commit format
- [ ] Includes run_id in commit message
- [ ] Pushes to main branch

---

### 7.7: Add error handling

**Action:** Ensure workflow logs errors but doesn't commit on failure
**File(s):** `.github/workflows/canary.yml`
**Details:**

- Commit step only runs if canary_run succeeds
- Workflow logs error if canary_run fails
- No partial results committed

**Acceptance:**

- [ ] Commit step conditional on success
- [ ] Workflow doesn't fail silently
- [ ] Error logs available for debugging

---

## Implementation Constraints

_Rules from CLAUDE.md and project conventions that MUST be followed during this task._

- Use conventional commit format: `chore: update canary metrics (run_id)`
- Commit only if canary run succeeds (no partial results)
- Use GitHub Actions best practices (pinned action versions)
- Set proper permissions for workflow (contents: write for commits)
- Use github-actions[bot] as commit author

---

## Edge Cases to Handle

| Scenario                        | Expected Behavior                       | Subtask |
| ------------------------------- | --------------------------------------- | ------- |
| Canary run fails mid-execution  | Workflow logs error, no commit          | 7.7     |
| Git push fails (merge conflict) | Workflow fails, maintainer notified     | 7.6     |
| jq not available                | Installation step fails, workflow stops | 7.4     |
| Manual dispatch trigger         | Workflow executes immediately           | 7.2     |

---

## Files to Create / Modify

### New Files

| File Path                      | Purpose                             |
| ------------------------------ | ----------------------------------- |
| `.github/workflows/canary.yml` | Weekly automated canary CI workflow |

### Modified Files

_None_

---

## Test Requirements

### Tests to Write

_Integration testing in Task 8_

For this task, verify workflow syntax and test manually.

### Test Scenarios

**Happy Path:**

1. Given workflow file exists, when weekly schedule triggers, then canary runs and commits results

**Error Cases:**

1. Given canary run fails, when workflow executes, then no commit made
2. Given invalid workflow syntax, when workflow validates, then error shown

**Edge Cases:**

1. Given manual workflow_dispatch, when triggered, then runs immediately

---

## Success Criteria

_All criteria must pass for this task to be marked as completed._

- [ ] All subtask acceptance criteria are met
- [ ] File `.github/workflows/canary.yml` exists
- [ ] Workflow syntax is valid (GitHub validates it)
- [ ] Workflow has both schedule and manual triggers
- [ ] Environment variables properly set for canary.sh
- [ ] Commit step is conditional on success
- [ ] Conventional commit format used
- [ ] Workflow follows GitHub Actions best practices

---

## Validation Commands

_Run these commands after implementation to verify the task is complete._

```bash
# Verify file exists
test -f .github/workflows/canary.yml && echo "✓ Workflow file exists" || echo "✗ File missing"

# Validate YAML syntax
if command -v yamllint &>/dev/null; then
  yamllint .github/workflows/canary.yml
else
  echo "yamllint not installed; GitHub will validate on push"
fi

# Validate workflow syntax (requires GitHub CLI)
if command -v gh &>/dev/null; then
  gh workflow view "Weekly Canary Benchmark"
else
  echo "gh CLI not installed; manual verification needed"
fi

# Check workflow has required triggers
grep -q 'schedule:' .github/workflows/canary.yml && echo "✓ Schedule trigger found" || echo "✗ Missing schedule"
grep -q 'workflow_dispatch:' .github/workflows/canary.yml && echo "✓ Manual trigger found" || echo "✗ Missing dispatch"

# Check conventional commit format in workflow
grep -q 'chore: update canary metrics' .github/workflows/canary.yml && echo "✓ Conventional commit format" || echo "✗ Wrong format"
```

**Expected output:** File exists, YAML valid, triggers present, commit format correct.

---

## Rollback Plan

_If this task introduces breaking changes, how to undo:_

```bash
# Remove workflow file
rm -f .github/workflows/canary.yml

# Remove .github/workflows/ if empty
rmdir .github/workflows/ 2>/dev/null || true
rmdir .github/ 2>/dev/null || true
```

---

## Notes

- This workflow will not run until after the PR is merged to main
- First run will occur on the next Sunday at 00:00 UTC after merge
- Manual testing via workflow_dispatch requires push to main first
- Workflow requires repository permissions: `contents: write` (for commits)
- GitHub Actions runner minutes are free for public repos (per PRD assumptions)
- The workflow commits directly to main (no PR); ensure this is acceptable
- Consider adding notifications (Slack, email) for failures in future enhancement
