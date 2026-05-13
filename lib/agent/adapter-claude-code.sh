#!/bin/bash
# lib/agent/adapter-claude-code.sh — Claude Code reference adapter (ADR-012/013).
#
# Implements the six-function adapter contract. Wraps mz-* skill
# invocations with:
#   - Schema injection to worktree (.monozukuri-schemas/) before invocation
#   - Proper exit-code capture with pipefail
#   - Error envelope writing to MONOZUKURI_ERROR_FILE on failure (ADR-013)
#
# Required env vars (set by pipeline.sh before calling agent_run_phase):
#   MONOZUKURI_FEATURE_ID   feature being processed
#   MONOZUKURI_WORKTREE     absolute path to the feature worktree
#   MONOZUKURI_AUTONOMY     supervised | checkpoint | full_auto
#   MONOZUKURI_MODEL        model alias (optional; empty = config default)
#   MONOZUKURI_LOG_FILE     where to tee claude output (optional)
#   MONOZUKURI_ERROR_FILE   path for structured error envelope on failure (optional)
#   SKILL_COMMAND           deprecated; use agents.claude-code.skills.<phase> in config

# monozukuri_emit is sourced from lib/cli/emit.sh by cmd/run.sh.
# Provide a no-op stub for tests that source this adapter in isolation.
if ! declare -f monozukuri_emit &>/dev/null; then
  monozukuri_emit() { :; }
fi

# error/warn/info may be provided by the caller chain (lib/core/util.sh or similar).
# Provide lightweight stubs so this adapter works when sourced in isolation.
if ! declare -f error &>/dev/null; then
  error() { printf 'error: %s\n' "$*" >&2; }
fi

# stream_parse_emit_file is sourced from lib/cli/stream-parse.sh when available.
if ! declare -f stream_parse_emit_file &>/dev/null; then
  local _sp_sh
  _sp_sh="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/cli/stream-parse.sh"
  [[ -f "$_sp_sh" ]] && source "$_sp_sh" || true
fi
if ! declare -f stream_parse_emit_file &>/dev/null; then
  stream_parse_emit_file() { :; }
fi

agent_name() { echo "claude-code"; }

agent_capabilities() {
  printf '%s\n' '{
  "agent": "claude-code",
  "supports": {
    "phases":         ["prd","techspec","tasks","code","tests","pr"],
    "skills":              true,
    "native_edit":         true,
    "shell_access":        true,
    "mcp":                 true,
    "streaming":           true,
    "token_counting":      "exact",
    "approval_modes":      ["read-only","auto-edit","full-access"],
    "session_continuity":  true
  },
  "models": {
    "aliases": {
      "opus":     "claude-opus-4-7",
      "sonnet":   "claude-sonnet-4-6",
      "haiku":    "claude-haiku-4-5",
      "opusplan": "{plan:opus,code:sonnet}"
    },
    "default": "opusplan"
  },
  "auth": {
    "methods": ["api_key:ANTHROPIC_API_KEY", "oauth:claude.ai"],
    "verify":  "claude --version && claude auth status"
  }
}'
}

agent_doctor() {
  if ! command -v claude &>/dev/null; then
    printf 'claude CLI not found. Install: https://claude.ai/code\n' >&2
    return 1
  fi
  if ! claude auth status >/dev/null 2>&1; then
    printf 'claude not authenticated. Run: claude login\n' >&2
    return 1
  fi
  return 0
}

agent_login_hint() { printf 'claude login\n'; }

