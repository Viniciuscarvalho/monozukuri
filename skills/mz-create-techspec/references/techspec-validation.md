# TechSpec Validation Rules

The validator (`lib/schema/validate.sh`) checks these rules. This file is the authoritative rule source; PR2 couples the validator to read from here instead of hardcoded regexes.

## Required sections

### Technical approach (REQUIRED)

Accept any of:

- `## Approach`
- `## Technical Approach`
- `## Implementation`
- `## Implementation Approach`
- `## Architecture`
- `## Design`
- `## Solution`

_Current validator regex (`validate.sh:69`):_ `^#{2,3}[[:space:]]+(technical|implementation|approach|architecture|design|solution)` (case-insensitive)

### Files likely touched (REQUIRED)

Accept any of:

- A heading containing `files` + (`likely` or `touched`): `## Files likely touched` / `## Files to touch` / `## File change map`
- The YAML key `files_likely_touched:` at line start

_Current validator (`validate.sh:73`):_ `^#{2,3} [Ff]iles.*(likely|touched)|^files_likely_touched:`

This section MUST contain at least one `- ` list item (a file path). An empty section fails validation.

_Current validator (`validate.sh:78-85`):_ awk-based scan for a `- ` line after the files heading.

---

## Structure rules

### Key decisions table (RECOMMENDED)

The `## Approach` or `## Key decisions` section SHOULD include a markdown table with columns `Decision | Choice | Why`.

### Components (RECOMMENDED)

The TechSpec SHOULD include at least one `### <ComponentName>` section with its location, interface, and behavior.

### Testing (RECOMMENDED)

A `## Testing` section SHOULD list:

- Coverage target (percentage)
- Test file paths and what they cover
- Validation commands (all must exit 0)

---

## Token budget

The body of `techspec.md` MUST NOT exceed **1200 words**.

---

## Heading aliases for PR2 validator

| Canonical section    | Accepted aliases                                                                                            |
| -------------------- | ----------------------------------------------------------------------------------------------------------- |
| Technical approach   | Approach · Technical Approach · Implementation · Implementation Approach · Architecture · Design · Solution |
| Files likely touched | Files likely touched · File change map · Files Touched · Files to Modify · files_likely_touched (YAML key)  |
