<!-- monozukuri:generated-start v1 -->
<!-- This section is maintained by monozukuri. Manual edits inside these markers will be overwritten on next generate. -->

<!-- monozukuri:generated-end -->

# AGENTS.md

> Canonical agent-instructions file for this repo. `CLAUDE.md` and `GEMINI.md` are symlinks to this file so every coding agent sees the same conventions. Codex and Aider read `AGENTS.md` natively. Per-package `AGENTS.md` (e.g. `ui/AGENTS.md`) take precedence in their subtree.

Monozukuri is an autonomous feature-delivery CLI. It reads a backlog (Linear, GitHub Issues, or `features.md`), runs a 6-phase loop per feature (PRD → TechSpec → Tasks → Code → Tests → PR), and opens pull requests autonomously.

It is **not** a Claude Code skill itself. It runs _outside_ any coding agent and calls it via the agent's CLI (Claude Code, Codex, Gemini, Kiro, or Aider).

## Stack

- Bash 4+ (orchestration, adapters, validators, gates)
- Node 18+ with Ink/React (TUI + JS adapters/validators)
- Distribution: Homebrew tap, npm (`@viniciuscarvalho/monozukuri`), repo-dev
- Tests: Bats (`test/unit/`, `test/integration/`, `test/conformance/`, `test/properties/`)

## Repository layout

```
bin/                Entry points (Node dispatcher → cmd/*.sh)
cmd/                One file per subcommand: run, init, status, doctor, setup, cleanup, ...
lib/
  agent/            Adapter contract + per-agent implementations (claude-code, codex, gemini, kiro, aider)
  cli/              Output, colors, symbols, layout, emit, errors
  config/           Schema, loader, validators
  core/             Loop, worktree, exit-codes, router, cost
  ingest/           Backlog adapters (markdown, github, linear)
  memory/           3-tier learning store
  ops/              Operational helpers
  prompt/           Templates (phases/) + render.sh
  review/           Review tooling
  run/              Pipeline, validators, retry, shutdown, workflow-scratchpad
  schema/           validate.sh — the schema reprompt loop
  setup/            First-run setup
  ui/               TUI helpers
skills/             mz-* skills (Claude Code only — codex/gemini use rendered prompts)
templates/          Scaffolds copied by `monozukuri init`
.qa/                Release gate: layers/, fixtures/, mock binaries, recordings
docs/adr/           Architecture Decision Records — read before changing core behavior
ui/                 Ink TUI (optional)
test/               Bats tests
```

## State directory

