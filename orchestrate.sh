#!/bin/bash
# orchestrate.sh — Shell Script Orchestrator CLI (Compozy-style entry point)
#
# Thin CLI parser + dispatcher. Sub-commands live in cmd/; library modules
# live in lib/. Scripts that remain in scripts/ are accessed via $SCRIPTS_DIR.
#
# Usage:
#   ./orchestrate.sh init                      # Scaffold project
#   ./orchestrate.sh run                       # Execute orchestration
#   ./orchestrate.sh run --autonomy full_auto  # Override autonomy
#   ./orchestrate.sh run --dry-run             # Show plan, don't execute
#   ./orchestrate.sh status                    # Show current state
#   ./orchestrate.sh clean                     # Remove all worktrees
#
# Flags:
#   --autonomy <level>   Override: supervised | checkpoint | full_auto
#   --adapter <type>     Override: markdown | github | linear
#   --config <path>      Config file (default: .monozukuri/config.yaml)
#   --plan               Show the plan, don't execute
#   --dry-run             Alias for --plan
#   --help               Show this help

set -euo pipefail

# ── Path resolution — works from Homebrew, local dev, or NPX ─────────

if [ -n "${MONOZUKURI_HOME:-}" ]; then
  # Set by wrapper (Homebrew or NPX)
  SCRIPT_DIR="$MONOZUKURI_HOME"
else
  # Running directly from repo root
  SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0" 2>/dev/null || echo "$0")")" && pwd)"
fi

# Project root is always the current working directory
PROJECT_ROOT="$(pwd)"

# New Compozy-style directory layout
LIB_DIR="$SCRIPT_DIR/lib"
CMD_DIR="$SCRIPT_DIR/cmd"
SCRIPTS_DIR="$SCRIPT_DIR/scripts"
TEMPLATES_DIR="$SCRIPT_DIR/templates"

# Export SCRIPTS_DIR so lib modules (pipeline.sh, memory.sh, config/load.sh)
# can reference scripts/ helpers without knowing SCRIPT_DIR.
export SCRIPTS_DIR

# Everything else operates on PROJECT_ROOT
ROOT_DIR="$PROJECT_ROOT"
CONFIG_DIR="$ROOT_DIR/.monozukuri"
STATE_DIR="$CONFIG_DIR/state"
RESULTS_DIR="$CONFIG_DIR/results"

cd "$ROOT_DIR"

# ── Colors (load early so helpers and cmd/ files can use them) ────────
# shellcheck source=lib/cli/colors.sh
source "$LIB_DIR/cli/colors.sh"

# ── Helpers (available before modules load) ───────────────────────────

log()    { printf "${C_CYAN}▶${C_NC} [orchestrate] %s\n" "$*"; }
info()   { printf "${C_DIM}  [orchestrate] %s${C_NC}\n" "$*"; }
warn()   { printf "${C_YELLOW}⚠${C_NC}  [orchestrate] %s\n" "$*" >&2; }
err()    { printf "${C_RED}✗${C_NC} [orchestrate] %s\n" "$*" >&2; }
banner() {
  printf "\n${C_BOLD}${C_CYAN}%s${C_NC}\n" "═══════════════════════════════════════════════════"
  printf "${C_BOLD}  %s${C_NC}\n" "$*"
  printf "${C_BOLD}${C_CYAN}%s${C_NC}\n" "═══════════════════════════════════════════════════"
}

# ── CLI Parsing ───────────────────────────────────────────────────────

SUBCOMMAND=""
OPT_AUTONOMY=""
OPT_ADAPTER=""
OPT_MODEL=""
OPT_CONFIG=".monozukuri/config.yaml"
OPT_DRY_RUN=false
OPT_FEATURE=""
OPT_RESUME_FEAT=""
OPT_RESUME_ACK=false
OPT_SKIP_CYCLE_CHECK=false
OPT_SAMPLE=10
OPT_LEARNING_ACTION=""
OPT_LEARNING_ID=""
OPT_LEARNING_CANDIDATES=false
OPT_INGEST_FEAT=""
OPT_JSON=false
OPT_NON_INTERACTIVE=false
OPT_RESUME=false
OPT_CONFIG_ACTION=""
OPT_AGENT_SUBCMD=""
OPT_AGENT_NAME=""
OPT_ROUTING_ACTION=""
OPT_ROUTING_PHASE=""
OPT_CONVENTIONS_ACTION=""
OPT_CONVENTIONS_ID=""
OPT_CONVENTIONS_SOURCE=false

