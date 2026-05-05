> **Stale — superseded by the gap-driven launch plan.** This document was the original week-by-week execution checklist for v1.0. After a grilling session surfaced large gaps (session-auth blindness, multi-project ops absent, gate not enforced in CI, foreign-project context bootstrap missing), it was replaced by a risk-driven phase plan (Phases A–G). Preserved here for historical context only. Do not use as a source of truth.

---

# Monozukuri — Path B Execution Plan

**Decision:** Path B. Six focused weeks. Public v1.0 launch end of Week 6.

**This document is operational, not architectural.** All architecture is settled across the previous planning documents (Vision, Plan, Verification, Multi-Agent, Conventions, Skills, CLI Output, Release Map). This is the day-by-day checklist for actually shipping.

**Rule above all rules:** If a day's deliverable isn't done, the next day doesn't start. No skipping. No parallel work to "save time." The discipline is the deliverable.

---

## Week 0 — Setup (this weekend, before Week 1 starts)

Pre-work that must be done before Monday of Week 1, otherwise the whole plan slips immediately.

### Saturday — Decision artifacts

- [ ] Print this document. Tape it to your wall or pin in your IDE.
- [ ] Create GitHub Project board "Monozukuri v1.0" with 6 columns (Week 1 through Week 6)
- [ ] Create one issue per day below (30 issues total). Title format: `W1D1: Push local code to main`. Don't write descriptions — just titles for now.
- [ ] Add `v1.0` milestone to repo, target date = Monday Week 7
- [ ] Block calendar: 2 hours/day for 6 weeks. Same time daily. Non-negotiable.

### Sunday — Inventory

- [ ] Run on your local machine: `git status` in monozukuri repo
- [ ] List every uncommitted change, every local-only file, every WIP branch
- [ ] Save list as `LOCAL_INVENTORY.md` (do not commit yet)
- [ ] Identify which uncommitted changes correspond to which planning documents
- [ ] Mark which can ship as-is, which need cleanup, which should be discarded

If you have more than 3 hours of uncommitted work, that's a sign of how big the gap-to-Git is. Acknowledge it. Don't try to commit it all at once on Monday.

---

## Week 1 — Stop the bleeding

**Theme:** Get local code into Git. Add circuit breakers. Make next overnight run financially safe.

**Critical principle for Week 1:** No new features. Only versioning what exists + adding limits.

### Monday (W1D1) — Push local to main

