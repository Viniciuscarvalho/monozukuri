#!/bin/bash
# cmd/conventions.sh — sub_conventions(): inspect and generate project convention files.
# Sourced by orchestrate.sh; inherits SCRIPT_DIR, LIB_DIR, CMD_DIR,
# PROJECT_ROOT, ROOT_DIR, and all OPT_* variables.

sub_conventions() {
  source "$LIB_DIR/agent/conventions.sh"
  source "$LIB_DIR/agent/conventions-promote.sh"

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

    generate|preview)
      source "$LIB_DIR/agent/conventions-generate.sh"
      source "$LIB_DIR/agent/conventions-merge.sh"

      local block; block=$(mktemp)
      conventions_generate_content "$repo_root" > "$block"

      if [[ "${OPT_CONVENTIONS_WRITE:-false}" == "true" ]]; then
        conventions_merge_write "$repo_root" "$block"
      else
        printf '── Preview (use --write to apply) ──────────────────────────────\n'
        if [[ -f "$repo_root/AGENTS.md" ]]; then
          conventions_merge_diff "$repo_root" "$block" || true
        else
          cat "$block"
        fi
        printf '────────────────────────────────────────────────────────────────\n'
      fi
      rm -f "$block"
      ;;

    write)
      source "$LIB_DIR/agent/conventions-generate.sh"
      source "$LIB_DIR/agent/conventions-merge.sh"

      if [[ "${OPT_NON_INTERACTIVE:-false}" != "true" ]] && \
         [[ "${OPT_CONVENTIONS_YES:-false}" != "true" ]]; then
        printf 'Write generated block to %s/AGENTS.md? [y/N] ' "$repo_root"
        read -r reply
        [[ "$reply" =~ ^[Yy]$ ]] || { printf 'Aborted.\n'; return 0; }
      fi

      local block; block=$(mktemp)
      conventions_generate_content "$repo_root" > "$block"
      conventions_merge_write "$repo_root" "$block"
      rm -f "$block"
      ;;

    diff)
      source "$LIB_DIR/agent/conventions-generate.sh"
      source "$LIB_DIR/agent/conventions-merge.sh"

      local block; block=$(mktemp)
      conventions_generate_content "$repo_root" > "$block"
      conventions_merge_diff "$repo_root" "$block" || true
      rm -f "$block"
      ;;

    restore)
      source "$LIB_DIR/agent/conventions-merge.sh"
      conventions_restore "$repo_root" "${OPT_CONVENTIONS_ID:-}"
      ;;

    restore-list)
      source "$LIB_DIR/agent/conventions-merge.sh"
      conventions_restore_list "$repo_root"
      ;;

    candidates)
      local records
      records=$(conventions_list_candidates "$repo_root")
      local count
      count=$(jq 'length' <<<"$records")

      if [[ "$count" -eq 0 ]]; then
        printf 'No promotion candidates found.\n'
        printf 'Candidates are learning entries with confidence >= 0.8 and hits >= 3.\n'
        return 0
      fi

      if [[ "${OPT_JSON:-false}" == "true" ]]; then
        printf '%s\n' "$records"
      else
        printf '%s candidate(s) ready for promotion:\n\n' "$count"
        jq -r '.[] | "• [" + .source.file + "] " + .summary + " (" + (.confidence*100|floor|tostring) + "% confidence)"' \
          <<<"$records"
        printf '\nRun: monozukuri conventions promote <learn-id>\n'
      fi
      ;;

    promote)
      if [[ -z "${OPT_CONVENTIONS_ID:-}" ]]; then
        printf 'Usage: monozukuri conventions promote <learn-id>\n' >&2
        return 1
      fi
      conventions_write_promoted "$repo_root" "${OPT_CONVENTIONS_ID}"
      ;;

    *)
      printf 'Unknown conventions action: %s\n' "$action" >&2
      printf 'Available: list [--source], show <query>, sources,\n' >&2
      printf '           generate [--write], write [-y], diff,\n' >&2
      printf '           restore [<backup>], restore-list,\n' >&2
      printf '           candidates, promote <id>\n' >&2
      return 1
      ;;
  esac
}
