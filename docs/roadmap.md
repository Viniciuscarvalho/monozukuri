# Monozukuri Roadmap — Gap List (Revised 2026-04-26)

Eight gaps, ~13 weeks of focused work to L5. All gaps ship within the L5 window.
Estimates reflect architectural decisions resolved in a 14-question design session
on 2026-04-26; see the referenced ADRs for full context.

---

## Dependency order

```
Gap 1 ──► Gap 2 ──► (feeds) Gap 5
      └──► Gap 3 ──► Gap 4
      └──► Gap 7

Gap 6 and Gap 8 are parallelisable alongside Gap 5 (late quarter).

CI-loop scope (new) is part of Gap 2's executor refactor.
```

Gap 1 is the dependency root for Gaps 2, 3, 4, and 5. Do not start those until
phase artifact schemas are stable.

---

## Gaps

### Gap 1 — Phase artifact schemas

**Effort**: 1 week  
**ADR**: [ADR-012](adr/012-adapter-contract-and-schemas.md)  
**Capability unlock**: L3+ stable (partial)

JSON Schema files in `schemas/` for PRD, TechSpec, Tasks, and Code-commit-summary.
Schema-in-prompt (cached system block) + one humanized-error reprompt on validation
failure. TechSpec schema gains required `files_likely_touched: string[]`.

No slack — critical path for Gaps 2, 3, 4, and 5.

---

### Gap 2 — Stratified failure handling, idempotent resumption & rate-limit policy

**Effort**: 2 weeks (expanded from 1 wk; resumption and rate-limit handling folded
in)  
**ADR**: [ADR-013](adr/013-failure-handling-resumption-rate-limits.md)  
**Capability unlock**: L3+ stable

Four deliverables in one executor refactor:

1. **Adapter error envelope** — structured `{class, code, message, retryable_after?}`.
2. **Policy table** — transient → retry; phase → 1 reprompt; fatal → abort; unknown
   → treat as phase.
3. **Idempotent resumption** — run-manifest + per-worktree state; atomic writes;
   `monozukuri run --resume` with manifest-vs-disk reconciliation.
4. **Rate-limit threshold ladder** — sleep ≤10 min; defer ≤60 min; pause-clean
   otherwise. Cross-agent failover opt-in only.

Also includes **CI poll + reprompt loop** (~0.75 wk of new scope from ADR-014
terminal-state decision): poll checks after PR open; classify flake; one agent
reprompt on red CI; pause-clean on timeout.

---

### Gap 3 — Adapter contract + Claude Code reference adapter + Aider

**Effort**: 3.5–4 weeks (expanded from 2 wk; hybrid schema-contract raises
per-adapter build cost)  
**ADR**: [ADR-012](adr/012-adapter-contract-and-schemas.md), [ADR-015](adr/015-routing-implicit-deps-review-surface.md)  
**Capability unlock**: L4 (Claude Code reference), L4+ (Aider GA)  
**Schedule risk**: Aider adapter is the only labelled risk in the 13-week plan

Three deliverables:

1. **Adapter contract spec** — `docs/adapter-contract.md` documenting the error
   envelope (ADR-013), schema-in-prompt requirement (ADR-012), and routing config
   interface (ADR-015). Published as `v1.0.0`.
2. **Claude Code reference adapter** — existing Claude Code integration refactored
   to fully satisfy the published contract and pass the conformance suite.
3. **Aider adapter (stretch)** — second production adapter. Clears the conformance
   suite. Ships as alpha at L4; promoted to GA at L4+ once canary results
   accumulate.

---

### Gap 4 — Per-phase routing & threshold-gated `routing suggest`

**Effort**: 1 week  
**ADR**: [ADR-015](adr/015-routing-implicit-deps-review-surface.md)  
**Capability unlock**: L4  
**Depends on**: Gap 3 (needs ≥2 adapters to make routing meaningful)

Two deliverables:

1. **`routing.yaml`** — per-project, per-phase adapter selection.
   User-level defaults overridden by project-level config.
2. **`routing suggest`** — ships in Gap 4 but is data-gated: refuses to recommend
   until ≥4 canary runs per (adapter, phase) pair exist. Formula:
   `0.6 × ci_pass_rate + 0.4 × (1 - cost_percentile)`. Documented; overridable.