while [ $# -gt 0 ]; do
  case "$1" in
    init|run|status|clean|calibrate|learning|promote-learning|ingest-status|doctor|config|agent|routing|metrics|review|conventions)
      if [ -z "$SUBCOMMAND" ]; then
        SUBCOMMAND="$1"
      elif [ "$SUBCOMMAND" = "agent" ] && [ -z "$OPT_AGENT_SUBCMD" ]; then
        OPT_AGENT_SUBCMD="$1"
      elif [ "$SUBCOMMAND" = "agent" ] && [ -z "$OPT_AGENT_NAME" ]; then
        OPT_AGENT_NAME="$1"
      elif [ "$SUBCOMMAND" = "routing" ] && [ -z "$OPT_ROUTING_ACTION" ]; then
        OPT_ROUTING_ACTION="$1"
      elif [ "$SUBCOMMAND" = "routing" ] && [ -z "$OPT_ROUTING_PHASE" ]; then
        OPT_ROUTING_PHASE="$1"
      fi
      ;;
    --resume-paused)
      shift; OPT_RESUME_FEAT="$1"; SUBCOMMAND="resume-paused"
      ;;
    --ack)
      OPT_RESUME_ACK=true
      ;;
    --autonomy)
      shift; OPT_AUTONOMY="$1"
      ;;
    --adapter)
      shift; OPT_ADAPTER="$1"
      ;;
    --model)
      shift; OPT_MODEL="$1"
      ;;
    --config)
      shift; OPT_CONFIG="$1"
      ;;
    --feature)
      shift; OPT_FEATURE="$1"
      ;;
    --plan|--dry-run)
      OPT_DRY_RUN=true
      ;;
    --skip-cycle-check)
      OPT_SKIP_CYCLE_CHECK=true
      ;;
    --sample)
      shift; OPT_SAMPLE="$1"
      ;;
    --candidates)
      OPT_LEARNING_CANDIDATES=true
      ;;
    --json)
      OPT_JSON=true
      ;;
    --non-interactive)
      OPT_NON_INTERACTIVE=true
      ;;
    --resume)
      OPT_RESUME=true
      ;;
    list|archive|promote)
      [ "$SUBCOMMAND" = "learning" ]     && OPT_LEARNING_ACTION="$1"
      [ "$SUBCOMMAND" = "conventions" ]  && OPT_CONVENTIONS_ACTION="$1"
      ;;
    sources|show)
      [ "$SUBCOMMAND" = "conventions" ]  && OPT_CONVENTIONS_ACTION="$1"
      ;;
    --source)
      [ "$SUBCOMMAND" = "conventions" ]  && OPT_CONVENTIONS_SOURCE=true
      ;;
    validate)
      [ "$SUBCOMMAND" = "config" ] && OPT_CONFIG_ACTION="$1"
      ;;
    show)
      [ "$SUBCOMMAND" = "config" ]       && OPT_CONFIG_ACTION="$1"
      [ "$SUBCOMMAND" = "conventions" ]  && OPT_CONVENTIONS_ACTION="$1"
      ;;
    list|enable)
      [ "$SUBCOMMAND" = "agent" ] && [ -z "$OPT_AGENT_SUBCMD" ] && OPT_AGENT_SUBCMD="$1"
      ;;
    suggest)
      [ "$SUBCOMMAND" = "routing" ] && [ -z "$OPT_ROUTING_ACTION" ] && OPT_ROUTING_ACTION="$1"
      ;;
    --help|-h)
      echo "Usage: orchestrate.sh <command> [flags]"
      echo ""
      echo "Commands:"
      echo "  doctor                       Check all dependencies and report status"
      echo "  init                         Scaffold config, .env, features.md, .gitignore"
      echo "  config validate              Validate .monozukuri/config.yaml against schema"
      echo "  config show [--json]         Print resolved config"
      echo "  run                          Execute the orchestration loop"
      echo "  status                       Show current orchestrator state"
      echo "  clean                        Remove all worktrees and reset state"
      echo "  calibrate                    Show token-cost calibration guidance"
      echo "  learning list                List all learning entries"
      echo "  learning list --candidates   List only promotion candidates"
      echo "  learning archive <id>        Archive a learning entry by ID"
      echo "  learning promote <id>        Promote a project entry to global tier"
      echo "  promote-learning <id>        Alias for: learning promote <id>"
      echo "  ingest-status                Show active background ingest jobs (ADR-009)"
      echo "  agent list                   List all adapters and their install status"
      echo "  agent doctor [name]          Check install/auth for all or one adapter"
      echo "  agent enable <name>          Set the active agent in .monozukuri/config.yaml"
      echo "  routing suggest [phase]      Recommend adapter per phase (data-threshold-gated)"
      echo "  metrics                      View recent canary metrics and trends"
      echo "  review export <run-id>       Generate static HTML review bundle"
      echo "  review open <run-id>         Generate and open review bundle in browser"
      echo "  review list                  List all runs with summaries"
      echo "  conventions list             Show all parsed conventions"
      echo "  conventions list --source    Group conventions by source file"
      echo "  conventions show <query>     Show full body of matching convention"
      echo "  conventions sources          List detected convention files"
      echo ""
      echo "Flags:"
      echo "  --autonomy <level>           supervised | checkpoint | full_auto"
      echo "  --adapter <type>             markdown | github | linear"
      echo "  --model <name>              opus | sonnet | haiku | opusplan"
      echo "  --config <path>              Config file (default: .monozukuri/config.yaml)"
      echo "  --feature <id>              Run only the specified feature"
      echo "  --plan, --dry-run            Show plan without executing"
      echo "  --resume-paused <feat-id>    Resume a paused feature from its checkpoint"
      echo "  --ack                        Acknowledge human-class pauses for --resume-paused"
      echo "  --skip-cycle-check           Skip the cycle-completion gate"
      echo "  --sample <n>                 Sample size for calibrate (default: 10)"
      echo "  --json                       Emit machine-readable JSON (status, learning list)"
      echo "  --non-interactive            Skip all prompts; use defaults"
      echo "  --resume                     Resume the most recent run (idempotent)"
      echo "  --help                       Show this help"
      exit 0
      ;;
    *)
      if [ "$SUBCOMMAND" = "learning" ] && [ -z "$OPT_LEARNING_ACTION" ]; then
        OPT_LEARNING_ACTION="$1"
      elif [ "$SUBCOMMAND" = "learning" ] && [ -z "$OPT_LEARNING_ID" ]; then
        OPT_LEARNING_ID="$1"
      elif [ "$SUBCOMMAND" = "promote-learning" ] && [ -z "$OPT_LEARNING_ID" ]; then
        OPT_LEARNING_ID="$1"
      elif [ "$SUBCOMMAND" = "ingest-reviews" ] && [ -z "$OPT_INGEST_FEAT" ]; then
        OPT_INGEST_FEAT="$1"
      elif [ "$SUBCOMMAND" = "agent" ] && [ -z "$OPT_AGENT_SUBCMD" ]; then
        OPT_AGENT_SUBCMD="$1"
      elif [ "$SUBCOMMAND" = "agent" ] && [ -z "$OPT_AGENT_NAME" ]; then
        OPT_AGENT_NAME="$1"
      elif [ "$SUBCOMMAND" = "routing" ] && [ -z "$OPT_ROUTING_ACTION" ]; then
        OPT_ROUTING_ACTION="$1"
      elif [ "$SUBCOMMAND" = "routing" ] && [ -z "$OPT_ROUTING_PHASE" ]; then
        OPT_ROUTING_PHASE="$1"
      elif [ "$SUBCOMMAND" = "conventions" ] && [ -z "$OPT_CONVENTIONS_ACTION" ]; then
        OPT_CONVENTIONS_ACTION="$1"
      elif [ "$SUBCOMMAND" = "conventions" ] && [ -z "$OPT_CONVENTIONS_ID" ]; then
        OPT_CONVENTIONS_ID="$1"
      else
        err "Unknown argument: $1"
        err "Run: monozukuri --help"
        exit 1
      fi
      ;;
  esac
  shift
