# ADR-027: Sufficiency Router

- **Status: Accepted**
- **Date**: 2026-05-26
- **Related**: ADR-025 (Memory v2 Provenance Schema), ADR-026 (MEM-05 Sufficiency Router Design)

## Problem

Memory v2 makes learnings auditable, but injecting every eligible learning into
every prompt scales poorly. It increases token use, hides the few relevant
insights inside boilerplate, and makes cross-agent behavior harder to compare.

The router needs to preserve provenance while keeping the default prompt small
and giving the agent a deterministic way to ask for more context.

## Alternatives considered

### A. Inject full

Inject every eligible learning with `id`, `insight`, `rationale`, `source`,
`tags`, and agent scope. This gives maximum context on the first call, but pays
the full token cost even when the phase only needs one short insight.

### B. Always summary

Inject only compact learning summaries. This has the lowest token footprint in
the MEM-05 replay, but gives the agent no recovery path when the summary omits
an important rationale or source detail.

### C. Summary + on-demand escalation

Inject compact summaries first. If detail is needed, the agent emits
`<request-memory id="lrn-xxx"/>` at the beginning of its response. The pipeline
parses the marker, logs the escalation, injects raw Memory v2 fields for the
requested learning, and re-prompts the same phase. Each phase caps escalation
turns to prevent loops.

## Experiment data

MEM-05 compared the three strategies across `claude-code`, `codex`, and
`gemini` using five replay features and the `prd`, `techspec`, and `tasks`
phases. Raw artifacts and machine-readable metrics live under
`docs/experiments/sufficiency-router/`.

The committed replay is deterministic fake mode, so latency ties are expected.
Schema validation is the quality proxy requested by the spike.

| Agent | Strategy | avg_total_tokens_estimated | avg_latency_ms | schema pass rate |
| --- | --- | ---: | ---: | ---: |
| claude-code | Inject full | 615.00 | 1 | 100% |
| claude-code | Always summary | 341.80 | 1 | 100% |
| claude-code | Summary + on-demand escalation | 381.20 | 1 | 100% |
| codex | Inject full | 613.60 | 1 | 100% |
| codex | Always summary | 340.20 | 1 | 100% |
| codex | Summary + on-demand escalation | 379.80 | 1 | 100% |
| gemini | Inject full | 613.87 | 1 | 100% |
| gemini | Always summary | 340.53 | 1 | 100% |
| gemini | Summary + on-demand escalation | 380.07 | 1 | 100% |

Criterion: strategy C must win or tie for first in at least one metric for at
least two of the three agents. C tied for first on schema pass rate and latency
for all three agents, so the criterion passed. It did not beat always-summary on
tokens; the design accepts that overhead to preserve a recovery path.

## Decision

Adopt strategy C for production Memory v2 prompts:

- Build a deterministic summary capped around 500 `cl100k_base` tokens.
- Preserve omitted IDs in `available_on_request`.
- Instruct agents to request detail with `<request-memory id="lrn-xxx"/>` only
  when the summary is insufficient.
- Parse requests in each adapter through the shared `parse_memory_requests`
  contract.
- Log summarize, escalation requested, escalation granted, and escalation denied
  events to `memory-trace.jsonl`.

## Consequences

- Default prompts stay compact and auditable.
- The system has an explicit recovery path when a summary lacks necessary
  rationale or provenance.
- Cross-agent behavior is testable because Claude Code, Codex, and Gemini share
  the same marker format.
- The router is not an ML ranking system. Relevance remains deterministic in v2:
  scope, agent compatibility, tags, and `applied_count`.
- Release candidates should still rerun the MEM-05 harness in live mode before
  GA because the accepted evidence in this repo is deterministic replay data.
