<p align="center">
  <img src="assets/banner.svg" alt="Monozukuri — autonomous feature delivery" width="900">
</p>

<p align="center">
  <strong>ものづくり — reads your backlog, creates worktrees, invokes a Claude Code skill for each feature, and opens PRs. While you're away.</strong>
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
    <img src="https://img.shields.io/badge/platform-Claude%20Code-purple.svg" alt="Platform: Claude Code">
  </a>
  <a href="https://github.com/sponsors/Viniciuscarvalho">
    <img src="https://img.shields.io/badge/sponsor-♥-ea4aaa.svg" alt="Sponsor">
  </a>
</p>

<p align="center">
  <code>autonomous backlog</code> · <code>git worktrees</code> · <code>skill-agnostic</code> · <code>3-tier learning</code> · <code>Linear · GitHub · Markdown</code>
</p>

---

## Quick start

```bash
brew tap viniciuscarvalho/tap
brew install monozukuri

cd your-project
monozukuri doctor       # verify all dependencies are present and authenticated
monozukuri init
monozukuri run --dry-run    # preview the plan
monozukuri run              # execute
```

> **Requires:** `node >= 18`, `jq`, `gh` (for PR creation), and the Claude Code CLI (`claude`).  
> Run `monozukuri doctor` after install — it checks every dependency and surfaces missing auth in one pass.

---

## Highlights

- **One command, whole backlog.** `monozukuri run` walks every feature in your source — Linear, GitHub Issues, or a plain `features.md` — without further input.
- **Skill-agnostic.** Defaults to [Feature-marker](https://github.com/Viniciuscarvalho/Feature-marker), but works with any Claude Code skill. Swap via a single config line.
- **Isolated git worktrees per feature.** No branch juggling, no dirty working directory, no cross-contamination between runs.
- **Three autonomy levels.** From `supervised` (pause after each phase) to `full_auto` (fully unattended overnight runs).
- **Cost-aware size & cycle gates.** Skips features that are too large, verifies every phase completed, enforces token budgets.
- **3-tier learning store.** Every completed feature writes learnings at feature / project / global scope — the next run starts smarter.
- **Multiple backlog adapters.** `markdown`, `github`, `linear` — pick where your backlog already lives.
- **Local-first, zero vendor lock-in.** Runs on your machine, writes plain files, uses your own `claude` CLI credentials.

---

## How it works

<p align="center">
  <img src="assets/architecture.svg" alt="Monozukuri autonomous loop architecture" width="800">
</p>

```mermaid
flowchart LR
  B[Backlog] -->|size gate| W[Git Worktree]
  W -->|invoke skill| S["Claude Code Skill<br/>PRD → Tests → PR"]
  S -->|cycle gate| PR[Pull Request]
  PR -->|learning store| B
```

For each feature in the backlog, Monozukuri:

```
1. Reads + sorts backlog from your source (Linear, GitHub Issues, or features.md)
2. Runs the size gate — skips features that are too large or too risky
3. Creates an isolated git worktree with context from completed features
4. Calls your Claude Code skill (default: /feature-marker)
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
```

### NPM (global)

```bash
npm install -g @viniciuscarvalho/monozukuri
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
```

### `monozukuri init`

| Flag       | Default    | Description                                     |
| ---------- | ---------- | ----------------------------------------------- |
| `--force`  | `false`    | Overwrite existing config                       |
| `--source` | `markdown` | Backlog adapter: `markdown`, `github`, `linear` |

### `monozukuri run`

| Flag         | Default         | Description                                           |
| ------------ | --------------- | ----------------------------------------------------- |
| `--dry-run`  | `false`         | Preview the plan without executing                    |
| `--autonomy` | _(from config)_ | `supervised`, `checkpoint`, `full_auto`               |
| `--feature`  |                 | Run a single feature by ID                            |
| `--resume`   | `false`         | Skip already-completed features                       |
| `--model`    | _(from config)_ | Override model: `opus`, `sonnet`, `haiku`, `opusplan` |
| `--skill`    | _(from config)_ | Override skill command                                |

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
# Which Claude Code skill to invoke for each feature
skill:
  command: feature-marker

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

## Works with any Claude Code skill

Monozukuri is skill-agnostic. It defaults to [Feature-marker](https://github.com/Viniciuscarvalho/Feature-marker) but works with any Claude Code skill that handles feature implementation.

Configure which skill to invoke in `.monozukuri/config.yaml`:

```yaml
skill:
  command: feature-marker # any Claude Code slash-command
```

Popular options:

- [Feature-marker](https://github.com/Viniciuscarvalho/Feature-marker) — PRD → TechSpec → Tasks → Code → Tests → PR
- Your own custom skill
- No skill — just a well-written `CLAUDE.md` in your project

---

## Relationship to Feature-marker

Monozukuri and Feature-marker are **separate, independently installable tools** that work together:

|               | Feature-marker                         | Monozukuri                        |
| ------------- | -------------------------------------- | --------------------------------- |
| **What**      | Claude Code skill for one feature      | Terminal loop for a whole backlog |
| **Where**     | Inside Claude Code (`/feature-marker`) | Your terminal (`monozukuri run`)  |
| **Installs**  | `brew install feature-marker`          | `brew install monozukuri`         |
| **State dir** | `.claude/feature-state/`               | `.monozukuri/`                    |

The only connection is the `skill.command` config value in `.monozukuri/config.yaml`.

---

## Project layout

```
bin/                       CLI entry points (Node shim + shell dispatcher)
scripts/                   Orchestrator shell implementation
  orchestrate.sh           Main loop
templates/                 Config templates copied by `monozukuri init`
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
2. Run `./scripts/orchestrate.sh --help` to confirm your environment
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
