# Monozukuri — Vision

> _This document is the canonical, grilled version of the Monozukuri vision.
> Every architectural claim is backed by an ADR. Every timeline commitment is
> verified by a concrete artifact. See [`docs/capability-ladder.md`](capability-ladder.md)
> for the current level and dated milestones._

---

## Part 1 — Honest current-state assessment

### Three independent dimensions

| Dimension                    | Question                                                                  |
| ---------------------------- | ------------------------------------------------------------------------- |
| **Agent agnosticism**        | Can monozukuri use Claude / Codex / Gemini / Kiro interchangeably?        |
| **System-type universality** | Can monozukuri build backend / frontend / mobile features?                |
| **Autonomous-box claim**     | Does it run end-to-end without a human, recover from failures, and learn? |

### Scoring monozukuri today

| Dimension                | Today                                          | Rationale                                                                                                                 |
| ------------------------ | ---------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| Agent agnosticism        | 🟡 **Architecturally ready, not yet built**    | Skills are Claude Code-specific. The adapter contract (ADR-012) is decided but not yet in code.                           |
| System-type universality | 🟢 **Already universal in principle**          | The loop is language/stack-agnostic; the agent does the actual coding. Limits come from the agent, not monozukuri.        |
| Autonomous-box claim     | 🟡 **Pipeline exists, robustness gaps remain** | The 6-phase loop is real and shipping. Failure recovery, learning measurability, and token discipline are not yet proven. |

**Today: L2 cleanly, L3 on cooperative inputs.** See [`docs/capability-ladder.md`](capability-ladder.md).

---

## Part 2 — Vision: monozukuri as a true autonomous box

### One-line vision

> **Monozukuri is the autonomous box that turns a feature backlog into CI-green
> pull requests, on any stack, with any coding agent, while you sleep — and gets
> measurably better every week.**

Three load-bearing claims:

1. **Backlog → CI-green PRs** — the input is intent; the output is code that
   passes CI, ready for human review and merge. _(ADR-014)_
2. **Any stack, any agent** — the user's choice, not yours. _(ADR-012, ADR-015)_
3. **Measurably better every week** — learning is verifiable, not vibes. _(ADR-014)_

If a future feature does not strengthen one of those three claims, defer it.

### The end-to-end flow

```
USER:  monozukuri run
       (and walks away)

┌─────────────────────────────────────────────────────────────────────────────┐
│ 0. PREFLIGHT                                                                │
│    doctor → adapter health → cost budget reservation → lock acquired        │
├─────────────────────────────────────────────────────────────────────────────┤
│ 1. BACKLOG INGESTION                                                        │
│    Source adapter (md / gh / linear) → normalised feature objects           │
│    Validate explicit depends_on refs · dedup in-flight PRs                  │
│    Resolve dependencies · topo-sort                                         │
├─────────────────────────────────────────────────────────────────────────────┤
│ 2. PER-FEATURE GATES                                                        │
│    Size estimation · cost estimation · skip if over budget · learn skip     │
├─────────────────────────────────────────────────────────────────────────────┤
│ 3. WORKTREE ISOLATION                                                       │
│    git worktree per feature · context-pack relevant files · learning top-K  │
├─────────────────────────────────────────────────────────────────────────────┤
│ 4. PHASE LOOP (per feature)                                                 │
│                                                                             │
│    PRD          → schema-validated (ADR-012) · learning injection           │
│    ↓                                                                        │
│    TechSpec     → schema-validated · files_likely_touched[] required        │
│    ↓                                                                        │
│    Tasks        → JSON schema · atomicity/files/AC lints · 1 reprompt max  │
│    ↓                                                                        │
│    [IMPLICIT-DEP GATE]                                                      │
│    Check files_likely_touched overlap with in-flight worktrees              │
│    Overlap → defer until conflicting feature reaches cycle-gate             │
│    ↓                                                                        │
│    Code         → per-task commits in worktree · transient retry on failure │
│    ↓                                                                        │
│    Tests        → run project's test command · capture results              │
│    ↓                                                                        │
│    PR           → opened with body referencing all artifacts                │
│    ↓                                                                        │
│    CI WAIT      → poll checks until terminal (60-min default timeout)       │
│                   classify flake → re-run failed job up to 2×               │
│                   red after rerun → 1 agent reprompt + fixup + re-wait once │
│                   still red → feature.failed with PR link + CI logs         │
│                                                                             │
│    Phase routing: each phase can use a different agent/model (ADR-015)      │
│    Failure classification: adapter classifies · core decides policy         │
│      transient → retry · phase → 1 reprompt · fatal → abort (ADR-013)      │
│                                                                             │
│    RATE-LIMIT HANDLING (between any phase invocation)                       │
│      retry_after ≤ 10 min  → sleep-and-wait                                │
│      ≤ 60 min              → defer feature · advance to next independent    │
│      > 60 min OR all blocked → pause-clean · exit with resume message      │
│      Cross-agent failover: opt-in only (routing.failover: true)             │
├─────────────────────────────────────────────────────────────────────────────┤
│ 5. CYCLE GATE                                                               │
│    All artifacts present · valid · committed · PR exists · CI green         │
│    Otherwise: feature.failed with structured reason                         │
├─────────────────────────────────────────────────────────────────────────────┤
│ 6. LEARNING CAPTURE                                                         │
│    Per-feature: what we learned about this feature                          │
│    Per-project: conventions, patterns, pitfalls in this repo                │
│    Per-global: cross-project patterns, agent quirks, model preferences      │
│    Compaction: dedup, contradict-detect, promote/demote tiers               │
│    Post-code: record files_actually_touched vs files_likely_touched         │
├─────────────────────────────────────────────────────────────────────────────┤
│ 7. NEXT FEATURE                                                             │
│    Dependents of failed feature → skipped with reason                       │
│    Deferred features → re-evaluated when their window opens                 │
│    Independents → proceed                                                   │
│    Loop until backlog drained or cost ceiling hit                           │
├─────────────────────────────────────────────────────────────────────────────┤
│ 8. RUN REPORT                                                               │
│    Succeeded · failed · skipped · total tokens · USD spent                  │
│    Per-feature breakdown · which learnings applied · PR list                │
│    CI pass rate · phase retry counts · rate-limit wait time                 │
│    Routing recommendation update                                            │
│    Trace files preserved for audit                                          │
│    monozukuri review export <run-id> → portable HTML report                 │
└─────────────────────────────────────────────────────────────────────────────┘

USER returns to a PR list, a cost report, and CI-green code ready for review.
```

