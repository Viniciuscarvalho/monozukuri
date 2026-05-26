---
name: repo-skill-audit
description: Audit a repository's local skills, agents, and instruction files for Codex compatibility and recommend only missing or redundant workflow assets. Use when the user asks whether skills are adapted to Codex, how to invoke project skills or agents, or which skills to install after scanning a repo. Do not use for ordinary code review or non-agent tooling.
---

# Repo Skill Audit

Audit the repository's agent-facing assets before recommending installs, migrations, or new skills.

## Evidence Order

1. Inspect repository-local instruction files first: `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, `.codex/`, `.agents/`, `.claude/`, and any package-level instruction files.
2. Inventory local skills and agents:
   - `.agents/skills/**/SKILL.md`
   - `.codex/skills/**/SKILL.md`
   - `.claude/skills/**/SKILL.md`
   - `.agents/agents/**`
   - `.codex/agents/**`
3. Search skill and agent bodies for runtime assumptions before giving a verdict:
   - `Task tool`
   - `Task(`
   - `TodoWrite`
   - `Bash(`
   - `Read(`
   - `Edit(`
   - `Write(`
   - `mcp__`
   - `claude-code`
   - `Claude Code`
4. Compare the repository's existing coverage to the requested workflow. Recommend only missing capabilities; do not recommend generic platform skills already covered by project-local skills.
5. Check available global or curated skills only after the local inventory is understood.

## Verdict Rules

- Say `discoverable/loadable` when the files exist in a Codex-visible skill root but still contain legacy tool names or unavailable MCP assumptions.
- Say `fully adapted` only when the skill body can run in Codex without Claude-only tool calls, unavailable MCP names, or workflow steps that require another runtime.
- Say `not present` when no local skill or agent asset covers the requested workflow.
- If the user asks how to invoke skills or agents, include practical prompts such as `use <skill-name>` or `use the <agent-name> subagent to inspect <scope>`.

## Recommendation Rules

- Prefer extending an existing local skill when the workflow is already mostly covered.
- Prefer installing a curated skill when the missing workflow is generic and already exists.
- Create a new skill only when the repository repeats a narrow workflow that is not adequately covered by local or curated skills.
- Avoid broad "install everything" recommendations. Name the smallest useful set and explain what each item adds.

## Output

Return:

- Direct compatibility verdict.
- Counts and paths inspected.
- Legacy references found, with file paths.
- Existing coverage that should not be duplicated.
- Missing skills or agents worth adding.
- Concrete invocation examples for the current repository.
- Validation commands run, or why validation was not run.

Stop after the report unless the user explicitly asks to migrate, install, or create assets.
