# PRD — {{FEATURE_ID}}: {{FEATURE_TITLE}}

> **Token budget for this document: 600 words max.** Be specific, not narrative. Every sentence must drive a code decision. No introductions, no conclusions, no rationale paragraphs.

**Feature:** {{FEATURE_ID}}
**Source:** {{SOURCE_REF}}
**Date:** {{DATE}}
**Status:** {{STATUS}}

---

## Context

**Stack:** {{STACK}} · {{LANGUAGES}} · {{FRAMEWORKS}} · {{PACKAGE_MANAGER}}
**Test framework:** {{TEST_FRAMEWORK}}
**Entry points relevant to this feature:** {{ENTRY_POINTS}}

### Project conventions to follow

{{#each project_learnings}}

- {{this.summary}}
  {{/each}}

### Original request

> {{ORIGINAL_PROMPT}}

---

## Problem

{{PROBLEM_STATEMENT}}
_(2–3 sentences. What is broken or missing today that this feature fixes.)_

---

## Solution

{{SOLUTION_OVERVIEW}}
_(2–3 sentences. What we're building. No implementation details — those go in TechSpec.)_

---

## Success criteria

| Criterion       | How verified       |
| --------------- | ------------------ |
| {{CRITERION_1}} | {{VERIFICATION_1}} |
| {{CRITERION_2}} | {{VERIFICATION_2}} |

_Each criterion must be verifiable by running a command or inspecting a file. No subjective metrics._

---

## Functional requirements

### FR-001: {{FR_1_TITLE}} [MUST]

**Behavior:** {{FR_1_DESCRIPTION}}

**Acceptance criteria:**

1. Given {{PRECONDITION_1}}, when {{ACTION_1}}, then {{EXPECTED_RESULT_1}}
2. Given {{PRECONDITION_2}}, when {{ACTION_2}}, then {{EXPECTED_RESULT_2}}

**Negative cases:**

1. Given {{INVALID_PRECONDITION}}, when {{INVALID_ACTION}}, then {{ERROR_BEHAVIOR}}

### FR-002: {{FR_2_TITLE}} [MUST | SHOULD]

_(same structure)_

---

## Non-functional requirements

| ID      | Type          | Requirement         | Validation                      |
| ------- | ------------- | ------------------- | ------------------------------- |
| NFR-001 | Performance   | {{NFR_PERF}}        | `{{NFR_PERF_CMD}}`              |
| NFR-002 | Security      | {{NFR_SEC}}         | {{NFR_SEC_VALIDATION}}          |
| NFR-003 | Compatibility | {{BACKWARD_COMPAT}} | Tests pass against existing API |

_Only list NFRs that the agent will actively enforce. Skip aspirational ones._

---

## Hard constraints

- {{HARD_CONSTRAINT_1}}
- {{HARD_CONSTRAINT_2}}

_Things the implementation MUST NOT do. Be specific: "no new runtime dependencies" beats "minimize dependencies"._

---

## Out of scope

- {{OUT_OF_SCOPE_1}}
- {{OUT_OF_SCOPE_2}}

_Things explicitly excluded from this feature. Anything else is implicitly fair game._

---

**Handoff to TechSpec:** every FR ID and NFR ID above must be addressed by a component, file, or test in the TechSpec.
