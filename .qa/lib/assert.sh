#!/bin/bash
# .qa/lib/assert.sh — assertion helpers for release gate layers
# All assert_* functions print a one-line failure reason to stderr and return 1 on failure.

_qa_pass() { printf '  ✓ %s\n' "$1"; }
_qa_fail() { printf '  ✗ %s\n' "$1" >&2; return 1; }

assert_eq() {
  local label="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    _qa_pass "$label"
  else
    _qa_fail "$label: expected '$expected', got '$actual'"
  fi
}

assert_not_empty() {
  local label="$1" value="$2"
  if [ -n "$value" ]; then
    _qa_pass "$label"
  else
    _qa_fail "$label: value is empty"
  fi
}

assert_file_exists() {
  local label="$1" path="$2"
  if [ -f "$path" ]; then
    _qa_pass "$label"
  else
    _qa_fail "$label: file not found: $path"
  fi
}

assert_file_nonempty() {
  local label="$1" path="$2"
  if [ -s "$path" ]; then
    _qa_pass "$label"
  else
    _qa_fail "$label: file is empty or missing: $path"
  fi
}

assert_grep() {
  local label="$1" pattern="$2" file="$3"
  if grep -qE "$pattern" "$file" 2>/dev/null; then
    _qa_pass "$label"
  else
    _qa_fail "$label: pattern '$pattern' not found in $file"
  fi
}

assert_exit0() {
  local label="$1" cmd="$2"
  local rc=0
  eval "$cmd" >/dev/null 2>&1 || rc=$?
  if [ "$rc" -eq 0 ]; then
    _qa_pass "$label"
  else
    _qa_fail "$label: '$cmd' exited $rc"
  fi
}

assert_json_valid() {
  local label="$1" file="$2"
  if python3 -c "import json, sys; json.load(open(sys.argv[1]))" "$file" 2>/dev/null; then
    _qa_pass "$label"
  else
    _qa_fail "$label: invalid JSON in $file"
  fi
}

assert_json_field() {
  local label="$1" file="$2" jq_expr="$3"
  local result
  result=$(python3 -c "
import json, sys
data = json.load(open(sys.argv[1]))
expr_parts = sys.argv[2].lstrip('.').split('.')
v = data
for p in expr_parts:
    if p and isinstance(v, dict):
        v = v.get(p)
    elif p and isinstance(v, list):
        v = v[int(p)] if p.isdigit() else None
print('ok' if v not in (None, '', [], {}) else 'empty')
" "$file" "$jq_expr" 2>/dev/null || echo "error")
  if [ "$result" = "ok" ]; then
    _qa_pass "$label"
  else
    _qa_fail "$label: field '$jq_expr' is absent/empty in $file"
  fi
}
