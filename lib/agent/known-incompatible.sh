#!/bin/bash
# lib/agent/known-incompatible.sh — Registry of skills known to violate the
# monozukuri autonomy contract (AGENTS.md: "Full_auto contract is sacred").
#
# Skills here have been confirmed to:
#   - Ask for human input despite MONOZUKURI_INTERACTIVE=0, or
#   - Write artifacts to a non-standard path, or
#   - Otherwise break the orchestrator ↔ skill contract.
#
# See docs/adapter-contract.md#known-incompatible-skills for the full rationale
# and upgrade path for each entry.

# is_skill_known_incompatible <skill_name>
# Returns 0 (true) if <skill_name> is in the incompatible registry.
is_skill_known_incompatible() {
  local skill_name="$1"
  case "$skill_name" in
    feature-marker) return 0 ;;
    *)              return 1 ;;
  esac
}

# known_incompatible_reason <skill_name>
# Prints a human-readable explanation of why the skill is incompatible and what
# to use instead. Prints nothing for unknown skills.
known_incompatible_reason() {
  local skill_name="$1"
  case "$skill_name" in
    feature-marker)
      echo "external skill — does not read MONOZUKURI_INTERACTIVE and will prompt for human input even under full_auto. Use mz-create-prd / mz-create-techspec / mz-create-tasks (bundled mz-* skills honor the contract)."
      ;;
  esac
}
