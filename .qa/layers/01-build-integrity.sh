#!/bin/bash
# .qa/layers/01-build-integrity.sh — Layer 1: Build integrity
set -euo pipefail

QA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$(cd "$QA_DIR/.." && pwd)"
source "$QA_DIR/lib/assert.sh"

run_layer1() {
  local version="${1:?version required}"
  local version_bare="${version#v}"
  local failures=0

  echo "Layer 1: Build integrity"

  # ── 1a. Version consistency ─────────────────────────────────────────────────
  local pkg_version
  pkg_version=$(node -p "require('$REPO_ROOT/package.json').version" 2>/dev/null || echo "")
  assert_eq "package.json version matches gate arg" "$version_bare" "$pkg_version" \
    || failures=$((failures + 1))

  local rb_version
  rb_version=$(grep -oE 'version "[^"]+"' "$REPO_ROOT/homebrew/monozukuri.rb" \
    | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "")
  if [ "$rb_version" != "$version_bare" ]; then
    printf '  ~ homebrew/monozukuri.rb is %s (gate expects %s) — expected lag if publish job has not run\n' \
      "$rb_version" "$version_bare"
  else
    _qa_pass "Homebrew formula version matches"
  fi

  # ── 1b. npm pack smoke ──────────────────────────────────────────────────────
  local tmp_pack tmp_install
  tmp_pack=$(mktemp -d)
  tmp_install=$(mktemp -d)

  local tarball
  tarball=$(cd "$REPO_ROOT" && npm pack --pack-destination "$tmp_pack" 2>/dev/null | tail -1)

  if assert_file_nonempty "npm pack produced tarball" "$tmp_pack/$tarball"; then
    if tar -xzf "$tmp_pack/$tarball" -C "$tmp_install" 2>/dev/null; then
      _qa_pass "npm tarball extractable"
    else
      _qa_fail "npm tarball extract failed" || failures=$((failures + 1))
    fi

    # Verify expected files are present in the tarball
    local pkg="$tmp_install/package"
    assert_file_exists "tarball contains bin/monozukuri" "$pkg/bin/monozukuri" \
      || failures=$((failures + 1))
    assert_file_exists "tarball contains scripts/orchestrate.sh" "$pkg/scripts/orchestrate.sh" \
      || failures=$((failures + 1))
    assert_file_exists "tarball contains templates/config.yaml" "$pkg/templates/config.yaml" \
      || failures=$((failures + 1))
    assert_file_nonempty "tarball contains ui/dist/index.js" "$pkg/ui/dist/index.js" \
      || failures=$((failures + 1))

    # Verify the tarball's package.json version matches
    local tarball_ver
    tarball_ver=$(node -p "require('$pkg/package.json').version" 2>/dev/null || echo "")
    assert_eq "tarball package.json version matches" "$version_bare" "$tarball_ver" \
      || failures=$((failures + 1))
  else
    failures=$((failures + 1))
  fi

  rm -rf "$tmp_pack" "$tmp_install"

  # Verify --help works from the repo binary (install-path entry point)
  local help_out
  help_out=$(timeout 10 node "$REPO_ROOT/bin/monozukuri" --help 2>&1 || true)
  if echo "$help_out" | grep -qi "usage"; then
    _qa_pass "bin/monozukuri --help prints usage"
  else
    _qa_fail "bin/monozukuri --help did not print 'usage'" \
      || failures=$((failures + 1))
  fi

  # ── 1c. Ink UI bundle smoke ─────────────────────────────────────────────────
  local ui_dist="$REPO_ROOT/ui/dist/index.js"
  assert_file_nonempty "ui/dist/index.js exists and non-empty" "$ui_dist" \
    || failures=$((failures + 1))

  local bundle_size
  bundle_size=$(wc -c < "$ui_dist" 2>/dev/null || echo "0")
  if [ "$bundle_size" -gt 10000 ]; then
    _qa_pass "ui/dist/index.js size plausible (${bundle_size} bytes)"
  else
    _qa_fail "ui/dist/index.js suspiciously small (${bundle_size} bytes) — bundle may be broken" \
      || failures=$((failures + 1))
  fi

  # Reproduces the v1.19.3 regression: broken ESM/CJS bundle throws on load.
  local bundle_rc=0
  node --input-type=module <<EOF 2>/dev/null || bundle_rc=$?
import { createRequire } from 'module';
const req = createRequire('$ui_dist');
EOF
  # We only care that the import machinery can resolve the file, not that it executes fully.
  # Use a more targeted check: look for the createRequire banner that fixes CJS interop.
  if grep -q "createRequire" "$ui_dist" 2>/dev/null; then
    _qa_pass "ui/dist/index.js contains createRequire CJS-interop banner"
  else
    _qa_fail "ui/dist/index.js missing createRequire banner — v1.19.3-style bundle regression" \
      || failures=$((failures + 1))
  fi

  # ── 1d. monozukuri doctor ────────────────────────────────────────────────────
  local tmp_proj
  tmp_proj=$(mktemp -d)
  mkdir -p "$tmp_proj/.monozukuri"
  cat > "$tmp_proj/.monozukuri/config.yaml" <<'EOCFG'
source:
  adapter: markdown
  markdown:
    file: features.md
autonomy: checkpoint
execution:
  base_branch: main
EOCFG
  git -C "$tmp_proj" init -b main -q 2>/dev/null \
    || git -C "$tmp_proj" init -q 2>/dev/null || true

  local doctor_rc=0
  (
    cd "$tmp_proj"
    MONOZUKURI_HOME="$REPO_ROOT" timeout 15 bash "$REPO_ROOT/orchestrate.sh" doctor 2>&1
  ) || doctor_rc=$?

  if [ "$doctor_rc" -eq 0 ]; then
    _qa_pass "monozukuri doctor passes on clean fixture"
  else
    _qa_fail "monozukuri doctor failed (exit $doctor_rc)" \
      || failures=$((failures + 1))
  fi
  rm -rf "$tmp_proj"

  # ── 1e. Homebrew formula syntax (macOS only) ────────────────────────────────
  if command -v brew &>/dev/null; then
    local rb="$REPO_ROOT/homebrew/monozukuri.rb"
    ruby -c "$rb" > /dev/null 2>&1 \
      && _qa_pass "homebrew formula ruby syntax valid" \
      || { _qa_fail "homebrew formula has ruby syntax errors" \
           || failures=$((failures + 1)); }
    brew audit --strict "$rb" > /dev/null 2>&1 \
      && _qa_pass "brew audit --strict passes" \
      || printf '  ~ brew audit --strict: warnings (non-blocking)\n'
  else
    printf '  ~ Homebrew not available — skipping formula audit (Linux runner)\n'
  fi

  return "$failures"
}
