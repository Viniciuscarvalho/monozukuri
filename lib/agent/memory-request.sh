#!/bin/bash
# lib/agent/memory-request.sh — Structured Memory v2 escalation marker parser.

agent_parse_memory_requests_generic() {
  local response=""
  if [ "$#" -gt 0 ]; then
    response="$1"
  else
    response=$(cat)
  fi

  local response_file
  response_file=$(mktemp)
  printf '%s' "$response" > "$response_file"
  node - "$response_file" <<'JSEOF'
const fs = require('fs');
const response = fs.readFileSync(process.argv[2], 'utf8');
const prefix = response.match(/^\s*(?:(?:<request-memory\s+id=["'][A-Za-z0-9_.:-]+["']\s*\/>\s*)+)/);
if (!prefix) process.exit(0);
const seen = new Set();
for (const match of prefix[0].matchAll(/<request-memory\s+id=["']([A-Za-z0-9_.:-]+)["']\s*\/>/g)) {
  if (!seen.has(match[1])) {
    console.log(match[1]);
    seen.add(match[1]);
  }
}
JSEOF
  local rc=$?
  rm -f "$response_file" 2>/dev/null || true
  return "$rc"
}
