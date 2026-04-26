<p align="center">
  <img src="assets/banner.svg" alt="Monozukuri — autonomous feature delivery" width="900">
</p>

<p align="center">
  <strong>ものづくり — reads your backlog, creates worktrees, runs your coding agent of choice for each feature, and opens PRs. While you're away.</strong>
</p>

<p align="center">
  <a href="https://github.com/Viniciuscarvalho/monozukuri/actions/workflows/ci.yml">
    <img src="https://github.com/Viniciuscarvalho/monozukuri/actions/workflows/ci.yml/badge.svg" alt="CI">
  </a>
  <a href="https://www.npmjs.com/package/@viniciuscarvalho/monozukuri">
    <img src="https://img.shields.io/npm/v/@viniciuscarvalho/monozukuri.svg" alt="npm version">
  </a>
  <a href="https://github.com/Viniciuscarvalho/homebrew-tap">
    <img src="https://img.shields.io/badge/homebrew-tap-orange.svg" alt="Homebrew Tap">
  </a>
  <a href="https://github.com/Viniciuscarvalho/monozukuri/releases">
    <img src="https://img.shields.io/github/v/release/Viniciuscarvalho/monozukuri?include_prereleases" alt="Release">
  </a>
  <a href="https://github.com/Viniciuscarvalho/monozukuri/blob/main/LICENSE">
    <img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License: MIT">
  </a>
  <a href="https://github.com/Viniciuscarvalho/monozukuri">
    <img src="https://img.shields.io/badge/agents-Claude%20Code%20%C2%B7%20Codex%20%C2%B7%20Gemini%20%C2%B7%20Kiro-purple.svg" alt="Agents: Claude Code · Codex · Gemini · Kiro">
  </a>
  <a href="https://github.com/sponsors/Viniciuscarvalho">
    <img src="https://img.shields.io/badge/sponsor-♥-ea4aaa.svg" alt="Sponsor">
  </a>
</p>

<p align="center">
  <code>autonomous backlog</code> · <code>git worktrees</code> · <code>agent-agnostic</code> · <code>3-tier learning</code> · <code>Linear · GitHub · Markdown</code>
</p>

---

## Quick start

```bash
# First install
brew tap viniciuscarvalho/tap
brew install monozukuri

# Upgrade later
brew update && brew upgrade monozukuri
```

```bash
cd your-project
monozukuri doctor       # verify all dependencies are present and authenticated
monozukuri init
monozukuri run --dry-run    # preview the plan
monozukuri run              # execute
```

> **Requires:** `node >= 18`, `jq`, `gh` (for PR creation), and a supported coding-agent CLI (`claude`, `codex`, `gemini`, or `kiro`).  
> Run `monozukuri doctor` after install — it checks every dependency and surfaces missing auth in one pass.

---

## Choose your agent

Monozukuri drives any major coding-agent CLI through a single adapter contract. Pick the one you already have installed:

```yaml
# .monozukuri/config.yaml
agent: claude-code # default — needs the `claude` CLI
# agent: codex       # OpenAI Codex CLI  (needs OPENAI_API_KEY)
# agent: gemini      # Google Gemini CLI (needs GEMINI_API_KEY or gcloud ADC)
# agent: kiro        # AWS Kiro          (needs AWS credentials)
```

Switch at any time with `monozukuri agent enable <name>`, or detect what's available with `monozukuri agent list`.

---

## Highlights

- **One command, whole backlog.** `monozukuri run` walks every feature in your source — Linear, GitHub Issues, or a plain `features.md` — without further input.
- **Agent-agnostic.** Drives Claude Code, Codex, Gemini, or Kiro through a single adapter contract. Switch agents with one config line — no other changes required.
- **Isolated git worktrees per feature.** No branch juggling, no dirty working directory, no cross-contamination between runs.
- **Three autonomy levels.** From `supervised` (pause after each phase) to `full_auto` (fully unattended overnight runs).
- **Cost-aware size & cycle gates.** Skips features that are too large, verifies every phase completed, enforces token budgets.
- **3-tier learning store.** Every completed feature writes learnings at feature / project / global scope — the next run starts smarter.
- **Multiple backlog adapters.** `markdown`, `github`, `linear` — pick where your backlog already lives.
- **Local-first, zero vendor lock-in.** Runs on your machine, writes plain files, uses your own agent CLI credentials.

---

## How it works

<p align="center">
  <img src="assets/architecture.svg" alt="Monozukuri autonomous loop architecture" width="800">
</p>

