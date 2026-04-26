# ADR-012: Adapter Contract & Phase Artifact Schemas

- **Status**: Accepted
- **Date**: 2026-04-26
- **Deciders**: Vinicius Carvalho
- **Supersedes**: —
- **Related**: ADR-006 (Agent Discovery & Routing), ADR-008 (Orchestrator Economy), ADR-015 (Routing, Implicit Deps, Review Surface)

---

## Context

Today the adapter "contract" is implicit — each adapter (claude-code, codex, gemini,
kiro) is a shell script under `lib/agent/`. The schema for phase artifacts (PRD,
TechSpec, Tasks) is whatever the skill chooses to emit. This means:

1. Monozukuri cannot distinguish a valid artifact from a hallucinated one.
2. There is no automated conformance check across adapters.
3. Reliable quality gates downstream of the skill phase are impossible.

Two decisions from the 2026-04-26 vision grilling are captured here:

- **Q6 — Adapter contract level**: Hybrid schema-as-contract. Monozukuri owns
  artifact schemas; adapters own prompts and tool use.
- **Q7 — Schema validation policy**: Schema-in-prompt (cached) + exactly one
  reprompt with humanized errors. This "one reprompt rule" is a cross-cutting
  invariant — CI handling (ADR-014) and failure classification (ADR-013) follow
  the same cap.

---

## Decision

### 1. Phase artifact schemas

Monozukuri publishes JSON Schema files in `schemas/` for each phase artifact:

| File                                 | Phase    | Key required fields                                                                |
| ------------------------------------ | -------- | ---------------------------------------------------------------------------------- |
| `schemas/prd.schema.json`            | PRD      | `title`, `problem`, `solution`, `acceptance_criteria[]`, `risks[]`                 |
| `schemas/techspec.schema.json`       | TechSpec | `summary`, `approach`, `files_likely_touched[]`, `dependencies[]`, `test_strategy` |
| `schemas/tasks.schema.json`          | Tasks    | `tasks[].id`, `tasks[].title`, `tasks[].acceptance_criteria[]`, `tasks[].files[]`  |
| `schemas/commit-summary.schema.json` | Code     | `commit_sha`, `files_changed[]`, `summary`                                         |

All schemas use `additionalProperties: false` and lenient string formats (no
format: uri, no minLength on freetext). Schemas are versioned using SemVer in
`schemas/CHANGELOG.md`.

`techspec.schema.json` requires a `files_likely_touched: string[]` field (used by
implicit-dep detection in ADR-015).

### 2. Schema-in-prompt requirement

Every adapter MUST send the relevant phase schema as a **cached system-prompt
block** before the phase invocation. This is a conformance requirement documented
in `docs/adapter-contract.md` (Gap 3 deliverable). Until Gap 3 ships, Claude Code
is the sole adapter and this ADR is its implementation spec.

### 3. One-reprompt validation rule

Monozukuri validates each phase output against the phase schema. On failure:

1. Generate a humanized error summary (not the raw AJV output). Example:
   `Field tasks[2].acceptance_criteria is missing required key "verifiable".`
2. Reprompt the adapter once with the humanized summary.
3. If still invalid → phase-class failure (handled per ADR-013 policy table).

One reprompt maximum, matching CI (ADR-014) and phase-failure (ADR-013) policy.
Repeated schema failures on the same adapter/phase are learning signals for
routing (ADR-015).

### 4. Conformance definition

An adapter is conformant if, given any canary feature (see ADR-014), it emits
valid schema output for every phase within the one-reprompt budget. Non-conformant
adapters are not listed as supported until they pass the conformance suite.

### 5. Deferred artifacts

`docs/adapter-contract.md` and `schemas/*.json` ship as Gap 1 and Gap 3
deliverables respectively. This ADR declares the architecture; the artifacts ship
when the corresponding gaps open.

---

## Consequences

### Positive

- Monozukuri can detect garbage output without being able to write the code itself.
- Schemas double as the conformance test harness for new adapters.
- Repeated schema failures become routing and learning signal at no extra cost.
- `additionalProperties: false` makes the contract explicit to adapter authors.

### Negative / Trade-offs

- Each new adapter must implement schema-in-prompt, adding ~1 day to adapter build
  cost.
- Schemas must be maintained across feature evolution; a breaking schema change
  requires a version bump and a migration note.
- Schema strictness calibration is ongoing — too strict causes false-fail retries;
  too loose lets bad artifacts through.

### Neutral

- Phase prompts move from monozukuri's skill into each adapter's implementation.
  Monozukuri owns the output contract; the prompt strategy is the adapter's
  responsibility.
- The error-formatting utility (`lib/schema/humanize-error.sh` or equivalent) is
  a small shared module reused by all phase validators.

---

## Implementation Notes

- JSON Schema draft: 2020-12. Validate with `ajv-cli` (already a transitive
  dependency via Node.js).
- Cached system-prompt mechanism depends on the adapter's CLI. For Claude Code,
  use a system-prompt file passed via `--system-prompt`. Document the equivalent
  for each adapter in `docs/adapter-contract.md`.
- Schema files live in `schemas/` at the monorepo root, not inside `lib/`.
- `schemas/CHANGELOG.md` tracks breaking vs additive changes using SemVer.
  Patch = added optional field. Minor = added required field (with migration).
  Major = removed or renamed field.
