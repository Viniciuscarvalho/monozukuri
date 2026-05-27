#!/usr/bin/env bash
# Run a verification command with a wall-clock budget and clear diagnostics.
set -euo pipefail

SECONDS_BUDGET="${MONOZUKURI_VERIFY_TIMEOUT_SECONDS:-300}"
LABEL="verification"

usage() {
  cat <<'EOF'
Usage: scripts/verification/with-timeout.sh [--seconds N] [--label NAME] -- command [args...]

Runs command with a wall-clock timeout. On timeout, exits 124 and prints a
diagnostic naming the verification label and budget.
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --seconds)
      shift
      SECONDS_BUDGET="$1"
      ;;
    --label)
      shift
      LABEL="$1"
      ;;
    --)
      shift
      break
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

if [ $# -eq 0 ]; then
  echo "with-timeout: missing command" >&2
  usage >&2
  exit 2
fi

if ! [[ "$SECONDS_BUDGET" =~ ^[0-9]+$ ]] || [ "$SECONDS_BUDGET" -lt 1 ]; then
  echo "with-timeout: --seconds must be a positive integer" >&2
  exit 2
fi

run_with_timeout() {
  if command -v timeout >/dev/null 2>&1; then
    timeout "$SECONDS_BUDGET" "$@"
    return $?
  fi

  perl -e '
    my $seconds = shift @ARGV;
    $SIG{ALRM} = sub { exit 124 };
    alarm $seconds;
    exec @ARGV;
  ' "$SECONDS_BUDGET" "$@"
}

set +e
run_with_timeout "$@"
status=$?
set -e

if [ "$status" -eq 124 ]; then
  echo "with-timeout: ${LABEL} exceeded ${SECONDS_BUDGET}s" >&2
fi

exit "$status"