```mermaid
flowchart LR
  B[Backlog] -->|size gate| W[Git Worktree]
  W -->|adapter contract| S["Coding Agent<br/>PRD → Tests → PR"]
  S -->|cycle gate| PR[Pull Request]
  PR -->|learning store| B
```

For each feature in the backlog, Monozukuri:

```
1. Reads + sorts backlog from your source (Linear, GitHub Issues, or features.md)
2. Runs the size gate — skips features that are too large or too risky
3. Creates an isolated git worktree with context from completed features
4. Invokes your coding agent (claude-code, codex, gemini, or kiro)
     └─ PRD → Tech Spec → Tasks → Code → Tests → PR
5. Runs the cycle gate — verifies all phases completed and PR exists
6. Writes learnings to the 3-tier store (feature / project / global)
7. Moves to the next feature → repeat until backlog is clean
```

---

## Installation

### Homebrew (recommended)

```bash
brew tap viniciuscarvalho/tap
brew install monozukuri

# Upgrade later
brew update && brew upgrade monozukuri
```

### NPM (global)

```bash
npm install -g @viniciuscarvalho/monozukuri

# Upgrade later
npm update -g @viniciuscarvalho/monozukuri
```

### NPX (no install)

```bash
npx @viniciuscarvalho/monozukuri run --dry-run
```

### From source

```bash
git clone https://github.com/Viniciuscarvalho/monozukuri.git
cd monozukuri
./scripts/orchestrate.sh --help
```

After any install method, run `monozukuri doctor` to confirm every dependency is available and authenticated.

---

## CLI reference

```bash
monozukuri init                           # scaffold .monozukuri/config.yaml in your project
monozukuri run                            # execute the backlog loop
monozukuri run --dry-run                  # preview the plan without executing
monozukuri run --autonomy full_auto       # fully autonomous (bypass permissions)
monozukuri run --feature feat-001         # run a single feature by ID
monozukuri run --resume                   # skip already-completed features
monozukuri status                         # show current loop state
monozukuri cleanup                        # remove worktrees and reset state
monozukuri learning list                  # show captured learnings
monozukuri calibrate                      # calibrate token cost estimates
monozukuri doctor                         # verify dependencies, auth, and environment
monozukuri agent list                     # list available agents and install status
monozukuri agent enable <name>            # set active agent in config (claude-code | codex | gemini | kiro)
monozukuri agent doctor [name]            # check install and auth for all or one agent
```

### `monozukuri init`

| Flag       | Default    | Description                                     |
| ---------- | ---------- | ----------------------------------------------- |
| `--force`  | `false`    | Overwrite existing config                       |
| `--source` | `markdown` | Backlog adapter: `markdown`, `github`, `linear` |

### `monozukuri run`

| Flag         | Default         | Description                                                          |
| ------------ | --------------- | -------------------------------------------------------------------- |
| `--dry-run`  | `false`         | Preview the plan without executing                                   |
| `--autonomy` | _(from config)_ | `supervised`, `checkpoint`, `full_auto`                              |
| `--feature`  |                 | Run a single feature by ID                                           |
| `--resume`   | `false`         | Skip already-completed features                                      |
| `--model`    | _(from config)_ | Override model: `opus`, `sonnet`, `haiku`, `opusplan`                |
| `--agent`    | _(from config)_ | Override agent: `claude-code`, `codex`, `gemini`, `kiro`             |
| `--skill`    | _(deprecated)_  | Deprecated — use `--agent` and `agents.claude-code.skills` in config |

### `monozukuri status`

| Flag     | Default | Description                        |
| -------- | ------- | ---------------------------------- |
| `--json` | `false` | Machine-readable output for piping |

### `monozukuri learning list`

| Flag      | Default | Description                              |
| --------- | ------- | ---------------------------------------- |
| `--tier`  | `all`   | `feature`, `project`, `global`, or `all` |
| `--limit` | `20`    | Maximum entries to show                  |

### `monozukuri cleanup`

| Flag    | Default | Description              |
| ------- | ------- | ------------------------ |
| `--yes` | `false` | Skip confirmation prompt |

---

## Autonomy levels

| Level        | Behaviour                                                      |
| ------------ | -------------------------------------------------------------- |
| `supervised` | Pauses after each phase for your approval                      |
| `checkpoint` | Full pipeline, creates PR, waits for merge before next feature |
| `full_auto`  | Full pipeline + `bypassPermissions` + proceeds immediately     |

Set once in `.monozukuri/config.yaml` or override per-run with `--autonomy`.

---

## Supported models

Set a default in config or override with `--model`.

