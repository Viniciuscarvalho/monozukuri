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
    assert_file_exists "tarball contains orchestrate.sh" "$pkg/orchestrate.sh" \
      || failures=$((failures + 1))
    assert_file_exists "tarball contains cmd/loop.sh" "$pkg/cmd/loop.sh" \
      || failures=$((failures + 1))
    assert_file_exists "tarball contains lib/agent/contract.sh" "$pkg/lib/agent/contract.sh" \
      || failures=$((failures + 1))
    assert_file_exists "tarball contains lib/prompt/render.sh" "$pkg/lib/prompt/render.sh" \
      || failures=$((failures + 1))
    assert_file_exists "tarball contains config/pricing.yaml" "$pkg/config/pricing.yaml" \
      || failures=$((failures + 1))
    assert_file_exists "tarball contains schemas/learning-v2.schema.json" "$pkg/schemas/learning-v2.schema.json" \
      || failures=$((failures + 1))
    assert_file_exists "tarball contains skills/mz-create-prd/SKILL.md" "$pkg/skills/mz-create-prd/SKILL.md" \
      || failures=$((failures + 1))
    assert_file_exists "tarball contains scripts/orchestrate.sh" "$pkg/scripts/orchestrate.sh" \
      || failures=$((failures + 1))
    assert_file_exists "tarball contains templates/config.yaml" "$pkg/templates/config.yaml" \
      || failures=$((failures + 1))
    assert_file_nonempty "tarball contains ui/dist/index.js" "$pkg/ui/dist/index.js" \
      || failures=$((failures + 1))
    assert_file_nonempty "tarball contains ui/dist/App.js" "$pkg/ui/dist/App.js" \
      || failures=$((failures + 1))

    # Verify the tarball's package.json version matches
    local tarball_ver
    tarball_ver=$(node -p "require('$pkg/package.json').version" 2>/dev/null || echo "")
    assert_eq "tarball package.json version matches" "$version_bare" "$tarball_ver" \
      || failures=$((failures + 1))

    local pkg_help pkg_loop_help
    pkg_help=$(timeout 10 node "$pkg/bin/monozukuri" --help 2>&1 || true)
    if echo "$pkg_help" | grep -qi "usage"; then
      _qa_pass "extracted npm package --help works"
    else
      _qa_fail "extracted npm package --help failed" \
        || failures=$((failures + 1))
    fi

    pkg_loop_help=$(timeout 10 node "$pkg/bin/monozukuri" loop --help 2>&1 || true)
    if echo "$pkg_loop_help" | grep -qi "usage"; then
      _qa_pass "extracted npm package loop --help works"
    else
      _qa_fail "extracted npm package loop --help failed" \
        || failures=$((failures + 1))
    fi

    local pkg_proj
    pkg_proj=$(mktemp -d)
    git -C "$pkg_proj" init -q 2>/dev/null \
      || git -C "$pkg_proj" init -q 2>/dev/null || true

    local init_rc=0
    (
      cd "$pkg_proj"
      timeout 20 node "$pkg/bin/monozukuri" init --non-interactive >/dev/null
    ) || init_rc=$?
    if [ "$init_rc" -eq 0 ]; then
      _qa_pass "extracted npm package init works in a clean project"
    else
      _qa_fail "extracted npm package init failed (exit $init_rc)" \
        || failures=$((failures + 1))
    fi
    assert_file_exists "init creates .monozukuri/config.yaml" "$pkg_proj/.monozukuri/config.yaml" \
      || failures=$((failures + 1))
    assert_file_exists "init creates features.md" "$pkg_proj/features.md" \
      || failures=$((failures + 1))
    if [ ! -d "$pkg_proj/.agents/skills" ]; then
      _qa_pass "init does not install project skills"
    else
      _qa_fail "init unexpectedly installed project skills" \
        || failures=$((failures + 1))
    fi

    local loop_rc=0 loop_out
    loop_out=$(
      cd "$pkg_proj"
      PATH="$REPO_ROOT/.qa/fixtures/mocks/claude:$PATH" \
        MONOZUKURI_HOME="$pkg" \
        timeout 90 node "$pkg/bin/monozukuri" loop feat-001 --agent claude-code --non-interactive --no-ui --cleanup 2>&1
    ) || loop_rc=$?
    if [ "$loop_rc" -eq 0 ] && echo "$loop_out" | grep -q "\\[1/1\\] feat-001"; then
      _qa_pass "extracted npm package loop runs with mock agent"
    else
      _qa_fail "extracted npm package loop smoke failed (exit $loop_rc)" \
        || failures=$((failures + 1))
    fi
    rm -rf "$pkg_proj"
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

  local ui_app="$REPO_ROOT/ui/dist/App.js"
  assert_file_nonempty "ui/dist/App.js exists and non-empty" "$ui_app" \
    || failures=$((failures + 1))

  local dist_size
  dist_size=$(find "$REPO_ROOT/ui/dist" -type f -name '*.js' -print0 2>/dev/null \
    | xargs -0 wc -c 2>/dev/null \
    | awk 'END { print $1 + 0 }')
  if [ "$dist_size" -gt 10000 ]; then
    _qa_pass "ui/dist JS output size plausible (${dist_size} bytes)"
  else
    _qa_fail "ui/dist JS output suspiciously small (${dist_size} bytes) — build may be broken" \
      || failures=$((failures + 1))
  fi

  # SEL-06 builds Ink with tsc directly to avoid the dynamic-require ESM/CJS
  # bundle regression. In that mode index.js is a small entrypoint and App.js
  # carries the TUI implementation.
  if grep -q "from './App.js'" "$ui_dist" 2>/dev/null \
    && grep -q "render(" "$ui_dist" 2>/dev/null \
    && grep -q "function App" "$ui_app" 2>/dev/null; then
    _qa_pass "ui/dist uses tsc ESM entrypoint with App implementation"
  else
    _qa_fail "ui/dist missing tsc ESM entrypoint/App implementation" \
      || failures=$((failures + 1))
  fi

  # ── 1d. monozukuri doctor ────────────────────────────────────────────────────
  # Skip on CI: gh auth and claude CLI are developer tools absent from runners.
  if [ "${GITHUB_ACTIONS:-false}" = "true" ]; then
    printf '  ~ monozukuri doctor skipped in CI (gh/claude not available on runner)\n'
  else
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
  fi

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
