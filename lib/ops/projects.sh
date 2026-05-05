#!/bin/bash
# lib/ops/projects.sh — Global project registry for multi-project summary.
#
# Registry file: ~/.monozukuri/projects.json
# Shape: [{ "path": "/abs/path", "last_run": "ISO", "agent": "name" }, ...]
#
# Public API:
#   projects_register <path> <agent>   — upsert entry for this project
#   projects_list                      — print registry as JSON array
#
# Called by cmd/run.sh after config is loaded.

_PROJECTS_FILE="${_PROJECTS_FILE:-${HOME}/.monozukuri/projects.json}"
_PROJECTS_LOCK="${_PROJECTS_LOCK:-${HOME}/.monozukuri/projects.lock}"

_projects_acquire_lock() {
  local attempts=0
  while ! mkdir "$_PROJECTS_LOCK" 2>/dev/null; do
    attempts=$((attempts + 1))
    if [ "$attempts" -ge 100 ]; then
      rmdir "$_PROJECTS_LOCK" 2>/dev/null || true
      mkdir "$_PROJECTS_LOCK" 2>/dev/null || true
      break
    fi
    sleep 0.1
  done
}

_projects_release_lock() {
  rmdir "$_PROJECTS_LOCK" 2>/dev/null || true
}

projects_register() {
  local proj_path="${1:?projects_register: path required}"
  local agent="${2:-unknown}"
  local now
  now=$(date -u +%Y-%m-%dT%H:%M:%SZ)

  mkdir -p "$(dirname "$_PROJECTS_FILE")"
  [ -f "$_PROJECTS_FILE" ] || echo '[]' > "$_PROJECTS_FILE"

  _projects_acquire_lock

  local tmp="${_PROJECTS_FILE}.tmp.$$"
  node -e "
    const fs = require('fs');
    const path = '$proj_path';
    const agent = '$agent';
    const now = '$now';
    let entries;
    try { entries = JSON.parse(fs.readFileSync('$_PROJECTS_FILE','utf-8')); } catch(e) { entries = []; }
    const existing = entries.find(e => e.path === path);
    if (existing) {
      existing.last_run = now;
      existing.agent = agent;
    } else {
      entries.push({ path, agent, last_run: now });
    }
    fs.writeFileSync('$tmp', JSON.stringify(entries, null, 2));
    fs.renameSync('$tmp', '$_PROJECTS_FILE');
  " 2>/dev/null || true

  _projects_release_lock
}

projects_list() {
  [ -f "$_PROJECTS_FILE" ] || echo '[]'
  [ -f "$_PROJECTS_FILE" ] && cat "$_PROJECTS_FILE"
}
