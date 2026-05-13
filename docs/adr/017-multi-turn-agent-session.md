# ADR-017: Multi-Turn Agent Session

- **Status**: Accepted
- **Date**: 2026-05-13
- **Deciders**: Vinicius Carvalho
- **Supersedes**: —
- **Related**: ADR-012 (Adapter Contract & Phase Artifact Schemas — amended, not superseded), ADR-008 (Orchestrator Economy), ADR-013 (Failure Handling & Resumption), ADR-015 (Routing, Implicit Deps, Review Surface), ADR-016 (Thirteen-Week Plan)

---

## Context

Every monozukuri phase today is a cold `claude --print` process. No `--session-id`,
`--resume`, or `--continue` flag is used anywhere in `lib/agent/adapter-claude-code.sh`.
Each invocation re-bootstraps from scratch:

| Re-injected material                                                  | Approx. tokens |
| --------------------------------------------------------------------- | -------------- |
| SKILL.md or template prelude                                          | 2–5 K          |
| AGENTS.md / CLAUDE.md                                                 | 3 K            |
| Prior validated artifacts (PRD → TechSpec → tasks.json) via Read tool | 3–15 K         |
| Worktree re-walk for context                                          | 2–5 K          |
| **Per-phase overhead**                                                | **~7 K**       |

Six phases × 7 K ≈ **42 K tokens wasted per feature**. On a typical 120 K-token
feature that is 30–40 % overhead. The savings are **re-bootstrap elimination**, not
Anthropic's ephemeral prompt cache (5-minute TTL; Code phase routinely exceeds this).

The `claude` CLI supports persistent sessions: `--session-id <uuid>` pins a new
session on turn 1; `--resume <uuid>` continues on subsequent turns. Session transcripts
are stored locally at `~/.claude/projects/<cwd-slug>/<uuid>.jsonl` and replayed on
`--resume`. **Important:** `--continue` is buggy in non-interactive mode (GitHub
issue #3976) and must never be used in scripts — always pin the UUID explicitly.

---

## Decision

### 1. Architectural redesign: phases are turns within a single session per feature

`agent_run_phase` for tier-1 adapters (see §2) dispatches each phase as a
**turn** on a persistent session rather than a new process. The session is identified
by a UUID stored in `<run_dir>/<feat>/session.json`.

Turn 1 (PRD): `claude --session-id <uuid> --print <prompt>`
Turns 2–6: `claude --resume <uuid> --print <continuation_prompt>`

Context accumulates naturally. Prior artifacts do not need to be re-read.

### 2. Tier-1 / tier-2 capability gate — no fake-session shims

`agent_capabilities` returns a new field `supports.session_continuity`:

- **claude-code**: `true` → uses real `--session-id`/`--resume` threading
- **codex, gemini, kiro, aider**: `false` → cold-process path unchanged

`lib/run/pipeline.sh` reads this flag before a feature run and sets
`MONOZUKURI_MULTI_TURN_ACTIVE=1` only when both the env flag and the capability are
true. A misconfigured run (multi-turn flag + tier-2 agent) degrades to cold-process
with a doctor warning — no hard error.

### 3. Phase-level turns, schema-fix in-turn

The 6 phases (prd → techspec → tasks → code → tests → pr) = 6 turns per feature.
Schema reprompts (`MONOZUKURI_PHASE=fix-schema`) are **continuation messages on the
same session**, not new cold processes. The existing `schema_validate_with_reprompt`
calls `agent_run_phase` unchanged; the adapter resolves the session and sends the
fix message via `--resume`. `MONOZUKURI_SCHEMA_MAX_REPROMPTS` still caps the count.

### 4. Resume policy: same-session preferred, new-session re-bootstrap on miss

On `monozukuri retry` or crash recovery:

1. Adapter reads `session.json`, extracts `session_id` and `last_completed_turn`.
2. Checks `~/.claude/projects/<cwd-slug>/<uuid>.jsonl` exists.
3. If found: `--resume <uuid>`, pick up from next turn.
4. If missing: start a new session, use the **standard** (non-continuation) template
   that re-injects prior validated artifacts. A `session.resume_missed` event is
   emitted via `monozukuri_emit` for observability. Correctness is preserved;
   cost savings on the resume path are lost.

### 5. Same `agent_run_phase` entry point — no new contract functions

ADR-012's 6-function contract is preserved. The `fix-schema` turn reuses
`agent_run_phase`; the adapter handles session resolution internally. Tier-2 adapters
require no code change beyond the one-line capability declaration.

### 6. Rollout: opt-in via `MONOZUKURI_MULTI_TURN=1`, default off in v1.49.0

Multi-turn is disabled by default. Users opt in by exporting
`MONOZUKURI_MULTI_TURN=1`. After validation on FitToday-cms (≥ 3 features, ≥ 25 %
token reduction versus cold-process baselines, no failed/paused features), the
default flips to on in v1.50.0 and this ADR's status moves to **Accepted**.

### Design decisions implicit in the above

**A. Skills (Tier-1 native path) are bypassed in multi-turn mode.**
`mz-*` skills are bootstrap-heavy — each `--agent <skill>` invocation pulls SKILL.md
fresh, undermining session reuse. When `MONOZUKURI_MULTI_TURN_ACTIVE=1`, the adapter
forces the Tier-2 rendered-template path for every phase. The cold-process default
preserves the skill path for users who do not opt in. Doctor warns when a user
enables multi-turn that skills will not be invoked.

**B. Continuation prompts are short per-phase templates.**
`lib/prompt/phases/<phase>.continue.tmpl.md` contains a brief directive for phases
2–6 (no `prd.continue` — PRD is always turn 1). `render_phase_prompt` picks the
`.continue` template when `MONOZUKURI_MULTI_TURN_ACTIVE=1` and a session is active,
falling back to the standard template if the file is absent.

---

## Consequences

### Positive

- ~30–40 % token reduction per feature on claude-code (re-bootstrap elimination).
- Prior phase artifacts are available to the agent from session context — no
  re-injection, no Read-tool round-trips, less prompt noise.
- Schema reprompts are cheaper: the agent already holds the full phase context.
- Resume after crash recovers within the same session where possible, avoiding
  re-running completed phases.
- No change to tier-2 adapters beyond a one-line capability declaration.

### Negative / Trade-offs

- Two code paths in `lib/run/pipeline.sh` and `lib/agent/adapter-claude-code.sh`
  (multi-turn and cold-process). Surface to maintain increases.
- Worktree path stability is now a correctness requirement for session resume.
  Moving a worktree directory mid-feature silently breaks same-session resume
  (falls back to cold re-bootstrap).
- `mz-*` skills are unused under multi-turn mode. Users who opt in trade skill
  encapsulation for token savings. Doctor surfaces this trade-off.
- Session jsonl grows with full tool-use history across 6 turns (potentially
  hundreds of KB). `--resume` replays it in-process; very large sessions may
  increase turn startup latency. Monitored via telemetry, not remediated here.
- Parity gap between tier-1 (savings realised) and tier-2 (no savings) widens.
  Honest documentation required.

### Neutral

- `lib/schema/validate.sh` requires no code change.
- `lib/core/cost.sh` remains estimate-only this release. Actual `usage` from
  `stream-json` is deferred to ADR-018. The 30–40 % claim is validated by comparing
  cumulative estimates across opt-in and cold-process runs, not real billing data.
- ADR-012's 6-function adapter contract is preserved (amendment: new
  `session_continuity` field in `agent_capabilities` output).

