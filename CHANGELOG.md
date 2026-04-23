# Changelog

## [1.0.0] — 2026-04-23

### Added

- Initial release — extracted from [Feature-marker](https://github.com/Viniciuscarvalho/Feature-marker)
- Skill-agnostic orchestration loop: configure any Claude Code skill via `skill.command` in `.monozukuri/config.yaml`
- Backlog adapters: Linear (GraphQL), GitHub Issues (`gh` CLI), Markdown (`features.md`)
- Git worktree isolation with context carry-forward between features
- ADR-008: Token economy — cost gates, stack-adaptive routing, 3-tier learning store (feature / project / `~/.claude/monozukuri/`), size gate, cycle gate
- ADR-009: Local model integration — Ollama/lm-studio embedding, classification, summarization, optional code generation
- ADR-010: Stuck-state elimination — subshell fix, `op_timeout` wrapper, PID tracking, review ingest
- ADR-011: Security hardening — prompt sanitization, injection screening, stack-adaptive permission guardrails, codebase grounding
- Three entry points: `brew install monozukuri`, `npx @viniciuscarvalho/monozukuri`, `./scripts/orchestrate.sh`
- Autonomy levels: `supervised`, `checkpoint`, `full_auto`
- Homebrew formula: `viniciuscarvalho/tap/monozukuri`
- NPM package: `@viniciuscarvalho/monozukuri`
