#!/usr/bin/env bats
# test/integration/learning_promotion_inject.bats
#
# Verifies the full promotion-to-injection pipeline:
#   1. A learning entry reaches promotion_candidate=true after hits>=3 AND confidence>=0.8
#   2. The promoted entry's fix text is present in the rendered PRD prompt for the
#      next feature
#
# The test exercises:
#   - learning_write (dedup + hits counter)
#   - learning_verify (confidence + promotion_candidate flag)
#   - context_pack_build (reads promoted learnings via mem_get_learnings hook)
#   - monozukuri_render ({{#each project_learnings}} expansion in prd.tmpl.md)

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
LIB_DIR="$REPO_ROOT/lib"

setup() {
  TMPDIR_TEST="$(mktemp -d)"
  export STATE_DIR="$TMPDIR_TEST/state"
  export ROOT_DIR="$TMPDIR_TEST/root"
  mkdir -p "$STATE_DIR" "$ROOT_DIR/.claude/feature-state"

  # Stubs required by learning.sh + context-pack.sh
  info() { :; }
  warn() { :; }
  err()  { echo "ERR: $*" >&2; }
  export -f info warn err

  source "$LIB_DIR/memory/learning.sh"
  source "$LIB_DIR/prompt/context-pack.sh"
  source "$LIB_DIR/prompt/render.sh"

  PROJECT_LEARNED="$ROOT_DIR/.claude/feature-state/learned.json"
  PRD_TMPL="$LIB_DIR/prompt/phases/prd.tmpl.md"
  export PROJECT_LEARNED PRD_TMPL

  # A deterministic fix text we can grep for in the rendered prompt
  PROMO_FIX="Always run npm ci before invoking the build step to ensure a clean install"
  export PROMO_FIX
}

teardown() {
  rm -rf "$TMPDIR_TEST"
}

# ── helpers ──────────────────────────────────────────────────────────────────

_write_3x_same_sig() {
  local sig="$1" fix="$2"
  learning_write "feat-a" "$sig" "$fix"
  learning_write "feat-b" "$sig" "$fix"
  learning_write "feat-c" "$sig" "$fix"
}

_get_learn_id() {
  local sig="$1"
  node -p "
    try {
      const e = JSON.parse(require('fs').readFileSync('$PROJECT_LEARNED','utf-8'));
      const m = e.find(x => !x.archived && x.pattern === $(node -p "JSON.stringify('$sig')" 2>/dev/null || echo "\"\""));
      m ? m.id : '';
    } catch(_) { ''; }
  " 2>/dev/null || echo ""
}

_get_promotion_flag() {
  local sig="$1"
  node -p "
    try {
      const e = JSON.parse(require('fs').readFileSync('$PROJECT_LEARNED','utf-8'));
      const m = e.find(x => !x.archived && x.pattern === $(node -p "JSON.stringify('$sig')" 2>/dev/null || echo "\"\""));
      m ? String(m.promotion_candidate) : 'false';
    } catch(_) { 'false'; }
  " 2>/dev/null || echo "false"
}

# ── 1. hits=3 after 3 learning_write calls ───────────────────────────────────

