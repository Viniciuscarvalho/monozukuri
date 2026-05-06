#!/bin/bash
# lib/cli/stream-parse.sh — Parse claude --output-format stream-json sidecar files
# and emit tool/file events into the monozukuri event stream.
#
# Usage: stream_parse_emit_file <feat_id> <phase> <stream_jsonl_file>
#
# Reads a stream-json sidecar file produced by claude --output-format stream-json,
# extracts tool_use events, and calls monozukuri_emit for each:
#   tool.invoked  — when a tool call starts
#   tool.completed — immediately after (stream-json has no separate completion event)
#   file.touched  — for Read/Edit/Write/MultiEdit tool calls (includes file path)
#
# Requirements: node (already a monozukuri dependency), monozukuri_emit (from emit.sh)
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
  const obj = { type, ts, run_id: process.env.MONOZUKURI_RUN_ID || '', agent: process.env.MONOZUKURI_AGENT || 'claude-code', feature_id: feat_id, phase, ...fields };
  process.stdout.write(JSON.stringify(obj) + '\n');
}

const rl = readline.createInterface({ input: fs.createReadStream(stream_file), terminal: false });
rl.on('line', line => {
  if (!line.trim()) return;
  let ev;
  try { ev = JSON.parse(line); } catch (_) { return; }

  if (ev.type === 'tool_use') {
    const name = ev.name || '';
    const input = ev.input || {};
    const inputSummary = Object.keys(input).slice(0, 2).map(k => `${k}=${String(input[k]).slice(0, 40)}`).join(', ');
    emit('tool.invoked', { tool: name, input_summary: inputSummary });
    emit('tool.completed', { tool: name });

    if (FILE_TOOLS.has(name)) {
      const fp = extractFilePath(name, input);
      if (fp) emit('file.touched', { path: fp, op: FILE_OP[name] || 'read' });
    }
  }
});
JSEOF
}
