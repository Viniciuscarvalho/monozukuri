# ADR-021: Session Continuity for Codex (Gemini Deferred)

**Status:** Proposed
**Date:** 2026-05-14
**Related:** ADR-017 (Multi-Turn Agent Session), ADR-020 (Portable Skill Injection)

---

ADR-017 implemented session continuity for claude-code only. Tier-2 adapters declared `session_continuity: false` with no implementation. The Codex CLI supports `--conversation-id <uuid>` for persistent sessions. The Gemini CLI's equivalent mechanism is undocumented in the codebase and requires a research spike to confirm.

**Decision:** v2.0 implements session continuity for Codex only. Gemini is deferred to v2.1.

`adapter-codex.sh` gains the same session state machine as `adapter-claude-code.sh` (ADR-017 §1–4): turn 1 writes `session.json` with a new UUID passed via `--conversation-id <uuid>`; subsequent turns read the UUID and pass it again. On interruption or missing session file, the adapter emits `session.resume_missed` via `monozukuri_emit` and falls back to cold-process. `agent_capabilities` flips `session_continuity: true` once the implementation is verified against a real Codex run with `MONOZUKURI_MULTI_TURN=1`.

**Why not Gemini in v2.0?** The Gemini CLI flag for conversation continuity is unknown. Shipping an untested session flag risks silent failure — the session claim would be in `agent_capabilities` but the context may not actually persist. A single research spike to confirm the flag and record a real conformance fixture belongs in v2.1, not here.

**Rollout:** Follows ADR-017's opt-in pattern. `MONOZUKURI_MULTI_TURN=1` is required; Codex without that flag stays on cold-process. `monozukuri doctor` warns when `MONOZUKURI_MULTI_TURN=1` is set for Gemini, explaining that Gemini session continuity is not yet implemented.

**Implementation checklist:** The implementing PR must update `docs/adapter-contract.md` to reflect the `session_continuity` flag flip for the Codex adapter (from `false` to `true`). The Gemini adapter row remains `false` with a note referencing v2.1. Both changes belong in the ABI table that `lib/agent/contract.sh` is documented against.
