# ADR-025: Memory v2 Provenance Schema

- **Status**: Accepted
- **Date**: 2026-05-24
- **Deciders**: Vinicius Carvalho
- **Supersedes**: —
- **Related**: ADR-008 (Orchestrator Economy), ADR-009 (Local Models), ADR-010 (Stuck-State Elimination)

---

## Context

The v1 learning store records reusable fixes as error-pattern entries with
confidence and promotion flags. That is enough to reuse known fixes, but it is
not enough to answer why a learning exists, where it came from, how often it was
applied, or whether it is agent-specific.

Memory v2 needs to make each learning auditable without depending on free-form
markdown context. The minimum useful unit is a single learning entry that carries
provenance, application count, recency, promotion source, optional rationale, and
tags. This story introduces the schema and validator only; data migration and
runtime write paths stay separate so existing learning behavior remains stable.

## Decision

Memory v2 entries use a provenance-first schema documented in
`docs/schemas/memory-v2.md` and enforced by `schemas/learning-v2.schema.json`.
The canonical entry shape is:

```yaml
id: lrn-YYYY-MM-DD-NNN
scope: feature|project|global
insight: string
rationale: string
source:
  feature_id: string
  phase: prd|techspec|tasks|code|tests|pr
  run_id: string
  artifact: string
  line_range: [int, int]
applied_count: int
last_applied: ISO8601
promoted_from: feature|user_correction|manual|auto_detected
agent_specific: claude-code|codex|gemini|null
tags:
  - string
```

The validator accepts either one entry object or an array of entries. It validates
JSON files directly and YAML files through a small dependency-free YAML subset
parser that supports the documented schema shape. The parser is deliberately a
validator boundary, not a general YAML API for production write paths.

The public validation interface is:

```bash
monozukuri memory lint [file...]
```

When files are passed, each file is validated independently. Without files,
`memory lint` searches known Memory v2 store locations under `.monozukuri/` and
prints a helpful no-store message when none exist. A valid lint exits `0`;
invalid input exits `1` and reports the file plus field path.

## Consequences

### Positive

- Every Memory v2 learning can be traced back to a feature, phase, run, artifact,
  and optional line range.
- `applied_count` and `last_applied` make stale or frequently-used learnings easy
  to distinguish.
- `promoted_from` separates agent-observed learnings from manual corrections and
  user decisions.
- `agent_specific` prevents over-applying a Claude-specific or Codex-specific
  learning to another adapter.
- A JSON Schema gives tests, fixtures, and future migration code one validation
  contract.

### Negative / Trade-offs

- The schema is stricter than v1 and will reject vague learnings without
  provenance.
- YAML support is intentionally narrow; complex YAML documents must be converted
  to JSON before linting.
- Migration from v1 requires explicit mapping from `pattern/fix/tier` to
  `insight/rationale/scope`, which is not part of this story.

### Neutral

- v1 `learning` commands and `learned.json` stores continue to work unchanged.
- Memory v2 stores may be introduced alongside v1 before any automatic migration.

---

## Implementation Notes

- Add `schemas/learning-v2.schema.json` as the machine-readable contract.
- Add `docs/schemas/memory-v2.md` with field semantics, constraints, examples,
  and lint usage.
- Add `monozukuri memory lint` in a new `cmd/memory.sh` command.
- Keep validation dependency-free using Node.js, which is already required by
  Monozukuri.
- Add ten fixtures covering valid entries, arrays, optional fields, invalid IDs,
  invalid enums, missing provenance, string length limits, line ranges, null
  `agent_specific`, and YAML input.
