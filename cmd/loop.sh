#!/bin/bash
# cmd/loop.sh — sub_loop(): sequential non-interactive feature loop
# Sourced by orchestrate.sh; inherits SCRIPT_DIR, LIB_DIR, CMD_DIR,
# SCRIPTS_DIR, TEMPLATES_DIR, PROJECT_ROOT, ROOT_DIR, CONFIG_DIR,
# STATE_DIR, RESULTS_DIR, and all OPT_* variables.

_loop_bootstrap_modules() {
  if [ -f "$LIB_DIR/cli/emit.sh" ]; then
    source "$LIB_DIR/cli/emit.sh"
  else
    monozukuri_emit() { :; }
  fi

  source "$LIB_DIR/core/modules.sh"
  modules_init "$LIB_DIR"

  module_require core/util
  module_require config/load
  module_require core/worktree
  module_require memory/memory
  module_require cli/output
  module_require core/json-io
  module_require core/stack-profile
  module_require core/feature-state
  module_require core/platform
  module_require core/cost
  module_require core/router
  source "$LIB_DIR/agent/contract.sh"
  module_require memory/learning
  module_require run/size-gate
  module_require run/cycle-gate
  module_optional run/local-model "local_model::embed" "local_model::classify" \
                                  "local_model::summarize" "local_model::generate"
  module_optional run/ingest "ingest_trigger_if_merged" "ingest_reap_stale"
  module_optional run/injection-screen "sanitize_with_local_model"
  module_require prompt/sanitize
  module_require schema/validate
  module_require agent/error
  module_require run/policy
  module_require run/manifest
  module_require run/ci-poll
  module_require run/routing
  module_require run/dep-check
  module_require run/implicit-dep
  module_require prompt/context-pack
  module_require prompt/render
  module_require agent/registry
  module_require run/pause
  module_require run/phase-3
  module_require run/phase-4
  module_require run/pipeline
}

_loop_resolve_config_file() {
  local config_file="$OPT_CONFIG"
  if [ ! -f "$config_file" ]; then
    if [ -f ".monozukuri/config.yaml" ]; then
      config_file=".monozukuri/config.yaml"
    elif [ -f ".monozukuri/config.yml" ]; then
      config_file=".monozukuri/config.yml"
    elif [ -f "$TEMPLATES_DIR/config.yaml" ]; then
      config_file="$TEMPLATES_DIR/config.yaml"
    fi
  fi
  printf '%s\n' "$config_file"
}

_loop_make_run_id() {
  local rand
  rand=$(od -An -N3 -tx1 /dev/urandom 2>/dev/null | tr -d ' \n')
  [ -n "$rand" ] || rand=$(printf '%06d' "$$")
  printf 'loop-%s-%s\n' "$(date +%Y-%m-%d)" "$rand"
}

