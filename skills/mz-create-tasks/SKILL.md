---
name: mz-create-tasks
description: Decompose a PRD and TechSpec into a structured tasks.json task list for monozukuri's code phase. Use when the orchestrator routes the tasks phase. Do not use for PRD or TechSpec generation.
argument-hint: "[feature-id]"
---

You are executing the **tasks** phase of monozukuri's autonomous feature loop.

## Inputs available

- PRD at `$MONOZUKURI_RUN_DIR/$MONOZUKURI_FEATURE_ID/prd.md`
- TechSpec at `$MONOZUKURI_RUN_DIR/$MONOZUKURI_FEATURE_ID/techspec.md`
- Project conventions — from `CLAUDE.md`, `AGENTS.md`, or the monozukuri learning store
- The prompt template at `references/tasks-template.md` — describes the expected output format
- The validation rules at `references/tasks-validation.md`
- The output schema at `references/tasks-schema.md` (canonical JSON schema: `schemas/tasks.schema.json`)

## Output contract

Write the task list to `$MONOZUKURI_RUN_DIR/$MONOZUKURI_FEATURE_ID/tasks.json` as a JSON array matching the schema in `references/tasks-schema.md`.

The file MUST satisfy `references/tasks-validation.md`. The validator runs immediately after; failures trigger a reprompt.

## Hard rules

- Every task must be completable in ≤ 60 minutes of agent time.
- Every task must touch ≤ 5 files.
- Every task must have at least one verifiable acceptance criterion.
- Every FR and NFR from the PRD must appear in at least one task.
- Return ONLY the JSON array — no markdown, no commentary, no code fences.
- In autonomous mode, never block. Decompose at the granularity the TechSpec implies.

## Workflow

1. Read the PRD and TechSpec at the input paths.
2. Read `references/tasks-template.md` for the output format.
3. Read `references/tasks-schema.md` for the JSON schema.
4. Read `references/tasks-validation.md`.
5. Identify every component, file change, and test from the TechSpec.
6. Group into tasks satisfying the time and file-count constraints.
7. Write the task list as valid JSON to `$MONOZUKURI_RUN_DIR/$MONOZUKURI_FEATURE_ID/tasks.json`.
