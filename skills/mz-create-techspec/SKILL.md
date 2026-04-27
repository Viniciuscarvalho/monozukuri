---
name: mz-create-techspec
description: Generate a TechSpec artifact that translates a PRD into a concrete implementation plan. Use when the orchestrator routes the techspec phase or when the user asks to draft a technical specification. Do not use for PRD generation or task decomposition.
argument-hint: "[feature-id]"
---

You are executing the **techspec** phase of monozukuri's autonomous feature loop.

## Inputs available

- PRD at `$MONOZUKURI_RUN_DIR/$MONOZUKURI_FEATURE_ID/prd.md` — every FR and NFR must be addressed
- Project conventions — from `CLAUDE.md`, `AGENTS.md`, or the monozukuri learning store
- The template at `references/techspec-template.md` — authoritative for section structure
- The validation rules at `references/techspec-validation.md`

## Output contract

Write the TechSpec to `$MONOZUKURI_RUN_DIR/$MONOZUKURI_FEATURE_ID/techspec.md`.

The file MUST satisfy `references/techspec-validation.md`. The validator runs immediately after; failures trigger a reprompt.

## Hard rules

- Every FR and NFR from the PRD must be addressed by at least one component, file, or test entry.
- The `files_likely_touched` section must list at least one file path — this is a hard validator check.
- File budget: ≤ `MAX_FILES` files touched (value from the template). If the feature needs more, stop and flag it as two features.
- Token budget: 1200 words for the body.
- Replace every `{{PLACEHOLDER}}` — no placeholder survives.
- In autonomous mode, never block. Choose the most idiomatic approach for this codebase and document the decision in the Key Decisions table.

## Workflow

1. Read the PRD at `$MONOZUKURI_RUN_DIR/$MONOZUKURI_FEATURE_ID/prd.md`.
2. Read `references/techspec-template.md`.
3. Read `references/techspec-validation.md`.
4. Read `CLAUDE.md` and/or `AGENTS.md` for codebase conventions.
5. Grep for relevant existing files to populate `Existing codebase patterns` and `files_likely_touched`.
6. Render the template, filling all placeholders.
7. Write the rendered TechSpec to the output path.

## Workflow memory

Before starting, read `$MONOZUKURI_MEMORY_DIR/MEMORY.md` (if it exists) for shared feature context from the PRD phase. After writing the TechSpec, update `$MONOZUKURI_TASK_MEMORY` with the key architectural decisions and file scope recorded. If `$MONOZUKURI_NEEDS_COMPACTION` is non-empty and not `none`, run the `mz-workflow-memory` skill to compact memory files before continuing.
