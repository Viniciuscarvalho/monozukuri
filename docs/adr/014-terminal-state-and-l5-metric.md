# ADR-014: Terminal State (CI-Green PR) & L5 Measurability

- **Status**: Accepted
- **Date**: 2026-04-26
- **Deciders**: Vinicius Carvalho
- **Supersedes**: —
- **Related**: ADR-008 (Orchestrator Economy), ADR-009 (Local Models), ADR-013 (Failure Handling)

---

## Context

The one-line vision used "merged pull requests" as the terminal state; the flow
diagram ends at "PR opened." These are different products. Owning the merge step
requires auto-merge policy, branch-protection bypass, post-review-comment
iteration, and conflict resolution if main moved — a materially larger surface
with different accountability.

Separately, the L5 claim — "measurably better every week" — had no concrete
metric, no benchmark, and no falsifiability. Without a fixed benchmark, "run N+1
better than run N" is unverifiable because the features, repo state, and agent
behaviour all vary between runs.

Three grilling decisions (Q1, Q4, Q5 from the 2026-04-26 session) are resolved
here. The deferral of PR review iteration (Q3) is also recorded.

---

## Decision

### 1. Terminal state

The box's job ends at **PR opened with passing CI**. Specifically:

- A pull request is open against the project's base branch.
- All required CI checks on that PR are green.
- The human review-and-merge step is explicitly outside the box's scope.

"Merged pull requests" is removed from all copy (README, vision, one-line tagline).
The honest framing: _"turns your feature backlog into CI-green pull requests."_

### 2. CI interaction loop

After the PR phase opens a pull request:

1. **Poll** GitHub/GitLab checks API until terminal status (success, failure, or
   cancelled). Default timeout: 60 minutes (configurable via
   `config.yaml: run.ci_timeout_minutes`).
2. **Classify red results:**
   - If the failed check is in the project's known-flaky list
     (`config.yaml: ci.flaky_checks[]`), re-run the failed job. Cap: 2 re-runs,
     no agent involvement.
   - Otherwise, treat as a real failure.
3. **One agent reprompt:** fetch CI logs, reprompt the agent on the same worktree
   with full logs, push a fixup commit, re-wait once.
4. **Still red:** `feature.failed(reason: ci.red, pr_url: ..., ci_logs_path: ...)`.
   The box logs the PR link so the human can investigate.

The one-reprompt cap matches ADR-012 (schema validation) and ADR-013 (phase
failure). Every reprompt budget in the box is bounded at one.

The CI loop adds a new sub-step to Phase 4 of the flow diagram:
`PR opened → CI WAIT → Cycle Gate`.

### 3. Canary benchmark

L5 measurability rests on a **fixed benchmark**, not real-world runs:

- Repository: `monozukuri-canaries` (separate public repo).
- Contents: ~20 frozen feature specifications spanning the stack matrix — Node API
  endpoint, React component, Python script, SQL migration, Go handler, Swift view,
  Terraform module, dbt model, etc.
- Invariant: the canary features are never changed once published. The benchmark is
  the constant; the box is the variable.
- Schedule: weekly `monozukuri run` against the canary repo, triggered by CI in
  the main monozukuri repo. Results committed to `docs/canary-history.md`.

The `monozukuri-canaries` repo and `docs/canary-history.md` are Gap 5 deliverables.
This ADR declares the architecture; both artifacts ship when Gap 5 opens.

Each canary repo has its own CI workflow so that "CI-green" means something
non-trivial: tests, lint, typecheck, and at least one integration assertion.

### 4. Headline metric: CI-pass-rate-on-first-PR

$$\text{CI-pass-rate-on-first-PR} = \frac{\text{canary features with CI-green on first PR attempt}}{\text{all canary features attempted in the window}}$$

- **Denominator**: all features attempted, not only PRs opened. Features that
  fail before the PR phase count as failures in the denominator.
- **Window**: 4-week trailing mean. Comparing single runs is too noisy.
- **Badge text**: `monozukuri L5: 71% (4-wk trailing, 20-canary benchmark)`
  linking to `docs/canary-history.md`.
- **Stratification**: always published per stack slice (backend, frontend, mobile,
  infra, data). Never blended into a single number that hides a 30%-mobile /
  95%-backend split.

### 5. Diagnostic metrics

Always shown alongside the headline; never promoted to the headline:

| Metric                    | What it measures                                                |
| ------------------------- | --------------------------------------------------------------- |
| `tokens_per_feature`      | Cost efficiency — should trend down                             |
| `feature_completion_rate` | % of backlog features that reach CI-green PR                    |
| `phase_retry_rate`        | % of phase invocations requiring a reprompt                     |
| `ci_flake_rate`           | % of CI re-runs that were classified as flakes vs real failures |

### 6. PR review iteration — deferred to L5+

Responding to human review comments (parsing review feedback, reprompting the
agent on the same worktree, pushing fixup commits) is explicitly parked outside
this quarter. Rationale:

- It requires ~2–3 weeks of additional scope (GitHub event handling, comment
  threading, review-intent classification).
- Building it before L5 learning data exists means building the wrong reprompt
  strategy.
- The honest copy ("CI-green PRs for your review") is already a strong product.

This is named **L5+: human-in-the-loop review iteration** and tracked separately.

---

## Consequences

### Positive

- "PR opened with passing CI" is a clean, auditable terminal state with no
  ambiguity about what the box owns.
- CI-pass-rate-on-first-PR is the hardest metric to fake — green CI on a canary
  with real assertions requires actually correct code.
- The canary benchmark doubles as a regression suite for monozukuri itself: PRs
  against the main repo can gate on canary pass rate.
- Stratified reporting surfaces stack-level weaknesses that a blended score would
  hide.

### Negative / Trade-offs

- The canary suite requires upfront investment (~1 week to write 20 well-scoped
  features with real CI workflows).
- Maintaining canary features as the ecosystem evolves (new Node LTS, new Swift
  version) is ongoing work.
- The 4-week trailing window means L5 improvement claims lag reality by up to a
  month.

### Neutral

- Human review and merge remain the human's responsibility; no change to project
  branch protection or merge policy.
- The capability ladder (ADR-016) references this metric as the L5 verification
  artifact.

---

## Implementation Notes

- CI polling uses `gh pr checks <pr-number> --watch` or the Checks API endpoint
  `GET /repos/{owner}/{repo}/commits/{ref}/check-runs`.
- The flaky-check list (`ci.flaky_checks[]`) is a plain string array of check
  names (e.g., `["e2e-browser-tests", "integration-slow"]`). Populated by the user
  in `config.yaml`.
- `docs/canary-history.md` schema (one row per weekly run):
  `date | run_id | headline_% | tokens_avg | completion_% | stack_breakdown_json`
- The canary CI job lives in `.github/workflows/canary.yml` in the
  `monozukuri-canaries` repo, triggered by `workflow_dispatch` and a weekly
  `schedule` cron.
