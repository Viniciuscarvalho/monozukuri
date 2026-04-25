#!/bin/bash
# scripts/doctor.sh — compatibility shim
# The real sub_doctor() now lives in cmd/doctor.sh.
# This shim sources it so existing callers remain unbroken.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CMD_DOCTOR="$REPO_ROOT/cmd/doctor.sh"

if [ -f "$CMD_DOCTOR" ]; then
  source "$CMD_DOCTOR"
  sub_doctor "$@"
else
  echo "Cannot find cmd/doctor.sh in $REPO_ROOT" >&2
  exit 1
fi