### What "autonomous box" actually requires

Six properties. All six must hold or the box leaks.

**1. Self-diagnosing input.** The box knows whether the backlog is well-formed before
it starts. Bad inputs — including dangling `depends_on` references — fail loudly
with exact fixes, not silently mid-run. _(ADR-015 §3a)_

**2. Bounded execution.** Every phase has a token budget, a wall-clock timeout, and a
kill switch. The one-reprompt rule is the kill switch: every reprompt trigger in the
box (CI red, schema validation failure, phase failure) allows exactly one reprompt.
No unbounded retry loops. _(ADR-012 §3, ADR-013 §3, ADR-014 §2)_

**3. Stratified failure handling.** Transient errors retry. Phase errors reprompt
once. Cycle-gate errors fail one feature and continue. Fatal errors abort the run
with state preserved. Rate limits pause cleanly rather than stalling silently.
The box never gets stuck. _(ADR-013)_

**4. Idempotent resumption.** Crash on feature 7 of 23 →
`monozukuri run --resume` continues from feature 7 with no rerun of 1–6. State is
stored as a run-manifest + per-worktree `state.json`, with atomic writes and
manifest-vs-disk reconciliation on resume. _(ADR-013 §4)_

**5. Verifiable artifacts.** Every phase produces a structured artifact that validates
against a published JSON schema. The box knows when the agent emits garbage, even
when the box couldn't write the code itself. _(ADR-012)_

**6. Compounding learning.** Run N+1 measurably outperforms run N on similar features.
The headline metric — CI-pass-rate-on-first-PR on the fixed canary benchmark —
trends upward. Tokens per feature and retry counts trend down. The data is public in
`docs/canary-history.md`. Without this, the box is a script that runs in a loop,
not a learning system. _(ADR-014)_

### What the user experiences

**`monozukuri run`** — the box itself. Ink TUI for interactive runs; clean structured
logs for unattended runs. Returns a concrete run report: CI-green PRs, cost, time,
learnings applied, rate-limit wait time.

**`monozukuri status`** — the audit surface. What is in flight, what failed, why,
what to do next. Always answerable from on-disk state.

**`monozukuri review`** _(Gap 6)_ — the trust surface. `monozukuri review open <run-id>`
generates a self-contained HTML report and opens it locally. No server — the bundle
is a file, portable and permanently durable. This is what you show a sceptical CTO.

### The capability ladder

See [`docs/capability-ladder.md`](capability-ladder.md) for the full table with
dated milestones and verifying artifacts.

| Level   | What the box does                                                 |
| ------- | ----------------------------------------------------------------- |
| **L1**  | Single feature, supervised                                        |
| **L2**  | Single feature, unattended ✅ stable                              |
| **L3**  | Backlog, unattended, single agent (cooperative inputs) ✅ partial |
| **L3+** | Same, with schema validation + stratified failure + resume        |
| **L4**  | Per-phase multi-agent routing                                     |
| **L4+** | Aider as second production adapter                                |
| **L5**  | Measurably self-improving on the canary benchmark                 |
| **L5+** | PR review iteration (post-L5)                                     |

---

## Part 3 — The gap and how to close it

See [`docs/roadmap.md`](roadmap.md) for the full gap list with effort estimates,
dependencies, and ADR references.

### Priority order

**Gap 1 — Phase artifact schemas (L3+ foundation) · 1 wk**
Today the skill emits whatever it wants. Tomorrow every phase produces an artifact
that validates against a published schema, with one reprompt on validation failure.
_ADR-012. Effort: 1 week. Critical-path dependency root._

