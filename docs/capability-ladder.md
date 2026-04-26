# Monozukuri Capability Ladder

The capability ladder is the canonical answer to "what does monozukuri reliably do
today?" Each level is a public commitment. Each commitment is verified by a concrete
artifact — not by a claim.

> **Current level: L2 cleanly, L3 on cooperative inputs.**
> See the table below for what is stable, what is in progress, and the verifying
> artifact for each level.

---

## Levels

| Level                                    | What the box does                                                                                                                                          | Example                                                   | Ships at                             | Verifying artifact                                                                                                    |
| ---------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------- | ------------------------------------ | --------------------------------------------------------------------------------------------------------------------- |
| **L1** Single feature, supervised        | Run one feature end-to-end with a human pausing between phases                                                                                             | `monozukuri run --feature feat-001 --autonomy supervised` | ✅ Stable                            | Manual review of phase outputs                                                                                        |
| **L2** Single feature, unattended        | Run one feature end-to-end without a human                                                                                                                 | `monozukuri run --feature feat-001 --autonomy full_auto`  | ✅ Stable                            | E2E test on a single-feature backlog                                                                                  |
| **L3** Backlog, unattended, single agent | Run a whole backlog, single agent, with size gates and resume on cooperative inputs                                                                        | `monozukuri run`                                          | ✅ Partial (cooperative inputs only) | Cycle-gate tests; `monozukuri run --resume` E2E test                                                                  |
| **L3+** Backlog, unattended, robust      | Same as L3 but with schema-validated artifacts, stratified failure handling, and idempotent resume                                                         | `monozukuri run`                                          | **week ~3.5** _(2026-05-17)_         | Cycle-gate + reconciliation tests; schema conformance test; resume after synthetic crash                              |
| **L4** Backlog, unattended, multi-agent  | Per-phase adapter dispatch; `routing suggest` gated on canary data; implicit-dep gate live                                                                 | `monozukuri run --routing-profile auto`                   | **week ~8** _(2026-06-21)_           | `docs/adapter-contract.md` + `schemas/` published; conformance test on canary repo with Claude Code reference adapter |
| **L4+** Aider GA                         | Same as L4, with Aider as a second production-quality adapter                                                                                              | `monozukuri run` with `routing.yaml: code: aider`         | **week ~10** _(2026-07-05)_          | Aider canary results in `docs/canary-history.md`; Aider-specific conformance suite passing                            |
| **L5** Self-improving                    | Headline metric (CI-pass-rate-on-first-PR) published weekly with 4-week trailing trend; tokens and completion rate as diagnostics; cost honesty calibrated | `monozukuri run` — metrics improve weekly                 | **week ~13** _(2026-07-26)_          | `docs/canary-history.md` updated weekly; badge in README: `monozukuri L5: NN% (4-wk trailing, 20-canary benchmark)`   |
| **L5+** Human-in-the-loop review         | Box responds to PR review comments, reprompts on the same worktree, pushes fixup commits                                                                   | _(unscheduled)_                                           | Post-L5                              | Tracked separately once L5 metrics stabilise                                                                          |

---

## What "verifying artifact" means

A verifying artifact is something a sceptical external reader can check
independently:

- A test in the repo that passes in CI
- A published spec or schema file
- A data file (`docs/canary-history.md`) updated by an automated weekly run
- A badge in the README that links to the data

If the verifying artifact does not exist, the level is not claimed. Publishing the
artifact is part of shipping the level.

---

## Milestone timeline

All weeks are measured from the grilling date (2026-04-26). The only labelled
schedule risk is the Aider adapter inside Gap 3; all other milestones are firm.

```
Apr 26 ──────── May 17 ──────────────── Jun 21 ──── Jul 05 ──────── Jul 26
start           L3+ stable              L4          L4+ Aider GA    L5
```

---

## What is NOT on the ladder

Items explicitly deferred and the reason:

| Item                                      | Reason                                                                                                                           |
| ----------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| **PR review iteration** (L5+)             | Requires 2–3 weeks additional scope; building the reprompt strategy before L5 learning data exists means building the wrong one. |
| **Jira backlog adapter**                  | Not yet implemented; removed from copy until shipped. Roadmapped after L5.                                                       |
| **Hosted SaaS**                           | A future option. The box is a local CLI. Promoted when ≥100 teams ask for it.                                                    |
| **Native mobile simulator orchestration** | Different problem shape. Deferred.                                                                                               |
| **ML training jobs**                      | Non-PR-shaped workflow. Out of scope.                                                                                            |
| **Marketplace for skills/templates**      | Premature. Deferred until ≥1000 users.                                                                                           |

---

_Source of truth for milestone reasoning: ADR-016._
_Source of truth for L5 metric: ADR-014._
_Canary history (populated by Gap 5): `docs/canary-history.md`._
