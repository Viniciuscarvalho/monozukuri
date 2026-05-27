![Monozukuri — autonomous feature delivery](assets/banner.svg)

**ものづくり — reads your backlog, creates worktrees, runs a coding agent for each feature, and opens PRs. While you're away.**

[![npm version](https://img.shields.io/npm/v/@viniciuscarvalho/monozukuri.svg)](https://www.npmjs.com/package/@viniciuscarvalho/monozukuri)
[![Homebrew Tap](https://img.shields.io/badge/homebrew-tap-orange.svg)](https://github.com/Viniciuscarvalho/homebrew-tap)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Agents: Claude Code · Codex · Gemini](https://img.shields.io/badge/agents-Claude%20Code%20%C2%B7%20Codex%20%C2%B7%20Gemini-purple.svg)](https://github.com/Viniciuscarvalho/monozukuri)

**Monozukuri** (ものづくり) is a Japanese concept meaning "the art and science of making things" — continuous improvement, craftsmanship, and the relentless pursuit of quality in creation. The same principles that should govern autonomous software delivery.

![Monozukuri in action](docs/assets/pick-loop.gif)

![Web dashboard — both features complete](docs/assets/dashboard.png)

## Quick start

```bash
brew tap viniciuscarvalho/tap
brew install monozukuri

cd your-project
monozukuri init
monozukuri doctor
monozukuri backlog list
monozukuri pick --top 3 | monozukuri loop
```

Requires `node >=18`, `jq`, `gh`, and a coding agent CLI (`claude`, `codex`, or `gemini`). See [docs/installation.md](docs/installation.md) for NPX, source installs, and platform notes.

## What Monozukuri does

For each selected feature, Monozukuri creates an isolated git worktree, runs a coding agent through PRD, TechSpec, Tasks, Code, Tests, and PR phases, then opens a pull request and moves to the next feature.

It runs from supervised mode to `full_auto`, persists state under `.monozukuri/`, supports resume after interruptions, and uses Memory v2 to keep learnings traceable instead of hidden in prompt history.

## Pick & Loop

`pick` selects ranked backlog IDs. `loop` executes them.

```bash
monozukuri backlog list --label cli,docs --agent codex
monozukuri pick --top 3
monozukuri pick --top 3 --json | jq -r '.[].id' | monozukuri loop
monozukuri loop status --follow
monozukuri loop --resume
```

Full details live in [docs/execution.md](docs/execution.md), [docs/schemas/loop-state.md](docs/schemas/loop-state.md), and [docs/v2-migration.md](docs/v2-migration.md).

## Memory v2

Memory v2 records where each learning came from, how often it was applied, and which agent should see it. The sufficiency router injects compact summaries first and lets agents request raw detail with `<request-memory id="lrn-xxx"/>` only when needed.

Start with:

```bash
monozukuri memory migrate --dry-run
monozukuri memory migrate
monozukuri memory why <lrn-id>
monozukuri memory trace <run-id>
```

Read [docs/schemas/memory-v2.md](docs/schemas/memory-v2.md), [docs/adr/027-sufficiency-router.md](docs/adr/027-sufficiency-router.md), and [docs/experiments/sufficiency-router/README.md](docs/experiments/sufficiency-router/README.md) for the schema, decision, and MEM-05 data.

## Documentation

| Topic | Where |
| --- | --- |
| v1 to v2 migration | [docs/v2-migration.md](docs/v2-migration.md) |
| Execution and loop behavior | [docs/execution.md](docs/execution.md) |
| Configuration reference | [docs/configuration.md](docs/configuration.md) |
| Backlog adapters | [docs/adapters.md](docs/adapters.md) |
| Troubleshooting | [docs/troubleshooting.md](docs/troubleshooting.md) |
| Release process | [docs/release-process.md](docs/release-process.md) |
| v2 alpha readiness | [docs/release/v2-alpha.md](docs/release/v2-alpha.md) |
| Architecture decisions | [docs/adr/](docs/adr/) |

## Architecture decisions

| ADR | Decision |
| --- | --- |
| [ADR-024](docs/adr/024-backlog-priority-scoring.md) | Backlog priority scoring |
| [ADR-025](docs/adr/025-memory-v2-provenance-schema.md) | Memory v2 provenance schema |
| [ADR-026](docs/adr/026-sufficiency-router-design.md) | MEM-05 sufficiency-router spike |
| [ADR-027](docs/adr/027-sufficiency-router.md) | Production sufficiency-router convention |

## License

MIT © [Vinicius Carvalho](https://github.com/Viniciuscarvalho)

Created and maintained by Vinicius Carvalho.
