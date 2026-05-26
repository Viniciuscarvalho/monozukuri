# Monozukuri v2 Migration Guide

This guide upgrades an existing v1 project to the v2 alpha command set: ranked
selection, resumable loops, and Memory v2 provenance.

## Breaking changes

No breaking project configuration change is expected for v1 users. Existing
`.monozukuri/config.yaml` files, backlog adapters, and v1 learning stores remain
readable. v2 adds commands and state files; it does not require rewriting a
project before the first run.

Two behavior changes are visible:

- `monozukuri pick` and `monozukuri loop` now persist selection and loop state
  under `.monozukuri/state/`.
- Memory injection uses compact summaries plus explicit escalation markers
  instead of injecting every learning by default.

## Upgrade steps

1. Upgrade the CLI through your install channel.
2. Run `monozukuri doctor` in the target project and fix missing agent CLIs or
   invalid config before running a loop.
3. Preview memory migration:

   ```bash
   monozukuri memory migrate --dry-run
   ```

4. Apply migration:

   ```bash
   monozukuri memory migrate
   ```

5. Validate the new store:

   ```bash
   monozukuri memory lint .monozukuri/memory-v2.json
   ```

6. Smoke-test selection and loop composition:

   ```bash
   monozukuri backlog list --limit 10
   monozukuri pick --top 3 | monozukuri loop --cleanup
   ```

## New commands

| Area | Command | Purpose |
| --- | --- | --- |
| Selection | `monozukuri backlog list` | List ranked backlog items with table, JSON, or CSV output. |
| Selection | `monozukuri pick --top N` | Print the top ranked feature IDs without opening the TUI. |
| Selection | `monozukuri pick --json --top N` | Emit selected features as JSON for CI pipelines. |
| Selection | `monozukuri pick --replay [N]` | Reuse the latest or N-th latest persisted selection. |
| Selection | `monozukuri pick --history` | Inspect the last 20 persisted selections. |
| Loop | `monozukuri loop <ids...>` | Execute selected features in sequence. |
| Loop | `monozukuri loop --resume [run-id]` | Resume a checkpointed loop run. |
| Loop | `monozukuri loop --list-runs` | List resumable loop runs. |
| Loop | `monozukuri loop status [run-id]` | Read structured loop progress. |
| Memory | `monozukuri memory migrate` | Convert v1 learning stores to Memory v2. |
| Memory | `monozukuri memory lint` | Validate Memory v2 stores against the schema. |
| Memory | `monozukuri memory why [lrn-id]` | Inspect provenance and application history. |
| Memory | `monozukuri memory trace <run-id>` | Debug summary and escalation decisions for a run. |
| Memory | `monozukuri memory compact` | Deterministically merge duplicates and drop stale learnings. |

All selection filters from `backlog list` apply to `pick`: `--label`,
`--status`, `--exclude-blocked`, and `--agent`.

## Migrating memory

`monozukuri memory migrate` reads the v1 learning stores, writes
`.monozukuri/memory-v2.json`, and creates a backup under
`.monozukuri/memory.v1.bak/`.

Fields that did not exist in v1 are filled conservatively:

| v2 field | Migration value |
| --- | --- |
| `applied_count` | `0` |
| `last_applied` | `null` |
| `source.run_id` | `migrated-from-v1` |
| `promoted_from` | `manual` |

Use `--dry-run` first in projects with hand-edited learning files. Use
`--reverse` only for compatibility checks; it writes a roundtrip v1 projection
and does not replace the v2 store.

## Reading the Memory v2 schema

The schema is documented in [docs/schemas/memory-v2.md](schemas/memory-v2.md)
and validated by [schemas/learning-v2.schema.json](../schemas/learning-v2.schema.json).

Each learning answers four questions:

- What is the reusable insight? Read `insight` and optional `rationale`.
- Where did it come from? Read `source.feature_id`, `source.phase`,
  `source.run_id`, and `source.artifact`.
- How often has it mattered? Read `applied_count` and `last_applied`.
- Which agent should see it? Read `agent_specific`; `null` means all agents.

During prompt rendering, v2 emits compact summary lines such as:

```markdown
<!-- learning: lrn-2026-05-24-001 --> [lrn-2026-05-24-001, applied 7x] Use direct Bats for CLI behavior changes.
```

If the compact summary is not enough, an agent can request raw detail by placing
`<request-memory id="lrn-xxx"/>` at the start of its response.

## Troubleshooting

### 1. `memory migrate` says no v1 store was found

Run `monozukuri doctor` to confirm the project root. If the project never used
v1 memory, this is safe; create v2 learnings through future runs or manual
fixtures.

### 2. `memory lint` rejects a migrated file

Open the reported ID and compare it with `docs/schemas/memory-v2.md`. The most
common issue is an invalid `source.phase` or a missing `source.artifact`.

### 3. `pick` returns an empty list

Check the default status filter. `monozukuri pick` defaults to `ready`; pass
`--status done`, `--status blocked`, or remove label filters while debugging.

### 4. `pick --replay` prints an old selection

Inspect `.monozukuri/state/pick-history.jsonl` with
`monozukuri pick --history`. The newest entry is replayed by default.

### 5. The TUI does not open in CI

Use non-interactive mode: `monozukuri pick --top N`, `monozukuri pick --json`,
or pipe IDs directly into `monozukuri loop`.

### 6. `loop --resume` restarts a running task

This is expected after an interruption. A task left in `running` state is marked
`inconclusive`, its old worktree is preserved, and a new worktree is created.

### 7. The loop stops before starting the next feature

Check cost and time caps. If `--max-cost`, `--max-time`, or
`--max-tokens-per-task` is reached, the current task finishes and the next task
is not started.

### 8. A full-auto loop keeps failing in the same phase

Look for the circuit breaker message. After the configured number of consecutive
failures, the loop exits with code `5` and persists state for inspection.

### 9. A learning appears for the wrong agent

Run `monozukuri memory list --agent codex` or the relevant adapter id. Universal
learnings use `agent_specific: null`; agent-only learnings must match the active
adapter exactly.

### 10. Memory context is missing details

Run `monozukuri memory trace <run-id>` to see which learnings were summarized,
which IDs were omitted as `available_on_request`, and whether escalation was
granted or denied.