@test "hits reaches 3 after three learning_write calls with the same sig" {
  local sig="schema-reprompt-exhausted: prd:missing a problem/overview section heading"
  _write_3x_same_sig "$sig" "$PROMO_FIX"

  local hits
  hits=$(node -p "
    try {
      const e = JSON.parse(require('fs').readFileSync('$PROJECT_LEARNED','utf-8'));
      const m = e.find(x => !x.archived && x.pattern === $(node -p "JSON.stringify('$sig')" 2>/dev/null || echo "\"\""));
      m ? m.hits : 0;
    } catch(_) { 0; }
  " 2>/dev/null || echo "0")
  [ "$hits" -eq 3 ]
}

# ── 2. promotion_candidate=false before verify ───────────────────────────────

@test "promotion_candidate is false before learning_verify runs" {
  local sig="schema-reprompt-exhausted: prd:missing a problem/overview section heading"
  _write_3x_same_sig "$sig" "$PROMO_FIX"

  local flag
  flag=$(_get_promotion_flag "$sig")
  [ "$flag" = "false" ]
}

# ── 3. promotion_candidate=true after verify with success ────────────────────
#
# confidence = success_count / (success_count + failure_count)
# One success → confidence = 1.0 ≥ 0.8, hits = 3 ≥ 3 → promote.

@test "promotion_candidate becomes true after learning_verify success with hits>=3" {
  local sig="schema-reprompt-exhausted: prd:missing a problem/overview section heading"
  _write_3x_same_sig "$sig" "$PROMO_FIX"

  local learn_id
  learn_id=$(_get_learn_id "$sig")
  [ -n "$learn_id" ]

  learning_verify "$learn_id" "true" "$PROJECT_LEARNED"

  local flag
  flag=$(_get_promotion_flag "$sig")
  [ "$flag" = "true" ]
}

# ── 4. Promoted fix text appears in context_pack_build project_learnings ─────
#
# mem_get_learnings is an optional hook in context-pack.sh. When defined it is
# called to load learnings from the store. We implement it here to return the
# fix text of all promoted entries so context_pack_build can inject them.

@test "promoted fix text is present in context_pack_build project_learnings" {
  local sig="schema-reprompt-exhausted: prd:missing a problem/overview section heading"
  _write_3x_same_sig "$sig" "$PROMO_FIX"

  local learn_id
  learn_id=$(_get_learn_id "$sig")
  learning_verify "$learn_id" "true" "$PROJECT_LEARNED"

  # Implement the hook that context-pack.sh calls when available
  mem_get_learnings() {
    node -e "
      try {
        const e = JSON.parse(require('fs').readFileSync('$PROJECT_LEARNED','utf-8'));
        e.filter(x => !x.archived && x.promotion_candidate)
          .forEach(x => console.log('- ' + x.fix));
      } catch(_) {}
    " 2>/dev/null || true
  }
  export -f mem_get_learnings

  local ctx_file="$TMPDIR_TEST/ctx.json"
  FEATURE_TITLE="Next feature" FEATURE_DESCRIPTION="Test desc" \
    context_pack_build "feat-next-001" "$ctx_file"

  [ -f "$ctx_file" ]

  local has_fix
  has_fix=$(node -p "
    try {
      const d = JSON.parse(require('fs').readFileSync('$ctx_file','utf-8'));
      const learnings = d.project_learnings || [];
      const found = learnings.some(l => (l.summary||'').includes('npm ci'));
      found ? 'yes' : 'no';
    } catch(_) { 'no'; }
  " 2>/dev/null || echo "no")
  [ "$has_fix" = "yes" ]
}

# ── 5. Rendered PRD prompt contains the promoted fix text ─────────────────────

@test "rendered PRD prompt includes promoted entry fix text" {
  [ -f "$PRD_TMPL" ] || skip "prd.tmpl.md not found at expected path"

  local sig="schema-reprompt-exhausted: prd:missing a problem/overview section heading"
  _write_3x_same_sig "$sig" "$PROMO_FIX"

  local learn_id
  learn_id=$(_get_learn_id "$sig")
  learning_verify "$learn_id" "true" "$PROJECT_LEARNED"

  mem_get_learnings() {
    node -e "
      try {
        const e = JSON.parse(require('fs').readFileSync('$PROJECT_LEARNED','utf-8'));
        e.filter(x => !x.archived && x.promotion_candidate)
          .forEach(x => console.log('- ' + x.fix));
      } catch(_) {}
    " 2>/dev/null || true
  }
  export -f mem_get_learnings

  local ctx_file="$TMPDIR_TEST/ctx.json"
  FEATURE_TITLE="Next feature" FEATURE_DESCRIPTION="Test desc" \
    context_pack_build "feat-next-001" "$ctx_file"

  local rendered
  rendered=$(monozukuri_render "$PRD_TMPL" "$ctx_file")

  [[ "$rendered" == *"npm ci"* ]]
}

# ── 6. Confidence >= 0.8 is satisfied by a single verify(success=true) ────────

@test "confidence is >= 0.8 after one successful verify" {
  local sig="schema-reprompt-exhausted: prd:missing a problem/overview section heading"
  _write_3x_same_sig "$sig" "$PROMO_FIX"

  local learn_id
  learn_id=$(_get_learn_id "$sig")
  learning_verify "$learn_id" "true" "$PROJECT_LEARNED"

  local confidence
  confidence=$(node -p "
    try {
      const e = JSON.parse(require('fs').readFileSync('$PROJECT_LEARNED','utf-8'));
      const m = e.find(x => !x.archived && x.pattern === $(node -p "JSON.stringify('$sig')" 2>/dev/null || echo "\"\""));
      m ? m.confidence : 0;
    } catch(_) { 0; }
  " 2>/dev/null || echo "0")

  node -e "process.exit(parseFloat('$confidence') >= 0.8 ? 0 : 1)" 2>/dev/null
}

# ── 7. Entries below threshold do NOT become promotion candidates ─────────────

@test "entry with insufficient hits (hits=2) does not become a promotion candidate" {
  local sig="schema-reprompt-exhausted: prd:missing a problem/overview section heading"

  # Only 2 writes → hits=2 (below threshold of 3)
  learning_write "feat-a" "$sig" "$PROMO_FIX"
  learning_write "feat-b" "$sig" "$PROMO_FIX"

  local learn_id
  learn_id=$(_get_learn_id "$sig")
  learning_verify "$learn_id" "true" "$PROJECT_LEARNED"

  local flag
  flag=$(_get_promotion_flag "$sig")
  [ "$flag" = "false" ]
}
