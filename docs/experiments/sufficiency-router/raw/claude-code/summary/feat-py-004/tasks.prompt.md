You are running the MEM-05 sufficiency-router experiment.

Agent under test: claude-code
Strategy under test: summary
Feature: feat-py-004 - Add input validation with pydantic
Stack: python
Description:
Validate all request bodies with pydantic v2 models. Return 422 on validation failure.

Memory context:
- lrn-2026-05-25-101: Prefer public CLI behavior tests for orchestrator changes.
- lrn-2026-05-25-102: Keep live-agent experiments local-only and outside CI.
- lrn-2026-05-25-103: Use schema validation pass rate as the quality proxy for replay experiments.
- lrn-2026-05-25-104: For python features, keep file changes narrow and name likely entry points explicitly.
- lrn-2026-05-25-105: Codex and Gemini need schemas inline because they do not receive worktree schema injection.

Return only a JSON array of task objects. Each task must include:
id, title, description, files_touched, acceptance_criteria.

Output only the requested artifact unless you need on-demand memory escalation.