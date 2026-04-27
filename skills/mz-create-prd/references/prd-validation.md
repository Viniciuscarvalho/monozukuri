# PRD Validation Rules

The validator (`lib/schema/validate.sh`) checks these rules automatically. This file is the authoritative rule source; PR2 of the skills plan will couple the validator to read from here instead of hardcoded regexes.

## Required sections

### Problem framing (REQUIRED)

Accept any of:

- `## Problem`
- `## Problem Statement`
- `## Background`
- `## Overview`
- `## Summary`
- `## Motivation`
- `## Background/Motivation`

_Current validator regex (`validate.sh:56`):_ `^#{2,3}[[:space:]]+(problem|overview|summary|background)` (case-insensitive)

**Aliases pending PR2 coupling:** `Motivation`, `Background/Motivation`, `Problem Statement`

### Solution (REQUIRED)

- `## Solution`

### Success criteria (REQUIRED)

Accept any of:

- `## Success criteria`
- `## Acceptance criteria`
- `## Definition of done`
- `## Goal`

_Current validator regex (`validate.sh:60`):_ `^#{2,3}[[:space:]]+(success|acceptance|definition|criteria|goal)` (case-insensitive)

### Functional requirements (RECOMMENDED)

- `## Functional requirements` with at least one `### FR-NNN:` block

### Hard constraints (RECOMMENDED)

- `## Hard constraints`

### Out of scope (RECOMMENDED)

- `## Out of scope`

---

## Structure rules

### FR-NNN blocks (when Functional requirements section is present)

Each `### FR-NNN:` block SHOULD contain:

- A `**Behavior:**` line describing the feature behavior in prose
- An `**Acceptance criteria:**` list with at least one Given/When/Then item
- A `**Negative cases:**` section with at least one error/rejection case

### Token budget

The body of `prd.md` (excluding headings and metadata lines) MUST NOT exceed **600 words**.

---

## Heading aliases for PR2 validator

When PR2 ships, the validator reads this table to accept all aliases for each required section:

| Canonical section | Accepted aliases                                                                                   |
| ----------------- | -------------------------------------------------------------------------------------------------- |
| Problem framing   | Problem · Problem Statement · Background · Overview · Summary · Motivation · Background/Motivation |
| Solution          | Solution                                                                                           |
| Success criteria  | Success criteria · Acceptance criteria · Definition of done · Goal                                 |
