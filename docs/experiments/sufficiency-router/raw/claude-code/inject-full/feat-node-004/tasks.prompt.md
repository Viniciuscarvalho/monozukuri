You are running the MEM-05 sufficiency-router experiment.

Agent under test: claude-code
Strategy under test: inject-full
Feature: feat-node-004 - Add environment config validation
Stack: node
Description:
Validate required env vars at startup. Fail fast with clear error if missing.

Memory context:
- id: lrn-2026-05-25-101
  insight: Prefer public CLI behavior tests for orchestrator changes.
  rationale: Bats through orchestrate.sh catches parser and dispatch regressions that unit tests miss.
  scope: project
  source: test/integration/memory_why.bats#MEM-04/tests
  agent_specific: any
  tags: testing,cli,node
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
  tags: quality,schema,node
- id: lrn-2026-05-25-104
  insight: For node features, keep file changes narrow and name likely entry points explicitly.
  rationale: Narrow file maps reduce over-editing in autonomous phases.
  scope: project
  source: .qa/fixtures/scale/node/features.md#feat-node-004/techspec
  agent_specific: any
  tags: node,file-map
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