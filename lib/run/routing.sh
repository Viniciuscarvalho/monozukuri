#!/bin/bash
# lib/run/routing.sh — Per-phase adapter routing config (ADR-015, Gap 4)
#
# Reads routing.yaml at project (.monozukuri/routing.yaml) and user
# (~/.config/monozukuri/routing.yaml) level. Project-level overrides user-level.
#
# Exports PHASE_ADAPTER_<UPPERCASE_PHASE> for each configured phase,
# and ROUTING_FAILOVER (true|false).
#
# Functions:
#   routing_load [PROJECT_ROOT]                    — parse routing.yaml files, export env vars
#   routing_adapter_for_phase PHASE                — echo resolved adapter name
#   routing_record_run ADAPTER PHASE CI_PASS COST  — append canary result to data store

ROUTING_DATA_DIR="${ROUTING_DATA_DIR:-${STATE_DIR:-}/routing-data}"

# routing_load [PROJECT_ROOT]
# Parses user-level then project-level routing.yaml (project overrides user).
routing_load() {
  local project_root="${1:-${ROOT_DIR:-$(pwd)}}"
  local user_cfg="${XDG_CONFIG_HOME:-$HOME/.config}/monozukuri/routing.yaml"
  local project_cfg="$project_root/.monozukuri/routing.yaml"

  if [ -f "$user_cfg" ];    then _routing_parse "$user_cfg";    fi
  if [ -f "$project_cfg" ]; then _routing_parse "$project_cfg"; fi
}

# _routing_parse FILE — parse a two-level routing.yaml; export env vars.
_routing_parse() {
  local yaml="$1"
  local in_phases=0

  while IFS= read -r line || [ -n "$line" ]; do
    # Strip inline comments and trailing whitespace
    line="${line%%#*}"
    line="${line%"${line##*[! ]}"}"
    [ -z "$line" ] && continue

    # Top-level key (no leading whitespace)
    if [[ "$line" =~ ^[a-zA-Z] ]]; then
      in_phases=0
      if [[ "$line" == "phases:" ]]; then
        in_phases=1
        continue
      fi
      if [[ "$line" =~ ^failover:[[:space:]]*(.*) ]]; then
        ROUTING_FAILOVER="${BASH_REMATCH[1]}"
        export ROUTING_FAILOVER
      fi
      continue
    fi

    # Indented phase entry (only inside phases: block)
    if [[ "$in_phases" == "1" && "$line" =~ ^[[:space:]]+([a-zA-Z_-]+):[[:space:]]*(.*) ]]; then
      local phase="${BASH_REMATCH[1]}"
      local adapter="${BASH_REMATCH[2]}"
      # Normalise phase to uppercase, hyphens → underscores for env var name
      local env_var
      env_var="PHASE_ADAPTER_$(printf '%s' "$phase" | tr '[:lower:]-' '[:upper:]_')"
      export "$env_var=$adapter"
    fi
  done < "$yaml"
}

# routing_adapter_for_phase PHASE
# Reads PHASE_ADAPTER_<PHASE> env var; falls back to MONOZUKURI_AGENT.
routing_adapter_for_phase() {
  local phase="$1"
  local env_var
  env_var="PHASE_ADAPTER_$(printf '%s' "$phase" | tr '[:lower:]-' '[:upper:]_')"
  local adapter="${!env_var:-}"
  printf '%s\n' "${adapter:-${MONOZUKURI_AGENT:-claude-code}}"
}

# routing_record_run ADAPTER PHASE CI_PASS(0|1) COST_USD
# Appends a JSONL record to $ROUTING_DATA_DIR/<adapter>/<phase>.jsonl.
routing_record_run() {
  local adapter="$1" phase="$2" ci_pass="$3" cost_usd="${4:-0}"
  local data_dir="${ROUTING_DATA_DIR}/$adapter"
  mkdir -p "$data_dir"
  local ts
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date +%Y-%m-%dT%H:%M:%SZ)"
  printf '{"adapter":"%s","phase":"%s","ci_pass":%s,"cost_usd":%s,"ts":"%s"}\n' \
    "$adapter" "$phase" "$ci_pass" "$cost_usd" "$ts" \
    >> "$data_dir/${phase}.jsonl"
}
