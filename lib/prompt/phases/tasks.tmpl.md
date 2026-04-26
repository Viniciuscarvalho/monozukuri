You are executing the **tasks** phase for feature `{{MONOZUKURI_FEATURE_ID}}`.

Autonomy level: **{{MONOZUKURI_AUTONOMY}}**

## Feature

{{FEATURE_TITLE}}

## Inputs

- PRD: `{{MONOZUKURI_RUN_DIR}}/{{MONOZUKURI_FEATURE_ID}}/prd.md`
- TechSpec: `{{MONOZUKURI_RUN_DIR}}/{{MONOZUKURI_FEATURE_ID}}/techspec.md`

## Project conventions (learned from prior runs)

{{LEARNINGS_BLOCK}}

## Output contract

Write `tasks.json` to `{{MONOZUKURI_RUN_DIR}}/{{MONOZUKURI_FEATURE_ID}}/tasks.json` matching this schema. Return ONLY the JSON, no commentary.

Each task must:

- be completable in ≤ 60 minutes
- touch ≤ 5 files
- have at least one verifiable acceptance criterion

```json
[
  {
    "id": "task-001",
    "title": "Short imperative title",
    "description": "What to build and why",
    "files_touched": ["path/to/file.ts"],
    "acceptance_criteria": ["Observable outcome that proves the task is done"]
  }
]
```
