#!/bin/bash
# lib/core/modules.sh — Module dependency declaration and load-time diagnostics
#
# Replaces the implicit source-order coupling in cmd/run.sh with explicit
# declarations. module_require fails fast with a named diagnostic; module_optional
# creates no-op stubs so callers can guard with `declare -f`.
#
# Usage in cmd/run.sh:
#   source "$LIB_DIR/core/modules.sh"
#   modules_init "$LIB_DIR"
#   module_require core/util
#   module_optional run/local-model  local_model::embed local_model::classify
#
# Usage in a module that depends on another:
#   module_require core/json-io    (within the sourced file itself)

_MODULES_LOADED=""
_MODULES_LIB_DIR=""

# modules_init <lib_dir>
# Must be called once before any module_require / module_optional call.
modules_init() {
  _MODULES_LIB_DIR="$1"
}

# _module_path <name>
# Resolves a bare module name or qualified path to an absolute .sh path.
_module_path() {
  local name="$1"
  if [[ "$name" == */* ]]; then
    echo "$_MODULES_LIB_DIR/$name.sh"
    return
  fi
  for prefix in core memory plan run cli prompt config; do
    local candidate="$_MODULES_LIB_DIR/$prefix/$name.sh"
    [ -f "$candidate" ] && echo "$candidate" && return
  done
  echo "$_MODULES_LIB_DIR/$name.sh"
}

# _module_loaded <name>
# Returns 0 if the module has already been sourced, 1 otherwise.
_module_loaded() {
  case "$_MODULES_LOADED" in *"|$1|"*) return 0 ;; esac
  return 1
}

# _module_mark_loaded <name>
_module_mark_loaded() {
  _MODULES_LOADED="${_MODULES_LOADED}|$1|"
}

# module_require <name>
# Sources the module. Exits with a named error if the file is not found.
module_require() {
  local name="$1"
  _module_loaded "$name" && return 0
  local path
  path=$(_module_path "$name")
  if [ ! -f "$path" ]; then
    printf '[monozukuri] FATAL: required module "%s" not found (resolved: %s)\n' "$name" "$path" >&2
    exit 1
  fi
  # shellcheck source=/dev/null
  source "$path"
  _module_mark_loaded "$name"
}

# module_optional <name> [stub_function...]
# Sources the module when present. When absent, registers each stub_function as
# a no-op so callers can test availability with `declare -f <fn>`.
module_optional() {
  local name="$1"; shift
  _module_loaded "$name" && return 0
  local path
  path=$(_module_path "$name")
  if [ -f "$path" ]; then
    # shellcheck source=/dev/null
    source "$path"
    _module_mark_loaded "$name"
  else
    for fn in "$@"; do
      # shellcheck disable=SC2116
      eval "$(echo "${fn}() { return 0; }")" 2>/dev/null || true
    done
  fi
}

# module_loaded <name>
# Returns 0 if the module was sourced, 1 otherwise. Useful in conditionals.
module_loaded() {
  _module_loaded "$1"
}
