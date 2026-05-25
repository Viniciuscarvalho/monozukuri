# ADR-026: Sufficiency Router Design

- **Status**: Accepted
- **Date**: 2026-05-25
- **Deciders**: Vinicius Carvalho
- **Supersedes**: —
- **Related**: ADR-025 (Memory v2 Provenance Schema), ADR-019 (Conformance Recordings for Tier-2 Adapters), ADR-018 (Real Cost from Stream-JSON Usage Field)

---

## Context

Memory v2 can now record provenance and track which learnings were injected into
agent prompts. The remaining design question is how much memory to inject. Full
injection is simple, but it grows every prompt as the learning store grows.
Summary-only injection is cheaper, but gives agents no way to recover when a
summary omits the detail needed for a phase.

MEM-05 evaluates three alternatives before any production router is added:

- **A: Inject full** — include every eligible learning with insight, rationale,
  source, tags, and agent scope.
- **B: Always summary** — include compact learning summaries only.
- **C: Summary + on-demand escalation** — start with summaries; if the agent
  prints `MEMORY_ESCALATE:` or the artifact fails schema validation, rerun the
  phase once with full details for selected learnings.

The experiment harness and committed data live under
`docs/experiments/sufficiency-router/`. The committed dataset is deterministic
fake replay data so CI and review remain cost-free. The same harness supports
live local replay with:

```bash
node scripts/experiments/sufficiency-router.js --live --agents claude-code,codex,gemini
```

## Decision

Proceed with design C for the future production sufficiency router, with one
constraint: production implementation must keep escalation bounded to one retry
per phase and must keep live-agent measurement local-only.

The committed experiment covers 5 fixture features, 3 agents, 3 strategies, and
3 phases for 135 runs. Quality is measured by schema validation pass rate.
Tokens and latency are estimated consistently by the harness.

| Agent | Strategy | Schema pass rate | Avg total tokens | Avg latency ms |
| --- | --- | ---: | ---: | ---: |
| claude-code | Inject full | 1.00 | 615.00 | 1.00 |
| claude-code | Always summary | 1.00 | 341.80 | 1.00 |
| claude-code | Summary + on-demand | 1.00 | 381.20 | 1.00 |
| codex | Inject full | 1.00 | 613.60 | 1.00 |
| codex | Always summary | 1.00 | 340.20 | 1.00 |
| codex | Summary + on-demand | 1.00 | 379.80 | 1.00 |
| gemini | Inject full | 1.00 | 613.87 | 1.00 |
| gemini | Always summary | 1.00 | 340.53 | 1.00 |
| gemini | Summary + on-demand | 1.00 | 380.07 | 1.00 |

C ties for best schema pass rate and latency in all 3 agents, while reducing
average prompt+output tokens by roughly 38% compared with full injection. B is
cheapest in this deterministic replay, but it has no recovery path when a
summary is insufficient. C is therefore the preferred design: it keeps most of
the token savings while preserving a bounded escape hatch.

The proceed criterion is satisfied: C wins or ties in at least one metric for 3
of 3 agents, which is greater than the required 2 of 3 agents.

## Consequences

### Positive

- Memory injection can become cheaper than full injection without removing the
  option to recover missing detail.
- The router decision is backed by a repeatable harness and raw artifacts, not
  only prompt intuition.
- The same harness can be rerun against real Claude, Codex, and Gemini CLIs
  before production rollout.

### Negative / Trade-offs

- On-demand escalation adds a second possible agent call for a phase.
- Agents must learn the `MEMORY_ESCALATE:` request convention.
- Summary-only remains cheaper when every phase succeeds on the first try.

### Neutral

- This ADR does not implement the production router.
- The experiment harness intentionally stays local-only and must not run in CI.
- The quality proxy is schema validation pass rate; semantic product quality is
  out of scope for this spike.

---

## Implementation Notes

- Keep production memory behavior unchanged in MEM-05.
- Use `scripts/experiments/sufficiency-router.js --fake` for cost-free fixture
  replay and PR validation.
- Use `--live` only from a local maintainer machine with authenticated CLIs.
- Store experiment outputs in `docs/experiments/sufficiency-router/`, including
  `features.json`, `results.csv`, `results.json`, and raw per-run artifacts.
- A future production router should expose strategies equivalent to
  `inject-full`, `summary`, and `on-demand`, but MEM-05 should not add user-facing
  config for them.
