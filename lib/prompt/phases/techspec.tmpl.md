You are executing the **techspec** phase for feature `{{MONOZUKURI_FEATURE_ID}}`.

Autonomy level: **{{MONOZUKURI_AUTONOMY}}**

## Feature

{{FEATURE_TITLE}}

## Inputs

- PRD: `{{MONOZUKURI_RUN_DIR}}/{{MONOZUKURI_FEATURE_ID}}/prd.md`

## Project conventions (learned from prior runs)

{{LEARNINGS_BLOCK}}

## Output contract

Write `techspec.md` to `{{MONOZUKURI_RUN_DIR}}/{{MONOZUKURI_FEATURE_ID}}/techspec.md`.

The document MUST contain all six sections below. Return the markdown only — no preamble.
Output schema: `.monozukuri-schemas/techspec.schema.json` (key required field: `files_likely_touched`).

## Architecture

Component diagram or prose description of how this feature fits into the existing system.

## APIs

New or modified endpoints/functions/interfaces with their signatures and contracts.

## Data Model

Schema changes or new data structures required.

## Files Likely Touched

Bullet list of every file path likely to be created or modified during implementation.
Include both source files and test files. Example:

- `src/routes/auth.ts`
- `src/middleware/authenticate.ts`
- `test/unit/auth.test.ts`

## Risks

Technical risks and their mitigations.

## Test Plan

How correctness will be verified: unit tests, integration tests, manual checks.