---

### Gap 5 — Measurable learning + canary benchmark + Multi-Run Protocol (MRP)

**Effort**: 3 weeks (expanded from 2 wk; canary suite is an explicit deliverable)  
**ADR**: [ADR-014](adr/014-terminal-state-and-l5-metric.md)  
**Capability unlock**: L5  
**Depends on**: Gap 1 (schemas), Gap 3 (multiple adapters for meaningful data)

Three deliverables:

1. **`monozukuri-canaries` repo** — ~20 frozen features spanning the stack matrix
   (Node, React, Python, SQL, Go, Swift, Terraform, dbt, etc.). Each has a CI
   workflow that runs real assertions.
2. **Weekly canary run** — scheduled `monozukuri run` against the canary repo;
   results committed to `docs/canary-history.md`.
3. **MRP plumbing** — 4-week trailing metric computation; badge generation;
   per-stack stratification; `docs/canary-history.md` schema.

Headline metric: CI-pass-rate-on-first-PR. Diagnostics: tokens-per-feature,
feature-completion-rate, phase-retry-rate, ci-flake-rate.

---

### Gap 6 — Run review surface (Ink TUI live + static HTML export)

**Effort**: 1 week  
**ADR**: [ADR-015](adr/015-routing-implicit-deps-review-surface.md)  
**Capability unlock**: trust surface (no ladder level gated on this alone)  
**Parallelisable**: alongside Gap 5 late in the quarter

Two deliverables:

1. **Live dashboard** — the Ink TUI already exists (Plan A). No change needed
   unless the run-manifest schema from Gap 2 requires adapter work.
2. **`monozukuri review`** — static HTML+JS+JSON bundle at
   `runs/<run-id>/review/index.html`. Commands: `export` (write) and `open`
   (write + open). Fully offline; no server required. Preserves "no hosted runtime"
   copy.

---

### Gap 7 — Implicit-dep detection & explicit-dep validation

**Effort**: ~3 days  
**ADR**: [ADR-015](adr/015-routing-implicit-deps-review-surface.md)  
**Capability unlock**: L4 (correctness)  
**Depends on**: Gap 1 (TechSpec schema needs `files_likely_touched` field)

Three deliverables:

1. **Explicit-dep validation** — at backlog ingestion, `depends_on` references
   validated against the full feature list. Bad refs fail loud at file:line.
2. **Pre-Code gate** — checks in-flight worktrees for `files_likely_touched`
   overlap; serialises conflicting features until the earlier one reaches cycle-gate.
3. **Post-Code verification** — records `files_actually_touched` from
   `git diff --name-only` as a learning and routing signal.

---

### Gap 8 — Pricing & calibration

**Effort**: 1 week  
**Capability unlock**: L5 (cost honesty)  
**Parallelisable**: alongside Gap 5 late in the quarter

Versioned pricing table (`config/pricing.yaml`) with per-(agent, model) token
costs. Per-(agent, model, phase) calibration coefficients updated from canary run
data. Real-time cost tracking in the run report. `monozukuri calibrate` subcommand
prints guidance from the last N runs.

---

## Summary

| Gap                                        | Effort     | Ladder level     | Risk                        |
| ------------------------------------------ | ---------- | ---------------- | --------------------------- |
| 1 — Schemas                                | 1 wk       | L3+ (foundation) | None (clear scope)          |
| 2 — Failure + resumption + rate-limit      | 2 wk       | L3+              | None                        |
| 3 — Adapter contract + Claude Code + Aider | 3.5–4 wk   | L4 / L4+         | **Aider adapter (stretch)** |
| 4 — Routing                                | 1 wk       | L4               | None                        |
| 5 — Learning + canary + MRP                | 3 wk       | L5               | Canary suite quality        |
| 6 — Review surface                         | 1 wk       | Trust surface    | None                        |
| 7 — Implicit deps                          | 0.5 wk     | L4 correctness   | None                        |
| 8 — Pricing/calibration                    | 1 wk       | L5 cost honesty  | None                        |
| **Total**                                  | **~13 wk** | **L5**           | Aider only                  |

_Full milestone timeline: [`docs/capability-ladder.md`](capability-ladder.md)._
