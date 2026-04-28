# Changelog

## [1.19.3](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.19.2...v1.19.3) (2026-04-28)


### Bug Fixes

* **ui:** stub react-devtools-core to eliminate missing-package error at runtime ([#66](https://github.com/Viniciuscarvalho/monozukuri/issues/66)) ([f312c48](https://github.com/Viniciuscarvalho/monozukuri/commit/f312c48aca50a837116301f472b54980f24af534))

## [1.19.2](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.19.1...v1.19.2) (2026-04-27)


### Bug Fixes

* **ui:** open /dev/tty for Ink keyboard input; avoid raw mode error in non-TTY context ([7ca35f5](https://github.com/Viniciuscarvalho/monozukuri/commit/7ca35f5054542c1f10becd9b9e3004e45868ef93))
* **ui:** open /dev/tty for Ink keyboard input; avoid raw mode error in non-TTY context ([82ee32b](https://github.com/Viniciuscarvalho/monozukuri/commit/82ee32b855700edb878a8469b2cda147c4e89a7a))

## [1.19.1](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.19.0...v1.19.1) (2026-04-27)


### Bug Fixes

* **memory:** workflow_memory_prepare crash — exports lost in subshell ([747c8e7](https://github.com/Viniciuscarvalho/monozukuri/commit/747c8e78403022b41c0d776d2cca2e8ef98de6c8))
* **memory:** workflow_memory_prepare must export to parent process ([23f629a](https://github.com/Viniciuscarvalho/monozukuri/commit/23f629a45db412ad0de2c8cf5f172e9dcffd05c6))

## [1.19.0](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.18.0...v1.19.0) (2026-04-27)


### Features

* **ui:** surface skills, workflow memory, and setup events in TUI (PR6) ([e75bc65](https://github.com/Viniciuscarvalho/monozukuri/commit/e75bc65fbf7010c8d012727b9e4ab1850b8385e1))
* **ui:** surface skills, workflow memory, and setup events in TUI (PR6) ([8116c7b](https://github.com/Viniciuscarvalho/monozukuri/commit/8116c7b98e37ef27df2f35c88e988e90908d0f78))

## [1.18.0](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.17.0...v1.18.0) (2026-04-27)


### Features

* **adapter:** add skill-native invocation path to adapter-claude-code (PR4) ([8ff8c15](https://github.com/Viniciuscarvalho/monozukuri/commit/8ff8c15513bcd3a580dbbd2b9a442338a7dffda7))
* **adapter:** skill-native invocation path + release-please v5 (PR4) ([2b26d3d](https://github.com/Viniciuscarvalho/monozukuri/commit/2b26d3d3cb6bb4a198846434592e82f89af0f33e))
* **memory:** workflow memory harness + README skills documentation (PR5) ([088a305](https://github.com/Viniciuscarvalho/monozukuri/commit/088a30590541702259e79ef2bfeda95587766c1d))
* **memory:** workflow memory harness + README skills documentation (PR5) ([7ced242](https://github.com/Viniciuscarvalho/monozukuri/commit/7ced242e2fa6205106e7597fc65ca527f938fd42))
* **setup:** add monozukuri setup installer command (PR3) ([62f83b3](https://github.com/Viniciuscarvalho/monozukuri/commit/62f83b3f374960f79a949b1aba3a86ed00074e68))


### Bug Fixes

* **ci:** suppress monozukuri-vX prefix in release-please v5 tags ([8a7d11e](https://github.com/Viniciuscarvalho/monozukuri/commit/8a7d11e78715df6ea844998bc87e2b97bc853192))
* **ci:** suppress monozukuri-vX prefix in release-please v5 tags ([64fe15d](https://github.com/Viniciuscarvalho/monozukuri/commit/64fe15decd1e43018c36b230484b96753f47f92b))
* **metrics:** fix 8 pre-existing test failures in metrics module ([fff0494](https://github.com/Viniciuscarvalho/monozukuri/commit/fff0494c86cd22e656d0c8cbb7d76797c170293a))
* **metrics:** remove comment drift from linter revert in metrics.sh ([4a1a628](https://github.com/Viniciuscarvalho/monozukuri/commit/4a1a628bac077a629b7bdb31abcafc110049e203))

## [1.17.0](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.16.0...v1.17.0) (2026-04-27)


### Features

* **validator:** couple validate.sh to skills/*-validation.md aliases (PR2) ([d52a25a](https://github.com/Viniciuscarvalho/monozukuri/commit/d52a25a0909e9488fe9bb0f7e08219a3b943dbef))

## [1.16.0](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.15.0...v1.16.0) (2026-04-27)


### Features

* **skills:** scaffold 8 mz-* phase skills (PR1 of skills plan) ([200cc90](https://github.com/Viniciuscarvalho/monozukuri/commit/200cc90a3ee2cf6afc2b0af3b77620946c55a6e3))
* **skills:** scaffold 8 mz-* phase skills (PR1 of skills plan) ([ebf01a9](https://github.com/Viniciuscarvalho/monozukuri/commit/ebf01a9276f4bb7dcdf62748f93fcba047642f78))

## [1.15.0](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.14.0...v1.15.0) (2026-04-27)


### Features

* **conventions:** seed AGENTS.md and add it to Claude Code adapter native context ([b987513](https://github.com/Viniciuscarvalho/monozukuri/commit/b9875133641939cbe606ad1b8f562ceb6ba7ed6c))
* **conventions:** seed AGENTS.md and align Claude Code adapter with multi-agent convention surface ([d1e8f7a](https://github.com/Viniciuscarvalho/monozukuri/commit/d1e8f7a64630c6c2f3a1d6d74a7105f1c1a5e032))

## [1.14.0](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.13.0...v1.14.0) (2026-04-27)


### Features

* add agent-blocker channel (EXIT_AGENT_BLOCKED=21) ([93b4697](https://github.com/Viniciuscarvalho/monozukuri/commit/93b46974489d34bc920544ea3a1b6caf7f055dc3))
* configurable schema reprompt budget + human escalation ([682f63f](https://github.com/Viniciuscarvalho/monozukuri/commit/682f63fb4ef31c79c83678741eaef8f5cf76c6ca))
* configurable schema reprompt budget + human escalation path ([6d974f5](https://github.com/Viniciuscarvalho/monozukuri/commit/6d974f5d3e2a228d0419cea7a80e21f3c01da92f))


### Bug Fixes

* fold error status into failed counter across all three reporters ([e6e5762](https://github.com/Viniciuscarvalho/monozukuri/commit/e6e57626e308e2079fef48ed51ca8f1729e46f62))

## [1.13.0](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.12.0...v1.13.0) (2026-04-27)


### Features

* enable Ink terminal UI via Node dispatcher in Homebrew ([3a9e226](https://github.com/Viniciuscarvalho/monozukuri/commit/3a9e226006585d425701b1253141df58f881adf6))
* enable Ink terminal UI via Node dispatcher in Homebrew ([8c12967](https://github.com/Viniciuscarvalho/monozukuri/commit/8c12967d1158674256e426b53752bf46d14c95d2))

## [1.12.0](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.11.0...v1.12.0) (2026-04-26)


### Features

* **conventions:** auto-sync AGENTS.md after each run (PR4) ([793a678](https://github.com/Viniciuscarvalho/monozukuri/commit/793a6787943ad6a58da78737ec13c290724e6e45))
* **conventions:** generate AGENTS.md from learning store (PR3) ([801ec1e](https://github.com/Viniciuscarvalho/monozukuri/commit/801ec1e893770dcf028ae4517a02c1910f84b279))
* **conventions:** surface promotion candidates as convention entries (PR5) ([7782e3a](https://github.com/Viniciuscarvalho/monozukuri/commit/7782e3abd47528d53b52472f578499d89b0c7e31))
* **conventions:** surface promotion candidates as convention entries (PR5) ([629488f](https://github.com/Viniciuscarvalho/monozukuri/commit/629488fd240414948a65141705ba3fd555aff40e))

## [1.11.0](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.10.0...v1.11.0) (2026-04-26)


### Features

* **conventions:** read and inject project convention files ([0da6119](https://github.com/Viniciuscarvalho/monozukuri/commit/0da611918f5f6a83689a9110d7c70de975ec5587))

## [1.10.0](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.9.0...v1.10.0) (2026-04-26)


### Features

* **gap8:** deferred status in FeatureList — yellow icon and label in completed list ([b25aaf1](https://github.com/Viniciuscarvalho/monozukuri/commit/b25aaf1676a8e8223fe4604bf10ae6d4ee0f181b))
* **gap8:** pricing and calibration — L5 cost honesty ([e930e07](https://github.com/Viniciuscarvalho/monozukuri/commit/e930e0763141eca52d999ab834c746a00a6144c9))
* **gap8:** pricing and calibration — L5 cost honesty (ADR-008) ([f066ffe](https://github.com/Viniciuscarvalho/monozukuri/commit/f066ffef006f07f16fa68eb05c7cb642ac850d1c))

## [Unreleased]

### Features

- **gap8:** pricing & calibration — versioned `config/pricing.yaml`, `pricing_cost_usd()` for real USD cost tracking, `monozukuri calibrate` subcommand with per-(agent,model,phase) coefficient learning, deferred feature UI state (ADR-008)

## [1.9.0](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.8.0...v1.9.0) (2026-04-26)

### Features

- **gap7:** implicit-dep detection + ingestion validator (ADR-015) ([5852a39](https://github.com/Viniciuscarvalho/monozukuri/commit/5852a392597df28ce150a65ee49ffd4ef3eb6d94))

## [1.8.0](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.7.0...v1.8.0) (2026-04-26)

### Features

- **gap6:** run review — export, open, list subcommands (ADR-015) ([7b6e03c](https://github.com/Viniciuscarvalho/monozukuri/commit/7b6e03ca322f4ede636fcbac96f460caef175b17))

## [1.7.0](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.6.0...v1.7.0) (2026-04-26)

### Features

- Gap 5 - L5 Measurability Infrastructure ([a86f766](https://github.com/Viniciuscarvalho/monozukuri/commit/a86f76677d429c85b4e5a7250733ae4dd039ebf9))

## [1.6.0](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.5.0...v1.6.0) (2026-04-26)

### Features

- **gap4:** per-phase routing config, routing_load, and threshold-gated routing suggest (ADR-015) ([30cec4f](https://github.com/Viniciuscarvalho/monozukuri/commit/30cec4f26e8b9341cfddfdbc6bc85e691126e96d))
- **gap4:** per-phase routing config, routing_load, and threshold-gated suggest (ADR-015) ([1272e08](https://github.com/Viniciuscarvalho/monozukuri/commit/1272e08128e4bc4dea41633bca256b3f36da0a20))

## [1.5.0](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.4.0...v1.5.0) (2026-04-26)

### Features

- **contract:** gap 3 — adapter contract v1.0.0, claude-code improvements, aider adapter (ADR-012) ([cdfee8e](https://github.com/Viniciuscarvalho/monozukuri/commit/cdfee8ea67cd894caead3f164401542c0d822aa4))
- **contract:** gap 3 — adapter contract v1.0.0, claude-code improvements, aider adapter (ADR-012) ([0edde5d](https://github.com/Viniciuscarvalho/monozukuri/commit/0edde5d59905161f8b7ae75e7805ac9fb0e8346d))
- **gap3:** phase-aware templates, context-pack, registry, render node path ([d1396a9](https://github.com/Viniciuscarvalho/monozukuri/commit/d1396a941fb65babe0ee741e9492ec1773e078bb))

## [1.4.0](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.3.0...v1.4.0) (2026-04-26)

### Features

- **failure:** gap 2 — stratified failure handling, idempotent resumption, CI poll (ADR-013/014) ([92a4ceb](https://github.com/Viniciuscarvalho/monozukuri/commit/92a4ceb155d17bb3f175e98c28bd1d8187a08250))
- **failure:** gap 2 — stratified failure handling, idempotent resumption, CI poll (ADR-013/014) ([e63d1eb](https://github.com/Viniciuscarvalho/monozukuri/commit/e63d1eba70459021c4a57a8374ce55a1783ae21d))

## [1.3.0](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.2.0...v1.3.0) (2026-04-26)

### Features

- **schema:** gap 1 — phase artifact schemas and validation (ADR-012) ([6103b82](https://github.com/Viniciuscarvalho/monozukuri/commit/6103b826a7150338c6985bbeac169beb5130fb7b))
- **schema:** Gap 1 — phase artifact schemas and validation (ADR-012) ([1e1ae12](https://github.com/Viniciuscarvalho/monozukuri/commit/1e1ae12003a623dc4a07f34c47d36efd74ac03ae))

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