---

## Implementation Notes

### New state file: `<run_dir>/<feat>/session.json`

```json
{
  "session_id": "01J...uuid",
  "cwd": "/abs/path/to/worktree",
  "created_at": "2026-05-13T22:00:00Z",
  "last_completed_turn": "techspec",
  "agent": "claude-code"
}
```

`session_id` + `cwd` + `created_at` + `agent` written by adapter on turn 1.
`last_completed_turn` updated by pipeline after each phase passes validation.

### New env vars

| Var                            | Set by                             | Meaning                              |
| ------------------------------ | ---------------------------------- | ------------------------------------ |
| `MONOZUKURI_MULTI_TURN`        | user / `.monozukuri/config.yaml`   | `1` = opt-in                         |
| `MONOZUKURI_MULTI_TURN_ACTIVE` | `lib/run/pipeline.sh`              | `1` when flag + capability both true |
| `MONOZUKURI_SESSION_ID`        | `lib/agent/adapter-claude-code.sh` | current feature session UUID         |

### Critical files

| File                                                                | Change                                                                                                                                                        |
| ------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `docs/adr/017-multi-turn-agent-session.md`                          | this ADR (new)                                                                                                                                                |
| `lib/agent/adapter-claude-code.sh`                                  | `agent_capabilities` amendment; `_cc_session_id_for_feature` helper; `--session-id`/`--resume` dispatch; fix-schema continuation; resume-miss fallback + emit |
| `lib/agent/adapter-codex.sh`                                        | add `"session_continuity": false` to `supports`                                                                                                               |
| `lib/agent/adapter-gemini.sh`                                       | same                                                                                                                                                          |
| `lib/agent/adapter-kiro.sh`                                         | same                                                                                                                                                          |
| `lib/agent/adapter-aider.sh`                                        | same                                                                                                                                                          |
| `lib/run/pipeline.sh`                                               | capability gate → `MONOZUKURI_MULTI_TURN_ACTIVE`; write `session.json` `last_completed_turn` after each phase                                                 |
| `lib/prompt/render.sh`                                              | `render_phase_prompt` branches on `MONOZUKURI_MULTI_TURN_ACTIVE` to prefer `.continue` template                                                               |
| `lib/prompt/phases/{techspec,tasks,code,tests,pr}.continue.tmpl.md` | new, ~10 lines each                                                                                                                                           |
| `cmd/doctor.sh`                                                     | print `MONOZUKURI_MULTI_TURN` state; warn on tier-2 + multi-turn mismatch                                                                                     |
| `test/unit/multi_turn_session_helper.bats`                          | new                                                                                                                                                           |
| `test/unit/render_continue_templates.bats`                          | new                                                                                                                                                           |
| `test/integration/multi_turn_adapter.bats`                          | new                                                                                                                                                           |
| `test/integration/multi_turn_resume_miss.bats`                      | new                                                                                                                                                           |

### Validation experiment (before status → Accepted)

1. Run 3 features cold-process; record `cost.json.cumulative_tokens`.
2. Run 3 features with `MONOZUKURI_MULTI_TURN=1`; record same.
3. Average reduction ≥ 25 % and zero failed/paused → flip default on in v1.50.0.
