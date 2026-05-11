#!/bin/bash
# lib/cli/stream-parse.sh — Parse claude --output-format stream-json sidecar files
# and emit tool/file/token events into the monozukuri event stream.
#
# Usage: stream_parse_emit_file <feat_id> <phase> <stream_jsonl_file>
#
# Reads a stream-json sidecar file produced by claude --output-format stream-json,
# extracts events, and writes JSONL records to stdout:
#   tool.invoked       — when a tool call starts (name, input_summary)
#   tool.completed     — immediately after (stream-json has no separate completion event)
#   file.touched       — for Read/Edit/Write/MultiEdit tool calls (path, op)
#   phase.token_update — cumulative tokens_out for a message, one per delta with usage
#   phase.completed    — final totals at message_stop (tokens_in, tokens_out, totals)
#
# Day 1 deliverable for the TUI plan: gives the UI per-phase token telemetry so
# the ActivePanel can render `tokens_out` and compute a rate metric. Parsing
# remains post-hoc (runs on the saved sidecar after the phase finishes) — a
# follow-up PR will add a live-streaming variant for real-time UI updates.
#
# Event schema: see docs/streaming-events.md.
#
# Requirements: node (already a monozukuri dependency), MONOZUKURI_RUN_ID set
# (otherwise this is a no-op so direct shell invocations don't leak events).
#
# Codex/Gemini adapters: untouched — only claude-code uses stream-json.

stream_parse_emit_file() {
  local feat_id="$1"
  local phase="$2"
  local stream_file="$3"

  [ -f "$stream_file" ] || return 0
  [ -n "${MONOZUKURI_RUN_ID:-}" ] || return 0

  node - "$feat_id" "$phase" "$stream_file" <<'JSEOF'
const fs = require('fs');
const readline = require('readline');
const [,, feat_id, phase, stream_file] = process.argv;

const FILE_TOOLS = new Set(['Read', 'Write', 'Edit', 'MultiEdit', 'NotebookEdit']);
const FILE_OP = { Read: 'read', Write: 'write', Edit: 'edit', MultiEdit: 'edit', NotebookEdit: 'edit' };

function extractFilePath(name, input) {
  if (!input || typeof input !== 'object') return null;
  return input.file_path || input.path || input.notebook_path || null;
}

function emit(type, fields) {
  const ts = new Date().toISOString();
  const obj = {
    type,
    ts,
    run_id: process.env.MONOZUKURI_RUN_ID || '',
    agent: process.env.MONOZUKURI_AGENT || 'claude-code',
    feature_id: feat_id,
    phase,
    ...fields,
  };
  process.stdout.write(JSON.stringify(obj) + '\n');
}

// Anthropic stream-json carries usage in two places:
//   - message_start.message.usage         (initial accounting)
//   - message_delta.usage                 (cumulative output_tokens during gen)
// Some Claude Code wrapper variants also surface a top-level `usage` field on
// the same event types. We accept both shapes.
function readUsage(ev) {
  if (ev.usage && typeof ev.usage === 'object') return ev.usage;
  if (ev.message && ev.message.usage && typeof ev.message.usage === 'object') return ev.message.usage;
  return null;
}

// Running totals across the entire stream.
let tokensIn = 0;
let tokensOut = 0;
let cacheCreate = 0;
let cacheRead = 0;
let sawAnyToken = false;

const rl = readline.createInterface({ input: fs.createReadStream(stream_file), terminal: false });

rl.on('line', line => {
  if (!line.trim()) return;
  let ev;
  try { ev = JSON.parse(line); } catch (_) { return; }

  // ── tool / file events (existing behaviour) ─────────────────────────────
  if (ev.type === 'tool_use') {
    const name = ev.name || '';
    const input = ev.input || {};
    const inputSummary = Object.keys(input).slice(0, 2)
      .map(k => `${k}=${String(input[k]).slice(0, 40)}`).join(', ');
    emit('tool.invoked',   { tool: name, input_summary: inputSummary });
    emit('tool.completed', { tool: name });

    if (FILE_TOOLS.has(name)) {
      const fp = extractFilePath(name, input);
      if (fp) emit('file.touched', { path: fp, op: FILE_OP[name] || 'read' });
    }
    return;
  }

  // ── token telemetry (new) ───────────────────────────────────────────────
  const usage = readUsage(ev);
  if (usage) {
    if (typeof usage.input_tokens === 'number' && usage.input_tokens > tokensIn) {
      tokensIn = usage.input_tokens;
    }
    if (typeof usage.cache_creation_input_tokens === 'number') {
      cacheCreate = Math.max(cacheCreate, usage.cache_creation_input_tokens);
    }
    if (typeof usage.cache_read_input_tokens === 'number') {
      cacheRead = Math.max(cacheRead, usage.cache_read_input_tokens);
    }
    if (typeof usage.output_tokens === 'number') {
      // message_delta.usage carries the cumulative output_tokens for the
      // message — take the max so retries / mid-stream resets don't shrink it.
      const next = Math.max(tokensOut, usage.output_tokens);
      if (next !== tokensOut) {
        tokensOut = next;
        sawAnyToken = true;
        emit('phase.token_update', {
          tokens_out: tokensOut,
          tokens_in: tokensIn,
        });
      }
    }
  }

  // ── phase completion summary ────────────────────────────────────────────
  if (ev.type === 'message_stop' || ev.type === 'result') {
    emit('phase.completed', {
      tokens_in: tokensIn,
      tokens_out: tokensOut,
      tokens_total: tokensIn + tokensOut,
      cache_creation_input_tokens: cacheCreate,
      cache_read_input_tokens: cacheRead,
      had_token_telemetry: sawAnyToken,
    });
  }
});
JSEOF
}
