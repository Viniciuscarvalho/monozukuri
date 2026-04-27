# TechSpec — {{FEATURE_ID}}: {{FEATURE_TITLE}}

> **Token budget for this document: 1200 words max.** Code over prose. Tables over paragraphs. Show interfaces, not explanations of interfaces.

**Feature:** {{FEATURE_ID}}
**Inherits from:** `./prd.md`
**Date:** {{DATE}}
**Status:** {{STATUS}}

---

## Approach

{{APPROACH_SUMMARY}}
_(3–5 sentences. The core design decision and how it fits the existing codebase. No restating PRD goals.)_

### Key decisions

| Decision       | Choice       | Why          |
| -------------- | ------------ | ------------ |
| {{DECISION_1}} | {{CHOICE_1}} | {{REASON_1}} |
| {{DECISION_2}} | {{CHOICE_2}} | {{REASON_2}} |

_Only list decisions where a different choice would meaningfully change the implementation. Skip obvious choices._

---

## Existing codebase patterns this feature MUST follow

```{{LANGUAGE}}
{{ERROR_HANDLING_EXAMPLE}}
```

```{{LANGUAGE}}
{{LOGGING_EXAMPLE}}
```

```{{LANGUAGE}}
{{TEST_EXAMPLE}}
```

**Naming:** files `{{FILE_NAMING}}` · functions `{{FUNC_NAMING}}` · types `{{TYPE_NAMING}}`

**Project conventions** (from learning store):
{{#each project_learnings}}

- {{this.summary}}
  {{/each}}

---

## File change map

> **File budget: ≤ {{MAX_FILES}} files touched.** If this feature requires more, it's two features — split it before proceeding.

### New files

| Path             | Purpose       | Implements |
| ---------------- | ------------- | ---------- |
| `{{NEW_FILE_1}}` | {{PURPOSE_1}} | FR-001     |
| `{{NEW_FILE_2}}` | {{PURPOSE_2}} | FR-002     |

### Modified files

| Path             | Change       | Risk             | Implements |
| ---------------- | ------------ | ---------------- | ---------- |
| `{{MOD_FILE_1}}` | {{CHANGE_1}} | low / med / high | FR-001     |
| `{{MOD_FILE_2}}` | {{CHANGE_2}} | low / med / high | NFR-002    |

### Read for context only

| Path              | Why       |
| ----------------- | --------- |
| `{{READ_FILE_1}}` | {{WHY_1}} |

---

## Components

### {{COMPONENT_1_NAME}}

**Location:** `{{FILE_PATH_1}}`
**Implements:** FR-001

**Public interface:**

```{{LANGUAGE}}
{{COMPONENT_1_INTERFACE}}
```

**Behavior:**

1. {{STEP_1}}
2. {{STEP_2}}
3. {{STEP_3}}

**Errors:**
| Condition | Handling |
|---|---|
| {{ERROR_1}} | {{HANDLING_1}} |
| {{ERROR_2}} | {{HANDLING_2}} |

### {{COMPONENT_2_NAME}}

_(same structure)_

---

## Data model

```{{LANGUAGE}}
{{ENTITY_SCHEMA}}
```

**Migrations required:** {{YES_NO}}
**Migration:** {{MIGRATION_DETAILS}}

_Omit this section if the feature touches no persisted data._

---

## API design

_Omit this section if the feature has no external interface._

### {{METHOD}} {{ENDPOINT}}

**Implements:** FR-001

**Request:**

```json
{{REQUEST}}
```

**Response (success / error):**

```json
{{RESPONSE_SUCCESS}}
```

```json
{{RESPONSE_ERROR}}
```

---

## Configuration

_Omit if no new config keys._

| Key            | Type       | Default       | Purpose    |
| -------------- | ---------- | ------------- | ---------- |
| `{{CONFIG_1}}` | {{TYPE_1}} | {{DEFAULT_1}} | {{DESC_1}} |

---

## Testing

**Coverage target:** {{COVERAGE}}%

| Scope       | Test file           | Covers                              |
| ----------- | ------------------- | ----------------------------------- |
| Unit        | `{{TEST_FILE_1}}`   | {{COMPONENT_1}} happy + error paths |
| Unit        | `{{TEST_FILE_2}}`   | {{COMPONENT_2}} happy + error paths |
| Integration | `{{INT_TEST_FILE}}` | {{INTEGRATION_SCENARIO}}            |

### Validation commands

```bash
{{TEST_COMMAND}}
{{LINT_COMMAND}}
{{TYPE_CHECK_COMMAND}}
{{BUILD_COMMAND}}
```

_All four commands must exit 0 before the cycle gate passes._

---

## Dependencies

_Omit if no new dependencies._

| Package       | Version | Purpose     | License     |
| ------------- | ------- | ----------- | ----------- |
| {{NEW_DEP_1}} | {{VER}} | {{PURPOSE}} | {{LICENSE}} |

---

## Task ordering

_Hint for the Tasks phase — not binding, but the agent should justify any deviation._

1. {{TASK_1}} — {{RATIONALE_1}}
2. {{TASK_2}} — {{RATIONALE_2}}
3. {{TASK_3}} — {{RATIONALE_3}}

```
{{TASK_1}} → {{TASK_2}} → {{TASK_3}}
                ↓
         {{TASK_4}} (tests)
                ↓
         {{TASK_5}} (PR)
```

---

**Handoff to Tasks phase:** every component, file, and test referenced above must appear in at least one task. Each task must touch ≤ 5 files and complete in ≤ 60 minutes of agent time.