- Per-project state: `.monozukuri/` (created by `monozukuri init` in the user's project)
- Per-run scratchpad: `.monozukuri/runs/<run_id>/<feature_id>/` (state.json, memory/, logs/)
- Workflow memory: `<run_dir>/<feature_id>/memory/` — produced by `workflow_memory_prepare`
- Global learning store: `~/.claude/monozukuri/learned/`
- Worktrees: `.worktrees/<feature_id>/` (relative to the user's project root)

## v1.0 SLO

> **3 foreign projects × 5 features each × ≤30% Phase-3 pause rate × $50/night cost ceiling × weekly triage.**

Layer 6 of the release gate (`.qa/layers/06-scale-soak.sh`) is the machine-readable enforcement of this SLO. If Layer 6 fails, v1.0 does not tag. See `docs/release-process.md`.

## Key env vars

| Variable                          | Purpose                                                             |
| --------------------------------- | ------------------------------------------------------------------- |
| `MONOZUKURI_HOME`                 | Set by wrappers; points to install root (contains `lib/`, `cmd/`)   |
| `MONOZUKURI_AUTONOMY`             | `supervised` \| `checkpoint` \| `full_auto` (default: `checkpoint`) |
| `ANTHROPIC_MODEL`                 | Override model (highest precedence over config)                     |
| `LINEAR_API_KEY`                  | Required when `source.adapter: linear`                              |
| `SKILL_TIMEOUT_SECONDS`           | Wall-clock cap per adapter call (default 1800; codex/gemini/kiro)   |
| `MONOZUKURI_SCHEMA_MAX_REPROMPTS` | Schema fix reprompts before pausing (default 3)                     |
| `MONOZUKURI_MAX_FEATURE_TOKENS`   | Token-spend ceiling per feature (default 80 000; claude-code only)  |
| `MAX_RETRIES`                     | Feature-level retry attempts before marking failed (default 2)      |
| `MONOZUKURI_SKIP_LIVE_CANARY`     | `1` in CI — skip Layer 5 (live `claude` call)                       |
| `MONOZUKURI_SKIP_SCALE_SOAK_LIVE` | `1` in CI — skip live variant of Layer 6                            |
| `MONOZUKURI_SKIP_CONFORMANCE`     | `1` in CI — skip Layer 7 (replay-vs-live drift check)               |

`SKILL_COMMAND` is deprecated and maps to `agents.claude-code.skills.<phase>` via the back-compat shim in `lib/config/load.sh`.

## Entry points

| How installed | Command                                         |
| ------------- | ----------------------------------------------- |
| Homebrew      | `monozukuri <subcommand>`                       |
| NPX           | `npx @viniciuscarvalho/monozukuri <subcommand>` |
| Repo (dev)    | `./orchestrate.sh <subcommand>`                 |

All three set `MONOZUKURI_HOME` and exec `orchestrate.sh`. The top-level script resolves `LIB_DIR=$MONOZUKURI_HOME/lib`, `CMD_DIR=$MONOZUKURI_HOME/cmd`, `SCRIPTS_DIR=$MONOZUKURI_HOME/scripts`. `scripts/orchestrate.sh` is a compatibility shim for Homebrew v1.0.0 installs only.

## Agent invocation

The default agent is `claude-code`. Change in `.monozukuri/config.yaml`:

```yaml
agent: claude-code # default — uses the claude CLI
# agent: codex     # OpenAI Codex CLI
# agent: gemini    # Google Gemini CLI
# agent: kiro      # AWS Kiro
# agent: aider     # Aider
```

Skills (`mz-*`) are a **Claude Code feature only**. Codex, Gemini, and Aider use rendered prompts injected via `lib/prompt/render.sh` and may produce less consistent artifact structure on complex projects. Skill parity for those agents is planned for v1.2.

## Conventions you must follow

### Validator contracts are authoritative

Phase artifacts are validated by `lib/schema/validate.sh` against the schemas in `lib/schema/`. Validators accept heading aliases — never reject valid content over heading-name nitpicks. When adding a required section, update the template (`lib/prompt/phases/<phase>.tmpl.md` and/or `skills/mz-*/template.md`), the schema, **and** `test/properties/agent_output.bats` together — the property bats encode the same heading contract the validator enforces.

Accepted heading aliases:

- Problem section: `## Problem | Problem Statement | Background | Overview | Motivation | Background/Motivation`
- File-list section (TechSpec): `## File Layout | Files | Files Touched | Implementation Files | files_likely_touched`

### Full_auto contract is sacred

When `MONOZUKURI_AUTONOMY=full_auto`, skills must NEVER ask for human input. Make a defensible default, document the assumption in `## Open Questions`, and proceed. If you find a code path that asks for input in full_auto, that's a bug — fix the path, don't soften the contract.

For the current list of external skills confirmed to violate this contract, see [`docs/adapter-contract.md#known-incompatible-skills`](docs/adapter-contract.md#8-known-incompatible-skills). `monozukuri doctor` warns when any of these are active in `.monozukuri/config.yaml`.

### Reuse existing systems — don't reinvent

Before writing new code, check if it already exists:

- 3-tier learning store: `lib/memory/learning.sh` — capture project/global learnings here, not ad-hoc files
- Workflow memory: `<run_dir>/<feature_id>/memory/` via `workflow_memory_prepare` (`lib/run/workflow-scratchpad.sh`)
- Schema reprompt loop: `lib/schema/validate.sh` — feeds validator errors back into the next prompt
- Phase templates: `lib/prompt/phases/<phase>.tmpl.md` and `skills/mz-*/template.md` — render via `lib/prompt/render.sh`
- Event emit: `lib/cli/emit.sh` — use `monozukuri_emit`, never `echo` JSON events by hand
- Errors: `lib/cli/errors.sh` — use `monozukuri_error "what" "why" "fix" CODE`, never raw `echo "error" >&2`

### Protected directories

Do NOT write to:

- `.claude/` (Claude Code's territory)
- Anywhere outside the active worktree during a phase
- The user's home directory unless via `monozukuri setup` with consent

### Bash discipline

- `set -euo pipefail` at the top of every script
- Variables: `local x="$1"` always; quote all expansions; `${VAR:-default}` for optionals (especially under `set -u` — unbound-var aborts in subshells are a real failure mode)
- Function naming: `monozukuri_*` for the public output/emit/error API in `lib/cli/`; short module prefixes elsewhere (`_cc_*` claude-code adapter, `_l2_*` Layer 2 helpers, `_thin_shell_*` adapter base, `_wfm_*` workflow memory)
- `shellcheck --severity=error` clean — CI runs `find scripts -name "*.sh" | xargs shellcheck --severity=error`
- `shfmt -w -i 2` formatting (run via `make fmt`)
- Bake `$tmpdir` into RETURN traps with double quotes (`trap "rm -rf '$tmpdir'" RETURN`) — single quotes defer expansion until the local var may already be torn down under `set -u`

### Test infrastructure (record-replay pattern, zero CI cost)

Mocks are **recordings**, not hand-written canned text:

```
.qa/fixtures/recordings/<agent>/<phase>.{md,json,stream-json}
.qa/fixtures/recordings/metadata.json     # capture provenance
.qa/fixtures/mocks/replay-claude          # replay binary
.qa/fixtures/contexts/canary-feature.json
test/properties/agent_output.bats         # structural assertions, every PR
.qa/layers/07-conformance.sh              # replay-vs-live drift check
```

Mock modes (via `MOCK_CLAUDE_MODE`): `normal` (replay verbatim) | `hang` | `auth-expired` | `diverge` (drops a heading) | `build-fail`.

**Cost discipline:** Layers 5, 6-live, and 7 honour `MONOZUKURI_SKIP_*=1` flags, and CI sets every one of them to `1` in `.github/workflows/release-gate.yml`. Re-recording (`make rerecord-fixtures`) and `make conformance` are local-only developer commands. **Don't add a CI workflow that calls a live model** — see `docs/test-strategy.md`.

### Exit codes (defined in `lib/core/exit-codes.sh`)

```
EXIT_OK=0                    EXIT_CYCLE_GATE=13
EXIT_GENERIC=1               EXIT_SKILL_FAILED=14
EXIT_MISUSE=2                EXIT_WORKTREE_DIRTY=15
EXIT_CONFIG_INVALID=10       EXIT_USER_ABORT=20
EXIT_DEPENDENCY_MISSING=11   EXIT_AGENT_BLOCKED=21
EXIT_SIZE_GATE=12
```

Use named constants from `exit-codes.sh`, never bare numbers.

### Module load order (sub_run)

`lib/core/util.sh → lib/config/load.sh → lib/core/worktree.sh → lib/memory/memory.sh → lib/cli/output.sh → lib/core/json-io.sh → lib/core/stack-profile.sh → lib/core/cost.sh → lib/core/router.sh → lib/memory/learning.sh → lib/run/cycle-gate.sh → [lib/run/local-model.sh] → [lib/run/ingest.sh] → [lib/run/injection-screen.sh] → lib/run/pipeline.sh`

### Config resolution order

`.monozukuri/config.yaml` → `.monozukuri/config.yml` → `$TEMPLATES_DIR/config.yaml`

### Commits

Conventional commits enforced by commitlint:

```
feat(scope): description     fix(scope): description
docs(scope): description     refactor(scope): description
test(scope): description     ci(scope): description     chore(scope): description
```

Common scopes from history: `cli`, `core`, `agent`, `prompt`, `run`, `memory`, `setup`, `qa`, `ci`, `tui`, `adapters`, `arch`, plus phase-style `phase-c` … `phase-g`.

## Common tasks

- **Run all tests:** `make test` (or `bats test/unit test/integration test/conformance test/properties`)
- **Run only property tests:** `make test-properties` (free, fast — no API calls)
- **Lint:** `make lint` • **Format:** `make fmt` (shfmt -w -i 2)
- **Build TUI:** `npm run build --prefix ui`
- **Release gate locally (CI-equivalent):** `MONOZUKURI_SKIP_LIVE_CANARY=1 MONOZUKURI_SKIP_SCALE_SOAK_LIVE=1 MONOZUKURI_SKIP_CONFORMANCE=1 .qa/release-gate.sh v1.0.0-rc.X`
- **Re-record mock fixtures:** `make rerecord-fixtures` (LOCAL ONLY — ~$0.50/agent)
- **Run Layer 7 conformance:** `make conformance` (LOCAL ONLY — ~$0.30)

## When unsure

1. Read the relevant ADR in `docs/adr/` — they document why things are the way they are
2. Run `monozukuri doctor` to verify environment
3. Search for an existing utility before writing a new one
4. Prefer narrower scope: add what's asked, not adjacent improvements

## What NOT to do

- Don't add new dependencies without explicit justification (npm or shell)
- Don't bypass the validator with `|| true` — fix the validator or fix the output
- Don't add new mock binaries — extend recordings under `.qa/fixtures/recordings/`
- Don't add a GitHub Actions workflow that invokes a live agent (claude/codex/gemini) — keeps CI cost at $0
- Don't write to `main` directly — feature branches + PR + release gate
- Don't introduce a new output prefix like `[component]` — use `monozukuri_info/warn/error` helpers
- Don't single-quote `$tmpdir` (or any local) inside a RETURN trap under `set -u` — expand at trap-set time instead
