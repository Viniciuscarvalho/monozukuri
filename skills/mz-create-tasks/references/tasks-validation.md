# Tasks Validation Rules

The validator (`lib/schema/validate.sh`) checks these rules. This file is the authoritative rule source; PR2 couples the validator to read from here instead of hardcoded regexes.

## Output format

Tasks are emitted as `tasks.json` (a JSON array per the schema in `references/tasks-schema.md`).

The current validator also checks for a `tasks.md` artifact with task checkboxes — see §Current validator below for context on this discrepancy.

## Required structure

### JSON task list (`tasks.json`)

Each task object MUST have:

- `id` — string, e.g. `"task-001"`
- `title` — short imperative string
- `description` — what to build and why
- `files_touched` — array of file paths (≥ 1 item)
- `acceptance_criteria` — array of observable outcome strings (≥ 1 item)

### Per-task invariants

Every task MUST:

- be completable in ≤ 60 minutes of agent time
- touch ≤ 5 files
- have at least one verifiable acceptance criterion

### Coverage

Every FR and NFR from the PRD must appear in at least one task. The reviewer can verify this by cross-referencing task descriptions against the PRD's functional requirements list.

---

## Current validator behavior

_From `validate.sh:91-98`:_

The validator checks the tasks artifact for at least one checkbox pattern:

```
^[[:space:]]*-[[:space:]]\[[ xX]\]
```

This pattern targets a markdown `tasks.md`, but the tasks phase outputs `tasks.json`. This mismatch is part of the 40% validation failure rate documented in `MONOZUKURI_SKILLS_PLAN.md`. PR2 of the skills plan will update the validator to check `tasks.json` against the JSON schema instead.

**Until PR2 ships:** when using the raw-prompt adapter path, ensure a `tasks.md` summary with checkboxes for each task is generated alongside `tasks.json`. When the skill-native path is active (PR4+), only `tasks.json` is required.

---

## Heading aliases for PR2 validator

| Rule              | Pattern                                                                            |
| ----------------- | ---------------------------------------------------------------------------------- |
| Valid task object | Has `id`, `title`, `description`, `files_touched` (≥1), `acceptance_criteria` (≥1) |
| Time constraint   | `description` or metadata indicates ≤ 60 min                                       |
| File constraint   | `files_touched` array length ≤ 5                                                   |