agent_estimate_tokens() {
  local prompt; prompt=$(cat)
  if declare -f cost_estimate_tokens &>/dev/null; then
    cost_estimate_tokens "$prompt"
  else
    printf '%d\n' $(( ${#prompt} / 4 ))
  fi
}

# _cc_inject_schemas <wt_path>
# Copies phase schemas into <wt_path>/.monozukuri-schemas/ (ADR-012 schema-in-prompt).
_cc_inject_schemas() {
  local wt_path="$1"
  local schemas_dir
  # Navigate: lib/agent/ → lib/ → repo-root → schemas/
  schemas_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/schemas"
  local dest="$wt_path/.monozukuri-schemas"
  mkdir -p "$dest" 2>/dev/null || return 0
  for artifact in prd techspec tasks commit-summary; do
    local src="$schemas_dir/$artifact.schema.json"
    [ -f "$src" ] && cp "$src" "$dest/" 2>/dev/null || true
  done
}

# _cc_session_id_for_feature FEAT_ID
# Returns the Claude session UUID for FEAT_ID, creating session.json on first call.
# session.json lives at $STATE_DIR/$feat_id/session.json (same dir as cost.json).
_cc_session_id_for_feature() {
  local feat_id="$1"
  local state_base="${STATE_DIR:-${MONOZUKURI_RUN_DIR:-/tmp}}"
  local session_file="${state_base}/${feat_id}/session.json"

  if [[ -f "$session_file" ]]; then
    jq -r '.session_id // empty' "$session_file" 2>/dev/null
    return
  fi

  local uuid
  uuid=$(uuidgen 2>/dev/null || python3 -c "import uuid; print(uuid.uuid4())" 2>/dev/null || \
    printf '%04x%04x-%04x-%04x-%04x-%04x%04x%04x' \
      $RANDOM $RANDOM $RANDOM $RANDOM $RANDOM $RANDOM $RANDOM $RANDOM)

  mkdir -p "${state_base}/${feat_id}"
  printf '{"session_id":"%s","cwd":"%s","created_at":"%s","last_completed_turn":"","agent":"claude-code"}\n' \
    "$uuid" "${MONOZUKURI_WORKTREE:-}" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$session_file"
  printf '%s\n' "$uuid"
}

# _cc_session_jsonl_exists SESSION_ID WT_PATH
# Returns 0 if Claude's session transcript exists for the given UUID and worktree cwd.
_cc_session_jsonl_exists() {
  local session_id="$1"
  local wt_path="$2"
  local cwd_slug
  cwd_slug=$(printf '%s' "$wt_path" | tr '/' '-')
  [[ -f "${HOME}/.claude/projects/${cwd_slug}/${session_id}.jsonl" ]]
}

# _cc_invoke_claude FEAT_ID PHASE WT_PATH LOG_FILE [flags...]
# Shared invocation wrapper. When MONOZUKURI_RUN_ID is set (TUI mode), adds
# --output-format stream-json, writes a sidecar .stream.jsonl alongside LOG_FILE,
# extracts human-readable text into LOG_FILE, and post-emits tool/file events.
# Falls back to plain text mode when not running under the TUI dispatcher.
_cc_invoke_claude() {
  local feat_id="$1" phase="$2" wt_path="$3" log_file="$4"; shift 4
  local exit_code=0

  if [ -n "${MONOZUKURI_RUN_ID:-}" ]; then
    local sj_log="${log_file%.log}.stream.jsonl"
    # Inline node script: reads stream-json from stdin, writes text content to stdout.
    local _extract_text
    _extract_text='const rl=require("readline").createInterface({input:process.stdin,terminal:false});rl.on("line",l=>{try{const e=JSON.parse(l);if(e.type==="assistant"&&e.message&&Array.isArray(e.message.content)){for(const c of e.message.content)if(c.type==="text")process.stdout.write(c.text||"")}else if(e.type==="result")process.stdout.write(e.result||"")}catch(_){process.stdout.write(l+"\n")}});'
    (
      set -o pipefail
      cd "$wt_path" && platform_claude "${SKILL_TIMEOUT_SECONDS:-1800}" \
        "$@" --output-format stream-json --verbose 2>&1 \
        | tee "$sj_log" \
        | node -e "$_extract_text" \
        | tee "$log_file" >/dev/null
    ) || exit_code=$?
    stream_parse_emit_file "$feat_id" "$phase" "$sj_log" || true
  else
    (
      set -o pipefail
      cd "$wt_path" && platform_claude "${SKILL_TIMEOUT_SECONDS:-1800}" \
        "$@" 2>&1 | tee "$log_file"
    ) || exit_code=$?
  fi

  return "$exit_code"
}

# _cc_run_phase_skill SKILL FEAT_ID WT_PATH LOG_FILE
# Native skill invocation: claude --agent <skill> -p <feat-id>.
# Used when the mz-* skill for the current phase is installed in the worktree
# or globally. The skill reads CONTEXT_JSON and MONOZUKURI_RUN_DIR from the
# environment set by pipeline.sh.
_cc_run_phase_skill() {
  local skill="$1" feat_id="$2" wt_path="$3" log_file="$4"
  local effective_model="${MONOZUKURI_MODEL:-}"
  [ "$effective_model" = "opusplan" ] && effective_model="sonnet"

  local perm_flag=""
  [ "${MONOZUKURI_AUTONOMY:-}" = "full_auto" ] && perm_flag="--dangerously-skip-permissions"

  local phase="${MONOZUKURI_PHASE:-}"

  # Prevent `gh pr create` from opening $EDITOR in full_auto.
  # 180s cap: a real hang wastes 3 min, not 30.
  if [[ "${phase}" = "pr" ]] && [[ "${MONOZUKURI_AUTONOMY:-}" = "full_auto" ]]; then
    SKILL_TIMEOUT_SECONDS=180
    export GH_PROMPT_DISABLED=1
  fi

  local artifact_dir="$wt_path/tasks/prd-$feat_id"
  mkdir -p "$artifact_dir"
  local artifact_file="$artifact_dir/${phase}.md"

  # Observability: surface allowed-tools so users see the skill's tool budget
  # before invocation. Claude Code itself enforces the SKILL.md frontmatter;
  # this only logs what the skill *declares*. No-op when the skill isn't in
  # the manifest or declares no tools.
  if declare -f skill_allowed_tools &>/dev/null; then
    local _tools
    _tools=$(skill_allowed_tools "$skill")
    if [ -n "$_tools" ] && declare -f info &>/dev/null; then
      info "skill $skill declares allowed-tools: $_tools"
    fi
  fi

  local exit_code=0
  _cc_invoke_claude "$feat_id" "$phase" "$wt_path" "$log_file" \
    ${effective_model:+--model "$effective_model"} \
    --agent "$skill" \
    $perm_flag \
    -p "$feat_id" || exit_code=$?

  [ "$exit_code" -eq 0 ] && [ -s "$log_file" ] && cp "$log_file" "$artifact_file" || true
  return "$exit_code"
}

# _cc_run_phase_render PHASE FEAT_ID WT_PATH LOG_FILE [SESSION_FLAGS]
# Template-render path: renders template → pipes to claude --print.
# Used when no native skill is installed but CONTEXT_JSON is set.
# Covers all six phases (prd, techspec, tasks, code, tests, pr).
# SESSION_FLAGS: optional "--session-id <uuid>" or "--resume <uuid>" for multi-turn mode.
_cc_run_phase_render() {
  local phase="$1" feat_id="$2" wt_path="$3" log_file="$4"
  local session_flags="${5:-}"
  local effective_model="${MONOZUKURI_MODEL:-}"
  [ "$effective_model" = "opusplan" ] && effective_model="sonnet"

  local perm_flag=""
  [ "${MONOZUKURI_AUTONOMY:-}" = "full_auto" ] && perm_flag="--dangerously-skip-permissions"

  # Source render.sh if not already loaded
  if ! declare -f render_phase_prompt &>/dev/null; then
    local _render_sh
    _render_sh="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/prompt/render.sh"
    [[ -f "$_render_sh" ]] && source "$_render_sh"
  fi

  local rendered_prompt
  rendered_prompt=$(render_phase_prompt "$phase") || return 1

  local artifact_dir="$wt_path/tasks/prd-$feat_id"
  mkdir -p "$artifact_dir"
  local artifact_file="$artifact_dir/${phase}.md"

  local exit_code=0
  # shellcheck disable=SC2086
  _cc_invoke_claude "$feat_id" "$phase" "$wt_path" "$log_file" \
    ${effective_model:+--model "$effective_model"} \
    $perm_flag \
    $session_flags \
    -p "$rendered_prompt" || exit_code=$?

  [ "$exit_code" -eq 0 ] && [ -s "$log_file" ] && cp "$log_file" "$artifact_file" || true
  return "$exit_code"
}

agent_run_phase() {
  local feat_id="${MONOZUKURI_FEATURE_ID:?agent_run_phase: MONOZUKURI_FEATURE_ID not set}"
  local wt_path="${MONOZUKURI_WORKTREE:?agent_run_phase: MONOZUKURI_WORKTREE not set}"
  local log_file="${MONOZUKURI_LOG_FILE:-/tmp/monozukuri-${feat_id}-$(date +%s).log}"

  # ADR-012: inject schemas before invoking the agent
  _cc_inject_schemas "$wt_path"

  local exit_code=0
  local phase="${MONOZUKURI_PHASE:-}"

  # fix-schema: schema-reprompt dispatched here instead of calling platform_claude
  # directly. MONOZUKURI_FIX_CONTEXT carries the humanized AJV diagnostic from
  # schema_humanize_error. Symmetric with fix-retry (ADR-012).
  # ADR-017: when multi-turn is active, send fix as a continuation on the existing session.
  if [[ "$phase" == "fix-schema" ]]; then
    local fix_context="${MONOZUKURI_FIX_CONTEXT:-Rewrite the artifact with all required sections.}"
    local fix_model="${MONOZUKURI_MODEL:-}"
    [ "$fix_model" = "opusplan" ] && fix_model="opus"
    local fix_perm_flag=""
    [ "${MONOZUKURI_AUTONOMY:-}" = "full_auto" ] && fix_perm_flag="--permission-mode bypassPermissions"
    local exit_code=0

    if [[ "${MONOZUKURI_MULTI_TURN_ACTIVE:-0}" == "1" ]] && [[ -n "${MONOZUKURI_SESSION_ID:-}" ]]; then
      # Multi-turn: resume the session and send the fix as a new turn.
      # shellcheck disable=SC2086
      _cc_invoke_claude "$feat_id" "fix-schema" "$wt_path" "$log_file" \
        ${fix_model:+--model "$fix_model"} \
        $fix_perm_flag \
        --resume "${MONOZUKURI_SESSION_ID}" \
        -p "$fix_context" || exit_code=$?
    elif [ -n "${MONOZUKURI_RUN_ID:-}" ]; then
      local _fs_sj_log="${log_file%.log}.stream.jsonl"
      local _extract_text
      _extract_text='const rl=require("readline").createInterface({input:process.stdin,terminal:false});rl.on("line",l=>{try{const e=JSON.parse(l);if(e.type==="assistant"&&e.message&&Array.isArray(e.message.content)){for(const c of e.message.content)if(c.type==="text")process.stdout.write(c.text||"")}else if(e.type==="result")process.stdout.write(e.result||"")}catch(_){process.stdout.write(l+"\n")}});'
      (
        set -o pipefail
        cd "$wt_path" && printf '%s\n' "$fix_context" | \
          platform_claude "${SKILL_TIMEOUT_SECONDS:-1800}" \
            ${fix_model:+--model "$fix_model"} \
            $fix_perm_flag \
            --print --output-format stream-json --verbose 2>&1 \
          | tee "$_fs_sj_log" | node -e "$_extract_text" | tee "$log_file" >/dev/null
      ) || exit_code=$?
      stream_parse_emit_file "$feat_id" "fix-schema" "$_fs_sj_log" || true
    else
      (
        set -o pipefail
        cd "$wt_path" && printf '%s\n' "$fix_context" | \
          platform_claude "${SKILL_TIMEOUT_SECONDS:-1800}" \
            ${fix_model:+--model "$fix_model"} \
            $fix_perm_flag \
            --print 2>&1 | tee "$log_file"
      ) || exit_code=$?
    fi
    if [ "$exit_code" -ne 0 ] && [ -n "${MONOZUKURI_ERROR_FILE:-}" ]; then
      printf '{"class":"phase","code":"fix-schema-failed","message":"fix-schema exited with code %d"}\n' \
        "$exit_code" > "$MONOZUKURI_ERROR_FILE" 2>/dev/null || true
    fi
    return "$exit_code"
  fi

  # fix-retry: Phase 3 Ralph Loop dispatched here instead of calling platform_claude
  # directly. MONOZUKURI_FIX_CONTEXT carries the prompt built by phase-3.sh.
  if [[ "$phase" == "fix-retry" ]]; then
    local fix_context="${MONOZUKURI_FIX_CONTEXT:-Fix the failing tests.}"
    local fix_model="${MONOZUKURI_MODEL:-}"
    [ "$fix_model" = "opusplan" ] && fix_model="opus"
    local fix_perm_flag=""
    [ "${MONOZUKURI_AUTONOMY:-}" = "full_auto" ] && fix_perm_flag="--permission-mode bypassPermissions"
    local exit_code=0
    if [ -n "${MONOZUKURI_RUN_ID:-}" ]; then
      local _fr_sj_log="${log_file%.log}.stream.jsonl"
      local _extract_text
      _extract_text='const rl=require("readline").createInterface({input:process.stdin,terminal:false});rl.on("line",l=>{try{const e=JSON.parse(l);if(e.type==="assistant"&&e.message&&Array.isArray(e.message.content)){for(const c of e.message.content)if(c.type==="text")process.stdout.write(c.text||"")}else if(e.type==="result")process.stdout.write(e.result||"")}catch(_){process.stdout.write(l+"\n")}});'
      (
        set -o pipefail
        cd "$wt_path" && printf '%s\n' "$fix_context" | \
          platform_claude "${SKILL_TIMEOUT_SECONDS:-1800}" \
            ${fix_model:+--model "$fix_model"} \
            $fix_perm_flag \
            --print --output-format stream-json --verbose 2>&1 \
          | tee "$_fr_sj_log" | node -e "$_extract_text" | tee "$log_file" >/dev/null
      ) || exit_code=$?
      stream_parse_emit_file "$feat_id" "fix-retry" "$_fr_sj_log" || true
    else
      (
        set -o pipefail
        cd "$wt_path" && printf '%s\n' "$fix_context" | \
          platform_claude "${SKILL_TIMEOUT_SECONDS:-1800}" \
            ${fix_model:+--model "$fix_model"} \
            $fix_perm_flag \
            --print 2>&1 | tee "$log_file"
      ) || exit_code=$?
    fi
    if [ "$exit_code" -ne 0 ] && [ -n "${MONOZUKURI_ERROR_FILE:-}" ]; then
      printf '{"class":"phase","code":"fix-retry-failed","message":"fix-retry exited with code %d"}\n' \
        "$exit_code" > "$MONOZUKURI_ERROR_FILE" 2>/dev/null || true
    fi
    return "$exit_code"
  fi

  # ADR-017: multi-turn fast path — bypass skill detection, force rendered template + session flags
  if [[ "${MONOZUKURI_MULTI_TURN_ACTIVE:-0}" == "1" ]]; then
    local _mt_session_id
    _mt_session_id=$(_cc_session_id_for_feature "$feat_id")

    local _mt_state_base="${STATE_DIR:-${MONOZUKURI_RUN_DIR:-/tmp}}"
    local _mt_session_file="${_mt_state_base}/${feat_id}/session.json"
    local _mt_last_turn=""
    [[ -f "$_mt_session_file" ]] && \
      _mt_last_turn=$(jq -r '.last_completed_turn // empty' "$_mt_session_file" 2>/dev/null || true)

    local _mt_session_flags=""
    if [[ -z "$_mt_last_turn" ]]; then
      _mt_session_flags="--session-id ${_mt_session_id}"
    elif _cc_session_jsonl_exists "$_mt_session_id" "$wt_path"; then
      _mt_session_flags="--resume ${_mt_session_id}"
    else
      monozukuri_emit session.resume_missed feature_id "$feat_id" phase "$phase" \
        session_id "$_mt_session_id"
      _mt_session_id=$(_cc_session_id_for_feature "${feat_id}-fb-$(date +%s)")
      _mt_session_flags="--session-id ${_mt_session_id}"
    fi
    export MONOZUKURI_SESSION_ID="$_mt_session_id"

    monozukuri_emit skill.invoked feature_id "$feat_id" phase "$phase" tier "mt" skill "rendered:$phase"
    _cc_run_phase_render "$phase" "$feat_id" "$wt_path" "$log_file" "$_mt_session_flags" || exit_code=$?
    if [ "$exit_code" -eq 0 ]; then
      monozukuri_emit skill.completed feature_id "$feat_id" phase "$phase" tier "mt"
    else
      monozukuri_emit skill.failed feature_id "$feat_id" phase "$phase" tier "mt" exit_code "$exit_code"
    fi

  else
    # Cold-process path: Tier 1 (native skill) → Tier 2 (rendered template) → error

    # Lazy-load skill detection helpers
    if ! declare -f phase_to_skill &>/dev/null; then
      local _detect_sh
      _detect_sh="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/skill-detect.sh"
      [[ -f "$_detect_sh" ]] && source "$_detect_sh"
    fi

    # Tier 1: native skill invocation (skill installed in worktree or globally)
    # If route-tasks.sh resolved a specialist for this phase, it wins over the
    # generic phase-mapped skill. On specialist failure, fall back to the
    # phase-mapped skill and emit skill.fallback.
    #
    # Skill resolution order (implemented in lib/agent/skill-detect.sh:skill_installed):
    #   1. <worktree>/.claude/skills/<skill>/SKILL.md   — project-local install
    #   2. ~/.claude/skills/<skill>/SKILL.md             — global install (monozukuri setup --global)
    #   3. Tier 2: template-render path (CONTEXT_JSON present, no installed skill)
    #   4. Tier 3: legacy feature-marker (no phase mapping, no context)
    # Bundled mz-* skills in the monozukuri source tree are NOT used directly here;
    # they must first be installed via `monozukuri setup` to appear at one of the paths above.
    local skill=""
    [[ -n "$phase" ]] && declare -f phase_to_skill &>/dev/null && \
      skill="$(phase_to_skill "$phase")"

    local specialist="${ROUTED_AGENT:-}"
    local default_agent="${MONOZUKURI_AGENT:-claude-code}"
    [[ "$specialist" == "$default_agent" ]] && specialist=""

    # Prefer installed specialist; fall back to phase-mapped skill if it fails
    local tier1_skill=""
    if [[ -n "$specialist" ]] && declare -f skill_installed &>/dev/null && \
       skill_installed "claude-code" "$specialist" "$wt_path"; then
      tier1_skill="$specialist"
    elif [[ -n "$skill" ]] && declare -f skill_installed &>/dev/null && \
       skill_installed "claude-code" "$skill" "$wt_path"; then
      tier1_skill="$skill"
    fi

    if [[ -n "$tier1_skill" ]]; then
      monozukuri_emit skill.invoked feature_id "$feat_id" phase "$phase" tier "1" skill "$tier1_skill"
      _cc_run_phase_skill "$tier1_skill" "$feat_id" "$wt_path" "$log_file" || exit_code=$?
      # If specialist failed, retry with the generic phase-mapped skill
      if [[ "$exit_code" -ne 0 ]] && [[ "$tier1_skill" == "$specialist" ]] && [[ -n "$skill" ]] && \
         declare -f skill_installed &>/dev/null && skill_installed "claude-code" "$skill" "$wt_path"; then
        monozukuri_emit skill.fallback feature_id "$feat_id" phase "$phase" from_skill "$tier1_skill" to_skill "$skill" exit_code "$exit_code"
        exit_code=0
        _cc_run_phase_skill "$skill" "$feat_id" "$wt_path" "$log_file" || exit_code=$?
        tier1_skill="$skill"
      fi
      if [ "$exit_code" -eq 0 ]; then
        monozukuri_emit skill.completed feature_id "$feat_id" phase "$phase" tier "1"
      else
        monozukuri_emit skill.failed feature_id "$feat_id" phase "$phase" tier "1" exit_code "$exit_code"
      fi

    # Tier 2: template-render path (any phase, when CONTEXT_JSON is available)
    elif [[ -n "$phase" ]] && [[ -n "${CONTEXT_JSON:-}" ]] && [[ -f "${CONTEXT_JSON}" ]]; then
      monozukuri_emit skill.invoked feature_id "$feat_id" phase "$phase" tier "2" skill "rendered:$phase"
      _cc_run_phase_render "$phase" "$feat_id" "$wt_path" "$log_file" || exit_code=$?
      if [ "$exit_code" -eq 0 ]; then
        monozukuri_emit skill.completed feature_id "$feat_id" phase "$phase" tier "2"
      else
        monozukuri_emit skill.failed feature_id "$feat_id" phase "$phase" tier "2" exit_code "$exit_code"
      fi

    # No skill or render template available — hard error
    else
      error "No mz-* skill or render template available for phase '${phase:-<none>}'. Install skills via 'monozukuri setup' or ensure CONTEXT_JSON points to a valid context file."
      monozukuri_emit skill.failed feature_id "$feat_id" phase "$phase" tier "0" exit_code "1" reason "no-skill-or-template"
      exit_code=1
    fi
  fi

  # ADR-013: write error envelope so policy engine can classify without log scraping
  if [ "$exit_code" -ne 0 ] && [ -n "${MONOZUKURI_ERROR_FILE:-}" ]; then
    if declare -f agent_error_classify &>/dev/null; then
      agent_error_classify "$exit_code" "$log_file" > "$MONOZUKURI_ERROR_FILE" 2>/dev/null || true
    else
      printf '{"class":"unknown","code":"exit-%d","message":"claude exited with code %d"}\n' \
        "$exit_code" "$exit_code" > "$MONOZUKURI_ERROR_FILE" 2>/dev/null || true
    fi
  fi

  # Post-success scan: agent may have exited 0 while embedding a human-input blocker.
  # Use adapter-specific regex when available, otherwise fall back to the generic scanner.
  if [ "$exit_code" -eq 0 ] && [ -s "$log_file" ]; then
    local _blocker_fn="agent_blocker_marker"
    if declare -f "$_blocker_fn" &>/dev/null; then
      local _marker
      _marker=$("$_blocker_fn")
      if grep -qiE "$_marker" "$log_file" 2>/dev/null; then
        [ -n "${MONOZUKURI_ERROR_FILE:-}" ] && \
          printf '{"class":"human","code":"agent-blocker","message":"Agent requested human input"}\n' \
          > "$MONOZUKURI_ERROR_FILE" 2>/dev/null || true
        exit_code=${EXIT_AGENT_BLOCKED:-21}
      fi
    elif declare -f agent_scan_for_blocker &>/dev/null; then
      agent_scan_for_blocker "$log_file" "${MONOZUKURI_ERROR_FILE:-}" || exit_code=${EXIT_AGENT_BLOCKED:-21}
    fi
  fi

  return "$exit_code"
}

agent_report_cost() {
  if declare -f cost_report &>/dev/null; then
    cost_report
  else
    echo "0.00"
  fi
}

# agent_native_context_files — optional 7th contract function.
# Returns JSON array of repo-relative paths this agent reads on its own.
# Conventions from these files are referenced by path rather than re-injected.
agent_native_context_files() {
  printf '%s\n' '["AGENTS.md", "CLAUDE.md", ".claude/CLAUDE.md"]'
}
