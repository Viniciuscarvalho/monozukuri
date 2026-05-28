![Monozukuri — autonomous feature delivery](assets/banner.svg)

**ものづくり — turn a backlog into small, reviewable pull requests with coding agents, project skills, memory, and cost controls.**

[![npm version](https://img.shields.io/npm/v/@viniciuscarvalho/monozukuri.svg)](https://www.npmjs.com/package/@viniciuscarvalho/monozukuri)
[![Homebrew Tap](https://img.shields.io/badge/homebrew-tap-orange.svg)](https://github.com/Viniciuscarvalho/homebrew-tap)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Agents: Claude Code · Codex · Gemini](https://img.shields.io/badge/agents-Claude%20Code%20%C2%B7%20Codex%20%C2%B7%20Gemini-purple.svg)](https://github.com/Viniciuscarvalho/monozukuri)

**Monozukuri** (ものづくり) is a Japanese concept meaning "the art and science of making things" — continuous improvement, craftsmanship, and the relentless pursuit of quality in creation. The same principles that should govern autonomous software delivery.

![Monozukuri in action](docs/assets/pick-loop.gif)

![Web dashboard — both features complete](docs/assets/dashboard.png)

## What is Monozukuri?

Monozukuri is an open-source orchestrator for autonomous software delivery. It reads a backlog, ranks or selects features, creates isolated worktrees, runs a coding agent through a delivery pipeline, validates the result, opens pull requests, and preserves memory for the next run.

It does not replace Claude Code, Codex, or Gemini. It coordinates them.

Use a coding agent directly for a one-off change. Use Monozukuri when you want a repeatable queue of work with memory, validation, resumability, and cost control.

## Why use it?

- **Turn backlog into PRs:** select one or more features and let the loop execute them as separate work.
- **Keep context between runs:** Memory v2 records learnings, provenance, agent scope, and usage history.
- **Use project skills:** inject compatible skills from `.agents/skills/*/SKILL.md` and `.claude/skills/*/SKILL.md`.
- **Control spend:** set hard caps for cost, time, and tokens per task.
- **Recover cleanly:** resume from checkpoints after interruption, timeout, or machine failure.
- **Ship reviewable changes:** work happens in isolated worktrees and ends as pull requests.

## When not to use it

Monozukuri is not the fastest path for every change. Skip it when you only need a small, isolated edit and already know exactly what to ask an agent.

It works best when your project has a backlog, clear acceptance criteria, a test or validation path, and at least one authenticated agent CLI.

## Install

### v2 alpha

Use the alpha channel if you want `pick`, `loop`, Memory v2, and the new orchestration work.

```bash
npm install -g @viniciuscarvalho/monozukuri@next
```

or:

```bash
brew tap viniciuscarvalho/tap
brew install monozukuri-next
```

Then verify the install:

```bash
monozukuri doctor
# or, from Homebrew alpha:
monozukuri-next doctor
```

### Requirements

- Node.js 18+
- `jq`
- `gh` authenticated for pull request creation
- One agent CLI authenticated locally: `claude`, `codex`, or `gemini`

See [docs/installation.md](docs/installation.md) for NPX, source installs, and platform notes.

## First run

Inside a git project:

```bash
monozukuri init
monozukuri doctor
monozukuri backlog list
monozukuri pick --top 2 | monozukuri loop
```

If you installed the Homebrew alpha formula, use `monozukuri-next` in place of `monozukuri`.

## How it works

```text
backlog -> pick -> loop -> worktree -> agent phases -> tests -> PR -> memory
```

For every selected feature, Monozukuri runs a six-phase delivery pipeline:

| Phase | Output |
| --- | --- |
| PRD | Feature intent and acceptance criteria |
| TechSpec | Implementation plan and touched files |
| Tasks | Ordered implementation steps |
| Code | Changes in an isolated worktree |
| Tests | Validation and test summary |
| PR | Pull request with summary and evidence |

The loop keeps each feature independent. A failure in one task does not have to destroy the rest of the queue.

## Pick & Loop

`pick` selects ranked backlog IDs. `loop` executes them.

```bash
monozukuri backlog list --label cli,docs --agent codex
monozukuri pick --top 3
monozukuri pick --top 3 --json | jq -r '.[].id' | monozukuri loop
monozukuri loop status --follow
monozukuri loop --resume
```

Useful loop controls:

```bash
monozukuri loop feat-001 feat-002 --max-cost 5 --max-time 120
monozukuri loop --resume
monozukuri loop --list-runs
monozukuri loop status --follow
```

See [docs/execution.md](docs/execution.md) and [docs/schemas/loop-state.md](docs/schemas/loop-state.md) for the full behavior.

## Modes

Monozukuri supports different autonomy levels depending on how closely you want to supervise the run.

| Mode | Use when | Behavior |
| --- | --- | --- |
| `supervised` | You are watching the run | Shows interactive progress and pauses for decisions |
| `checkpoint` | You want safe automation | Runs until review or recovery checkpoints |
| `full_auto` | You want unattended execution | Continues without prompts, guarded by caps and circuit breakers |

Example:

```bash
MONOZUKURI_AUTONOMY=full_auto monozukuri pick --top 3 | monozukuri loop
```

## Agents and skills

Monozukuri runs outside the coding agent and invokes the agent through its CLI.

Supported agent targets include:

- Claude Code
- OpenAI Codex
- Gemini
- Kiro and Aider adapters where configured

Project skills can live in:

```text
.agents/skills/<skill-name>/SKILL.md
.claude/skills/<skill-name>/SKILL.md
```

`monozukuri doctor` reports whether the agent CLI is installed, auth is valid, skills were discovered, and which skills are injectable for the active agent.

## Memory v2

Memory v2 keeps agent work from starting cold every time. Each learning records:

- the insight and rationale
- the source feature, phase, run, and artifact
- how often it has been applied
- when it was last applied
- whether it applies to Claude Code, Codex, Gemini, or all agents

The sufficiency router injects compact summaries first. If an agent needs more detail, it can request a raw learning with:

```xml
<request-memory id="lrn-xxx"/>
```

Useful commands:

```bash
monozukuri memory migrate --dry-run
monozukuri memory migrate
monozukuri memory why <lrn-id>
monozukuri memory trace <run-id>
monozukuri memory compact --dry-run
```

Read [docs/schemas/memory-v2.md](docs/schemas/memory-v2.md), [docs/adr/027-sufficiency-router.md](docs/adr/027-sufficiency-router.md), and [docs/experiments/sufficiency-router/README.md](docs/experiments/sufficiency-router/README.md) for the schema, decision, and experiment data.

## Proof of work

The v2 alpha was validated with a live Codex canary against [`Viniciuscarvalho/monozukuri-soak-test`](https://github.com/Viniciuscarvalho/monozukuri-soak-test). The loop created two pull requests and both passed the sandbox CI.

Release details live in [docs/release/v2-alpha.md](docs/release/v2-alpha.md).

## Documentation

| Topic | Where |
| --- | --- |
| Install guide | [docs/installation.md](docs/installation.md) |
| Execution and loop behavior | [docs/execution.md](docs/execution.md) |
| Configuration reference | [docs/configuration.md](docs/configuration.md) |
| Backlog adapters | [docs/adapters.md](docs/adapters.md) |
| v1 to v2 migration | [docs/v2-migration.md](docs/v2-migration.md) |
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
