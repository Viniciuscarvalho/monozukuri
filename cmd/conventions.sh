#!/bin/bash
# cmd/conventions.sh — sub_conventions(): inspect parsed project convention files.
# Sourced by orchestrate.sh; inherits SCRIPT_DIR, LIB_DIR, CMD_DIR,
# PROJECT_ROOT, ROOT_DIR, and all OPT_* variables.

sub_conventions() {
  source "$LIB_DIR/agent/conventions.sh"

  local action="${OPT_CONVENTIONS_ACTION:-list}"
  local repo_root="${ROOT_DIR:-$(pwd)}"

  case "$action" in
    list)
      local records
      records=$(read_project_conventions "$repo_root")
      local count
      count=$(jq 'length' <<<"$records")

      if [[ "$count" -eq 0 ]]; then
        printf 'No convention files detected in: %s\n' "$repo_root"
        printf 'Scanned: AGENTS.md, .agents/AGENTS.md, docs/AGENTS.md, CLAUDE.md,\n'
        printf '         .claude/CLAUDE.md, .cursorrules, .aiderrules, .windsurfrules\n'
        return 0
      fi

      if [[ "${OPT_CONVENTIONS_SOURCE:-false}" == "true" ]]; then
        # Group by source file
        jq -r 'group_by(.source.file) | .[] |
          "── " + .[0].source.file + " (" + (length|tostring) + " conventions)",
          (.[] | "   • " + .summary)' <<<"$records"
      elif [[ "${OPT_JSON:-false}" == "true" ]]; then
        printf '%s\n' "$records"
      else
        printf '%s conventions loaded\n\n' "$count"
        jq -r '.[] | "• [" + .source.file + " / " + .summary + "]"' <<<"$records"
      fi
      ;;

    show)
      if [[ -z "${OPT_CONVENTIONS_ID:-}" ]]; then
        printf 'Usage: monozukuri conventions show <summary-substring>\n' >&2
        return 1
      fi
      local records match
      records=$(read_project_conventions "$repo_root")
      match=$(jq --arg q "${OPT_CONVENTIONS_ID}" \
        '[.[] | select(.summary | ascii_downcase | contains($q | ascii_downcase))]' \
        <<<"$records")
      local count
      count=$(jq 'length' <<<"$match")
      if [[ "$count" -eq 0 ]]; then
        printf 'No convention matched: %s\n' "${OPT_CONVENTIONS_ID}" >&2
        return 1
      fi
      jq -r '.[] | "Source : " + .source.file + " (line " + (.source.line|tostring) + ")",
                   "Section: " + .summary, "", .body, ""' <<<"$match"
      ;;

    sources)
      if ! conventions_detected_sources "$repo_root"; then
        printf 'No convention files detected in: %s\n' "$repo_root"
      fi
      ;;

    *)
      printf 'Unknown conventions action: %s\n' "$action" >&2
      printf 'Available: list [--source], show <query>, sources\n' >&2
      return 1
      ;;
  esac
}
