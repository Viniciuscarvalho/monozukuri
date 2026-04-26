# ADR-013: Stratified Failure Handling, Idempotent Resumption & Rate-Limit Policy

- **Status**: Accepted
- **Date**: 2026-04-26
- **Deciders**: Vinicius Carvalho
- **Supersedes**: —
- **Related**: ADR-010 (Stuck-State Elimination), ADR-012 (Adapter Contract & Schemas)

---

## Context

Today:

1. A transient model-rate-limit looks identical to a fatal configuration error —
   both surface as non-zero exit codes with no structured classification.
2. A crash on feature 7 of 23 forces a restart from feature 1; there is no
   crash-resume.
3. A multi-hour rate limit will silently stall or crash an overnight run with no
   user notification.
4. ADR-010 addressed stuck-state for supervised/checkpoint modes but left full_auto
   without systematic failure handling.

Four grilling decisions (Q2, Q8, Q9, Q12 from the 2026-04-26 vision session) are
consolidated here because they share a single failure-state model and the same
executor refactor.

---

## Decision

### 1. Adapter error envelope

Every adapter MUST return failures as a structured envelope:

```json
{
  "class": "transient | phase | fatal | unknown",
  "code": "<adapter-specific string>",
  "message": "<human-readable string>",
  "retryable_after": 120
}
```

`retryable_after` (seconds) is optional; include when the agent's API surfaces it
(e.g., `Retry-After` header). `unknown` is the safe default for errors the adapter
does not recognise.

### 2. Core policy table

| Class       | Policy                                                                                                           |
| ----------- | ---------------------------------------------------------------------------------------------------------------- |
| `transient` | Sleep `retryable_after` seconds (default: 30 if absent), retry the phase. Cap: 3 retries.                        |
| `phase`     | One reprompt on the same worktree with the error context. Still fails → escalate to `cycle-gate failure`.        |
| `fatal`     | Abort the run. Persist state (see §4). Exit with structured message listing the fatal reason and resume command. |
| `unknown`   | Treat as `phase`. Record the unknown classification for learning (Gap 5).                                        |

Cycle-gate failures emerge from phase failures and schema-invalid-after-reprompt
(per ADR-012); they are not classified at runtime.

Fatal class examples: missing API key, adapter CLI not installed, disk full, git
config absent, invalid worktree path. These fail the _run_, not one _feature_, because
subsequent features will hit the same wall.

### 3. One-reprompt invariant

The `phase` class policy allows exactly one reprompt. This matches the schema
validation policy (ADR-012) and the CI red-handling policy (ADR-014). The
"one reprompt rule" applies uniformly across all reprompt triggers.

### 4. Idempotent resumption state model

Two-tier state, authoritative on disk:

**Run manifest** — `$STATE_DIR/runs/<run-id>/manifest.json`

```json
{
  "run_id": "<uuid>",
  "started_at": "<ISO-8601>",
  "features": [
    {
      "id": "feat-001",
      "worktree_path": ".worktrees/feat-001",
      "current_phase": "code",
      "status": "in_progress | completed | failed | deferred"
    }
  ]
}
```

**Per-worktree state** — `<worktree_path>/.monozukuri/state.json`

Holds artifacts (paths to prd.md, techspec.md, tasks.md, commit-summary.json),
retry counters per phase, and the PR URL + head SHA once opened.

**Write discipline:**

- State update is always the final write — _after_ the side-effect (commit, push,
  PR open).
- All state file writes are atomic: `write-temp → fsync → rename`.
- PR-opened and CI-wait phases are keyed on `pr_url + head_sha` for idempotent
  re-entry: if a PR already exists for the current head, skip opening and continue
  from CI-wait.

**Resume flow (`monozukuri run --resume`):**

1. Read `manifest.json`. Identify the run to resume (most recent incomplete, or
   `--run-id <id>` override).
2. Reconcile manifest claims against disk: for each feature, verify worktree exists
   and `state.json` is present.
3. Missing worktree → `feature.failed(reason: worktree.missing)`. Continue to next.
   Use `--resume --recreate-missing` to rebuild from scratch instead.
4. Dirty worktree (uncommitted changes from a partial code phase) → warn, prompt in
   interactive mode; treat as `phase-class` reprompt in full_auto.
5. Honor the run lock: only one monozukuri run per project at a time. Stale lock
   (PID dead) → prompt for reclaim in interactive mode; auto-reclaim with warning
   in full_auto.

### 5. Rate-limit threshold policy

| `retry_after` value                                 | Action                                                                                                                                                      |
| --------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| ≤ 10 minutes                                        | Sleep-and-wait on the current feature. Log the wait duration.                                                                                               |
| > 10 min and ≤ 60 min (`max_block`, configurable)   | Mark feature `deferred_until: <ts>`. Advance to the next independent feature in the topo-sorted backlog. Return to deferred features when the window opens. |
| > `max_block` OR all remaining features are blocked | **Pause-clean**: persist state, release lock, exit with a structured message.                                                                               |

Default `max_block`: 60 minutes (configurable via `config.yaml: run.max_block_minutes`).

Pause-clean exit message format:

```
monozukuri: run paused at <ISO-8601>.
reason: rate-limited on <adapter> until <ISO-8601> (ETA: <human-relative>).
state preserved. resume with: monozukuri run --resume [--run-id <id>]
```

### 6. Cross-agent failover

Disabled by default. Enable with `routing.failover: true` in `config.yaml` or
`--allow-failover` at runtime. When enabled:

- A rate-limited adapter triggers failover to the next-best adapter per phase,
  selected from the routing recommendation table (ADR-015).
- Failover events are tagged in the run report with the original and fallback
  adapter names.

The default-off position prevents routing recommendation data (which recommends
Adapter A for a phase) from being silently overridden by a mid-run failover to
Adapter B.

---

## Consequences

### Positive

- `monozukuri run --resume` makes overnight failures recoverable without losing
  completed work.
- Structured error envelopes enable automated classification without regex-parsing
  stderr.
- Pause-clean keeps "while you sleep" honest: short rate limits are invisible; long
  ones stop cleanly rather than thrashing.
- Unknown classifications feed Gap 5 learning — adapters improve their classifiers
  over time from real-world error data.

### Negative / Trade-offs

- Run-manifest + per-worktree state is new disk surface area. Requires a
  `monozukuri cleanup <run-id>` subcommand for hygiene.
- Atomic state writes add overhead per phase completion (temp-file + fsync + rename
  is ~1 ms on SSDs; acceptable).
- Adapter teams must implement the error envelope; existing adapters need a one-time
  migration.

### Neutral

- Cycle-gate behaviour is unchanged from ADR-008; the gate now also checks CI
  status (ADR-014) but the mechanism is the same.
- `--skip-cycle-check` (ADR-008 bypass) is preserved for emergency deployments.

---

## Implementation Notes

- `lib/run/failure-classifier.sh` — reads the adapter envelope and dispatches to
  the policy table.
- `lib/run/state.sh` — atomic state read/write helpers (`state_write`, `state_read`,
  `state_update_phase`).
- `lib/run/manifest.sh` — manifest init, update, and reconcile-on-resume.
- Rate-limit sleep uses `sleep "$retryable_after"` with a max cap of
  `$((max_block * 60))` seconds before switching to defer-or-pause logic.
- Stale-lock detection: compare PID in `.monozukuri/run.lock` against
  `/proc/<pid>/status` (Linux) or `kill -0 <pid>` (macOS/POSIX).
