# ADR-018: Real Cost from Stream-JSON Usage Field

**Status:** Proposed
**Date:** 2026-05-14
**Related:** ADR-008 (Orchestrator Economy), ADR-017 (Multi-Turn Agent Session — Consequences §neutral)

---

`lib/core/cost.sh` records estimated token counts derived from character-count baselines. The Claude CLI's `--output-format stream-json` output already carries a `usage` object with real billed token counts (`input_tokens`, `output_tokens`, `cache_read_input_tokens`). ADR-017 deferred reading these to ADR-018.

The challenge: `_cc_invoke_claude` in `adapter-claude-code.sh` writes the stream.jsonl sidecar at `${log_file%.log}.stream.jsonl` during invocation, but `cost_record` is called later by `pipeline.sh` with only `(feat_id, phase, estimate)` — no path to the sidecar.

**Decision:** After each successful claude invocation, `_cc_invoke_claude` extracts the `usage` object from the stream.jsonl sidecar and writes it to `$STATE_DIR/$feat_id/$phase.usage.json`. `cost_record` reads this file opportunistically: when present it uses real token counts; when absent (non-TUI mode, tier-2 adapters, or pre-v2 runs) it falls back to the estimate argument unchanged. No change to `cost_record`'s signature or any of its five call sites in `pipeline.sh`.

**Why not pass the sidecar path as a 4th argument to `cost_record`?** That would require changing all five call sites in `pipeline.sh` and coupling the pipeline to the sidecar naming convention. The sidecar is an adapter implementation detail; `cost_record` should remain agnostic to how usage arrives.

**Why not have `cost_record` derive the path from `STATE_DIR` directly?** Same result as A, but the convention would be implicit in `cost_record` rather than explicit in the adapter. If a future adapter uses a different path, the implicit derivation silently misses the data. The sidecar-write approach makes the handoff explicit: the adapter writes it, `cost_record` reads it from a known location per the convention documented here.

**Constraint:** The sidecar is only written when `MONOZUKURI_RUN_ID` is set (TUI mode). In non-TUI mode the fallback to estimates is silent and correct — the SLO gate already uses conservative estimates and will only improve when real data is available.
