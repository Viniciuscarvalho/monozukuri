# Monozukuri Development Agents

These are project-local, on-demand agent profiles for developing Monozukuri itself.
They are not Monozukuri product-routing assets and must not change how the CLI
discovers agents in user projects.

## Invocation

Use these profiles by name when asking for focused work in this repository:

- `use monozukuri-software-engineer to implement <change>`
- `use monozukuri-qa-engineer to design and verify tests for <change>`
- `use monozukuri-code-reviewer to review <branch, diff, or PR>`

## Scope Rules

- Keep changes inside the active Monozukuri worktree.
- Do not write to `.claude/`.
- Do not edit `AGENTS.md` unless the task explicitly asks for instruction changes.
- Do not change `scripts/agent-discovery.sh`, router behavior, or runtime agent
  discovery unless the task is explicitly about product discovery.
- Reuse existing systems before adding new ones: validators, prompt templates,
  `lib/cli/emit.sh`, `lib/cli/errors.sh`, memory helpers, and Bats fixtures.
- Prefer narrow changes and focused verification over broad refactors.

## Agent Set

- `monozukuri-software-engineer.md` handles implementation and refactoring.
- `monozukuri-qa-engineer.md` handles test strategy, fixture design, release-gate
  confidence, and regression validation.
- `monozukuri-code-reviewer.md` handles risk-focused review before merge or ship.
