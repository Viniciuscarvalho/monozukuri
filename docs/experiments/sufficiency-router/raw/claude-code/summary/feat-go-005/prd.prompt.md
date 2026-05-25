You are running the MEM-05 sufficiency-router experiment.

Agent under test: claude-code
Strategy under test: summary
Feature: feat-go-005 - Add Prometheus metrics
Stack: go
Description:
Expose `/metrics` with request count and latency histograms via `prometheus/client_golang`.

Memory context:
- lrn-2026-05-25-101: Prefer public CLI behavior tests for orchestrator changes.
- lrn-2026-05-25-102: Keep live-agent experiments local-only and outside CI.
- lrn-2026-05-25-103: Use schema validation pass rate as the quality proxy for replay experiments.
- lrn-2026-05-25-104: For go features, keep file changes narrow and name likely entry points explicitly.
- lrn-2026-05-25-105: Codex and Gemini need schemas inline because they do not receive worktree schema injection.

Return a PRD markdown artifact with these top-level headings:
## Problem
## Solution
## Success criteria
## Functional requirements
## Out of scope

Output only the requested artifact unless you need on-demand memory escalation.