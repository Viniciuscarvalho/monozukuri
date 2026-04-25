#!/bin/bash
# lib/cli/colors.sh — ANSI color tokens for orchestrator terminal output
# Renamed from scripts/lib/ui.sh; adds NO_COLOR support per CLICOLOR_FORCE convention.

if [[ -n "${NO_COLOR:-}" ]] || [[ ! -t 1 ]]; then
  C_RED=''; C_GREEN=''; C_YELLOW=''; C_BLUE=''; C_CYAN=''; C_DIM=''; C_BOLD=''; C_NC=''
elif [[ -t 1 ]] || [[ "${FM_FORCE_COLOR:-}" == "1" ]]; then
  C_RED=$'\033[0;31m'
  C_GREEN=$'\033[0;32m'
  C_YELLOW=$'\033[0;33m'
  C_BLUE=$'\033[0;34m'
  C_CYAN=$'\033[0;36m'
  C_DIM=$'\033[2m'
  C_BOLD=$'\033[1m'
  C_NC=$'\033[0m'
fi
export C_RED C_GREEN C_YELLOW C_BLUE C_CYAN C_DIM C_BOLD C_NC