**Gap 2 — Stratified failure handling, idempotent resumption & rate-limit policy (L3+ robustness) · 2 wk**
Structured adapter error envelopes. Policy table. Run-manifest + per-worktree state
with atomic writes and resume reconciliation. Rate-limit threshold ladder.
_ADR-013. Effort: 2 weeks (expanded from 1 wk)._

**Gap 3 — Multi-agent adapter contract + Claude Code reference + Aider (L4 unlock) · 3.5–4 wk**
Adapter contract spec. Claude Code reference adapter refactored to satisfy it. Aider
as second adapter (stretch). Conformance = valid schema output on canary benchmark.
_ADR-012, ADR-015. Effort: 3.5–4 weeks. Aider is the only labelled schedule risk._

**Gap 4 — Per-phase routing & threshold-gated `routing suggest` (L4) · 1 wk**
`routing.yaml` per project. Per-phase adapter dispatch. `routing suggest` ships but
is gated on data: refuses to recommend until ≥4 canary runs per (adapter, phase)
pair. _ADR-015. Effort: 1 week after Gap 3._

**Gap 5 — Measurable learning + canary benchmark + MRP (L5 unlock) · 3 wk**
`monozukuri-canaries` repo with ~20 frozen features. Weekly scheduled run.
`docs/canary-history.md`. Headline metric: CI-pass-rate-on-first-PR.
_ADR-014. Effort: 3 weeks (expanded from 2 wk)._

**Gap 6 — Run review surface (trust) · 1 wk**
`monozukuri review export/open <run-id>`. Static HTML+JS+JSON bundle. No server.
The artifact you show a sceptical CTO. _ADR-015. Effort: 1 week._

**Gap 7 — Implicit-dep detection + explicit-dep validation (correctness) · 3 days**
Ingestion-time `depends_on` validation (fail loud at file:line).
`files_likely_touched` pre-Code gate. Post-code verification for learning.
_ADR-015. Effort: 3 days._

**Gap 8 — Pricing & calibration (cost honesty) · 1 wk**
Versioned pricing table. Per-(agent, model, phase) calibration coefficients.
Real-time cost tracking. `monozukuri calibrate`. _Effort: 1 week._

**Total to L5: ~13 weeks (≈ a quarter) of focused work.** The capability ladder
publishes shipping dates for L3+, L4, L4+, and L5 separately — progress is
observable in real time. The only labelled schedule risk is the Aider adapter
inside Gap 3.

### What does NOT belong in the vision

- **Code generation in monozukuri itself.** The agent does that.
- **PR review iteration** (L5+). Build it after L5 learning data exists.
- **Hosted SaaS.** A future option; not the box. Promoted when ≥100 teams ask.
- **Browser/UI for editing artifacts.** The artifacts are markdown. Use your editor.
- **Native mobile simulator orchestration.** Different problem shape. Defer.
- **ML training jobs.** Non-PR-shaped workflow. Out of scope.
- **A model of its own.** The whole point is agent agnosticism.
- **Marketplace for skills/templates.** Premature until ≥1000 users.
- **Jira backlog adapter** (in copy). Not yet implemented. Removed from copy until
  shipped.

The discipline of _not_ doing these is what keeps the box small enough to work.

### Honest copy you can ship today

> Monozukuri turns your feature backlog into CI-green pull requests. Point it at
> your backlog (markdown, GitHub, Linear), your coding agent (Claude Code today;
> Codex, Gemini, Aider, Kiro coming), and your project — it creates isolated
> worktrees, drives the agent through PRD → TechSpec → Tasks → Code → Tests → PR
> for each feature, waits for CI, and learns from every run so the next one is
> cheaper and more reliable. Local-first, open source, no hosted runtime — every
> run produces a portable HTML report you can share or attach to a PR.
>
> **Today** monozukuri runs full unattended loops on cooperative backlogs with
> Claude Code. We are working in the open toward true autonomous-box semantics:
> stratified failure recovery, multi-agent routing, and verifiable run-over-run
> improvement. See [`docs/capability-ladder.md`](capability-ladder.md) for exactly
> what is stable today and what is in flight.

---

## Summary

**Today:** monozukuri is a Claude Code-driven feature loop, stack-universal in
principle, autonomous on cooperative inputs. L2 cleanly, L3 with caveats.

**Vision:** an L5 autonomous box — any agent, any stack, measurably self-improving —
fed by a backlog, returning CI-green PRs.

**Gap:** ~13 weeks of focused work along eight specific gap items, all named in
[`docs/roadmap.md`](roadmap.md) with ADR references. Nothing in this vision requires
a research breakthrough; it is all engineering discipline.

**The thing that makes this real, not aspirational:** publishing the capability
ladder honestly with verifying artifacts, building the measurement system that
_proves_ the level you claim, and using monozukuri to build monozukuri so the
dogfood loop is visible from the outside.

Print the diagram. Pin it. Ship the gaps in order. Don't drift.