done

export OPT_SKIP_CYCLE_CHECK OPT_JSON OPT_NON_INTERACTIVE OPT_CONFIG_ACTION \
       OPT_AGENT_SUBCMD OPT_AGENT_NAME OPT_CONFIG \
       OPT_ROUTING_ACTION OPT_ROUTING_PHASE \
       OPT_CONVENTIONS_ACTION OPT_CONVENTIONS_ID OPT_CONVENTIONS_SOURCE

[ -z "$SUBCOMMAND" ] && { err "No command given. Run: monozukuri --help"; exit 1; }

# Verify we're in a git repo (doctor, routing, metrics, and review are exempt — pre-flight or read-only)
if [ "$SUBCOMMAND" != "doctor" ] && [ "$SUBCOMMAND" != "agent" ] && [ "$SUBCOMMAND" != "routing" ] && [ "$SUBCOMMAND" != "metrics" ] && [ "$SUBCOMMAND" != "review" ] && [ "$SUBCOMMAND" != "conventions" ] \
   && ! git rev-parse --is-inside-work-tree &>/dev/null; then
  echo "✗ Not inside a git repository." >&2
  echo "  Run this from the root of your project." >&2
  exit 1
fi

# ── Dispatch ──────────────────────────────────────────────────────────

case "$SUBCOMMAND" in
  doctor)          source "$CMD_DIR/doctor.sh"; sub_doctor ;;
  init)            source "$CMD_DIR/init.sh"; sub_init ;;
  run)             source "$CMD_DIR/run.sh"; sub_run ;;
  status)          source "$CMD_DIR/status.sh"; sub_status ;;
  clean)           source "$CMD_DIR/cleanup.sh"; sub_clean ;;
  calibrate)       source "$CMD_DIR/calibrate.sh"; sub_calibrate ;;
  config)          source "$CMD_DIR/config.sh"; sub_config ;;
  learning)        source "$CMD_DIR/learning.sh"; sub_learning ;;
  promote-learning) source "$CMD_DIR/learning.sh"; sub_promote_learning ;;
  resume-paused)   source "$CMD_DIR/resume.sh"; sub_resume_paused ;;
  ingest-status)   source "$CMD_DIR/ingest-status.sh"; sub_ingest_status ;;
  agent)           source "$CMD_DIR/agent.sh"; sub_agent ;;
  routing)         source "$CMD_DIR/routing.sh"; sub_routing ;;
  metrics)         source "$CMD_DIR/metrics.sh"; sub_metrics ;;
  review)          source "$CMD_DIR/review.sh"; sub_review "${@:2}" ;;
  conventions)     source "$CMD_DIR/conventions.sh"; sub_conventions ;;
esac
