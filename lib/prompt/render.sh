#!/bin/bash
# lib/prompt/render.sh
#
# Renders a phase prompt template into a final prompt string.
#
# A template is a markdown file with two kinds of placeholders:
#   {{VARIABLE}}                 → replaced with context.VARIABLE
#   {{#each array}}              → iterates context.array, exposing `this.field`
#     - {{this.summary}}              within the block. Closed by {{/each}}.
#   {{/each}}
#
# High-level entry point (phase name lookup):
#   render_phase_prompt [PHASE]
#     Reads PROMPT_PHASES_DIR or defaults to phases/ next to this file.
#     Reads CONTEXT_JSON env var for the context file path.
#     Falls back to sed substitution of MONOZUKURI_* env vars when CONTEXT_JSON
#     is not set (backward compat — legacy phases without a context pack).
#
# Low-level entry point (explicit paths):
#   monozukuri_render <template_path> <context_json_path>
#   echo '{"FEATURE_ID":"feat-001"}' | monozukuri_render <template_path> -
#
# Exit codes (monozukuri_render):
#   0   success — rendered prompt on stdout
#   2   misuse — bad arguments
#   10  template / context file not found
#   11  context JSON invalid
#   12  template references unknown variable (strict mode only)
#
# Dependencies: bash 4+, jq

_RENDER_SH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

monozukuri_render() {
  local template_path="${1:-}"
  local context_path="${2:-}"
  local strict="${MONOZUKURI_RENDER_STRICT:-0}"

  if [[ -z "$template_path" || -z "$context_path" ]]; then
    echo "usage: monozukuri_render <template_path> <context_json_path|->" >&2
    return 2
  fi

  [[ -f "$template_path" ]] || { echo "template not found: $template_path" >&2; return 10; }

  local context_json
  if [[ "$context_path" == "-" ]]; then
    context_json=$(cat)
  else
    [[ -f "$context_path" ]] || { echo "context not found: $context_path" >&2; return 10; }
    context_json=$(cat "$context_path")
  fi

  echo "$context_json" | jq empty 2>/dev/null || {
    echo "context JSON invalid" >&2
    return 11
  }

  local template
  template=$(cat "$template_path")

  # 1. Expand {{#each KEY}}...{{/each}} blocks first (so nested {{this.x}} are
  #    handled before simple substitution gets to them).
  template=$(_render_each_blocks "$template" "$context_json")

  # 2. Expand simple {{VARIABLE}} substitutions.
  template=$(_render_simple_vars "$template" "$context_json" "$strict")

  printf '%s\n' "$template"
}

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

