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

The document must contain all five sections below. Return the markdown only — no preamble.

## Architecture

Component diagram or prose description of how this feature fits into the existing system.

## APIs

New or modified endpoints/functions/interfaces with their signatures and contracts.

## Data Model

Schema changes or new data structures required.

## Risks

Technical risks and their mitigations.

## Test Plan

How correctness will be verified: unit tests, integration tests, manual checks.
