---
name: mz-workflow-memory
description: Maintain feature-scoped workflow memory (MEMORY.md and task_NN.md) across tasks within one feature run. Use when the orchestrator emits a memory bootstrap or compaction signal. Do not use for monozukuri's project/global learning store (lib/memory/learning.sh) — that is a separate durable layer.
version: 1.0.0
---

You are managing workflow memory for a single feature run in monozukuri.

## Autonomous mode

When `MONOZUKURI_INTERACTIVE=0`, never pause to ask a question. Make the most defensible choice and continue. Memory operations are housekeeping — they must never block feature progress.

## Overview

Workflow memory is feature-scoped and consists of two file types:

- `MEMORY.md` — shared across all tasks of a feature run. Holds context that matters to more than one task.
- `task_NN.md` — per-task file. Holds context specific to the current task's execution.

Memory lives at `$MONOZUKURI_MEMORY_DIR` (exported by the workflow-memory harness; resolves to `<run-dir>/<feature-id>/memory/`). Use `$MONOZUKURI_WORKFLOW_MEMORY` for the full path to `MEMORY.md` and `$MONOZUKURI_TASK_MEMORY` for the current task file.

This is **not** the same as the monozukuri global learning store at `~/.claude/monozukuri/learned/`. Workflow memory is transient within a feature run; the learning store is durable across features. Both layers are needed and serve different purposes.

## Soft caps

| File         | Line cap  | Byte cap |
| ------------ | --------- | -------- |
| `MEMORY.md`  | 150 lines | 12 KiB   |
| `task_NN.md` | 200 lines | 16 KiB   |

When a file exceeds its cap, the orchestrator sets `MONOZUKURI_NEEDS_COMPACTION` to `workflow`, `task`, or `both` before invoking the agent. When this env var is non-empty and not `none`, apply compaction rules before continuing any other work.

## Bootstrap (first task of a feature)

If `memory/MEMORY.md` does not exist, create it from `references/memory-template.md`.
If `memory/task_NN.md` does not exist for the current task, create it from `references/task-template.md`.

## Before each task

1. Read `MEMORY.md` — load shared context.
2. Read the previous task file (e.g. `task_NN-1.md`) if it exists — load handoff notes.
3. Load the current task's input (objective, files, AC) from `tasks.json`.

## After each task

1. Update `task_NN.md`: record decisions made, files touched, errors hit, corrections applied, and what's ready for the next run.
2. Promote items from `task_NN.md` to `MEMORY.md` only when ALL three hold:
   - Another task will need it to avoid mistakes or rediscovery.
   - It is durable across multiple runs of this feature.
   - It is not already explicit in the PRD, TechSpec, tasks.json, or the repo itself.

## Compaction rules (when soft cap is hit)

- Preserve: current state, durable decisions, reusable learnings, open risks, handoffs.
- Remove: repetition, stale notes, command transcripts, facts derivable from PRD/TechSpec/repo.
- Rewrite for clarity, not completeness — prefer short factual bullets over narrative logs.
- Compact `MEMORY.md` before `task_NN.md`.

## Section headings

Use the default sections from `references/memory-template.md` and `references/task-template.md`. Do not add ad-hoc top-level sections; place new content under the closest matching section.
