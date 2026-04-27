# Tasks Schema Reference

The canonical JSON Schema for `tasks.json` lives at:

```
schemas/tasks.schema.json
```

(relative to the monozukuri repo root, or `$MONOZUKURI_HOME/schemas/tasks.schema.json` at install time)

## Quick reference

```json
[
  {
    "id": "task-001",
    "title": "Short imperative title",
    "description": "What to build and why",
    "files_touched": ["path/to/file.sh"],
    "acceptance_criteria": ["Observable outcome that proves the task is done"]
  }
]
```

## Field rules

| Field                 | Type     | Required | Constraint                                   |
| --------------------- | -------- | -------- | -------------------------------------------- |
| `id`                  | string   | yes      | format `task-NNN`                            |
| `title`               | string   | yes      | imperative, ≤ 80 chars                       |
| `description`         | string   | yes      | what to build and why                        |
| `files_touched`       | string[] | yes      | ≥ 1 item, ≤ 5 items                          |
| `acceptance_criteria` | string[] | yes      | ≥ 1 item; each must be an observable outcome |

## Notes for PR3

When `monozukuri setup` ships (PR3), it will need to decide whether `schemas/tasks.schema.json` is installed into each agent's skills directory alongside the `mz-create-tasks` skill files, or whether the skill's `references/tasks-schema.md` pointer is sufficient. Until PR3, agents read the schema from the repo root.
