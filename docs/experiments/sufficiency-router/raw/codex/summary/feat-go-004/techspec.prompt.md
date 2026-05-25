You are running the MEM-05 sufficiency-router experiment.

Agent under test: codex
Strategy under test: summary
Feature: feat-go-004 - Add graceful shutdown
Stack: go
Description:
Handle os.Signal: drain in-flight requests within 30s, then exit 0.

Memory context:
- lrn-2026-05-25-101: Prefer public CLI behavior tests for orchestrator changes.
- lrn-2026-05-25-102: Keep live-agent experiments local-only and outside CI.
- lrn-2026-05-25-103: Use schema validation pass rate as the quality proxy for replay experiments.
- lrn-2026-05-25-104: For go features, keep file changes narrow and name likely entry points explicitly.
- lrn-2026-05-25-105: Codex and Gemini need schemas inline because they do not receive worktree schema injection.

Return a TechSpec markdown artifact with these top-level headings:
## Approach
## File change map
## Components
## Testing
The File change map section must contain at least one markdown list item.

Output only the requested artifact unless you need on-demand memory escalation.