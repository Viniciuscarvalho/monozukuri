# mz-\* Skill Versioning Contract

Bundled skills (`mz-*`) follow [Semantic Versioning 2.0.0](https://semver.org). The version is recorded in the `version:` field of each skill's `SKILL.md` frontmatter.

## Semver Semantics

**MAJOR** — breaking changes for skill output consumers:

- Change to the output artifact schema (e.g., renamed or removed required sections in a PRD, TechSpec, or Tasks artifact)
- Change to required environment variable inputs (removing or renaming a variable the skill depends on)
- Any change that causes a downstream skill or validator to reject previously valid output

**MINOR** — additive, non-breaking changes:

- New optional input (new env var the skill reads but does not require)
- Non-breaking prompt improvements (rephrasing, reordering sections) that do not alter output shape
- New Open Questions patterns or guidance blocks that do not remove existing ones
- Addition of optional output sections that validators accept but do not require

**PATCH** — safe, invisible changes:

- Bug fixes in reasoning instructions with no output shape change
- Wording corrections, typo fixes, clarifications
- Internal comment updates within the skill body

## Compatibility Matrix

| mz-\* version | monozukuri        |
| ------------- | ----------------- |
| 1.x           | `>=2.0.0, <3.0.0` |

Skills at `1.x` are guaranteed compatible with any monozukuri `2.x` release. A monozukuri `3.0.0` release may introduce a new skill contract (MAJOR bump) and will ship updated `mz-*` skills at `2.0.0`.

## Upgrade Path

When `monozukuri setup --status` reports a version mismatch (available > installed), run `monozukuri setup` to upgrade. Skills are installed by copying or symlinking from the monozukuri install root; no network fetch is required for bundled skills.

## Notes

- `grill-me` and `to-prd` are community skills fetched from GitHub and follow their own versioning.
- Skills installed from external sources (`sourceType: github`) are not covered by this contract.
