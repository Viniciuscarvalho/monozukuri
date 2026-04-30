---
name: mz-create-prd
description: Generate a PRD artifact for a monozukuri feature. Use when the orchestrator routes the prd phase or when the user asks to draft a feature PRD. Do not use for techspec/tasks generation or for editing an existing PRD.
argument-hint: "[feature-id]"
version: 1.0.0
---

You are executing the **prd** phase of monozukuri's autonomous feature loop.

## Inputs available

- Feature object (id, title, description, source ref) — provided via `MONOZUKURI_FEATURE_ID`, `MONOZUKURI_FEATURE_TITLE`, and `MONOZUKURI_RUN_DIR`
- Project conventions — from `CLAUDE.md`, `AGENTS.md`, or the monozukuri learning store
- The template at `references/prd-template.md` — this is authoritative for section structure
- The validation rules at `references/prd-validation.md` — the validator checks against this

## Output contract

Write the PRD to `$MONOZUKURI_RUN_DIR/$MONOZUKURI_FEATURE_ID/prd.md`.

The file MUST satisfy `references/prd-validation.md`. The validator (`lib/schema/validate.sh`) runs immediately after you finish; if it fails you will be reprompted with the specific error.

## Hard rules

- Use the section headings from `references/prd-template.md` EXACTLY. Do not rename, reorder, or merge them.
- In autonomous mode (`MONOZUKURI_INTERACTIVE=0`), never block on clarifying questions. Make the most defensible choice and record the assumption under `## Open Questions` if needed.
- Token budget: 600 words for the body content. Headings and metadata lines do not count.
- Replace every `{{PLACEHOLDER}}` — no placeholder may survive into the final artifact.

## Workflow

1. Read `references/prd-template.md`.
2. Read `references/prd-validation.md` — note every required heading and its accepted aliases.
3. Read `CLAUDE.md` and/or `AGENTS.md` if present in the repo root.
4. If available, load project conventions from the monozukuri learning store.
5. Render the template: fill each `{{PLACEHOLDER}}` from the feature inputs and project context.
6. Write the rendered PRD to `$MONOZUKURI_RUN_DIR/$MONOZUKURI_FEATURE_ID/prd.md`.
7. Do not emit commentary before or after the PRD content.

## Workflow memory

Before starting, read `$MONOZUKURI_MEMORY_DIR/MEMORY.md` (if it exists) for shared feature context from earlier phases. After writing the PRD, update `$MONOZUKURI_TASK_MEMORY` with the decisions made and any assumptions recorded. If `$MONOZUKURI_NEEDS_COMPACTION` is non-empty and not `none`, run the `mz-workflow-memory` skill to compact memory files before continuing.
