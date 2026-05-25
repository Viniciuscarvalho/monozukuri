You are running the MEM-05 sufficiency-router experiment.

Agent under test: codex
Strategy under test: inject-full
Feature: feat-go-004 - Add graceful shutdown
Stack: go
Description:
Handle os.Signal: drain in-flight requests within 30s, then exit 0.

Memory context:
- id: lrn-2026-05-25-101
  insight: Prefer public CLI behavior tests for orchestrator changes.
  rationale: Bats through orchestrate.sh catches parser and dispatch regressions that unit tests miss.
  scope: project
  source: test/integration/memory_why.bats#MEM-04/tests
  agent_specific: any
  tags: testing,cli,go
- id: lrn-2026-05-25-102
  insight: Keep live-agent experiments local-only and outside CI.
  rationale: Monozukuri release gates must preserve the zero-cost CI contract.
  scope: project
  source: docs/test-strategy.md#ADR-019/techspec
  agent_specific: any
  tags: cost,ci,experiment
- id: lrn-2026-05-25-103
  insight: Use schema validation pass rate as the quality proxy for replay experiments.
  rationale: The validator is deterministic and maps directly to whether the next phase can proceed.
  scope: global
  source: lib/schema/validate.sh#MEM-05/prd
  agent_specific: any
  tags: quality,schema,go
- id: lrn-2026-05-25-104
  insight: For go features, keep file changes narrow and name likely entry points explicitly.
  rationale: Narrow file maps reduce over-editing in autonomous phases.
  scope: project
  source: .qa/fixtures/scale/go/features.md#feat-go-004/techspec
  agent_specific: any
  tags: go,file-map
- id: lrn-2026-05-25-105
  insight: Codex and Gemini need schemas inline because they do not receive worktree schema injection.
  rationale: Rendered-prompt adapters cannot rely on Claude-style local schema files.
  scope: project
  source: lib/prompt/render.sh#F1/code
  agent_specific: any
  tags: codex,gemini,schema

Return only a JSON array of task objects. Each task must include:
id, title, description, files_touched, acceptance_criteria.

Output only the requested artifact unless you need on-demand memory escalation.