# Expands every {{#each KEY}}...{{/each}} block. KEY must be an array in
# context_json. Inside the block, {{this.field}} is replaced with each item's
# field. Items can be strings (use {{this}}) or objects (use {{this.field}}).
_render_each_blocks() {
  local tmpl="$1"
  local ctx="$2"

  # Use awk to find blocks because they're multi-line.
  # Output sentinels mark replacement points; we replace them after rendering.
  local marker="__MZ_EACH_$$_"
  local idx=0

  # Pull out each block to a temp file, replace with sentinel.
  local blocks_file
  blocks_file=$(mktemp)

  # awk extracts blocks and substitutes sentinels in tmpl
  # Parentheses around redirect targets prevent awk parsing > as comparison.
  tmpl=$(awk -v M="$marker" -v BF="$blocks_file" '
    BEGIN { in_block = 0; idx = 0 }
    /\{\{#each [a-zA-Z_][a-zA-Z0-9_]*\}\}/ {
      if (!in_block) {
        match($0, /\{\{#each [a-zA-Z_][a-zA-Z0-9_]*\}\}/)
        prefix = substr($0, 1, RSTART - 1)
        key_full = substr($0, RSTART, RLENGTH)
        suffix = substr($0, RSTART + RLENGTH)
        # Extract the key name
        gsub(/\{\{#each |\}\}/, "", key_full)
        printf "%s%s%d%s\n", prefix, M, idx, "__END__"
        # Begin capturing
        print key_full > (BF "_keys_" idx)
        in_block = 1
        block_idx = idx
        block_buf = suffix "\n"
        next
      }
    }
    /\{\{\/each\}\}/ {
      if (in_block) {
        # Capture content before {{/each}}
        match($0, /\{\{\/each\}\}/)
        block_buf = block_buf substr($0, 1, RSTART - 1)
        suffix = substr($0, RSTART + RLENGTH)
        printf "%s", block_buf > (BF "_body_" block_idx)
        close(BF "_body_" block_idx)
        in_block = 0
        # The sentinel for this block was already emitted above; just continue
        idx++
        printf "%s\n", suffix
        next
      }
    }
    {
      if (in_block) {
        block_buf = block_buf $0 "\n"
      } else {
        print
      }
    }
  ' <<<"$tmpl")

  # For each captured block, render it against its array and substitute back.
  local i=0
  while [[ -f "${blocks_file}_keys_${i}" ]]; do
    local key body rendered
    key=$(cat "${blocks_file}_keys_${i}")
    body=$(cat "${blocks_file}_body_${i}")
    rendered=$(_render_each_iteration "$body" "$ctx" "$key")
    # Substitute the sentinel with rendered content.
    # Bash string replacement handles multi-line values in $rendered correctly
    # (awk -v cannot pass newlines in variable values).
    local sentinel="${marker}${i}__END__"
    tmpl="${tmpl//${sentinel}/${rendered}}"
    rm -f "${blocks_file}_keys_${i}" "${blocks_file}_body_${i}"
    ((i++))
  done

  rm -f "$blocks_file" 2>/dev/null || true
  printf '%s' "$tmpl"
}

# Iterates over context_json[key] (must be an array) and renders body for each
# item, replacing {{this}} or {{this.<field>}} with item value or item.field.
_render_each_iteration() {
  local body="$1"
  local ctx="$2"
  local key="$3"

  local count
  count=$(echo "$ctx" | jq -r --arg k "$key" 'getpath([$k]) | if type == "array" then length else 0 end')

  local out=""
  local i=0
  while [[ $i -lt $count ]]; do
    local item iter_body
    item=$(echo "$ctx" | jq -c --arg k "$key" --argjson i "$i" '.[$k][$i]')
    iter_body="$body"

    # Replace {{this.field}} for object items
    while [[ "$iter_body" =~ \{\{this\.([a-zA-Z_][a-zA-Z0-9_]*)\}\} ]]; do
      local field="${BASH_REMATCH[1]}"
      local value
      value=$(echo "$item" | jq -r --arg f "$field" '.[$f] // ""')
      iter_body="${iter_body//\{\{this.${field}\}\}/$value}"
    done

    # Replace {{this}} for scalar items
    if [[ "$iter_body" == *"{{this}}"* ]]; then
      local scalar
      scalar=$(echo "$item" | jq -r '. // ""')
      iter_body="${iter_body//\{\{this\}\}/$scalar}"
    fi

    out+="$iter_body"
    ((i++))
  done

  printf '%s' "$out"
}

# Replaces every {{VAR}} with context.VAR.
# Unknown variables (not present in context) are left intact so agent
# fill-in placeholders like {{PROBLEM_STATEMENT}} survive rendering.
# In strict mode (MONOZUKURI_RENDER_STRICT=1), unknown variables are an error.
_render_simple_vars() {
  local tmpl="$1"
  local ctx="$2"
  local strict="$3"

  # Find all unique {{VAR}} references
  local vars
  vars=$(grep -oE '\{\{[a-zA-Z_][a-zA-Z0-9_]*\}\}' <<<"$tmpl" | sort -u || true)

  local var name value
  while IFS= read -r var; do
    [[ -z "$var" ]] && continue
    name="${var#\{\{}"
    name="${name%\}\}}"
    value=$(echo "$ctx" | jq -r --arg k "$name" 'getpath([$k]) // empty')

    if [[ -z "$value" ]]; then
      if [[ "$strict" == "1" ]]; then
        echo "missing context variable: $name" >&2
        return 12
      fi
      # Non-strict: leave unknown tokens intact (they are agent fill-in placeholders)
      continue
    fi

    # Use a delimiter unlikely to appear; perl-free portable replacement.
    tmpl="${tmpl//\{\{${name}\}\}/${value}}"
  done <<<"$vars"

  printf '%s' "$tmpl"
}

# ---------------------------------------------------------------------------
# render_phase_prompt PHASE — high-level wrapper for pipeline.sh / adapters.
#
# Looks up the template by phase name and renders it.
#   - If CONTEXT_JSON env var is set and the file exists → monozukuri_render
#   - Otherwise → legacy sed substitution of MONOZUKURI_* env vars
# ---------------------------------------------------------------------------

# _render_sed_escape VAL — escapes a value for safe insertion into a sed s|...|RHS|
_render_sed_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/|/\\|/g'
}

render_phase_prompt() {
  local phase="${1:-${MONOZUKURI_PHASE:-prd}}"
  local prompt_dir="${PROMPT_PHASES_DIR:-${_RENDER_SH_DIR}/phases}"
  local tmpl="${prompt_dir}/${phase}.tmpl.md"

  if [[ ! -f "$tmpl" ]]; then
    printf 'render_phase_prompt: no template for phase "%s" (looked in %s)\n' \
      "$phase" "$prompt_dir" >&2
    return 1
  fi

  # Rich rendering path: jq-based when CONTEXT_JSON is set
  if [[ -n "${CONTEXT_JSON:-}" ]] && [[ -f "${CONTEXT_JSON}" ]]; then
    monozukuri_render "$tmpl" "$CONTEXT_JSON"
    return $?
  fi

  # Legacy sed rendering path (backward compat — no context pack)
  sed \
    -e "s|{{MONOZUKURI_FEATURE_ID}}|$(_render_sed_escape "${MONOZUKURI_FEATURE_ID:-}")|g" \
    -e "s|{{FEATURE_ID}}|$(_render_sed_escape "${MONOZUKURI_FEATURE_ID:-}")|g" \
    -e "s|{{MONOZUKURI_PHASE}}|$(_render_sed_escape "${phase}")|g" \
    -e "s|{{MONOZUKURI_AUTONOMY}}|$(_render_sed_escape "${MONOZUKURI_AUTONOMY:-supervised}")|g" \
    -e "s|{{MONOZUKURI_WORKTREE}}|$(_render_sed_escape "${MONOZUKURI_WORKTREE:-}")|g" \
    -e "s|{{MONOZUKURI_RUN_DIR}}|$(_render_sed_escape "${MONOZUKURI_RUN_DIR:-}")|g" \
    -e "s|{{MONOZUKURI_MODEL}}|$(_render_sed_escape "${MONOZUKURI_MODEL:-}")|g" \
    -e "s|{{FEATURE_TITLE}}|$(_render_sed_escape "${FEATURE_TITLE:-}")|g" \
    -e "s|{{FEATURE_DESCRIPTION}}|$(_render_sed_escape "${FEATURE_DESCRIPTION:-}")|g" \
    -e "s|{{LEARNINGS_BLOCK}}|$(_render_sed_escape "${LEARNINGS_BLOCK:-No prior learnings.}")|g" \
    "$tmpl"
}

# ---------------------------------------------------------------------------
# Self-test (run when invoked directly with --self-test)
# ---------------------------------------------------------------------------

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  set -euo pipefail

  if [[ "${1:-}" == "--self-test" ]]; then
    tmp_dir=$(mktemp -d)
    trap "rm -rf $tmp_dir" EXIT

    cat >"$tmp_dir/tmpl.md" <<'EOF'
# {{FEATURE_ID}}: {{FEATURE_TITLE}}

## Conventions
{{#each project_learnings}}
- {{this.summary}}
{{/each}}

Stack: {{STACK}}
EOF

    cat >"$tmp_dir/ctx.json" <<'EOF'
{
  "FEATURE_ID": "feat-042",
  "FEATURE_TITLE": "Add OAuth refresh-token rotation",
  "STACK": "Node 18 + TypeScript",
  "project_learnings": [
    {"summary": "This codebase uses zod for validation"},
    {"summary": "All HTTP handlers return Result<T, E>"}
  ]
}
EOF

    actual=$(monozukuri_render "$tmp_dir/tmpl.md" "$tmp_dir/ctx.json")

    if [[ "$actual" == *"feat-042: Add OAuth refresh-token rotation"* \
       && "$actual" == *"This codebase uses zod for validation"* \
       && "$actual" == *"All HTTP handlers return Result<T, E>"* \
       && "$actual" == *"Stack: Node 18 + TypeScript"* ]]; then
      echo "self-test passed"
      exit 0
    else
      echo "self-test FAILED"
      echo "--- actual ---"
      echo "$actual"
      exit 1
    fi
  fi

  # Direct invocation: render the given template + context
  monozukuri_render "$@"
fi
