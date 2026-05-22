# Execution at a glance

This document shows what Monozukuri looks like while it runs, in each of the three autonomy levels, and what a successful run produces. It is the reference users open before their first `monozukuri run` — and the source for the hero asset embedded in the README.

If you are looking for _what to do when something breaks_, see [troubleshooting.md](troubleshooting.md). For the differences between autonomy modes, see [autonomy.md](autonomy.md).

---

## A 30-second tour

The hero GIF in the README captures this scenario, end to end:

1. A repository with two pending features in `features.md`.
2. `monozukuri run --dry-run` previews the plan and exits.
3. `monozukuri run --autonomy checkpoint` executes the first feature, opens a PR, pauses for merge.
4. The user merges the PR; Monozukuri picks up the second feature.
5. Final state: two open PRs, two worktrees cleaned up, learnings written.

The full unedited cast lives at [`assets/supervised.cast`](assets/supervised.cast). See [Recording the hero asset](#recording-the-hero-asset) below to regenerate it.

---

## What the dry run shows

`monozukuri run --dry-run` is the first command every new user should run. It reads the backlog, resolves the size gate, and prints the plan without invoking the skill or creating worktrees.

```
<!-- CAPTURE: paste output of `monozukuri run --dry-run` against a 2-feature backlog -->
```

The dry run is the answer to "what is this thing about to do to my repo?" Use it before every first run in an unfamiliar project.

---

## Selected loop mode

`monozukuri loop <id...>` runs only the selected backlog items through the same six-phase pipeline as `monozukuri run`. It is built for scripted batches after you have already ranked and validated the backlog:

```bash
monozukuri loop feat-001 feat-002 feat-003
monozukuri pick --top 3 | monozukuri loop
```

Loop worktrees are preserved by default under `.monozukuri/worktrees/loop-<date>-<random>/<feature-id>/` so failed features can be inspected. Pass `--cleanup` when you want the command to remove each loop worktree after the feature finishes.

Each feature is isolated. Missing IDs are reported and the loop continues. Failed features follow `--on-failure`: `continue` marks the feature failed and starts the next one, `stop` aborts the loop with exit code `3`, and `pause` asks for `retry`, `skip`, or `abort` when stdin is a TTY. In non-TTY contexts, `pause` behaves like `stop` with a clear message. Defaults follow autonomy: `full_auto` uses `continue`; `checkpoint` and `supervised` use `pause`.

The loop also has a consecutive-failure circuit breaker independent of `--on-failure`. By default, `--circuit-breaker 3` aborts after three failed features in a row, prints `Circuit breaker tripped: 3 consecutive failures` to stdout and stderr, writes the tripped state to `.monozukuri/state/loop-<id>/cost.json`, and exits `5`. Set `--circuit-breaker 0 --i-know-what-im-doing` only when you explicitly want to disable this safety guard.

Every selected loop run writes resumable state under `.monozukuri/state/loop-<id>/`: `manifest.json`, `progress.jsonl`, `cost.json`, and `checkpoint.json`. See [loop-state schema](schemas/loop-state.md) for the file contracts and atomic write rules.

Loop budgets are hard caps between features. The defaults are `--max-cost 10`, `--max-time 480`, and `--max-tokens-per-task 100000`; the loop finishes the current feature, writes `.monozukuri/state/loop-<id>/cost.json`, prints the final cost summary, and exits `4` before starting another feature when a cap is reached. The token ceiling rejects values above `500000`.

---

## Supervised mode (Ink TUI)

`monozukuri run --autonomy supervised` opens an interactive TUI. After each phase (PRD, TechSpec, Tasks, Code, Tests, PR) the run pauses for your approval. Use this mode when you are pairing with the agent or evaluating a new skill.

<!-- CAPTURE: still screenshot of the Ink TUI mid-run, ideally at the TechSpec approval gate.
     Path: docs/assets/supervised-tui.png -->

![Supervised TUI](assets/supervised-tui.png)

**Reading the TUI.** The top bar shows the active feature and the current phase. The center pane shows the phase output streaming from the skill. The bottom bar shows the approval prompt and the elapsed phase budget. Token cost accumulates in the right margin.

**When to use it.** First runs against a new project, skill development, and any time you want to see the agent's reasoning live. Not appropriate for unattended runs — it blocks on every gate.

---

## Checkpoint mode (structured logs + PR gate)

`monozukuri run --autonomy checkpoint` is the default. It executes the full PRD-to-PR pipeline without prompting, opens a PR, and then waits for that PR to merge before picking up the next feature. Output is structured logs, suitable for scrollback and CI capture.

```
<!-- CAPTURE: full structured-log output of a successful single-feature run in checkpoint mode.
     Trim aggressively — keep one PRD line, one TechSpec line, one Tasks line, the Code phase summary,
     the Tests phase summary, the PR creation line. ~30 lines max. -->
```

**Reading the log.** Each line is prefixed with the feature ID, the phase, and an event type (`start`, `progress`, `complete`, `gate`). A successful feature ends with a `phase=pr event=complete url=...` line. The cycle gate runs after the PR is created and confirms all six phases completed.

**When to use it.** Long-running backlogs where you want the agent to make progress unattended but still keep humans in the merge loop. The recommended mode for most teams.

---

## Full auto mode (structured logs + web dashboard)

`monozukuri run --autonomy full_auto` runs without any approval gates. It bypasses the agent's permission gates, opens the PR, and immediately starts the next feature. A local web dashboard launches on `http://localhost:7878` for live progress.

```
<!-- CAPTURE: same structured-log shape as checkpoint, but showing the transition from
     feature 1 -> feature 2 (one cycle gate complete, next size gate start). ~20 lines. -->
```

<!-- CAPTURE: screenshot of the web dashboard with two features in progress.
     Path: docs/assets/dashboard.png -->

![Full-auto dashboard](assets/dashboard.png)

**Reading the dashboard.** Each feature card shows the current phase, elapsed wall time, accumulated token cost, and the cycle-gate status. The top strip shows aggregate budget consumed against the configured ceiling.

**When to use it.** Overnight runs, large backlogs where merges happen async, and any environment where you trust the skill to ship without per-PR review. Pair with branch protection rules on `main`.

---

## What success looks like

After a successful `monozukuri run` against an N-feature backlog you should see:

- **N pull requests** open on the origin remote, each titled `feat: <feature-id> — <summary>` and linked from the feature in the backlog source.
- **N entries** in `.monozukuri/learnings/feature/` capturing per-feature outcomes, plus updates to `project/` and `global/` learning stores.
- **Zero git worktrees** remaining under `.monozukuri/worktrees/` — successful features clean themselves up.
- **A `state.json`** at `.monozukuri/state.json` with `status: complete` and a per-feature breakdown of duration, token cost, and gate decisions.

If any of these are missing or unexpected, the run did not complete cleanly. Go to [troubleshooting.md](troubleshooting.md).

---

## Recording the hero asset

The README hero GIF is regenerated from a [VHS](https://github.com/charmbracelet/vhs) tape. VHS is declarative, reproducible, and exports to GIF, MP4, and WebM from a single script — preferable to ad-hoc screen recordings for an asset that needs to track CLI changes.

**Why VHS over alternatives.** asciinema records faithfully but produces a `.cast` file that needs a player or a converter (agg) to embed in GitHub. terminalizer is heavier and harder to script. VHS produces a GIF directly, runs in CI, and the tape itself is reviewable in a PR.

**Scenario to record** (target length: 30–45 seconds):

1. Open in a fresh demo repo with a two-feature `features.md` already present.
2. Run `monozukuri init` — show the generated `.monozukuri/` layout briefly with `tree .monozukuri`.
3. Run `monozukuri run --dry-run` — let the plan render fully.
4. Run `monozukuri run --autonomy checkpoint` — let the first feature go through PRD and Tests, cut to the PR-open line.
5. End on the success state: `gh pr list` showing the open PR.

Keep typing slow enough to read but skip the agent's thinking time with VHS `Hide`/`Show` blocks around long waits.

**Tape skeleton** (save as `docs/assets/hero.tape`):

```tape
Output docs/assets/hero.gif
Set Theme "Catppuccin Mocha"
Set FontSize 14
Set Width 1200
Set Height 700
Set PlaybackSpeed 1.0

Type "monozukuri init" Sleep 500ms Enter
Sleep 2s
Type "monozukuri run --dry-run" Sleep 500ms Enter
Sleep 4s
Type "monozukuri run --autonomy checkpoint" Sleep 500ms Enter

Hide
Sleep 30s    # let PRD + TechSpec complete off-camera
Show

Sleep 8s     # show the rest of the pipeline streaming
Type "gh pr list" Sleep 500ms Enter
Sleep 3s
```

Run `vhs docs/assets/hero.tape` to regenerate. Commit the GIF alongside the tape; reviewers can re-run the tape locally to verify the asset matches the CLI.

**Capturing the failure clip.** The README does not embed the failure clip — it lives in [troubleshooting.md](troubleshooting.md). Use the same VHS approach with a tape that triggers a known failure (e.g. a feature with a `size_gate: skip` annotation, or a deliberately malformed PRD template) and shows the user recovering via `monozukuri status` followed by `monozukuri run --resume`. Target length: 10–15 seconds.
