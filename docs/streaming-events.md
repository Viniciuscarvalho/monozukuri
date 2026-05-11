# Streaming events

Contract between `claude --output-format stream-json` and the monozukuri TUI.

Anthropic's stream-json format emits one JSON object per line. `lib/cli/stream-parse.sh` reads the sidecar file produced by the claude CLI and translates the subset we care about into monozukuri JSONL events that the Ink TUI subscribes to.

## Upstream event types (from claude CLI)

The Claude Code CLI emits the following stream-json types (this list is the
subset monozukuri inspects — there are others we ignore):

| Type | Carries | When |
|---|---|---|
| `message_start` | `message.usage` with `input_tokens`, `cache_*` | Once at the beginning |
| `content_block_start` | `content_block.type = "text"` or `tool_use` | Every content block |
| `content_block_delta` | `delta.text` — text being generated | Throughout generation |
| `tool_use` | `name`, `input` — tool invocation | Each tool call |
| `message_delta` | `usage.output_tokens` (cumulative) | Periodically during gen |
| `message_stop` | (terminal marker) | Once at the end |
| `result` | Wrapper-specific terminal marker | Some CLI variants |

The CLI version determines exact field names; the parser is defensive and
checks both `ev.usage` and `ev.message.usage` for the same value.

## Monozukuri events emitted

`stream_parse_emit_file` writes these line-delimited JSON records to stdout:

### Common envelope (all events)

```json
{
  "type": "<event-type>",
  "ts": "2026-05-11T00:00:00.000Z",
  "run_id": "<MONOZUKURI_RUN_ID>",
  "agent": "claude-code",
  "feature_id": "<feat-id>",
  "phase": "<phase-name>"
}
```

### `tool.invoked` / `tool.completed`

Emitted as a pair for every `tool_use` event. No separate "completed" signal
arrives from upstream, so they fire back-to-back. The TUI uses these to drive
the "Recent activity" tree in the active panel.

```json
{
  "type": "tool.invoked",
  "tool": "Read",
  "input_summary": "file_path=src/api.ts"
}
```

`input_summary` is the first two input keys truncated to 40 chars each.

### `file.touched`

Emitted alongside tool events when the tool is `Read` / `Write` / `Edit` /
`MultiEdit` / `NotebookEdit`. Lets the TUI render which files the agent has
been operating on.

```json
{
  "type": "file.touched",
  "path": "src/api.ts",
  "op": "read"
}
```

`op` is `"read"` | `"write"` | `"edit"`.

### `phase.token_update` (added in this PR)

Cumulative output-token counter, fires once per `message_delta` that carries
new token data. The TUI can subscribe to compute live token totals and
derive a rate metric.

```json
{
  "type": "phase.token_update",
  "tokens_out": 180,
  "tokens_in": 1234
}
```

The parser only emits when `tokens_out` increases, so the sequence is
monotonic. `tokens_in` is the value last seen from `message_start.message.usage`.

### `phase.completed` (added in this PR)

Final summary, fires once on `message_stop` (or `result` for wrapper variants
that emit `result` instead). Includes cache metrics so the TUI / cost
reporter can show the cache hit ratio.

```json
{
  "type": "phase.completed",
  "tokens_in": 1234,
  "tokens_out": 180,
  "tokens_total": 1414,
  "cache_creation_input_tokens": 500,
  "cache_read_input_tokens": 2000,
  "had_token_telemetry": true
}
```

`had_token_telemetry` is `false` if the upstream stream contained no usage
records at all — useful for the TUI to fall back gracefully on older CLI
versions.

## How the TUI consumes these

`bin/monozukuri` (the Node dispatcher) spawns `orchestrate.sh`, captures its
stdout, and forwards JSONL events to the Ink subprocess via the event stream.
The Ink reducer (`ui/src/reducer.ts`) maps event types to state transitions:

| Event | Reducer action |
|---|---|
| `tool.invoked` | append to `feature.recentEvents` |
| `file.touched` | dedupe + append to `feature.recentFiles` |
| `phase.token_update` | update `feature.tokensOut`, recompute `feature.tokenRate` |
| `phase.completed` | finalize `feature.tokensTotal` + `feature.costUsd` |

## Cost discipline

Per AGENTS.md: never invoke a live agent from CI. The fixtures used by
`test/unit/stream_parse_tokens.bats` are synthetic — they reproduce the
upstream wire format byte-for-byte without spending API credits.

## Not yet covered (follow-up PRs)

- **Live streaming**: today the parser runs post-hoc on the saved sidecar
  file (`stream_parse_emit_file` is called after `_cc_invoke_claude` returns).
  A follow-up PR will add a live variant that emits events as they arrive,
  so the TUI shows tool activity in real-time during phase execution.
- **Rate computation in the parser**: `tokens/min` is currently the TUI's
  responsibility (`reducer.ts`). The parser stays dumb on purpose — it
  emits raw observations and the UI decides how to render them.
- **`text_delta` aggregation**: text-generation deltas are intentionally
  ignored (they would flood the event stream). The TUI shows "spinner +
  current tool", not the literal text being generated.