| Alias      | Use case                                                          |
| ---------- | ----------------------------------------------------------------- |
| `opus`     | Highest reasoning, highest cost — complex features                |
| `sonnet`   | Balanced default for most features                                |
| `haiku`    | Fast, cheap — small features and calibration runs                 |
| `opusplan` | Opus for planning phases, Sonnet for implementation — recommended |

---

## Backlog adapters

| Adapter    | Source                             | Auth                       |
| ---------- | ---------------------------------- | -------------------------- |
| `markdown` | `features.md` in your project root | None                       |
| `github`   | GitHub Issues filtered by label    | `gh auth login`            |
| `linear`   | Linear issues filtered by team     | `LINEAR_API_KEY` in `.env` |

---

## Configuration

After `monozukuri init`, edit `.monozukuri/config.yaml`:

```yaml
# Active coding agent (claude-code | codex | gemini | kiro)
agent: claude-code

# Per-agent settings (optional)
agents:
  claude-code:
    skills:
      prd: feature-marker # Claude Code skill to use for each phase
      code: feature-marker # omit a phase to use the rendered prompt directly
  codex:
    model: gpt-5
  gemini:
    model: gemini-2.5-pro
  kiro:
    use_native_specs: true # use `kiro spec create` for prd/techspec phases

source:
  adapter: markdown # linear | github | markdown
  markdown:
    file: features.md

autonomy: checkpoint # supervised | checkpoint | full_auto

model:
  default: opusplan # opus | sonnet | haiku | opusplan
```

See [`templates/config.yaml`](./templates/config.yaml) for the full reference with every option documented.

---

## Project layout

```
orchestrate.sh             Entry point (dev); Homebrew/NPX wrappers exec this
cmd/                       Subcommand handlers (init, run, status, agent, …)
lib/                       Library modules
  agent/                   Adapter contract + per-agent adapters (claude-code, codex, gemini, kiro)
  config/                  Config loader and schema
  core/                    Utilities, router, cost, worktree
  cli/                     Output helpers and JSONL emitter
  prompt/phases/           Per-phase prompt templates (prd, techspec, tasks, code, tests, pr)
  run/                     Pipeline, cycle gate, ingest, local-model
  memory/                  3-tier learning store
ui/                        Ink TUI — consumes JSONL event stream from orchestrator
templates/                 Config templates copied by `monozukuri init`
test/
  unit/                    Bats unit tests (lib/agent/*, cmd/*)
  integration/             Bats integration tests (dry-run, back-compat)
  conformance/             Agent conformance suite + UI display tests
  fixtures/                Mock agent binaries and sample project
bin/                       CLI entry points (Node shim + shell dispatcher)
homebrew/                  Homebrew formula source
npm/                       npm package metadata and shim
assets/                    Banner, architecture diagram
docs/adr/                  Architecture Decision Records
```

---

## Architecture decisions

| ADR                                                | Decision                                                              |
| -------------------------------------------------- | --------------------------------------------------------------------- |
| [ADR-008](docs/adr/008-orchestrator-economy.md)    | Token economy: cost gates, routing, 3-tier learning, size/cycle gates |
| [ADR-009](docs/adr/009-local-models.md)            | Local model integration (Ollama embedding / classifier / summarizer)  |
| [ADR-010](docs/adr/010-stuck-state-elimination.md) | Stuck-state elimination: subshell fix, timeouts, PID tracking         |
| [ADR-011](docs/adr/011-security-hardening.md)      | Security: prompt sanitization, permission guardrails, stack detection |

---

## Development

```bash
make verify    # full pipeline: lint → format-check → test
make lint      # shellcheck on every script
make fmt       # shfmt -w on every script
make test      # bats integration tests
make release   # tag + publish to npm + bump Homebrew formula
```

---

## Contributing

1. Fork and clone the repo
2. Run `./orchestrate.sh --help` to confirm your environment
3. Open a draft PR early — we review small, focused changes fastest
4. Follow [Conventional Commits](https://www.conventionalcommits.org/) so release notes stay clean

See [CONTRIBUTING.md](./CONTRIBUTING.md) and the `good first issue` label for a friendly on-ramp.

---

## The name

**Monozukuri** (ものづくり) is a Japanese concept meaning "the art and science of making things." It embodies continuous improvement, craftsmanship, and the relentless pursuit of quality in creation — the same principles that should govern autonomous software delivery.

---

## License

MIT © [Vinicius Carvalho](https://github.com/Viniciuscarvalho)

---

<p align="center">
  Built with 🤖 for the AI-assisted development community
</p>
