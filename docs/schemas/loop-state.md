# Loop State Schema

`monozukuri loop` persists resumable run state under:

```text
.monozukuri/state/loop-<date>-<random>/
```

The state directory is the canonical source for selected-loop recovery. The legacy
`.monozukuri/runs/loop-<id>/cost.json` file is still mirrored for older tooling.

## `manifest.json`

Tracks the selected tasks, their execution order, and terminal status.

```json
{
  "schema_version": 1,
  "run_id": "loop-2026-05-22-a3b9c2",
  "status": "running",
  "started_at": "2026-05-22T19:00:00.000Z",
  "updated_at": "2026-05-22T19:01:00.000Z",
  "completed_at": "2026-05-22T19:02:00.000Z",
  "reason": "cost",
  "tasks": [
    {
      "id": "feat-001",
      "order": 1,
      "status": "completed",
      "phase": "code",
      "updated_at": "2026-05-22T19:01:00.000Z"
    }
  ]
}
```

Task statuses are `pending`, `running`, `inconclusive`, `completed`, `failed`,
or `skipped`. Resume marks a previously `running` task as `inconclusive` before
re-enqueuing it in a new worktree so the interrupted worktree remains available
for inspection.

Run status mirrors the loop result: `running`, `completed`, `failed`, `stopped`,
`cap-reached`, `circuit-breaker-tripped`, or `aborted`.

## `progress.jsonl`

Append-only event log. Each line is one JSON object, so readers can stream it
without rewriting the whole file.

```json
{"schema_version":1,"run_id":"loop-2026-05-22-a3b9c2","event":"task.started","ts":"2026-05-22T19:00:00.000Z","task_id":"feat-001","status":"running"}
{"schema_version":1,"run_id":"loop-2026-05-22-a3b9c2","event":"phase.cost_recorded","ts":"2026-05-22T19:00:30.000Z","task_id":"feat-001","phase":"phase1","status":"recorded"}
```

Known events include `loop.started`, `loop.resumed`, `task.started`,
`task.completed`, `task.failed`, `task.skipped`, `task.inconclusive`,
`task.retry_failed`, `phase.cost_recorded`, and `loop.completed`.

`monozukuri loop status [run_id]` renders these lines in the operator-facing
format `[HH:MM:SS] [task-id] [phase] message`. `--follow` keeps reading the
append-only log every 2 seconds, so a second terminal can observe a running loop.

## `cost.json`

Loop-level cost accumulator, updated as phase costs are recorded.

```json
{
  "schema_version": 1,
  "run_id": "loop-2026-05-22-a3b9c2",
  "status": "running",
  "started_at": "2026-05-22T19:00:00.000Z",
  "limit_usd": 10,
  "limit_minutes": 480,
  "max_tokens_per_task": 100000,
  "total_usd": 0.042,
  "total_tokens": 42000,
  "phase_events": [
    {
      "feature_id": "feat-001",
      "phase": "phase1",
      "estimated_tokens": 25000,
      "estimated_usd": 0.025,
      "recorded_at": "2026-05-22T19:00:30.000Z"
    }
  ],
  "features": []
}
```

When the consecutive-failure circuit breaker trips, `cost.json` also includes
`circuit_breaker` with the configured limit and failed feature IDs.

## `checkpoint.json`

Last known safe resume point. If the process dies mid-task, resume tooling should
restart from `next_task_index`.

```json
{
  "schema_version": 1,
  "run_id": "loop-2026-05-22-a3b9c2",
  "status": "running",
  "last_safe_task_id": "feat-001",
  "next_task_index": 2,
  "next_task_id": "feat-002",
  "reason": "feature-failed",
  "updated_at": "2026-05-22T19:01:00.000Z"
}
```

## `summary.md`

Final loop report written when the selected loop exits successfully, fails,
stops, reaches a cap, trips the circuit breaker, or receives `SIGINT` after
state initialization.

```markdown
| ID | Status | Phases done | Tokens | Cost | Duration | PR URL |
| --- | --- | ---: | ---: | ---: | ---: | --- |
| feat-001 | completed | 6 | 42000 | $0.0420 | 120s | https://github.com/acme/app/pull/42 |
| feat-002 | failed | 3 | 18000 | $0.0180 | 45s |  |
| TOTAL | failed | 9 | 60000 | $0.0600 | 165s |  |
```

Terminal output uses an ASCII table by default and colorizes `completed`,
`failed`, and `skipped` statuses when the terminal supports color. Passing
`--report-format md` prints the markdown table instead. The persisted
`summary.md` is always markdown so it can be copied into issues, PRs, or run
notes without conversion.

## Resume Behavior

`monozukuri loop --resume <run_id>` loads `manifest.json` and `checkpoint.json`
from the selected state directory. Without a run ID, the most recently updated
non-completed loop state is selected.

Resume skips tasks whose status is `completed` or `skipped`. Tasks whose status
is `running` are marked `inconclusive`, logged in `progress.jsonl`, and run again
in a new worktree under `.monozukuri/worktrees/<run_id>-resume-<suffix>/`.
Existing worktrees are preserved. Tasks whose status is `failed` remain skipped
unless `--retry-failed` is passed, in which case they are returned to `pending`.

The loop-level `cost.json` is reused during resume. Caps such as `--max-cost`
apply to the accumulated total already present in the file, not to a reset or
remaining-only budget. `monozukuri loop --list-runs` lists non-completed loop
state directories that can be resumed.

## Write Discipline

`manifest.json`, `cost.json`, and `checkpoint.json` are written with
write-temp, `fsync`, and rename. `progress.jsonl` is append-only and guarded with
`flock` when available.
