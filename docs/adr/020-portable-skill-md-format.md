# ADR-020: Portable SKILL.md Injection for Tier-2 Adapters

**Status:** Proposed
**Date:** 2026-05-14
**Related:** ADR-012 (Adapter Contract), ADR-017 (Multi-Turn Agent Session — §A), ADR-021

---

`mz-*` skills use Claude Code's `--agent <skill>` invocation, which starts a fresh process and pulls SKILL.md natively. Tier-2 adapters (Codex, Gemini) have no equivalent native mechanism — they receive rendered prompts via `lib/prompt/render.sh` and miss the structured phase instructions that skills provide.

**Decision:** `lib/prompt/skill-inject.sh` prepends compatible SKILL.md content to a rendered phase prompt. Adapters that declare `skill_injection: true` in `agent_capabilities` call it before each phase prompt is sent to the CLI. Adapters that return `false` skip it (no-op path, no code change required).

**Turn scope under multi-turn mode:** When session continuity is active, `skill_inject()` prefixes **turn 1 only** (the PRD phase). Continuation prompts (turns 2–6 via `.continue.tmpl.md`) are intentionally short; the SKILL.md content injected on turn 1 accumulates in session context and does not need to be re-sent. This mirrors the rationale in ADR-017 §A (though via prompt text, not the `--agent` mechanism). If implementation reveals that a specific adapter's session does not reliably carry turn-1 context forward, that adapter can declare `skill_injection_every_turn: true` in `agent_capabilities` to revert to prefixing every turn without changing the shared `skill_inject()` implementation.

**Why prompt prefixing rather than a native skill mechanism?** Tier-2 CLIs have no equivalent to Claude Code's `--agent` flag that natively loads SKILL.md. Prompt prefixing is the only portable mechanism. It is less efficient (adds tokens each turn-1) but requires no per-adapter CLI knowledge beyond the prompt string.

**SKILL.md discovery:** skill discovery writes `.monozukuri/skills-manifest.json` from project-local `.agents/skills`, project-local `.claude/skills`, and supported global skill roots. Prompt injection resolves the first phase-compatible skill for the active adapter from that manifest, then falls back to the bundled `$MONOZUKURI_HOME/skills/mz-<phase>/SKILL.md`. A `.claude/skills` entry is portable only when its frontmatter declares a compatible `agent` such as `any`, `codex`, or `gemini`; otherwise it remains Claude-only.

**Implementation checklist:** The implementing PR must update `docs/adapter-contract.md` to document the two new `agent_capabilities` flags added by this ADR: `skill_injection` (boolean, required for all adapters) and `skill_injection_every_turn` (boolean, optional, defaults to `false`). Both flags must be added to the ABI table in that document alongside their valid values and the behaviour contract.
