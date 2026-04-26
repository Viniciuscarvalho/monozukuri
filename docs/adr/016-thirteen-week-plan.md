# ADR-016: 13-Week Plan & Capability Ladder Commitments

- **Status**: Accepted
- **Date**: 2026-04-26
- **Deciders**: Vinicius Carvalho
- **Supersedes**: —
- **Related**: ADR-012 (Schemas), ADR-013 (Failure Handling), ADR-014 (Terminal State & L5 Metric), ADR-015 (Routing, Implicit Deps, Review)

---

## Context

The original vision document claimed "~10 weeks of focused work" to reach L5. After
grilling 14 architectural decisions on 2026-04-26, the revised estimates are:

| Gap                                                | Original   | Revised      | Why                                                                               |
| -------------------------------------------------- | ---------- | ------------ | --------------------------------------------------------------------------------- |
| Gap 1 — Phase artifact schemas                     | 1 wk       | 1 wk         | Critical-path for Gaps 2, 3, 4, 5. No slack.                                      |
| Gap 2 — Failure handling + resumption + rate-limit | 1 wk       | **2 wk**     | Resumption and rate-limit handling folded in (ADR-013).                           |
| Gap 3 — Adapter contract + Claude Code ref + Aider | 2 wk       | **3.5–4 wk** | Hybrid schema-contract raises the per-adapter build cost; Aider labelled stretch. |
| Gap 4 — Routing (config + threshold-gated suggest) | 1 wk       | 1 wk         | Unchanged; suggest matures from canary data over time.                            |
| Gap 5 — Measurable learning + canary suite + MRP   | 2 wk       | **3 wk**     | Canary suite is an explicit prerequisite (ADR-014).                               |
| Gap 6 — Run review (Ink TUI + static HTML export)  | 1 wk       | 1 wk         | Static-bundle SPA reuses run-manifest (ADR-013).                                  |
| Gap 7 — Implicit-deps + ingestion dep validator    | 0.5 wk     | 0.5 wk       | Schema field + pre-Code gate + post-Code verify (ADR-015).                        |
| Gap 8 — Pricing & calibration                      | 1 wk       | 1 wk         | Agent-aware from day one.                                                         |
| New — CI poll + reprompt loop (ADR-014)            | —          | **0.75 wk**  | Net-new scope from terminal-state decision.                                       |
| **Total**                                          | **~10 wk** | **~13 wk**   |                                                                                   |

Claiming "10 weeks" against a 13-week plan would contradict the product's own
honesty-as-differentiator principle.

---

## Decision

### 1. Public claim

Replace "~10 weeks of focused work. That's a quarter." with:

> **~13 weeks (≈ a quarter) of focused work to L5.** The capability ladder
> publishes shipping dates for L3+, L4, L4+, and L5 separately — progress is
> observable in real time. The only labelled schedule risk is the Aider adapter
> inside Gap 3.

### 2. All gaps ship

No gap is deferred outside the L5 window. Cutting Gap 6 (review surface) or Gap 8
(pricing/calibration) would undermine the credibility artifacts the product depends
on.

### 3. Capability ladder milestones

The README capability ladder gains a "ships at" column. Each milestone is a public
commitment verified by a concrete artifact — not by the maintainer's claim.

| Level                            | Ships at  | What it proves                                                                                                                     | Verifying artifact                                                                 |
| -------------------------------- | --------- | ---------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------- |
| **L3+ stable**                   | week ~3.5 | Schema-validated artifacts, bounded-execution failures, idempotent resume on cooperative inputs                                    | Cycle-gate + reconciliation tests; `monozukuri run --resume` E2E test              |
| **L4 — config-driven routing**   | week ~8   | Per-phase adapter dispatch; Claude Code reference adapter; Aider in alpha; `routing suggest` gated on data; implicit-dep gate live | `docs/adapter-contract.md` + `schemas/` published; conformance test on canary repo |
| **L4+ — Aider GA**               | week ~10  | Aider clears conformance suite end-to-end; multi-agent claim independently verifiable                                              | Aider-specific canary results in `docs/canary-history.md`                          |
| **L5 — measurable canary trend** | week ~13  | Headline metric (CI-pass-rate-on-first-PR) + diagnostics published weekly with 4-week trailing trend; cost honesty calibrated      | `docs/canary-history.md`; weekly automated canary run; pricing/calibration tables  |

The discipline: publish where you actually are on the ladder, with the verifying
artifact next to the claim. A sceptical reviewer can click straight from claim to
evidence.

### 4. Only labelled schedule risk

The Aider adapter (the second adapter in Gap 3) is the only item without a firm
commitment. Everything else in the ladder above is achievable without Aider; L4
ships with Claude Code as the reference adapter and Aider in alpha. L4+ upgrades
Aider to GA once it clears conformance.

If Aider slips, L4 still ships on time. The only impact is that L4+'s Aider-GA
date is TBD.

### 5. PR review iteration — L5+

Responding to human review comments on opened PRs is explicitly outside the current
quarter. It is named **"L5+: human-in-the-loop review iteration"** and will be
promoted to the active roadmap once:

- L5 metrics are stable (so the reprompt strategy is informed by real data).
- The canary benchmark has accumulated enough runs to model review-comment types
  per stack.

Adding it before those conditions are met means building the wrong strategy.

### 6. Jira backlog adapter

The vision copy mentions Jira as a supported source adapter. It is not yet
implemented. Resolution: remove Jira from the README feature list until the adapter
ships. The honest copy lists only markdown, GitHub Issues, and Linear as supported.
Jira is roadmapped after L5.

---

## Consequences

### Positive

- "~13 weeks (≈ a quarter)" is defensible and close to the original gut estimate;
  it does not require hiding the expanded scope.
- Dated capability-ladder commitments with verifying artifacts are the most
  trust-building surface the product can publish.
- Labelling the only schedule risk (Aider) signals maturity — confident
  maintainers name their unknowns.

### Negative / Trade-offs

- The 13-week headline is longer than the original 10-week promise. Some readers
  will compare the two. The honest response: the original estimate was made before
  14 architectural decisions were pinned; the new number reflects actual design.
- Publishing dated milestones creates accountability. Missing a milestone is
  visible. The mitigation is the same for every commitment: update `docs/canary-history.md`
  honestly, including weeks where the metric regressed.

### Neutral

- The individual gap effort estimates are unchanged from what ADRs 012–015 imply;
  this ADR consolidates them into a single public commitment.
- Release-please and `CHANGELOG.md` are unaffected; L-level milestones are not
  semver events.

---

## Implementation Notes

- The capability ladder lives in `docs/capability-ladder.md` (new file, this PR).
  The README references it by link; it is not inlined.
- `docs/canary-history.md` is created when the first canary run completes (Gap 5).
  The capability-ladder file references it with a note: _"(populated by Gap 5 —
  file does not exist until the first canary run completes)"._
- Milestone calendar dates (from 2026-04-26):
  - L3+ stable (+3.5 wk): week of **2026-05-17**
  - L4 (+8 wk): week of **2026-06-21**
  - L4+ Aider GA (+10 wk): week of **2026-07-05** (subject to Aider conformance)
  - L5 (+13 wk): week of **2026-07-26**
