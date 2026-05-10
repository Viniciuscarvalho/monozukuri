## Problem

The QA gate needs a deterministic PRD artifact to verify the orchestration loop without burning real model credits. Hand-written canned text drifts from real agent output, so we record once and replay.

## Solution

Use a tiny canary feature (`canary-001`) and capture the PRD-phase output of `claude --print` into this file. The replay mock reads this verbatim when `MOCK_CLAUDE_MODE=normal`.

## Functional requirements

- Replay must be byte-identical across runs
- File must contain the headings the validator requires
- Re-recording is a single command: `make rerecord-fixtures`

## Out of scope

- Quality of the captured prose (validator only checks structure)
- Recording for agents the project does not support yet
