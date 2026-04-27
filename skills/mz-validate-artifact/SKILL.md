---
name: mz-validate-artifact
description: Validate a generated artifact (PRD, TechSpec, or Tasks) against its skill's validation rules before claiming the phase is complete. Use when the orchestrator runs schema_validate_with_reprompt or after any manual artifact edit. Do not use for runtime test validation (mz-run-tests handles that).
---

You are enforcing artifact quality for monozukuri's planning phases.

## What this skill does

This skill is a **discipline contract** — it defines the quality bar an artifact must meet before the phase advances. It does not execute code; the validator (`lib/schema/validate.sh`) runs in the harness. Your role is to:

1. Know what the validator checks.
2. Self-verify before the harness runs so you catch issues first.
3. Provide complete, well-structured rewrites when validation fails.

## Per-artifact rules

### PRD (`prd.md`)

Read and satisfy `skills/mz-create-prd/references/prd-validation.md` before submitting.

Heading aliases are read from `references/prd-validation.md` by the validator (PR2). Any accepted alias in the "Problem framing" and "Success criteria" rows passes.

### TechSpec (`techspec.md`)

Read and satisfy `skills/mz-create-techspec/references/techspec-validation.md` before submitting.

Heading aliases are read from `references/techspec-validation.md` by the validator (PR2). The "Files likely touched" section MUST contain at least one `- ` list item.

### Tasks (`tasks.json`)

Read and satisfy `skills/mz-create-tasks/references/tasks-validation.md` before submitting. The validator checks valid JSON, non-empty array, and all five required fields per task.

## When validation fails

1. Read the specific error from the validator output.
2. Identify the missing or malformed section.
3. Rewrite the **complete** artifact — not just the failing section. Partial patches rarely satisfy the validator.
4. Do not shrink the artifact below its word budget to fix a validation error.
5. After rewriting, re-verify against all rules before resubmitting.

## Hard rule

Never claim a phase is complete if the artifact has not been validated. "I checked it mentally" is not evidence. The validator must run and exit 0.

## Workflow memory

Before validating, read `$MONOZUKURI_MEMORY_DIR/MEMORY.md` for any prior validation failures or known heading-alias workarounds recorded by earlier runs. After validation succeeds, update `$MONOZUKURI_TASK_MEMORY` noting which artifact was validated and any aliased headings used. If `$MONOZUKURI_NEEDS_COMPACTION` is non-empty and not `none`, run the `mz-workflow-memory` skill to compact memory files before continuing.