- [ ] Triage `LOCAL_INVENTORY.md` into 3 buckets: ready-to-commit, needs-cleanup, discard
- [ ] Commit ready-to-commit changes in logical units (one feature per commit, conventional commit format)
- [ ] Push to `main`
- [ ] Verify CI passes (or note what doesn't run yet)

**Definition of done:** `git log origin/main` shows the work that's been running locally.

**Rollback:** Don't push if commits look messy. Better to spend Tuesday cleaning up than to push 47 commits at once.

### Tuesday (W1D2) — Move ADRs and docs

- [ ] Copy local ADRs to `docs/adr/` (012, 013, etc — anything past what's public)
- [ ] Move the 8 planning documents we've built into `docs/planning/` as historical record
- [ ] Update README to reference current ADRs
- [ ] Commit and push

**Definition of done:** anyone reading the repo can see the design history.

### Wednesday (W1D3) — Circuit breaker 1: max reprompts

In `lib/run/pipeline.sh` (or wherever schema reprompt lives):

```bash
: "${MONOZUKURI_MAX_REPROMPTS:=3}"

# In the schema validation loop:
if (( reprompt_attempt >= MONOZUKURI_MAX_REPROMPTS )); then
  monozukuri_emit phase.failed \
    --arg phase "$phase" \
    --arg reason "schema_validation_max_reprompts_exceeded" \
    --argjson attempts "$reprompt_attempt"
  return 14
fi
```

- [ ] Add the variable with default 3
- [ ] Update reprompt loop to respect it
- [ ] Add a Bats test: feature with persistent schema failure aborts after 3 attempts, not loops
- [ ] Document in `docs/configuration.md`

**Definition of done:** test passes; manually triggering a schema failure stops at attempt 3.

### Thursday (W1D4) — Circuit breaker 2: max phase attempts

```bash
: "${MONOZUKURI_MAX_PHASE_ATTEMPTS:=3}"

# Track per-phase attempt count in state
local attempt
attempt=$(monozukuri_state_get "$feature_id" "phase_${phase}_attempts" 0)
attempt=$((attempt + 1))
monozukuri_state_set "$feature_id" "phase_${phase}_attempts" "$attempt"

if (( attempt > MONOZUKURI_MAX_PHASE_ATTEMPTS )); then
  monozukuri_emit feature.failed \
    --arg feature_id "$feature_id" \
    --arg reason "phase_${phase}_max_attempts_exceeded"
  return 14
fi
```

- [ ] Add the variable + tracking
- [ ] Wire into pipeline before each phase invocation
- [ ] Bats test: feature stuck on same phase aborts after 3 attempts
- [ ] Document

**Definition of done:** test passes; the `feat-search` repeating-phase pattern from the recent output cannot recur.

### Friday (W1D5) — Circuit breaker 3: token cap + alias fix

```bash
: "${MONOZUKURI_MAX_TOKENS_PER_FEATURE:=100000}"

local total
total=$(monozukuri_state_get "$feature_id" total_tokens 0)
if (( total > MONOZUKURI_MAX_TOKENS_PER_FEATURE )); then
  monozukuri_emit feature.failed \
    --arg feature_id "$feature_id" \
    --arg reason "token_budget_exceeded" \
    --argjson tokens "$total"
  return 14
fi
```

- [ ] Add token cap
- [ ] **Fix TechSpec validator aliases:** accept any of `File Layout | Files | Files Touched | Files Affected | Implementation Files | files_likely_touched`
- [ ] Bats regression test: TechSpec with `## File Layout` section validates
- [ ] Force-fail any features stuck in current state files (manual cleanup)
- [ ] Tag as v1.20.0-alpha.1, push to npm with `--tag alpha`

**Definition of done:** alpha tag released. `npm install -g @viniciuscarvalho/monozukuri@alpha` installs it. Local test run completes without burning tokens on stuck features.

### Saturday — Week 1 retro (30 min)

- [ ] Review what shipped this week
- [ ] Note what slipped (if anything) and why
- [ ] Adjust Week 2 if needed (don't add scope; only remove)
- [ ] Run a 2-feature overnight test on a sandbox project
- [ ] Wake up Sunday, check results

If overnight test produces 2 successful features without token bleed, Week 1 succeeded. If not, that becomes Monday's debugging task and Week 2 slips by one day.

---

## Week 2 — Contract enforcement

**Theme:** Make full_auto really autonomous. Skills cannot block on user input.

### Monday (W2D1) — Define the contract

- [ ] Write `docs/contracts/skill-invocation.md` documenting:
  - Environment variables monozukuri sets when invoking a skill
  - What `MONOZUKURI_INTERACTIVE=0` requires (no questions, no blockers)
  - Expected output format (artifacts at known paths, sentinel at end)
  - Allowed failure modes (errors yes, asking questions no)

**Definition of done:** the contract is written down and committed. This is what you'll enforce against.

### Tuesday (W2D2) — Set the env vars in adapter

In `lib/agent/adapter-claude-code.sh`:

```bash
agent_run_phase() {
  local prompt; prompt=$(cat)

  export MONOZUKURI_INTERACTIVE
  if [[ "$MONOZUKURI_AUTONOMY" == "full_auto" ]]; then
    MONOZUKURI_INTERACTIVE=0
  else
    MONOZUKURI_INTERACTIVE=1
  fi

  export MONOZUKURI_FALLBACK_STRATEGY=document-and-proceed
  export MONOZUKURI_FEATURE_ID
  export MONOZUKURI_PHASE
  # ...

  echo "$prompt" | claude --print --model "$(resolve_model)"
}
```

- [ ] Export the env vars
- [ ] Same pattern for any other adapters that exist locally
- [ ] Push

**Definition of done:** running `monozukuri run --autonomy full_auto` exports `MONOZUKURI_INTERACTIVE=0` in the skill's env (verify with a debug skill that prints its env).

### Wednesday (W2D3) — Detect interactive output and fail loudly

The skill might still ignore the contract (especially feature-marker, which is external). Detect violations:

```bash
# In lib/run/pipeline.sh after capturing skill output
if [[ "$MONOZUKURI_INTERACTIVE" == "0" ]]; then
  if echo "$skill_output" | grep -qiE 'which (option|do you|would you)|please (confirm|choose|tell me)|\?$'; then
    monozukuri_emit feature.failed \
      --arg feature_id "$feature_id" \
      --arg reason "skill_violated_non_interactive_contract" \
      --arg evidence "$(echo "$skill_output" | grep -m1 '?' | head -c 200)"
    return 14
  fi
fi
```

- [ ] Add the detection
- [ ] Bats test: mock skill that asks a question is correctly flagged
- [ ] Document in error message what the user should do (file an issue against the skill)

**Definition of done:** the run from your most recent output (where feature-marker presented options A/B/C) would have failed cleanly with a specific reason instead of stalling.

### Thursday (W2D4) — Update feature-marker (separate repo)

This day is in the _feature-marker_ repo, not monozukuri:

- [ ] Read `MONOZUKURI_INTERACTIVE` env var
- [ ] When `=0`: never present option lists, never ask questions, instead make a defensible default and document in PRD's `## Open Questions` section
- [ ] When `=1`: behave as today
- [ ] Release feature-marker with a new minor version

**Definition of done:** running monozukuri full_auto with the new feature-marker against the same fixture project that previously hit the hook conflict completes the run with documented Open Questions.

If feature-marker is too tangled to update this fast, drop this day and use the time to add a config option `monozukuri.skip_known_problematic_skills: [feature-marker]` so monozukuri falls back to raw prompt invocation.

### Friday (W2D5) — Full integration test

- [ ] Build a fixture project with deliberate friction:
  - One feature with a missing dependency reference (forces "ambiguity")
  - One feature with a hook that conflicts with guardrails
  - One feature with a normally-successful spec
- [ ] Run `monozukuri run --autonomy full_auto` against it
- [ ] Document what happens

**Definition of done:** all 3 features either succeed or fail cleanly with structured reasons. Nothing stalls. Total cost <$5.

Tag v1.20.0-alpha.2 with the contract enforcement.

### Saturday — Week 2 retro + 5-feature overnight test

- [ ] Run a 5-feature overnight test on a sandbox project, full_auto, alpha.2
- [ ] Wake up Sunday, document results, identify what's still broken

This is the first test of "can it run unattended overnight at the size you actually want." Be honest with yourself about results.

---

## Week 3 — Real resume + operational learning

**Theme:** "Resume" actually resumes. Failures teach the system.

### Monday (W3D1) — Per-phase state granularity

Today's work is data structure, not features. Refactor state from per-feature to per-phase:

```yaml
# .monozukuri/state/feat-search.yaml (new format)
feature_id: feat-search
status: in-progress
phases:
  prd:
    status: completed
    completed_at: 2026-04-28T22:25:13Z
    tokens: 8420
    artifact: prd.md
  techspec:
    status: completed
    completed_at: 2026-04-28T22:27:01Z
    tokens: 12300
    artifact: techspec.md
  tasks:
    status: failed
    last_attempt_at: 2026-04-28T22:30:24Z
    error: schema_validation_max_reprompts_exceeded
    attempts: 3
  code:
    status: pending
  tests:
    status: pending
  pr:
    status: pending
```

- [ ] Define schema for new state file
- [ ] Write migration from old state format
- [ ] Update `monozukuri status` to read new format
- [ ] Bats tests for state read/write

**Definition of done:** existing in-flight features migrate cleanly to new format.

### Tuesday (W3D2) — Resume reads state and skips completed phases

```bash
# In pipeline.sh, before invoking each phase:
local phase_status
phase_status=$(monozukuri_state_get_phase "$feature_id" "$phase" status)

if [[ "$phase_status" == "completed" ]]; then
  monozukuri_emit phase.skipped --arg phase "$phase" --arg reason "already_completed"
  continue
fi
```

- [ ] Implement skip-completed logic
- [ ] Bats test: kill mid-Phase-3, run `--resume`, confirm Phases 1-2 skip and Phase 3 starts fresh

**Definition of done:** test passes. Resume actually resumes.

### Wednesday (W3D3) — Operational learning capture

When schema validation fails the same way 3+ times in a project, capture as project-tier learning:

```bash
# After schema failure
monozukuri_learning_record \
  --tier project \
  --kind operational \
  --summary "TechSpec validator expects 'files_likely_touched' but skill writes 'File Layout' — alias to add" \
  --evidence "feat-search/techspec, feat-export/techspec, feat-search-2/techspec" \
  --auto-applied false
```

When project-tier operational learning has `applied_count >= 3`, surface in next run:

```
WARNING: 3 features have failed with the same schema mismatch (files_likely_touched).
Consider adding alias to validation.md or filing an issue.
```

- [ ] Define operational learning schema
- [ ] Hook into schema failure path
- [ ] Surface accumulated operational learnings in run start banner
- [ ] Bats test

**Definition of done:** repeated schema failures become visible in subsequent runs as advisory output.

### Thursday (W3D4) — Worktree integrity recovery

Worktrees can become stale. Add cleanup logic:

- [ ] On run start: detect orphaned worktrees (in `.worktrees/` but no corresponding active feature)
- [ ] On feature failure (full_auto): cleanup worktree
- [ ] On feature failure (supervised/checkpoint): preserve worktree, log path for inspection
- [ ] `monozukuri cleanup --orphans` removes only orphans

**Definition of done:** running `monozukuri cleanup --dry-run` reports exactly what would be removed; `monozukuri cleanup --yes` removes only orphans (verified by test).

### Friday (W3D5) — Validation suite

Run the full integration suite against the work of Weeks 1-3:

- [ ] 5-feature run on Node fixture project, full_auto
- [ ] 3-feature run with deliberate friction
- [ ] Resume test: kill at random phase, --resume, verify continuation
- [ ] Cleanup test: run, fail intentionally, cleanup, verify clean state

Tag v1.20.0-alpha.3.

### Saturday — Week 3 retro

- [ ] Document which Week 3 deliverables shipped vs slipped
- [ ] Run another overnight test on sandbox
- [ ] Compare to Week 2 sandbox test — is improvement visible?

---

## Week 4 — Skills `mz-*` versioned

**Theme:** Monozukuri owns its skills.

This is the most architectural week. Slow it down if needed.

### Monday (W4D1) — Skill scaffolding

- [ ] Create `skills/` directory
- [ ] Scaffold 3 skills only: `mz-create-prd`, `mz-create-techspec`, `mz-create-tasks`
- [ ] Each gets `SKILL.md`, `template.md`, `validation.md`
- [ ] Lift existing templates (PRD, TechSpec) into the new locations

Don't try to scaffold all 8 skills this week. Three is enough to validate the pattern.

**Definition of done:** the 3 skill directories exist, each with the 3 files, all with content.

### Tuesday (W4D2) — Validator reads validation.md

```bash
# lib/run/validate-artifact.sh
validate_prd() {
  local file="$1"
  local rules
  rules=$(parse_validation_md "skills/mz-create-prd/validation.md")

  for required in $(echo "$rules" | jq -r '.required_sections[]'); do
    # ... check section exists, with alias support ...
  done
}
```

- [ ] Refactor validator to read from `validation.md`
- [ ] Bats test: validation rules update by editing validation.md, no code change

**Definition of done:** if you edit `skills/mz-create-prd/validation.md` to require a new section, the validator picks it up next run.

### Wednesday (W4D3) — `monozukuri setup` minimum viable

Don't aim for 5 agents. Aim for Claude Code only this week.

```bash
monozukuri setup                    # interactive, prompts for confirmation
monozukuri setup --agent claude-code --yes
monozukuri setup --uninstall
monozukuri setup --list
```

- [ ] Detect Claude Code (`~/.claude/` exists)
- [ ] Symlink the 3 skills into `~/.claude/skills/mz-*`
- [ ] Track installs in `~/.monozukuri/installed.json`
- [ ] Uninstall reverses cleanly

**Definition of done:** `monozukuri setup` works on your machine, installs skills, you can invoke `/mz-create-prd` from Claude Code directly.

### Thursday (W4D4) — Adapter prefers installed skill

```bash
# adapter-claude-code.sh
agent_run_phase() {
  local skill_name="mz-${MONOZUKURI_PHASE}"

  if mz_skill_installed "$skill_name" "claude-code"; then
    invoke_via_skill "$skill_name"
  else
    invoke_via_raw_prompt
  fi
}
```

- [ ] Detection function
- [ ] Skill invocation path
- [ ] Raw prompt fallback (already exists, just wire as fallback)
- [ ] Trace files distinguish `invocation_method`

**Definition of done:** with skills installed, traces show `invocation_method: skill`. Without, `invocation_method: raw_prompt`. Both produce schema-valid artifacts.

### Friday (W4D5) — Parity test

The test that proves the hybrid is honest:

- [ ] Run feature with `monozukuri setup` done — verify uses skill, artifacts valid
- [ ] `monozukuri setup --uninstall`, run same feature — verify uses raw prompt, artifacts valid
- [ ] Diff the artifacts — they should be schema-equivalent (same sections, same structure)

If the diff reveals divergence, fix this week before Week 5.

Tag v1.20.0-alpha.4.

### Saturday — Week 4 retro

The big check: does running with skills feel different than without? It should be slightly faster and produce identical artifacts. If artifacts differ structurally, something in the skill or template doesn't match the raw prompt — debug now, before release gate gets built on top of this.

---

## Week 5 — Release gate

**Theme:** Future regressions cannot ship.

This is the most important week. Without it, Weeks 1-4 erode silently over time.

### Monday (W5D1) — Layer 1: Build integrity

```
.qa/release-gate.sh
.qa/layers/01-build-integrity.sh
```

Layer 1 verifies the artifact installs and runs:

- [ ] Homebrew formula installs on clean prefix
- [ ] npm package installs in fresh node_modules
- [ ] `monozukuri --version` returns expected
- [ ] `monozukuri doctor` passes
- [ ] (If Ink TUI is being shipped) UI bundle loads without throwing

**Definition of done:** Layer 1 runs in <2 minutes and catches the 1.19.3-class bundle bug.

### Tuesday (W5D2) — Layer 2: Loop integrity

```
.qa/layers/02-loop-integrity.sh
.qa/fixtures/projects/sample-node-app/
.qa/mocks/mock-claude/
```

- [ ] Build mock-claude binary (canned responses for the 3 active phases)
- [ ] Build fixture project with 3 features
- [ ] Layer 2 runs the loop end-to-end against the fixture
- [ ] Verifies all 3 features complete, artifacts schema-valid, worktrees clean

**Definition of done:** Layer 2 catches the `MONOZUKURI_MEMORY_DIR`-class crash.

### Wednesday (W5D3) — Layer 3: Schema integrity + Layer 4: Backwards compat

Layer 3:

- [ ] Validate all fixture-generated artifacts against schemas
- [ ] Validate all alias rules work (PRD, TechSpec)

Layer 4:

- [ ] Migrate state from previous version's format
- [ ] Verify learning store readable across versions
- [ ] Verify resume works from prior-version state

**Definition of done:** both layers catch their respective regression classes.

### Thursday (W5D4) — Layer 5 + verdict + CI wiring

Layer 5: Live canary (one real `claude` invocation, one tiny feature, <$1)

- [ ] Live canary script
- [ ] Single-screen verdict format (PASS/FAIL with details)
- [ ] GitHub Actions workflow: `release-please` PR merge → release-gate runs → if pass, publish; if fail, abort

**Definition of done:** merging a release PR with a deliberate regression in code → CI fails → release does not publish.

### Friday (W5D5) — Run the gate against everything

- [ ] Run `release-gate.sh v1.0.0-rc.1` end-to-end
- [ ] Address every failure
- [ ] Run again until verdict is PASS

Tag v1.0.0-rc.1.

### Saturday — Week 5 retro

The release gate is now the law of the project. From here forward, no work merges to main without the gate passing. This is the structural change that makes v1.0 actually defendable.

---

## Week 6 — Polish and launch

**Theme:** External presentation. Ship publicly.

### Monday (W6D1) — README rewrite

Use the structure from the previous README plan + Compozy reference:

- [ ] Banner
- [ ] One-line pitch
- [ ] Badges (CI green, version, license)
- [ ] **Demo GIF** (record this Tuesday — placeholder for now)
- [ ] Highlights (8 bold-leadin bullets)
- [ ] Quick Start (4-step)
- [ ] How it Works (architecture diagram)
- [ ] CLI Reference (subcommand tables)
- [ ] Configuration
- [ ] Project Layout
- [ ] Architecture Decisions (link ADRs)
- [ ] Contributing
- [ ] License

**Definition of done:** README reads like a v1.0 product page, not a work-in-progress.

### Tuesday (W6D2) — Demo GIF

- [ ] Record asciinema of a real run: 3 features, full_auto, success
- [ ] Convert with `agg` to GIF
- [ ] Save as `assets/demo.gif`
- [ ] Add to README near the top

**Definition of done:** the GIF clearly shows monozukuri running and producing PRs.

### Wednesday (W6D3) — Output polish

The CLI output cleanup that's been discussed for weeks:

- [ ] Drop `[pricing]` prefix everywhere; replace with nothing or `[mz]`
- [ ] Status symbols: `▶ ✓ ✗ ⊘ ○`
- [ ] Phase codes: 3 letters
- [ ] Color: only on status column
- [ ] Width: respects 80 cols
- [ ] `phase: ""` empty fields fixed in events

Don't aim for the full polished-CLI plan. Just fix what looks unprofessional.

### Thursday (W6D4) — Project tooling

- [ ] CONTRIBUTING.md (5-step setup for contributors)
- [ ] CODE_OF_CONDUCT.md (Contributor Covenant 2.1)
- [ ] SECURITY.md (how to report vulnerabilities)
- [ ] `.github/ISSUE_TEMPLATE/` (bug, feature, question)
- [ ] `.github/PULL_REQUEST_TEMPLATE.md`
- [ ] `.github/dependabot.yml`
- [ ] `.editorconfig`, `.pre-commit-config.yaml`
- [ ] Conventional commits enforced via commitlint

**Definition of done:** opening an issue or PR shows structured templates. CI runs hooks.

### Friday (W6D5) — Final release rehearsal

- [ ] Run release-gate locally against current main
- [ ] Verify GitHub Actions workflow on a fork or branch (don't tag yet)
- [ ] Write Show HN post draft
- [ ] Write Dev.to post draft
- [ ] Open 10 "good first issue" tickets

**Definition of done:** everything is ready to push v1.0.0 tag on Sunday.

### Saturday — Pre-launch testing

- [ ] One last 5-feature overnight run on sandbox project
- [ ] Document results
- [ ] If clean: greenlight Sunday launch
- [ ] If issues: triage, decide if blocker or post-launch

### Sunday — LAUNCH

Time of day matters. Show HN posts at Tuesday-Thursday 8-10am ET get most traction. So actually:

**Don't launch Sunday.** Launch Tuesday W7D2 8am ET.

This Sunday:

- [ ] Tag v1.0.0
- [ ] Push tag, verify release-gate passes, verify npm + brew publish
- [ ] Test install from fresh machine
- [ ] Sleep on it Monday — gives you a buffer day to fix any critical install issue

---

## Week 7 — Launch (only Tuesday matters here)

### Tuesday (W7D2) — Show HN

- [ ] 8:00am ET: Show HN post
- [ ] Stay on thread for 3 hours, answer every comment
- [ ] Cross-post to Reddit (r/ClaudeAI, r/commandline) at 11am
- [ ] Dev.to post at 1pm
- [ ] Submit to awesome-claude-code, awesome-cli-apps lists by EOD

The rest of Week 7 is responding to feedback, fixing issues users find, planning v1.1 (TUI fix, multi-LLM adapters, conventions plan).

---

## Daily protocol

Same time every day. Two hours. Six weeks. No exceptions except illness.

**Hour 1:** the day's deliverable.
**Hour 2:** documentation, tests, push.

**End of day ritual (5 minutes):**

- Check off the day's box in this document
- Commit and push
- Note any blockers in tomorrow's issue
- Close the laptop

If a day's deliverable is genuinely too big, split it across two days, push the rest of that week back by one day. Don't compress to "catch up" — that's how Week 5 turns into a feature week and the gate doesn't get built.

---

## Kill switches for scope creep

These six weeks are tight. The biggest threat is "while I'm in there, I'll also fix X." Don't.

| Temptation                                | Defer to                  |
| ----------------------------------------- | ------------------------- |
| TUI Ink fix                               | v1.1                      |
| Multi-LLM adapters (Codex, Gemini, Aider) | v1.2                      |
| AGENTS.md auto-generation                 | v1.2                      |
| `monozukuri routing suggest`              | v1.3                      |
| Pricing per-model database                | v1.1                      |
| Hosted runner / SaaS                      | never (or v2.0 if signal) |
| 40+ agent breadth                         | v1.2                      |
| Web dashboard                             | never                     |
| Polished CLI output (full plan)           | v1.1                      |

If a feature isn't in the day-by-day above, **it doesn't go into v1.0.** Period.

The way to enforce this: write the temptation down in `docs/v1.1-backlog.md`, close the IDE tab, return to the day's deliverable. The backlog file is your release valve.

---

## Weekly retro template

End of every Saturday, fill this out:

```
Week N retro:
- Shipped: [what got done]
- Slipped: [what didn't, why]
- Learned: [unexpected things]
- Adjusted Week N+1: [if anything]
- Health check: [am I still on track for v1.0 in Week 6?]
```

If the health check turns red two weeks in a row, that's a signal to either cut scope or extend timeline. Don't push through and arrive at v1.0 with broken work.

---

## What to communicate publicly during the 6 weeks

**Don't tweet about the journey.** It creates pressure that distorts decisions. The launch post in Week 7 is the moment.

**Exception:** if you fix a specific bug that affected the runs we discussed (token bleed, schema mismatch, stuck phases), a single tweet is fine: "Fixed circuit breaker bug in Monozukuri — features can no longer burn unlimited tokens." That's value, not hype.

The launch is Tuesday Week 7. Build for that, not for the days in between.

---

## Final non-negotiable

If, after Week 5, the release gate is not passing reliably on `main`, **do not tag v1.0.** Push the launch back one week. The release gate is the difference between a credible v1.0 and a v0.x with confident branding. Skipping it to hit a date kills the entire point of Path B.

If you're tempted to skip it, re-read this document from the top and remember why you chose Path B over Path A.

---

## What you're holding right now

A six-week plan with 30 daily deliverables, zero new architecture, every day shippable. The architecture work is done in the previous 8 documents. **The work this week and the next five is execution discipline, not design.**

If you check off all 30 boxes, monozukuri ships v1.0 publicly on Tuesday of Week 7 with a release gate ensuring it stays shipped. That's the whole plan.

The single most important thing you can do today: print this document, pick the box for tomorrow (W1D1: Push local code to main), and do that one thing. Don't read ahead. Don't plan further. Just tomorrow's box.
