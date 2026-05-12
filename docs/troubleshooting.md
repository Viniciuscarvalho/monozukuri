# When things go wrong

Monozukuri runs unattended, which means failures need to be self-recoverable. This document is the map from "something looks off" to "fixed and resumed". It covers the state layout, the diagnostic commands, the recovery ladder, and the failure modes you are most likely to hit.

If you are reading this _before_ your first run, you probably want [execution.md](execution.md) instead.

---

## Where state lives

Everything Monozukuri knows about your run is under `.monozukuri/` in your project root. Nothing escapes that directory.

```
.monozukuri/
├── config.yaml              # your configuration (committed)
├── state.json               # current loop state (gitignored)
├── worktrees/               # one directory per in-flight feature (gitignored)
│   └── feat-001/
├── logs/                    # one log file per feature run (gitignored)
│   └── feat-001-2026-05-12T03-14-22.log
├── learnings/               # three-tier learning store (committed)
│   ├── feature/             #   per-feature outcomes
│   ├── project/             #   aggregated across this project
│   └── global/              #   aggregated across all your projects
└── locks/                   # PID files for stuck-state detection (gitignored)
```

The default `.gitignore` written by `monozukuri init` keeps state, logs, worktrees, and locks out of version control while preserving the config and the learnings.

---

## Diagnostic commands

The three commands you will use in this order:

**`monozukuri status`** is the first thing to run. It prints a one-screen summary of the current loop state — which feature is active, which phase, how long it has been running, and whether any locks are held.

```
<!-- CAPTURE: paste output of `monozukuri status` against a healthy in-progress run. -->
```

```
<!-- CAPTURE: paste output of `monozukuri status` against a stuck run — locked PID,
     phase elapsed time over the configured ceiling. -->
```

The fields to scan for are `status` (`idle` / `running` / `stuck` / `complete` / `failed`), `phase_elapsed_seconds` (compared against `phase_budget_seconds` from your config), and `lock_pid` (if non-empty, a worker is holding the lock; check with `ps -p $LOCK_PID`).

**`monozukuri logs <feature-id>`** prints the structured log for a specific feature. Use this when `status` points at a feature but does not tell you why it stalled. The log is the same content streamed during `checkpoint` and `full_auto` runs, replayable after the fact.

**`monozukuri learning list`** shows what the three-tier store has captured. Useful when the agent is making the same mistake across features — the project-tier learning should be reflecting (and correcting for) that pattern, and if it is not, the learning step itself may have failed.

---

## The recovery ladder

Recover in this order. Escalate only when the previous step does not resolve the issue.

**1. `monozukuri run --resume`** — picks up where the loop stopped, skipping features whose state is already `complete`. This is the right move for transient failures (rate limits, network blips, a single phase that exceeded budget). Worktrees and locks are reconciled automatically.

**2. `monozukuri run --resume --feature <id>`** — re-runs a single feature from scratch. Use this when one specific feature is stuck or produced a broken PR, but the rest of the backlog is fine. The previous worktree for that feature is removed first.

**3. `monozukuri cleanup`** — removes all worktrees, resets `state.json`, releases all locks. Destructive but recoverable: it does not touch your PRs, your learnings, or your config. Run this when the state has drifted far enough that resume is not converging. Follow with a fresh `monozukuri run`.

**4. Manual intervention** — if `cleanup` does not unstick the loop, you are most likely looking at a bug or a config mismatch. Capture `monozukuri status`, the latest `logs/`, and your `config.yaml`, then [open an issue](https://github.com/Viniciuscarvalho/monozukuri/issues/new).

---

## Common failure modes

### Size gate skip

**What you see.** A feature is reported as `skipped` with reason `size_gate` in `status` output. No worktree is created, no skill invoked, no PR opened.

**What it means.** The size gate estimated the feature would exceed the per-feature token or time budget configured under `gates.size` in your config. The gate is a _cost protection_, not an error — it is doing its job.

**What to do.** Either split the feature into smaller units in your backlog, or raise the size-gate ceiling in `config.yaml` (and accept the higher cost ceiling per feature). Run `monozukuri run --resume` after either change.

### Cycle gate failure

**What you see.** A feature reaches the PR phase but `status` reports `cycle_gate_failed`. The PR may or may not exist on the remote.

**What it means.** The cycle gate verifies that all six phases (PRD → TechSpec → Tasks → Code → Tests → PR) completed and produced their expected artifacts. A cycle-gate failure means the pipeline ran but one of the artifacts is missing or malformed — usually the test phase produced no test files, or the PR phase did not return a URL.

**What to do.** Inspect `logs/<feature-id>-*.log` for the phase that did not produce an artifact. If the PR was actually created on the remote, you can manually mark the feature complete with `monozukuri run --feature <id> --mark-complete`. Otherwise, `monozukuri run --resume --feature <id>` to re-run.

### Phase loop without progress

**What you see.** A feature stays on the same phase for longer than `phase_budget_seconds`. `status` reports `stuck` with the current phase highlighted.

**What it means.** The agent is producing output but not converging — usually the skill is re-attempting the same phase after a validator rejection. The circuit breaker should trip automatically at `phase_max_attempts`; if it does not, the loop will be terminated when wall time exceeds the per-feature ceiling.

**What to do.** Wait for the circuit breaker (the cleanest outcome — the failure will be recorded as a learning). If you cannot wait, `monozukuri cleanup` and inspect the log to see which validator was rejecting the output. The PRD template aliases and TechSpec headings are the most common culprits.

### Skill not found

**What you see.** A feature fails immediately with `skill: command not found`. No PRD is produced.

**What it means.** The skill referenced in `config.yaml` under `skill.command` cannot be resolved by the configured agent. Either the skill is not installed, or the name is misspelled.

**What to do.** Confirm the skill or command is available for your configured agent — for Claude Code, run `claude /list-commands`; for Codex, Gemini, or Kiro, verify the rendered prompt is accessible. For Feature-marker specifically: `brew install feature-marker`. Update `skill.command` in `config.yaml` to the correct name.

### `gh` not authenticated

**What you see.** The PR phase fails with `gh: authentication required`. All prior phases succeeded; the worktree contains a complete branch.

**What it means.** The GitHub CLI is not signed in for the current shell, or the token does not have `repo` scope.

**What to do.** `gh auth login` with `repo` scope, then `monozukuri run --resume`. The completed branch will be picked up and the PR phase re-attempted; no work is lost.

---

## Definitions

A few terms appear in the diagram and in command output without an obvious home elsewhere in the docs.

**Size gate.** The estimator that runs before a feature enters a worktree. It compares the projected token cost and wall time of the feature against the ceilings under `gates.size` in your config and either approves the feature, marks it `skip`, or escalates it for human review.

**Cycle gate.** The verifier that runs after the PR phase. It confirms that the six pipeline phases each produced their expected artifact (PRD file, TechSpec file, Tasks file, code diff, test files, PR URL). Failures here mean the pipeline ran but the cycle did not close cleanly.

**Three-tier learning store.** The learnings written at the end of each feature are aggregated at three levels: per-feature (what happened on this specific run), per-project (patterns across runs in this repo), and global (patterns across all repos you use Monozukuri in). The store is consulted at the start of each phase to prime the agent with relevant prior outcomes. See [ADR-008](adr/008-orchestrator-economy.md) for the full design.

**Circuit breaker.** The mechanism that terminates a phase after `phase_max_attempts` retries or `phase_budget_seconds` wall time. Prevents runaway loops in `full_auto` mode where there is no human gate. See [ADR-010](adr/010-stuck-state-elimination.md).
