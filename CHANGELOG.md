# Changelog

## [1.8.0](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.7.0...v1.8.0) (2026-04-26)


### Features

* **gap6:** run review — export, open, list subcommands (ADR-015) ([7b6e03c](https://github.com/Viniciuscarvalho/monozukuri/commit/7b6e03ca322f4ede636fcbac96f460caef175b17))

## [1.7.0](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.6.0...v1.7.0) (2026-04-26)


### Features

* Gap 5 - L5 Measurability Infrastructure ([a86f766](https://github.com/Viniciuscarvalho/monozukuri/commit/a86f76677d429c85b4e5a7250733ae4dd039ebf9))

## [1.6.0](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.5.0...v1.6.0) (2026-04-26)


### Features

* **gap4:** per-phase routing config, routing_load, and threshold-gated routing suggest (ADR-015) ([30cec4f](https://github.com/Viniciuscarvalho/monozukuri/commit/30cec4f26e8b9341cfddfdbc6bc85e691126e96d))
* **gap4:** per-phase routing config, routing_load, and threshold-gated suggest (ADR-015) ([1272e08](https://github.com/Viniciuscarvalho/monozukuri/commit/1272e08128e4bc4dea41633bca256b3f36da0a20))

## [1.5.0](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.4.0...v1.5.0) (2026-04-26)


### Features

* **contract:** gap 3 — adapter contract v1.0.0, claude-code improvements, aider adapter (ADR-012) ([cdfee8e](https://github.com/Viniciuscarvalho/monozukuri/commit/cdfee8ea67cd894caead3f164401542c0d822aa4))
* **contract:** gap 3 — adapter contract v1.0.0, claude-code improvements, aider adapter (ADR-012) ([0edde5d](https://github.com/Viniciuscarvalho/monozukuri/commit/0edde5d59905161f8b7ae75e7805ac9fb0e8346d))
* **gap3:** phase-aware templates, context-pack, registry, render node path ([d1396a9](https://github.com/Viniciuscarvalho/monozukuri/commit/d1396a941fb65babe0ee741e9492ec1773e078bb))

## [1.4.0](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.3.0...v1.4.0) (2026-04-26)


### Features

* **failure:** gap 2 — stratified failure handling, idempotent resumption, CI poll (ADR-013/014) ([92a4ceb](https://github.com/Viniciuscarvalho/monozukuri/commit/92a4ceb155d17bb3f175e98c28bd1d8187a08250))
* **failure:** gap 2 — stratified failure handling, idempotent resumption, CI poll (ADR-013/014) ([e63d1eb](https://github.com/Viniciuscarvalho/monozukuri/commit/e63d1eba70459021c4a57a8374ce55a1783ae21d))

## [1.3.0](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.2.0...v1.3.0) (2026-04-26)


### Features

* **schema:** gap 1 — phase artifact schemas and validation (ADR-012) ([6103b82](https://github.com/Viniciuscarvalho/monozukuri/commit/6103b826a7150338c6985bbeac169beb5130fb7b))
* **schema:** Gap 1 — phase artifact schemas and validation (ADR-012) ([1e1ae12](https://github.com/Viniciuscarvalho/monozukuri/commit/1e1ae12003a623dc4a07f34c47d36efd74ac03ae))

## [1.2.0](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.1.2...v1.2.0) (2026-04-26)

### Features

- **Multi-agent support** — monozukuri now drives Claude Code, Codex, Gemini, and Kiro through a uniform six-function adapter contract (`agent_name`, `agent_capabilities`, `agent_doctor`, `agent_estimate_tokens`, `agent_run_phase`, `agent_report_cost`). Switch agents with one config line or `monozukuri agent enable <name>`.
- **`monozukuri agent` subcommands** — `agent list` shows all adapters and install status; `agent doctor [name]` checks install and auth; `agent enable <name>` writes the chosen agent into `.monozukuri/config.yaml`.
- **`monozukuri init` wizard** — detects installed agents at init time and writes `agent: <name>` instead of the old hardcoded `skill.command: feature-marker`.
- **Agent field in JSONL events** — every event emitted to stdout now carries an `agent` field, surfacing adapter identity to the TUI and any downstream tooling.
- **TUI agent display** — the Ink header now shows `agent: <name>` alongside `model:`.
- **Jest test infra for the UI** — `npm test --prefix ui` is now wired up with ts-jest + ink-testing-library; 14 tests covering reducer and Header for all four adapters.
- **Phase prompt templates** — prompts extracted to `lib/prompt/phases/*.tmpl.md` and rendered by `lib/prompt/render.sh`, decoupling prompt content from agent invocation.
- **Pricing registry** — `lib/agent/pricing.yaml` holds per-token USD rates for all supported models.

### Breaking changes (back-compat shim included)

- Config key `skill.command` is deprecated in favour of `agent: <name>` + `agents.claude-code.skills.<phase>`. Old configs continue to work via a shim in `lib/config/load.sh` — no action required for existing users.

### Internal

- Consolidated duplicate `scripts/lib/` tree into canonical `lib/`; `scripts/lib/` deleted.
- `ROUTING_FALLBACK` default changed from `feature-marker` to the resolved agent name.
- Conformance suite added: `test/conformance/agent_phase_outputs.bats` and `test/conformance/ui_agent_display.bats`.

## [1.1.2](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.1.1...v1.1.2) (2026-04-26)

### Bug Fixes

- create bump branch before writing formula in homebrew-tap workflow ([e7ee2e8](https://github.com/Viniciuscarvalho/monozukuri/commit/e7ee2e836e03159d6c8d652011183d899a5ad566))

## [1.1.1](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.1.0...v1.1.1) (2026-04-26)

### Bug Fixes

- use injected github client in github-script, drop manual Octokit ([824c82e](https://github.com/Viniciuscarvalho/monozukuri/commit/824c82ea179c88cd5cafec6909b739417cd65cb4))

## [1.1.0](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.0.0...v1.1.0) (2026-04-26)

### Features

- add doctor command improvements, exit-codes, and errors.sh ([e5ea5e9](https://github.com/Viniciuscarvalho/monozukuri/commit/e5ea5e937673476fed0576b728874f4cf9e208e7))
- add monozukuri doctor command ([e7cd75e](https://github.com/Viniciuscarvalho/monozukuri/commit/e7cd75e0fd903c313171ea255f8d4a28072f9067))
- bundle to-prd and grill-me skills (pre-flight workflow) ([045c467](https://github.com/Viniciuscarvalho/monozukuri/commit/045c4673df2e2bee17082dd2fb9bf9a20db4f33e))
- bundle to-prd and grill-me skills from mattpocock/skills ([a113324](https://github.com/Viniciuscarvalho/monozukuri/commit/a113324fb24eaf9e3c9d1cc84dc7b8d8dd1c6fd3))
- Ink TUI, repo tooling, CI workflows, Bats harness, JSONL events ([1aa5caf](https://github.com/Viniciuscarvalho/monozukuri/commit/1aa5cafde4a7c452e2c53505726ca9fa1ffbc6a7))
- M2 UX polish + M5 launch prep ([3a35c4f](https://github.com/Viniciuscarvalho/monozukuri/commit/3a35c4f6ad2ccb8483e96a6a577bb67ae63e0dfe))

### Bug Fixes

- mermaid diagram + homebrew formula v1.0.0 checksum ([52dba02](https://github.com/Viniciuscarvalho/monozukuri/commit/52dba0231b62e735ea173e8606c79747b7f9c997))
- resolve 8 runtime bugs in full-auto PR creation flow ([33ec376](https://github.com/Viniciuscarvalho/monozukuri/commit/33ec3764f69f888446618595996149ed1aec64d0))

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