_loop_collect_ids() {
  local ids="${OPT_LOOP_IDS:-}"
  if [ -z "$ids" ] && [ ! -t 0 ]; then
    local line trimmed
    while IFS= read -r line; do
      trimmed=$(printf '%s' "$line" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
      [ -z "$trimmed" ] && continue
      if [ -n "$ids" ]; then
        ids="${ids},$trimmed"
      else
        ids="$trimmed"
      fi
    done
  fi
  printf '%s\n' "$ids"
}

_loop_item_for_id() {
  local backlog_file="$1" feat_id="$2"
  node - "$backlog_file" "$feat_id" <<'JSEOF'
const [,, backlogFile, featureId] = process.argv;
const fs = require('fs');
const items = JSON.parse(fs.readFileSync(backlogFile, 'utf8'));
const item = items.find((entry) => entry.id === featureId);
if (!item) process.exit(1);
process.stdout.write(JSON.stringify(item));
JSEOF
}

_loop_pr_label() {
  local feat_id="$1" status="$2"
  local pr_url pr_num
  pr_url=$(fstate_get_pr_url "$feat_id")
  if [ -n "$pr_url" ]; then
    pr_num="${pr_url##*/}"
    printf 'PR #%s\n' "$pr_num"
  elif [ "$status" = "done" ]; then
    printf 'done\n'
  else
    printf '%s\n' "$status"
  fi
}

_loop_validate_caps() {
  local max_cost="$1" max_time="$2" max_tokens="$3"

  if ! awk -v n="$max_cost" 'BEGIN { exit !(n ~ /^[0-9]+([.][0-9]+)?$/ && n > 0) }'; then
    err "--max-cost must be a positive USD amount"
    return 1
  fi
  if ! awk -v n="$max_time" 'BEGIN { exit !(n ~ /^[0-9]+$/ && n > 0) }'; then
    err "--max-time must be a positive integer number of minutes"
    return 1
  fi
  if ! awk -v n="$max_tokens" 'BEGIN { exit !(n ~ /^[0-9]+$/ && n > 0) }'; then
    err "--max-tokens-per-task must be a positive integer"
    return 1
  fi
  if [ "${OPT_LOOP_MAX_COST_EXPLICIT:-false}" != "true" ] && \
     ! awk -v n="$max_cost" 'BEGIN { exit !(n <= 50) }'; then
    err "--max-cost without an explicit override is capped at 50 USD"
    return 1
  fi
  if [ "${OPT_LOOP_MAX_TIME_EXPLICIT:-false}" != "true" ] && \
     [ "$max_time" -gt 1440 ]; then
    err "--max-time without an explicit override is capped at 1440 minutes"
    return 1
  fi
  if [ "$max_tokens" -gt 500000 ]; then
    err "--max-tokens-per-task hard ceiling is 500000"
    return 1
  fi
}

_loop_model_for_agent() {
  local agent="$1" model="${2:-}"
  case "$agent" in
    claude-code)
      case "$model" in
        opus) echo "claude-opus-4-7" ;;
        haiku) echo "claude-haiku-4-5" ;;
        claude-*) echo "$model" ;;
        *) echo "claude-sonnet-4-6" ;;
      esac
      ;;
    codex)
      case "$model" in
        gpt-*) echo "$model" ;;
        mini) echo "gpt-5.4-mini" ;;
        *) echo "gpt-5.5" ;;
      esac
      ;;
    gemini)
      case "$model" in
        gemini-*) echo "$model" ;;
        flash) echo "gemini-2.5-flash" ;;
        *) echo "gemini-2.5-pro" ;;
      esac
      ;;
    *) echo "$model" ;;
  esac
}

_loop_validate_failure_mode() {
  local mode="$1"
  case "$mode" in
    continue|stop|pause) return 0 ;;
    *)
      err "--on-failure must be one of: continue, stop, pause"
      return 1
      ;;
  esac
}

_loop_validate_circuit_breaker() {
  local limit="$1"
  if ! awk -v n="$limit" 'BEGIN { exit !(n ~ /^[0-9]+$/) }'; then
    err "--circuit-breaker must be a non-negative integer"
    return 1
  fi
  if [ "$limit" -eq 0 ] && [ "${OPT_LOOP_I_KNOW_WHAT_IM_DOING:-false}" != "true" ]; then
    err "--circuit-breaker 0 disables a safety guard; pass --i-know-what-im-doing to confirm"
    return 1
  fi
}

_loop_default_failure_mode() {
  local autonomy="$1"
  case "$autonomy" in
    full_auto) echo "continue" ;;
    checkpoint|supervised) echo "pause" ;;
    *) echo "continue" ;;
  esac
}

_loop_prompt_failure_action() {
  local feat_id="$1" action
  LOOP_PAUSE_ACTION="abort"
  while true; do
    printf 'Feature %s failed. Choose retry/skip/abort: ' "$feat_id"
    IFS= read -r action || action="abort"
    case "$action" in
      retry|skip|abort)
        LOOP_PAUSE_ACTION="$action"
        return 0
        ;;
      *)
        printf 'Invalid choice: %s. Expected retry, skip, or abort.\n' "$action"
        ;;
    esac
  done
}

