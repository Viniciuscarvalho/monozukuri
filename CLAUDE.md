# Monozukuri — Claude Code Context

## What this repo is

Monozukuri is a terminal orchestrator that reads a backlog (Linear, GitHub Issues, or `features.md`), creates isolated git worktrees, and invokes a coding agent for each feature — producing pull requests autonomously. It supports Claude Code, Codex, Gemini, and Kiro through a uniform agent adapter contract.

It is **not** a Claude Code skill itself. It runs _outside_ any coding agent and calls it via the agent's CLI.

## State directory

- Per-project state: `.monozukuri/` (created by `monozukuri init` in the user's project)
- Global learning store: `~/.claude/monozukuri/learned/`
- Worktrees: `.worktrees/` (relative to user's project root)

## Key env vars

| Variable          | Purpose                                                       |
| ----------------- | ------------------------------------------------------------- |
| `MONOZUKURI_HOME` | Set by wrappers; points to the install root (contains `lib/`) |
| `ANTHROPIC_MODEL` | Override model (takes highest precedence over config)         |
| `LINEAR_API_KEY`  | Required when `source.adapter: linear`                        |
| `SKILL_COMMAND`   | Deprecated; maps to `agents.claude-code.skills.<phase>`       |

## Entry points

| How installed | Command                                         |
| ------------- | ----------------------------------------------- |
| Homebrew      | `monozukuri <subcommand>`                       |
| NPX           | `npx @viniciuscarvalho/monozukuri <subcommand>` |
| Repo (dev)    | `./orchestrate.sh <subcommand>`                 |

All three set `MONOZUKURI_HOME` and exec `orchestrate.sh`. The top-level `orchestrate.sh` resolves `LIB_DIR=$MONOZUKURI_HOME/lib`, `CMD_DIR=$MONOZUKURI_HOME/cmd`, and `SCRIPTS_DIR=$MONOZUKURI_HOME/scripts` (loose helpers).

`scripts/orchestrate.sh` is a compatibility shim for Homebrew v1.0.0 installs only.

## Agent invocation

The default agent is `claude-code`. Change it in `.monozukuri/config.yaml`:

```yaml
agent: claude-code # default — uses the claude CLI
# agent: codex       # OpenAI Codex CLI
# agent: gemini      # Google Gemini CLI
# agent: kiro        # AWS Kiro
```

Legacy config (`skill.command: feature-marker`) is supported via a back-compat shim in `lib/config/load.sh`.

## Module load order (sub_run)

`lib/core/util.sh → lib/config/load.sh → lib/core/worktree.sh → lib/memory/memory.sh → lib/cli/output.sh → lib/core/json-io.sh → lib/core/stack-profile.sh → lib/core/cost.sh → lib/core/router.sh → lib/memory/learning.sh → lib/run/cycle-gate.sh → [lib/run/local-model.sh] → [lib/run/ingest.sh] → [lib/run/injection-screen.sh] → lib/run/pipeline.sh`

## Config resolution order

`.monozukuri/config.yaml` → `.monozukuri/config.yml` → `$TEMPLATES_DIR/config.yaml`
