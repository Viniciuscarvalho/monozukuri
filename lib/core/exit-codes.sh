#!/bin/bash
# lib/exit-codes.sh — Named exit code constants
# Source this file; do not execute it directly.

readonly EXIT_OK=0
readonly EXIT_GENERIC=1
readonly EXIT_MISUSE=2
readonly EXIT_CONFIG_INVALID=10
readonly EXIT_DEPENDENCY_MISSING=11
readonly EXIT_SIZE_GATE=12
readonly EXIT_CYCLE_GATE=13
readonly EXIT_SKILL_FAILED=14
readonly EXIT_WORKTREE_DIRTY=15
readonly EXIT_USER_ABORT=20
readonly EXIT_AGENT_BLOCKED=21
