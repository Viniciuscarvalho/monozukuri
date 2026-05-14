# ADR-023: Opt-In Telemetry Backend

**Status:** Proposed
**Date:** 2026-05-14
**Related:** ADR-008 (Orchestrator Economy), ADR-016 (Thirteen-Week Plan)

---

`lib/cli/emit.sh`'s `monozukuri_emit` emits JSONL events to stdout when `MONOZUKURI_RUN_ID` is set (TUI mode). Events are consumed by the Ink dispatcher and never leave the local machine. There is no aggregation path to surface phase-pause rates, token spend, or per-adapter error rates across runs.

**Decision:** New `lib/cli/telemetry.sh` exposes two functions: `telemetry_consent_check()` and `telemetry_flush(events_jsonl, endpoint)`. Consent is stored per-project at `telemetry.consent: true` in `.monozukuri/config.yaml`. `monozukuri init` and `monozukuri setup` each add a one-time prompt that writes this flag; running without the flag leaves it absent (interpreted as `false`). No events are buffered or forwarded unless the flag is explicitly `true`.

**Capture path:** `monozukuri_emit` gains a secondary write: when `telemetry_consent_check()` returns true and `MONOZUKURI_RUN_ID` is set, it tees the event JSON to `.monozukuri/telemetry/<run_id>.jsonl` in addition to stdout. The tee is a fire-and-forget append (`>>`) — failure to write the buffer file is silently ignored so that a full disk or permission error cannot abort a run. Non-TUI invocations (`MONOZUKURI_RUN_ID` unset) are not captured; `monozukuri_emit` already returns early in that path and there is nothing to buffer.

**Flush:** At run exit, `pipeline.sh` calls `telemetry_flush "$STATE_DIR/telemetry/<run_id>.jsonl" "$endpoint"`. `telemetry_flush` reads the buffer file, POSTs it as `Content-Type: application/x-ndjson` via `curl --silent --max-time 10 --retry 2`, then deletes the buffer on HTTP 2xx. On any failure (network unreachable, non-2xx, timeout), it logs the failure via `monozukuri_error` severity `warn`, leaves the buffer file intact for the next run, and returns 0 so the calling pipeline is not aborted.

**Endpoint configuration:** `telemetry.endpoint` in `.monozukuri/config.yaml`. When absent, `telemetry_flush` is a no-op even if consent is present — this prevents flushing to an undefined destination.

**Why per-project consent rather than global?** Per-project consent matches the existing `.monozukuri/` scoping model: each project has its own config, its own state directory, and its own `monozukuri init` invocation. A global consent file would require reading from `~/.monozukuri/` (a path that currently has no read precedent in the shell layer) and would implicitly opt in projects that were never explicitly consented. The cost of a per-project opt-in is one extra prompt during `monozukuri init`, which already walks the user through configuration.

**Constraint:** No new shell or npm dependencies. `curl` is already a transitive requirement of any Homebrew install. The buffer file is plain JSONL — no serialisation library needed.
