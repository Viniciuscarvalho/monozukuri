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

_Validator reads this alias table via `_validation_aliases()` in `validate.sh` (PR2)._

### Files likely touched (REQUIRED)

Accept any of:

- A heading containing `files` + (`likely` or `touched`): `## Files likely touched` / `## Files to touch` / `## File change map`
- The YAML key `files_likely_touched:` at line start

This section MUST contain at least one `- ` list item (a file path). An empty section fails validation.

_Validator reads this alias table via `_validation_aliases()` in `validate.sh` (PR2)._

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

## Heading aliases

| Canonical section    | Accepted aliases                                                                                                                                                 |
| -------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Technical approach   | Approach · Technical Approach · Implementation · Implementation Approach · Architecture · Design · Solution                                                      |
| Files likely touched | Files likely touched · File change map · Files Touched · Files to Modify · File Layout · Files Affected · Implementation Files · files_likely_touched (YAML key) |
