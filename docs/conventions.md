# Project Convention Files

Monozukuri reads your project's convention files and injects their content into every
phase prompt, so agents always have your coding standards in context.

## What monozukuri reads

Monozukuri scans your project root for these files on every run (all are read, not
first-match):

| File                | Tool                                          |
| ------------------- | --------------------------------------------- |
| `AGENTS.md`         | Universal (OpenAI Codex, Gemini, Aider, Kiro) |
| `.agents/AGENTS.md` | Alternative location                          |
| `docs/AGENTS.md`    | Docs-tree alternative                         |
| `CLAUDE.md`         | Claude Code (Anthropic)                       |
| `.claude/CLAUDE.md` | Claude Code (subdirectory)                    |
| `.cursorrules`      | Cursor (legacy)                               |
| `.aiderrules`       | Aider (legacy)                                |
| `.windsurfrules`    | Windsurf (legacy)                             |

## How conventions are merged with the learning store

Conventions are a **read-only dataset** — they are never written to or modified by the
learning store. On every run, monozukuri:

1. Scans all 8 paths above
2. Parses each file into one record per `##` section (fallback: one per paragraph)
3. Deduplicates by section heading (exact, case-insensitive)
4. Prepends the merged set to `project_learnings` in the context pack

Conventions appear in prompts as:

```
• [Build] Run `npm run build` before committing. Never commit with build errors.
• [Database] Use kysely for all queries. No raw SQL.
```

## Inspecting what monozukuri sees

Before trusting that conventions are reaching your agents, verify with:

```bash
# List all parsed conventions
monozukuri conventions list

# Group by source file
monozukuri conventions list --source

# Show full body of a specific convention
monozukuri conventions show database

# Which files were detected
monozukuri conventions sources
```

## Disabling convention injection

Set `MONOZUKURI_READ_CONVENTIONS=0` to disable all parsing for a run:

```bash
MONOZUKURI_READ_CONVENTIONS=0 monozukuri run
```

This flag is a temporary escape hatch. It will be removed once the feature
stabilises across adapter types.

## Writing an effective AGENTS.md

Structure your file with `##` headings — monozukuri parses one record per section:

```markdown
# AGENTS.md

## Build

npm run build

## Test

npm test -- --watchAll=false

## Conventions

- Named exports only, no defaults
- kebab-case filenames, PascalCase types

## Constraints

- No lodash
- Node 20+ only
```

Files without `##` headings are parsed by paragraph — each non-blank paragraph becomes
one convention record. This handles `.cursorrules` and similar legacy formats.
