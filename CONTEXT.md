# Monozukuri — Domain Context

## Glossary

### Adapter

A per-agent implementation under `lib/agent/` that translates the monozukuri phase contract into agent-specific CLI invocations. Each adapter must pass the conformance suite (`test/conformance/`) to be considered validated.

**Validated (GA):** claude-code
**Experimental (rendered-prompt mode, no conformance recordings):** codex, gemini, kiro, aider

### Autonomy Level

One of `supervised | checkpoint | full_auto`. Controls whether the operator is prompted between phases. In `full_auto`, no skill may block on user input — violating this is a contract bug, not a feature.

### Foreign Project

A project the monozukuri maintainer does not own or regularly work on. Used in the v1.0 SLO ("3 foreign projects × 5 features") to mean any project outside the maintainer's own repos. Stack is irrelevant — Kotlin, Swift, Java, TypeScript all qualify.

### Phase-3 Pause Rate

The fraction of features that enter a paused state at Phase 3 (code execution) across a run. SLO ceiling: ≤30%. Machine-readable gate: `.qa/layers/06-scale-soak.sh`.

### Release Gate

The 7-layer QA script at `.qa/release-gate.sh`. Layer 6 (scale soak) is the machine-readable v1.0 SLO enforcement. Layers 5, 6-live, and 7 are skipped in CI; they are manual pre-release checks.

### Recording

A captured real agent response under `.qa/fixtures/recordings/<agent>/`. Used by `replay-claude` for deterministic CI replay. Codex and Gemini recordings are currently seeded from claude-code recordings — not real agent output. Re-recording requires the respective CLI and `make rerecord-fixtures`.

### Skill (mz-\*)

A bundled Claude Code skill shipped with monozukuri (e.g. `mz-create-prd`). Skills are Claude Code only — other adapters use rendered prompts via `lib/prompt/render.sh`. All 8 bundled skills carry `version: 1.0.0` in their `SKILL.md` frontmatter.

### v1.0 SLO

> 3 foreign projects × 5 features each × ≤30% Phase-3 pause rate × $50/night cost ceiling × weekly triage.

This is an internal quality gate, not a public README claim. Evidence: FitToday-cms (TypeScript CMS, ~10 features, Claude Code adapter) constitutes a valid foreign-project run. Layer 6 mock variant passes in CI.

## Key decisions

- **Agent disclaimer (2026-05-13):** README now marks Claude Code as the reference adapter (GA) and Codex/Gemini/Kiro as experimental. Codex validation planned before Show HN.
- **Stack flexibility:** "Foreign project" in the SLO is stack-agnostic — Kotlin, Java, Swift, TypeScript all count. No requirement to specifically test go/node/python fixtures in live mode before launch.
- **Layer 6 live:** Not required before Show HN. FitToday-cms overnight run (~10 features, real PRs opened) is accepted as live evidence for the launch.
