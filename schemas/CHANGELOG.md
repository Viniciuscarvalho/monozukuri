# schemas/ CHANGELOG

## v1.1.2 — 2026-05-24 (MEM-03)

### Added

- Memory v2 prompt injection tracking writes per-feature
  `memory-injections.jsonl` traces and increments `applied_count` after
  successful phases.

## v1.1.1 — 2026-05-24 (MEM-02)

### Changed

- `learning-v2.schema.json` — `last_applied` now accepts `null` for migrated
  Memory v1 entries, because v1 did not track an equivalent application
  timestamp.

## v1.1.0 — 2026-05-24 (MEM-01)

### Added

- `learning-v2.schema.json` — Memory v2 learning entry with provenance, scope,
  application count, promotion source, agent specificity, and tags.

## v1.0.0 — 2026-04-26 (Gap 1)

Initial schema set for phase artifacts (ADR-012).

### Added

- `prd.schema.json` — Product Requirements Document: `feature_id`, `problem_statement`, `success_criteria` required
- `techspec.schema.json` — Technical Specification: `feature_id`, `technical_approach`, `files_likely_touched` required (ADR-015 implicit-dep gate depends on this field)
- `tasks.schema.json` — Task List: `feature_id`, `tasks[]` required; each task requires `id`, `description`, `acceptance_criteria`
- `commit-summary.schema.json` — Commit Summary: `task_id`, `files_changed`, `summary` required

### Current validation mode

Artifacts are Markdown. `lib/schema/validate.sh` enforces structural section requirements
against the Markdown format. Full JSON artifact emission with ajv enforcement is a Gap 3
deliverable (ADR-012 §5).

### Planned (Gap 3)

- Migrate artifact format from Markdown to JSON
- Add `ajv-cli` to `package.json` for CI-time schema enforcement
- Publish `docs/adapter-contract.md` referencing these schemas as the conformance target
