# Autonomy levels

Monozukuri runs in one of three autonomy levels — `supervised`, `checkpoint`, or `full_auto`. The level controls how much the agent does without asking you, how output is rendered, and how the safety gates behave. This page is the reference for picking the right level and switching between them.

If you want to _see_ what each mode looks like, [execution.md](execution.md) has the visuals. If something has gone wrong in any mode, [troubleshooting.md](troubleshooting.md) is the recovery map.

---

## Quick chooser

Pick `supervised` when you are pairing with the agent, evaluating a new skill, or running against an unfamiliar project for the first time. Pick `checkpoint` when you want the agent to make unattended progress but still want a human in the merge loop — this is the default and the right choice for most teams. Pick `full_auto` when you trust the skill, the backlog, and your branch protection enough to ship without per-PR review — typically overnight runs, refactors, or large mechanical changes.

You can switch between levels by passing `--autonomy <level>` on the CLI or by setting `autonomy:` in [config.yaml](configuration.md#autonomy). The CLI flag wins when both are set.

---

## At a glance

| Dimension             | `supervised`                 | `checkpoint`                     | `full_auto`                     |
| --------------------- | ---------------------------- | -------------------------------- | ------------------------------- |
| **Approval gates**    | After every phase            | After every PR (waits for merge) | None                            |
| **Output channel**    | Ink TUI (interactive)        | Structured logs                  | Structured logs + web dashboard |
| **Agent permissions** | Default (prompted)           | Default (prompted)               | Bypassed                        |
| **Default model**     | `opusplan`                   | `opusplan`                       | `opusplan`                      |
| **Resumable**         | Yes                          | Yes                              | Yes                             |
| **Unattended-safe**   | No                           | Partial — pauses on merge        | Yes                             |
| **Typical use**       | Skill evaluation, first runs | Day-to-day delivery              | Overnight / large backlogs      |

---

## Supervised

`monozukuri run --autonomy supervised` opens the Ink TUI and runs the pipeline phase by phase, pausing for your explicit approval at each boundary. You see the PRD before TechSpec starts, the TechSpec before Tasks, and so on. Approval is one keystroke; rejection lets you provide feedback that re-prompts the agent before retrying.

This is the only mode that uses the Ink TUI — `checkpoint` and `full_auto` both emit structured logs. The TUI is scoped to supervised intentionally: full-pipeline TUI rendering across long unattended runs creates more failure modes than it solves (terminal disconnects, scrollback loss, ESM bundling fragility). See [ADR-012](adr/012-adapter-contract-and-schemas.md) for the rationale.

**What the gates do here.** The size gate runs before the worktree is created — same as the other modes — but a `skip` decision will pause for your override instead of silently moving on. The cycle gate runs after the PR phase and surfaces a TUI alert if any phase artifact is missing. The circuit breaker is effectively disabled, because you are the breaker.

**When supervised is the wrong answer.** Long backlogs. Anything where you are not at the keyboard. The TUI blocks on every gate, so a 20-feature backlog in supervised mode is 20× the wait time of `checkpoint`.

---

## Checkpoint

`monozukuri run` (or explicitly `--autonomy checkpoint`) runs each feature end to end without prompting, opens a pull request, and then waits for that PR to merge before picking up the next feature. Output is structured logs — the same shape that streams into the web dashboard in `full_auto`, but without the dashboard.

This is the default level. It assumes you want the agent to make progress while you do other things, but you (or a teammate) still want to approve what ships by merging the PR. Branch protection on `main` makes this the safest production-grade mode.

**What the gates do here.** Size gate skips are silent — the feature is recorded as skipped in `monozukuri status` and the loop moves on. Cycle gate failures stop the loop on that feature and require `monozukuri run --resume --feature <id>` to retry. The circuit breaker is active: a phase that exceeds `phase_max_attempts` or `phase_budget_seconds` is terminated and recorded as a failure learning.

**How the merge wait works.** After the PR is opened, Monozukuri polls the GitHub API for the merge state of that PR. The poll interval and the maximum wait window are configurable under `merge_wait` in [config.yaml](configuration.md#gates). When the PR merges, the next feature starts immediately. If the maximum wait elapses without a merge, the run pauses with `status: waiting_on_merge` and can be resumed once the merge happens.

---

## Full auto

`monozukuri run --autonomy full_auto` runs without any approval gates. It bypasses the agent's permission gates, opens the PR, and immediately starts the next feature without waiting for merge. A local web dashboard launches on `http://localhost:7878`<!-- CONFIRM: dashboard port --> for live progress.

This mode is the reason Monozukuri exists. It is also the mode with the highest blast radius — a misconfigured skill in `full_auto` can burn through the entire backlog before anyone notices. Treat the safeguards below as non-optional.

**What the gates do here.** All gates run with no human override. Size-gate skips are silent. Cycle-gate failures stop _only that feature_, not the loop — the next feature starts immediately and the failed one waits for `--resume`. The circuit breaker is the primary safety net: every phase has a hard ceiling and the loop will never spend unbounded tokens or wall time on a single feature.

**Required safeguards.** Branch protection on `main` (required reviewers, required status checks). Code owner rules on directories the agent should never touch on its own. A configured budget ceiling at the run level (`run_budget_tokens` and `run_budget_minutes` under `gates`) so a runaway loop is bounded by something other than your patience. Without these, `full_auto` is not safe to run against a real codebase.

**The web dashboard.** The dashboard is scoped to `full_auto` because that is the mode where you most need to see progress without a terminal. Each feature card shows the current phase, elapsed wall time, accumulated token cost, and the cycle-gate status. The top strip shows aggregate consumption against the run budget. Closing the dashboard does not stop the loop — it is a view, not a controller. To stop the loop, send `SIGINT` to the orchestrator process or run `monozukuri cleanup` from another terminal.

---

## Switching modes mid-run

You cannot change the autonomy level of a _running_ loop, but you can interrupt and resume in a different mode. The interrupted state is preserved under `.monozukuri/state.json`; resuming with a different `--autonomy` flag will continue the loop under the new rules from the next feature boundary.

A common pattern: start a backlog in `checkpoint` to validate the first feature interactively, then resume in `full_auto` once the skill is producing PRs you trust.

```bash
monozukuri run --autonomy checkpoint
# ...first PR merges, output looks good...
# Ctrl-C to stop
monozukuri run --resume --autonomy full_auto
```

The size and cycle gate configurations do not change when the mode changes — they come from `config.yaml`, not from the CLI flag. If you need different gate ceilings between modes, edit the config between runs.

---

## Cost considerations

Token cost scales roughly linearly with the number of features and the per-feature complexity, and the autonomy level mostly does not affect it — the same six phases run in all three modes. Two exceptions:

The first is `supervised`, which can spend _more_ on rework if you reject phases and ask the agent to retry with feedback. Each rejection is a new phase invocation against the same feature. This is usually a worthwhile tradeoff (you are buying quality), but it is not free.

The second is `full_auto` with a poorly-tuned circuit breaker. A phase that loops at `phase_max_attempts: 10` against a validator it cannot satisfy will spend ten times what a phase with `phase_max_attempts: 3` spends. Tune the breaker for your skill before running large backlogs unattended. The defaults in `templates/config.yaml` are a reasonable starting point but not appropriate for every project.

See [ADR-008](adr/008-orchestrator-economy.md) for the full cost model and routing logic.