_loop_cost_init() {
  local cost_file="$1" loop_run_id="$2" max_cost="$3" max_time="$4" max_tokens="$5"
  node - "$cost_file" "$loop_run_id" "$max_cost" "$max_time" "$max_tokens" <<'JSEOF'
const [,, costFile, runId, maxCost, maxTime, maxTokens] = process.argv;
const fs = require('fs');
fs.writeFileSync(costFile, JSON.stringify({
  run_id: runId,
  status: 'running',
  started_at: new Date().toISOString(),
  limit_usd: Number(maxCost),
  limit_minutes: Number(maxTime),
  max_tokens_per_task: Number(maxTokens),
  total_usd: 0,
  total_tokens: 0,
  phase_events: [],
  features: []
}, null, 2));
JSEOF
}

_loop_cost_record_feature() {
  local cost_file="$1" feat_id="$2" feature_cost_file="$3" status="$4"
  node - "$cost_file" "$feat_id" "$feature_cost_file" "$status" <<'JSEOF'
const [,, costFile, featId, featureCostFile, status] = process.argv;
const fs = require('fs');
const data = JSON.parse(fs.readFileSync(costFile, 'utf8'));
let feature = { cumulative_tokens: 0, cumulative_usd: 0, phases: [] };
try {
  feature = JSON.parse(fs.readFileSync(featureCostFile, 'utf8'));
} catch (_) {}
const entry = {
  id: featId,
  status,
  tokens: Number(feature.cumulative_tokens || 0),
  usd: Number(feature.cumulative_usd || 0),
  phases: Array.isArray(feature.phases) ? feature.phases : [],
  recorded_at: new Date().toISOString()
};
data.features.push(entry);
data.total_tokens = data.features.reduce((sum, f) => sum + Number(f.tokens || 0), 0);
data.total_usd = Number(data.features.reduce((sum, f) => sum + Number(f.usd || 0), 0).toFixed(4));
data.updated_at = new Date().toISOString();
fs.writeFileSync(costFile, JSON.stringify(data, null, 2));
JSEOF
}

_loop_cost_record_circuit_breaker() {
  local cost_file="$1" limit="$2" consecutive_failures="$3" failed_feature_ids="$4"
  node - "$cost_file" "$limit" "$consecutive_failures" "$failed_feature_ids" <<'JSEOF'
const [,, costFile, limit, consecutiveFailures, failedFeatureIds] = process.argv;
const fs = require('fs');
const data = JSON.parse(fs.readFileSync(costFile, 'utf8'));
data.circuit_breaker = {
  tripped: true,
  limit: Number(limit),
  consecutive_failures: Number(consecutiveFailures),
  failed_feature_ids: failedFeatureIds ? failedFeatureIds.split(',').filter(Boolean) : [],
  resume_requires: '--circuit-breaker 0 --i-know-what-im-doing'
};
data.updated_at = new Date().toISOString();
fs.writeFileSync(costFile, JSON.stringify(data, null, 2));
JSEOF
}

_loop_cost_finalize() {
  local cost_file="$1" status="$2" elapsed_seconds="$3" reason="${4:-}"
  node - "$cost_file" "$status" "$elapsed_seconds" "$reason" <<'JSEOF'
const [,, costFile, status, elapsedSeconds, reason] = process.argv;
const fs = require('fs');
const data = JSON.parse(fs.readFileSync(costFile, 'utf8'));
data.status = status;
data.elapsed_seconds = Number(elapsedSeconds);
if (reason) data.reason = reason;
data.finished_at = new Date().toISOString();
fs.writeFileSync(costFile, JSON.stringify(data, null, 2));
JSEOF
}

_loop_cost_field() {
  local cost_file="$1" field="$2"
  node -p "try{JSON.parse(require('fs').readFileSync('$cost_file','utf8'))['$field']||0}catch(e){0}" \
    2>/dev/null || echo "0"
}

