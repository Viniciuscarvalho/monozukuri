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

Current hard checks (`lib/schema/validate.sh:56-64`):

- A section heading matching `problem | overview | summary | background` (case-insensitive, `##` or `###` level) MUST be present.
- A section heading matching `success | acceptance | definition | criteria | goal` MUST be present.

### TechSpec (`techspec.md`)

Read and satisfy `skills/mz-create-techspec/references/techspec-validation.md` before submitting.

Current hard checks (`lib/schema/validate.sh:67-88`):

- A section heading matching `technical | implementation | approach | architecture | design | solution` MUST be present.
- A `files_likely_touched` section heading or key MUST be present.
- That section MUST contain at least one `- ` list item.

### Tasks (`tasks.json`)

Read and satisfy `skills/mz-create-tasks/references/tasks-validation.md` before submitting.

## When validation fails

1. Read the specific error from the validator output.
2. Identify the missing or malformed section.
3. Rewrite the **complete** artifact — not just the failing section. Partial patches rarely satisfy the validator.
4. Do not shrink the artifact below its word budget to fix a validation error.
5. After rewriting, re-verify against all rules before resubmitting.

## Hard rule

Never claim a phase is complete if the artifact has not been validated. "I checked it mentally" is not evidence. The validator must run and exit 0.
