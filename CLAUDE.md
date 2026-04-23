# Monozukuri — Claude Code Context

## What this repo is

Monozukuri is a terminal orchestrator that reads a backlog (Linear, GitHub Issues, or `features.md`), creates isolated git worktrees, and invokes a Claude Code skill for each feature — producing pull requests autonomously.

It is **not** a Claude Code skill itself. It runs _outside_ Claude Code and calls it via the `claude` CLI.

## State directory

- Per-project state: `.monozukuri/` (created by `monozukuri init` in the user's project)
- Global learning store: `~/.claude/monozukuri/learned/`
- Worktrees: `.worktrees/` (relative to user's project root)

## Key env vars

| Variable          | Purpose                                                      |
| ----------------- | ------------------------------------------------------------ |
| `MONOZUKURI_HOME` | Set by wrappers; points to `scripts/` directory              |
| `ANTHROPIC_MODEL` | Override model (takes highest precedence over config)        |
| `LINEAR_API_KEY`  | Required when `source.adapter: linear`                       |
| `SKILL_COMMAND`   | Exported from `config.sh`; which Claude Code skill to invoke |

## Entry points

| How installed | Command                                         |
| ------------- | ----------------------------------------------- |
| Homebrew      | `monozukuri <subcommand>`                       |
| NPX           | `npx @viniciuscarvalho/monozukuri <subcommand>` |
| Repo (dev)    | `./scripts/orchestrate.sh <subcommand>`         |

All three set `MONOZUKURI_HOME` and exec `scripts/orchestrate.sh`.

## Skill invocation

The default skill is `feature-marker`. Change it in `.monozukuri/config.yaml`:

```yaml
skill:
  command: feature-marker # any Claude Code slash-command
```

`config.sh` exports `SKILL_COMMAND`; `runner.sh` reads `${SKILL_COMMAND:-feature-marker}`.

## Module load order (sub_run)

`util → config → worktree → memory → display → json_io → stack_profile → cost → router → learning → size_gate → cycle_gate → [local_model] → [ingest] → [injection_screen] → runner`

## Config resolution order

`.monozukuri/config.yaml` → `.monozukuri/config.yml` → `$TEMPLATES_DIR/config.yaml`