sub_loop() {
  trap 'exit 130' INT

  _loop_bootstrap_modules

  # Reuse run's incompatible-skill guard without invoking sub_run.
  if ! declare -f _run_check_incompatible_skills >/dev/null 2>&1; then
    source "$CMD_DIR/run.sh"
  fi

  local config_file
  config_file=$(_loop_resolve_config_file)
  load_config "$config_file"

  if declare -f routing_load >/dev/null 2>&1; then
    routing_load "$ROOT_DIR"
  fi

  local loop_run_id
  loop_run_id=$(_loop_make_run_id)
  WORKTREE_ROOT="$ROOT_DIR/.monozukuri/worktrees/$loop_run_id"
  AUTO_CLEANUP=false
  if [ "${OPT_LOOP_CLEANUP:-false}" = "true" ]; then
    AUTO_CLEANUP=true
  fi
  BRANCH_PREFIX="${BRANCH_PREFIX:-feat}/$loop_run_id"

  export ROOT_DIR CONFIG_DIR STATE_DIR RESULTS_DIR WORKTREE_ROOT
  export WORKTREE_BASE BRANCH_PREFIX BASE_BRANCH ADAPTER AUTONOMY MODEL_DEFAULT MODEL_PLAN MODEL_EXECUTE
  mkdir -p "$STATE_DIR" "$RESULTS_DIR" "$WORKTREE_ROOT" "$CONFIG_DIR/runs/$loop_run_id"

  local max_cost="${OPT_LOOP_MAX_COST:-10}"
  local max_time="${OPT_LOOP_MAX_TIME:-480}"
  local max_tokens="${OPT_LOOP_MAX_TOKENS_PER_TASK:-100000}"
  _loop_validate_caps "$max_cost" "$max_time" "$max_tokens" || return 1
  local on_failure="${OPT_LOOP_ON_FAILURE:-}"
  [ -n "$on_failure" ] || on_failure=$(_loop_default_failure_mode "$AUTONOMY")
  _loop_validate_failure_mode "$on_failure" || return 1
  local circuit_breaker="${OPT_LOOP_CIRCUIT_BREAKER:-3}"
  _loop_validate_circuit_breaker "$circuit_breaker" || return 1

  MONOZUKURI_MAX_FEATURE_TOKENS="$max_tokens"
  MODEL_AGENT="${MONOZUKURI_AGENT:-claude-code}"
  MODEL_PRIMARY=$(_loop_model_for_agent "$MODEL_AGENT" "${MODEL_DEFAULT:-}")
  export MONOZUKURI_MAX_FEATURE_TOKENS MODEL_AGENT MODEL_PRIMARY

  local loop_cost_file="$CONFIG_DIR/runs/$loop_run_id/cost.json"
  _loop_cost_init "$loop_cost_file" "$loop_run_id" "$max_cost" "$max_time" "$max_tokens"
  MONOZUKURI_LOOP_COST_FILE="$loop_cost_file"
  export MONOZUKURI_LOOP_COST_FILE

  _run_check_incompatible_skills
  mem_refresh_env

  local ids_csv
  ids_csv=$(_loop_collect_ids)
  if [ -z "$ids_csv" ]; then
    err "No feature IDs provided."
    err "Usage: monozukuri loop <id...> or pipe IDs on stdin"
    return 1
  fi

  run_adapter >/dev/null
  local backlog_file="$ROOT_DIR/$BACKLOG_OUTPUT"

  local ids=()
  local IFS_ORIG="$IFS"
  IFS=","
  read -r -a ids <<< "$ids_csv"
  IFS="$IFS_ORIG"

  local total="${#ids[@]}"
  local index=0 any_failed=0 cap_reached=0 cap_reason="" failure_stopped=0 failure_stop_reason=""
  local circuit_tripped=0 circuit_message="" consecutive_failures=0 consecutive_failed_ids=""
  local loop_started_at
  loop_started_at=$(date +%s)
  local feat_id item_json title body priority labels deps next_feat_id
  for feat_id in "${ids[@]}"; do
    index=$((index + 1))
    feat_id=$(printf '%s' "$feat_id" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
    [ -z "$feat_id" ] && continue

    local elapsed_now
    elapsed_now=$(( $(date +%s) - loop_started_at ))
    if [ "$elapsed_now" -ge $(( max_time * 60 )) ]; then
      cap_reached=1
      cap_reason="time"
      break
    fi

    if ! item_json=$(_loop_item_for_id "$backlog_file" "$feat_id"); then
      printf '[%d/%d] %s ✗ not found\n' "$index" "$total" "$feat_id"
      any_failed=1
      consecutive_failures=$((consecutive_failures + 1))
      if [ -n "$consecutive_failed_ids" ]; then
        consecutive_failed_ids="${consecutive_failed_ids},$feat_id"
      else
        consecutive_failed_ids="$feat_id"
      fi
      if [ "$circuit_breaker" -gt 0 ] && [ "$consecutive_failures" -ge "$circuit_breaker" ]; then
        circuit_tripped=1
        circuit_message="Circuit breaker tripped: $consecutive_failures consecutive failures"
        printf '%s\n' "$circuit_message"
        printf '%s\n' "$circuit_message" >&2
        _loop_cost_record_circuit_breaker "$loop_cost_file" "$circuit_breaker" "$consecutive_failures" "$consecutive_failed_ids"
        break
      fi
      continue
    fi

    title=$(echo "$item_json"    | node -p "JSON.parse(require('fs').readFileSync('/dev/stdin','utf-8')).title")
    body=$(echo "$item_json"     | node -p "JSON.parse(require('fs').readFileSync('/dev/stdin','utf-8')).body")
    priority=$(echo "$item_json" | node -p "JSON.parse(require('fs').readFileSync('/dev/stdin','utf-8')).priority")
    labels=$(echo "$item_json"   | node -p "JSON.parse(require('fs').readFileSync('/dev/stdin','utf-8')).labels.join(', ')")
    deps=$(echo "$item_json"     | node -p "JSON.parse(require('fs').readFileSync('/dev/stdin','utf-8')).dependencies.join(', ')||'none'")

    next_feat_id=""
    if [ "$index" -lt "$total" ]; then
      next_feat_id="${ids[$index]}"
    fi

    local loop_log="$CONFIG_DIR/runs/$loop_run_id/$feat_id/loop.log"
    mkdir -p "$(dirname "$loop_log")"

    local retry_feature="true"
    while [ "$retry_feature" = "true" ]; do
      retry_feature="false"
      local feature_exit=0
      run_feature "$feat_id" "$title" "$body" "$priority" "$labels" "$deps" "$index" "$total" "$next_feat_id" \
        >"$loop_log" 2>&1 || feature_exit=$?

      local final_status label
      final_status=$(fstate_get_status "$feat_id")
      _loop_cost_record_feature "$loop_cost_file" "$feat_id" "$STATE_DIR/$feat_id/cost.json" "$final_status"

      if { [ "$feature_exit" -eq 0 ] && [ "$final_status" = "done" ]; } || [ "$final_status" = "pr-created" ]; then
        label=$(_loop_pr_label "$feat_id" "$final_status")
        printf '[%d/%d] %s ✓ %s\n' "$index" "$total" "$feat_id" "$label"
        consecutive_failures=0
        consecutive_failed_ids=""
      else
        [ -n "$final_status" ] || final_status="failed"
        if [ "$final_status" != "failed" ]; then
          fstate_transition "$feat_id" "failed" "loop-feature-failed"
          final_status="failed"
        fi
        printf '[%d/%d] %s ✗ %s\n' "$index" "$total" "$feat_id" "$final_status"
        consecutive_failures=$((consecutive_failures + 1))
        if [ -n "$consecutive_failed_ids" ]; then
          consecutive_failed_ids="${consecutive_failed_ids},$feat_id"
        else
          consecutive_failed_ids="$feat_id"
        fi
        if [ "$circuit_breaker" -gt 0 ] && [ "$consecutive_failures" -ge "$circuit_breaker" ]; then
          any_failed=1
          circuit_tripped=1
          circuit_message="Circuit breaker tripped: $consecutive_failures consecutive failures"
          printf '%s\n' "$circuit_message"
          printf '%s\n' "$circuit_message" >&2
          _loop_cost_record_circuit_breaker "$loop_cost_file" "$circuit_breaker" "$consecutive_failures" "$consecutive_failed_ids"
          break
        fi

        case "$on_failure" in
          continue)
            any_failed=1
            ;;
          stop)
            any_failed=1
            failure_stopped=1
            failure_stop_reason="$feat_id"
            ;;
          pause)
            if [ ! -t 0 ]; then
              any_failed=1
              failure_stopped=1
              failure_stop_reason="$feat_id"
              printf 'Loop pause requested but stdin is not a TTY; stopping after failure: %s.\n' "$feat_id"
            else
              local pause_action
              _loop_prompt_failure_action "$feat_id"
              pause_action="$LOOP_PAUSE_ACTION"
              case "$pause_action" in
                retry)
                  retry_feature="true"
                  ;;
                skip)
                  any_failed=1
                  ;;
                abort)
                  any_failed=1
                  failure_stopped=1
                  failure_stop_reason="$feat_id"
                  ;;
              esac
            fi
            ;;
        esac
      fi
    done

    if [ "$AUTO_CLEANUP" = "true" ]; then
      wt_remove "$feat_id"
    fi

    local total_usd feature_tokens elapsed_after
    total_usd=$(_loop_cost_field "$loop_cost_file" "total_usd")
    feature_tokens=$(node -p "try{const d=JSON.parse(require('fs').readFileSync('$STATE_DIR/$feat_id/cost.json','utf8'));d.cumulative_tokens||0}catch(e){0}" 2>/dev/null || echo "0")
    elapsed_after=$(( $(date +%s) - loop_started_at ))
    if awk -v c="$total_usd" -v limit="$max_cost" 'BEGIN { exit !(c >= limit) }'; then
      cap_reached=1
      cap_reason="cost"
      break
    fi
    if [ "$elapsed_after" -ge $(( max_time * 60 )) ]; then
      cap_reached=1
      cap_reason="time"
      break
    fi
    if [ "$feature_tokens" -ge "$max_tokens" ]; then
      cap_reached=1
      cap_reason="tokens"
      break
    fi
    if [ "$failure_stopped" -eq 1 ]; then
      break
    fi
    if [ "$circuit_tripped" -eq 1 ]; then
      break
    fi
  done

  rm -f "$backlog_file"
  local elapsed_total final_status final_cost final_tokens
  elapsed_total=$(( $(date +%s) - loop_started_at ))
  if [ "$circuit_tripped" -eq 1 ]; then
    final_status="circuit-breaker-tripped"
  elif [ "$cap_reached" -eq 1 ]; then
    final_status="cap-reached"
  elif [ "$failure_stopped" -eq 1 ]; then
    final_status="stopped"
  elif [ "$any_failed" -eq 0 ]; then
    final_status="completed"
  else
    final_status="failed"
  fi
  _loop_cost_finalize "$loop_cost_file" "$final_status" "$elapsed_total" "$cap_reason"
  final_cost=$(_loop_cost_field "$loop_cost_file" "total_usd")
  final_tokens=$(_loop_cost_field "$loop_cost_file" "total_tokens")
  printf 'Loop cost: $%.4f / $%s, tokens: %s, elapsed: %ss / %sm\n' \
    "$final_cost" "$max_cost" "$final_tokens" "$elapsed_total" "$max_time"
  if [ "$circuit_tripped" -eq 1 ]; then
    return "${EXIT_CIRCUIT_BREAKER:-5}"
  fi
  if [ "$cap_reached" -eq 1 ]; then
    printf 'Loop cap reached: %s; no further features will start.\n' "$cap_reason"
    return "${EXIT_BUDGET_CAP:-4}"
  fi
  if [ "$failure_stopped" -eq 1 ]; then
    printf 'Loop stopped after failure: %s; no further features will start.\n' "$failure_stop_reason"
    return "${EXIT_LOOP_STOPPED:-3}"
  fi
  [ "$any_failed" -eq 0 ] || return 1
  return 0
}
