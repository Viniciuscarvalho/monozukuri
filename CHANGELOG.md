# Changelog

## [2.2.1-alpha.1](https://github.com/Viniciuscarvalho/monozukuri/compare/v2.2.0-alpha.1...v2.2.1-alpha.1) (2026-05-29)


### Documentation

* **agent:** add monozukuri development agents ([#291](https://github.com/Viniciuscarvalho/monozukuri/issues/291)) ([b45f7fa](https://github.com/Viniciuscarvalho/monozukuri/commit/b45f7fa0204d38a55807208618cb050f8f955bf8))

## [2.2.0-alpha.1](https://github.com/Viniciuscarvalho/monozukuri/compare/v2.1.0-alpha.1...v2.2.0-alpha.1) (2026-05-28)


### Features

* **cli:** add doctor readiness fix guidance ([#289](https://github.com/Viniciuscarvalho/monozukuri/issues/289)) ([b8d3e23](https://github.com/Viniciuscarvalho/monozukuri/commit/b8d3e23ed5251300e87b487b1651178c00a15df7))


### Documentation

* **readme:** clarify v2 alpha positioning ([#288](https://github.com/Viniciuscarvalho/monozukuri/issues/288)) ([3fe43f2](https://github.com/Viniciuscarvalho/monozukuri/commit/3fe43f2da4f066f1fcc76baa486c440717eea244))

## [2.1.0-alpha.1](https://github.com/Viniciuscarvalho/monozukuri/compare/v2.0.0-alpha.1...v2.1.0-alpha.1) (2026-05-27)


### Features

* **adapter:** add skill-native invocation path to adapter-claude-code (PR4) ([8ff8c15](https://github.com/Viniciuscarvalho/monozukuri/commit/8ff8c15513bcd3a580dbbd2b9a442338a7dffda7))
* **adapter:** skill-native invocation path + release-please v5 (PR4) ([2b26d3d](https://github.com/Viniciuscarvalho/monozukuri/commit/2b26d3d3cb6bb4a198846434592e82f89af0f33e))
* **adapters:** use CLI session auth for codex and gemini (drop API key requirement) ([#103](https://github.com/Viniciuscarvalho/monozukuri/issues/103)) ([9f88467](https://github.com/Viniciuscarvalho/monozukuri/commit/9f884676d28609779255687e1d3077857dd90d7d))
* add agent-blocker channel (EXIT_AGENT_BLOCKED=21) ([93b4697](https://github.com/Viniciuscarvalho/monozukuri/commit/93b46974489d34bc920544ea3a1b6caf7f055dc3))
* add agent-blocker channel (EXIT_AGENT_BLOCKED=21) ([ed75473](https://github.com/Viniciuscarvalho/monozukuri/commit/ed754733d93eda21bc884a96cb6ff674fa573422))
* add Codex, Gemini, Kiro adapters + pricing.yaml (Phases 4-6) ([f2ac1f6](https://github.com/Viniciuscarvalho/monozukuri/commit/f2ac1f606ddd4b0bf604dd9f0dcb360b43b40dd4))
* add doctor command improvements, exit-codes, and errors.sh ([e5ea5e9](https://github.com/Viniciuscarvalho/monozukuri/commit/e5ea5e937673476fed0576b728874f4cf9e208e7))
* add monozukuri agent subcommands + wizard init (Phase 7) ([877bf0b](https://github.com/Viniciuscarvalho/monozukuri/commit/877bf0b4ba768d2944cd12c1674805ec8491792c))
* add monozukuri doctor command ([e7cd75e](https://github.com/Viniciuscarvalho/monozukuri/commit/e7cd75e0fd903c313171ea255f8d4a28072f9067))
* add phase prompt templates and render.sh for multi-agent support ([cc163dd](https://github.com/Viniciuscarvalho/monozukuri/commit/cc163ddef66fb66cb761d0cf1a40e7471ef4f828))
* add promotional site + GitHub Pages deployment ([#207](https://github.com/Viniciuscarvalho/monozukuri/issues/207)) ([a5cf1dd](https://github.com/Viniciuscarvalho/monozukuri/commit/a5cf1ddb151c6311814499aace67cb17f3276d71))
* agent conformance suite + mock fixtures (Phase 3) ([008a996](https://github.com/Viniciuscarvalho/monozukuri/commit/008a996231b80f1a4747493659b06c6ba5864077))
* **agent:** add portable skill injection ([#218](https://github.com/Viniciuscarvalho/monozukuri/issues/218)) ([a1f4a77](https://github.com/Viniciuscarvalho/monozukuri/commit/a1f4a77032f747e7e356548f137540660db9f289))
* **agent:** ADR-017 multi-turn session for claude-code adapter ([#208](https://github.com/Viniciuscarvalho/monozukuri/issues/208)) ([7d6f981](https://github.com/Viniciuscarvalho/monozukuri/commit/7d6f9818965d651405278dd80e11982fc75929ed))
* **agent:** discover project + global skills, route phase_to_skill via manifest ([#167](https://github.com/Viniciuscarvalho/monozukuri/issues/167)) ([aa03ee8](https://github.com/Viniciuscarvalho/monozukuri/commit/aa03ee8a9e5d59ed0334f5b265b36896d3fa26d1))
* **agent:** record allowed-tools in manifest and log at invocation ([#172](https://github.com/Viniciuscarvalho/monozukuri/issues/172)) ([115f25c](https://github.com/Viniciuscarvalho/monozukuri/commit/115f25cfc9ba9bd3258803c40077907c89d13773))
* **agent:** scan GEMINI.md as a project-conventions source ([#165](https://github.com/Viniciuscarvalho/monozukuri/issues/165)) ([ecb5633](https://github.com/Viniciuscarvalho/monozukuri/commit/ecb5633fdf6a828cc1571039ed4023af6581ae5a))
* **agent:** walk nested AGENTS.md in subpackages (depth ≤ 3) ([#166](https://github.com/Viniciuscarvalho/monozukuri/issues/166)) ([46f87ac](https://github.com/Viniciuscarvalho/monozukuri/commit/46f87acef552c6713d574b71e0dd89396f9e397f))
* bundle to-prd and grill-me skills (pre-flight workflow) ([045c467](https://github.com/Viniciuscarvalho/monozukuri/commit/045c4673df2e2bee17082dd2fb9bf9a20db4f33e))
* bundle to-prd and grill-me skills from mattpocock/skills ([a113324](https://github.com/Viniciuscarvalho/monozukuri/commit/a113324fb24eaf9e3c9d1cc84dc7b8d8dd1c6fd3))
* **ci-guard:** add CI watcher skill and scripts ([#125](https://github.com/Viniciuscarvalho/monozukuri/issues/125)) ([20425e4](https://github.com/Viniciuscarvalho/monozukuri/commit/20425e4be38c7ef4bdda75090f73d2340b53a557))
* **ci:** RC release channel — [@next](https://github.com/next) npm + monozukuri-next brew + promotion scripts ([#195](https://github.com/Viniciuscarvalho/monozukuri/issues/195)) ([b361919](https://github.com/Viniciuscarvalho/monozukuri/commit/b36191972bf6f25ee936628f91e3bc5956701395))
* **cli:** add json backlog pick command ([#236](https://github.com/Viniciuscarvalho/monozukuri/issues/236)) ([4fc67ea](https://github.com/Viniciuscarvalho/monozukuri/commit/4fc67ea8155c1dea2b1df5c2327a462c943cb892))
* **cli:** add loop budget caps ([#253](https://github.com/Viniciuscarvalho/monozukuri/issues/253)) ([5dbf41d](https://github.com/Viniciuscarvalho/monozukuri/commit/5dbf41d0a9b44c9b063059d3b3e7d36748f83808))
* **cli:** add loop circuit breaker ([#257](https://github.com/Viniciuscarvalho/monozukuri/issues/257)) ([3dbb10e](https://github.com/Viniciuscarvalho/monozukuri/commit/3dbb10ee2dbf1a24279c3d72dac458c62f2f097c))
* **cli:** add loop failure modes ([#255](https://github.com/Viniciuscarvalho/monozukuri/issues/255)) ([4cd1770](https://github.com/Viniciuscarvalho/monozukuri/commit/4cd1770b13cc94c723260ab07a42ac7290cb21a8))
* **cli:** add ranked backlog list command ([#227](https://github.com/Viniciuscarvalho/monozukuri/issues/227)) ([d57ef92](https://github.com/Viniciuscarvalho/monozukuri/commit/d57ef921f34c8aaf0dbe4895fbcd569a3fccc299))
* **cli:** add selected backlog loop command ([#251](https://github.com/Viniciuscarvalho/monozukuri/issues/251)) ([ad6d3da](https://github.com/Viniciuscarvalho/monozukuri/commit/ad6d3dac7968ed087aa56f2661f5c9a05bd84705))
* **cli:** filter backlog list output ([#229](https://github.com/Viniciuscarvalho/monozukuri/issues/229)) ([02a4f8b](https://github.com/Viniciuscarvalho/monozukuri/commit/02a4f8b8779113878807cff447c74f5c98637d0b))
* **cli:** persist loop checkpoints ([#259](https://github.com/Viniciuscarvalho/monozukuri/issues/259)) ([6b843a1](https://github.com/Viniciuscarvalho/monozukuri/commit/6b843a1bb6d7c2a067de1a9680a2967fc3da916b))
* **cli:** score backlog priority ranking ([#234](https://github.com/Viniciuscarvalho/monozukuri/issues/234)) ([3d0bd66](https://github.com/Viniciuscarvalho/monozukuri/commit/3d0bd66c00544225d113442229481f28925854dc))
* **cli:** surface skills manifest in doctor + status ([#171](https://github.com/Viniciuscarvalho/monozukuri/issues/171)) ([0cf8de2](https://github.com/Viniciuscarvalho/monozukuri/commit/0cf8de289fddb02e9918af4d5ec6834d2bebf698))
* **cli:** TUI Day 1 — emit phase.token_update + phase.completed from stream-parse ([#176](https://github.com/Viniciuscarvalho/monozukuri/issues/176)) ([c399003](https://github.com/Viniciuscarvalho/monozukuri/commit/c3990034bb01be9f4e36f414c9ff3d126b2ac0b3))
* **cli:** validate backlog selection dependencies ([#232](https://github.com/Viniciuscarvalho/monozukuri/issues/232)) ([587a6b8](https://github.com/Viniciuscarvalho/monozukuri/commit/587a6b81c017f83dac6afe5c35f1249cf94012a6))
* configurable schema reprompt budget + human escalation ([682f63f](https://github.com/Viniciuscarvalho/monozukuri/commit/682f63fb4ef31c79c83678741eaef8f5cf76c6ca))
* configurable schema reprompt budget + human escalation path ([6d974f5](https://github.com/Viniciuscarvalho/monozukuri/commit/6d974f5d3e2a228d0419cea7a80e21f3c01da92f))
* **contract:** close full_auto blocker contract gaps ([#95](https://github.com/Viniciuscarvalho/monozukuri/issues/95)) ([d9f158d](https://github.com/Viniciuscarvalho/monozukuri/commit/d9f158d0aa5dfff778caecf8b0d5a0295af4d82d))
* **contract:** gap 3 — adapter contract v1.0.0, claude-code improvements, aider adapter (ADR-012) ([cdfee8e](https://github.com/Viniciuscarvalho/monozukuri/commit/cdfee8ea67cd894caead3f164401542c0d822aa4))
* **contract:** gap 3 — adapter contract v1.0.0, claude-code improvements, aider adapter (ADR-012) ([0edde5d](https://github.com/Viniciuscarvalho/monozukuri/commit/0edde5d59905161f8b7ae75e7805ac9fb0e8346d))
* **conventions:** auto-sync AGENTS.md after each run (PR4) ([793a678](https://github.com/Viniciuscarvalho/monozukuri/commit/793a6787943ad6a58da78737ec13c290724e6e45))
* **conventions:** generate AGENTS.md from learning store (PR3) ([801ec1e](https://github.com/Viniciuscarvalho/monozukuri/commit/801ec1e893770dcf028ae4517a02c1910f84b279))
* **conventions:** read and inject project convention files ([0da6119](https://github.com/Viniciuscarvalho/monozukuri/commit/0da611918f5f6a83689a9110d7c70de975ec5587))
* **conventions:** read and inject project convention files (PR1) ([a02f7c8](https://github.com/Viniciuscarvalho/monozukuri/commit/a02f7c88e6fbd4c1925a048616aec21e83dd3897))
* **conventions:** seed AGENTS.md and add it to Claude Code adapter native context ([b987513](https://github.com/Viniciuscarvalho/monozukuri/commit/b9875133641939cbe606ad1b8f562ceb6ba7ed6c))
* **conventions:** seed AGENTS.md and align Claude Code adapter with multi-agent convention surface ([d1e8f7a](https://github.com/Viniciuscarvalho/monozukuri/commit/d1e8f7a64630c6c2f3a1d6d74a7105f1c1a5e032))
* **conventions:** suppress duplicate context per adapter (PR2) ([2437140](https://github.com/Viniciuscarvalho/monozukuri/commit/2437140f934295ae8135b5391f020b4ab3863507))
* **conventions:** surface promotion candidates as convention entries (PR5) ([7782e3a](https://github.com/Viniciuscarvalho/monozukuri/commit/7782e3abd47528d53b52472f578499d89b0c7e31))
* **conventions:** surface promotion candidates as convention entries (PR5) ([629488f](https://github.com/Viniciuscarvalho/monozukuri/commit/629488fd240414948a65141705ba3fd555aff40e))
* enable Ink terminal UI via Node dispatcher in Homebrew ([3a9e226](https://github.com/Viniciuscarvalho/monozukuri/commit/3a9e226006585d425701b1253141df58f881adf6))
* enable Ink terminal UI via Node dispatcher in Homebrew ([8c12967](https://github.com/Viniciuscarvalho/monozukuri/commit/8c12967d1158674256e426b53752bf46d14c95d2))
* **failure:** gap 2 — stratified failure handling, idempotent resumption, CI poll (ADR-013/014) ([92a4ceb](https://github.com/Viniciuscarvalho/monozukuri/commit/92a4ceb155d17bb3f175e98c28bd1d8187a08250))
* **failure:** gap 2 — stratified failure handling, idempotent resumption, CI poll (ADR-013/014) ([e63d1eb](https://github.com/Viniciuscarvalho/monozukuri/commit/e63d1eba70459021c4a57a8374ce55a1783ae21d))
* Gap 5 - L5 Measurability Infrastructure ([a86f766](https://github.com/Viniciuscarvalho/monozukuri/commit/a86f76677d429c85b4e5a7250733ae4dd039ebf9))
* **gap3:** phase-aware templates, context-pack, registry, render node path ([d1396a9](https://github.com/Viniciuscarvalho/monozukuri/commit/d1396a941fb65babe0ee741e9492ec1773e078bb))
* **gap4:** per-phase routing config, routing_load, and threshold-gated routing suggest (ADR-015) ([30cec4f](https://github.com/Viniciuscarvalho/monozukuri/commit/30cec4f26e8b9341cfddfdbc6bc85e691126e96d))
* **gap4:** per-phase routing config, routing_load, and threshold-gated suggest (ADR-015) ([1272e08](https://github.com/Viniciuscarvalho/monozukuri/commit/1272e08128e4bc4dea41633bca256b3f36da0a20))
* **gap6:** run review — export, open, list subcommands (ADR-015) ([7b6e03c](https://github.com/Viniciuscarvalho/monozukuri/commit/7b6e03ca322f4ede636fcbac96f460caef175b17))
* **gap6:** run review — export, open, list subcommands (ADR-015) ([8af8917](https://github.com/Viniciuscarvalho/monozukuri/commit/8af8917b5fb201e1230d43cf9a9de8acac132e4b))
* **gap7:** implicit-dep detection + ingestion validator (ADR-015) ([5852a39](https://github.com/Viniciuscarvalho/monozukuri/commit/5852a392597df28ce150a65ee49ffd4ef3eb6d94))
* **gap7:** implicit-dep detection + ingestion validator (ADR-015) ([1a92ac9](https://github.com/Viniciuscarvalho/monozukuri/commit/1a92ac927d7b983979ca719c423321cd4c2cfa60))
* **gap8:** deferred status in FeatureList — yellow icon and label in completed list ([b25aaf1](https://github.com/Viniciuscarvalho/monozukuri/commit/b25aaf1676a8e8223fe4604bf10ae6d4ee0f181b))
* **gap8:** pricing and calibration — L5 cost honesty ([e930e07](https://github.com/Viniciuscarvalho/monozukuri/commit/e930e0763141eca52d999ab834c746a00a6144c9))
* **gap8:** pricing and calibration — L5 cost honesty (ADR-008) ([f066ffe](https://github.com/Viniciuscarvalho/monozukuri/commit/f066ffef006f07f16fa68eb05c7cb642ac850d1c))
* implement Gap 5 - L5 measurability infrastructure ([996c0e9](https://github.com/Viniciuscarvalho/monozukuri/commit/996c0e976dc3e986720cb305985ff679a755eea7))
* initial release — Monozukuri v1.0.0 ([d181a07](https://github.com/Viniciuscarvalho/monozukuri/commit/d181a07647388aa07f4042bd0d4ea7f032a8e234))
* Ink TUI, repo tooling, CI workflows, Bats harness, JSONL events ([1aa5caf](https://github.com/Viniciuscarvalho/monozukuri/commit/1aa5cafde4a7c452e2c53505726ca9fa1ffbc6a7))
* introduce multi-agent adapter contract (Phase 2) ([b143abd](https://github.com/Viniciuscarvalho/monozukuri/commit/b143abd84862c6fbb34ffedef3293c25b14fc162))
* M2 UX polish + M5 launch prep ([3a35c4f](https://github.com/Viniciuscarvalho/monozukuri/commit/3a35c4f6ad2ccb8483e96a6a577bb67ae63e0dfe))
* **memory:** workflow memory harness + README skills documentation (PR5) ([088a305](https://github.com/Viniciuscarvalho/monozukuri/commit/088a30590541702259e79ef2bfeda95587766c1d))
* **memory:** workflow memory harness + README skills documentation (PR5) ([7ced242](https://github.com/Viniciuscarvalho/monozukuri/commit/7ced242e2fa6205106e7597fc65ca527f938fd42))
* **orchestrator:** fix skill selection and add AGENTS.md discovery ([#90](https://github.com/Viniciuscarvalho/monozukuri/issues/90)) ([f3dd99e](https://github.com/Viniciuscarvalho/monozukuri/commit/f3dd99e42459b2b6493525d066a27b905c4b599c))
* **phase-a:** loop safety for unattended runs on codex/gemini ([#105](https://github.com/Viniciuscarvalho/monozukuri/issues/105)) ([2d27ddd](https://github.com/Viniciuscarvalho/monozukuri/commit/2d27ddd4b97a2838f5dcc740c4da7a8ebfa60251))
* **phase-b:** seed per-adapter context files on monozukuri init ([#106](https://github.com/Viniciuscarvalho/monozukuri/issues/106)) ([b92a614](https://github.com/Viniciuscarvalho/monozukuri/commit/b92a614e61c3cd6f7284c330816f93c7b7291c9a))
* **phase-c:** multi-project ops — budget ceiling, kill switch, summary, concurrency ([#109](https://github.com/Viniciuscarvalho/monozukuri/issues/109)) ([d164a8e](https://github.com/Viniciuscarvalho/monozukuri/commit/d164a8eb6c7bc99ff296c383e21a2c4d673c2df1))
* **phase-d:** release-gate truthfulness + CI enforcement ([#111](https://github.com/Viniciuscarvalho/monozukuri/issues/111)) ([e834c1c](https://github.com/Viniciuscarvalho/monozukuri/commit/e834c1c6088d9ba2b8c12b491a72a32cd0b876fc))
* **phase-e:** state-version stamping + opt-in telemetry ([#113](https://github.com/Viniciuscarvalho/monozukuri/issues/113)) ([975fdac](https://github.com/Viniciuscarvalho/monozukuri/commit/975fdacf97fde6837af4000015f96e6e72a78126))
* **phase-f:** schema render parity for codex/gemini ([#115](https://github.com/Viniciuscarvalho/monozukuri/issues/115)) ([14a1e77](https://github.com/Viniciuscarvalho/monozukuri/commit/14a1e770760bb3dbd6b1e5589ac88dfdd6e32bf7))
* **phase-g:** plan-doc reconciliation — env-var cleanup, CLAUDE.md, archive Path B ([#118](https://github.com/Viniciuscarvalho/monozukuri/issues/118)) ([f413fba](https://github.com/Viniciuscarvalho/monozukuri/commit/f413fba5049548d1337574d449da50274ebc641a))
* **phase3,adapters:** generalize Ralph Loop to all adapters via agent_run_phase ([#101](https://github.com/Viniciuscarvalho/monozukuri/issues/101)) ([462fd06](https://github.com/Viniciuscarvalho/monozukuri/commit/462fd0647e7c6e98a37120124a0078273b92be9e))
* **pipeline:** phase-split mz-* skills, schema compat, setup fix ([#124](https://github.com/Viniciuscarvalho/monozukuri/issues/124)) ([76be5b7](https://github.com/Viniciuscarvalho/monozukuri/commit/76be5b7d250a59e9a0418c1b736e6c2cd695ffc9))
* **qa:** Layer 4 backwards compat + fix cmd/resume.sh module loading ([#80](https://github.com/Viniciuscarvalho/monozukuri/issues/80)) ([07b0bc9](https://github.com/Viniciuscarvalho/monozukuri/commit/07b0bc9e4ca243e723d88091f2cb9e3d53e8fb68))
* **qa:** release gate harness — layers 1, 2 & 3 (PR 0→2) ([#78](https://github.com/Viniciuscarvalho/monozukuri/issues/78)) ([baac069](https://github.com/Viniciuscarvalho/monozukuri/commit/baac06929919eb7de747d1df8cc2a57009b30c2d))
* **qa:** replay-based mock infra + property tests + Layer 7 conformance (no CI cost) ([#161](https://github.com/Viniciuscarvalho/monozukuri/issues/161)) ([8edde0a](https://github.com/Viniciuscarvalho/monozukuri/commit/8edde0aa8df97a32f92bc65c274066f337733e7d))
* **release:** prepare v2 alpha ([#284](https://github.com/Viniciuscarvalho/monozukuri/issues/284)) ([2d487db](https://github.com/Viniciuscarvalho/monozukuri/commit/2d487db778da0754fe73e62cffd92565886d14b1))
* **resilience:** auto-mode schema resilience — paused recovery, retry command, UI visibility ([#132](https://github.com/Viniciuscarvalho/monozukuri/issues/132)) ([824b1bf](https://github.com/Viniciuscarvalho/monozukuri/commit/824b1bf0d800aed346e5757938a30d23aeafd258))
* **run:** auto-invoke skill-discovery on session start ([#170](https://github.com/Viniciuscarvalho/monozukuri/issues/170)) ([0c57136](https://github.com/Viniciuscarvalho/monozukuri/commit/0c5713622106a9e23faac6023b836251f3c76857))
* **schema:** gap 1 — phase artifact schemas and validation (ADR-012) ([6103b82](https://github.com/Viniciuscarvalho/monozukuri/commit/6103b826a7150338c6985bbeac169beb5130fb7b))
* **schema:** Gap 1 — phase artifact schemas and validation (ADR-012) ([1e1ae12](https://github.com/Viniciuscarvalho/monozukuri/commit/1e1ae12003a623dc4a07f34c47d36efd74ac03ae))
* **setup:** add monozukuri setup installer command (PR3) ([62f83b3](https://github.com/Viniciuscarvalho/monozukuri/commit/62f83b3f374960f79a949b1aba3a86ed00074e68))
* **setup:** add monozukuri setup installer command (PR3) ([9fde8bc](https://github.com/Viniciuscarvalho/monozukuri/commit/9fde8bc3f7bd04eaee0067015120efc653de3286))
* **skills:** publishable mz-* skill versioning and packaging ([#94](https://github.com/Viniciuscarvalho/monozukuri/issues/94)) ([c8090da](https://github.com/Viniciuscarvalho/monozukuri/commit/c8090da622b7e11eeed8bdf47c1c19906425e3d2))
* **skills:** scaffold 8 mz-* phase skills (PR1 of skills plan) ([200cc90](https://github.com/Viniciuscarvalho/monozukuri/commit/200cc90a3ee2cf6afc2b0af3b77620946c55a6e3))
* **skills:** scaffold 8 mz-* phase skills (PR1 of skills plan) ([ebf01a9](https://github.com/Viniciuscarvalho/monozukuri/commit/ebf01a9276f4bb7dcdf62748f93fcba047642f78))
* surface agent identity in TUI + stand up Jest test infra (Phase 8) ([95ec400](https://github.com/Viniciuscarvalho/monozukuri/commit/95ec40024841084a81b7dea12ca4f2ea8c50af0c))
* **tui:** TUI by default, silence bash render layer ([#92](https://github.com/Viniciuscarvalho/monozukuri/issues/92)) ([e79a683](https://github.com/Viniciuscarvalho/monozukuri/commit/e79a683042d614111e98eee2b1fea8039e99067b))
* **tui:** visual polish pass — unified border, token enforcement, braille spinner ([#198](https://github.com/Viniciuscarvalho/monozukuri/issues/198)) ([5f43ae4](https://github.com/Viniciuscarvalho/monozukuri/commit/5f43ae45890966b19cce846285c182dba7675fac))
* **ui:** consolidate TUI Days 2-5 + composite screenshot into main ([#182](https://github.com/Viniciuscarvalho/monozukuri/issues/182)) ([e7a0c64](https://github.com/Viniciuscarvalho/monozukuri/commit/e7a0c64948345fff758e05946b0f6640ea480d13))
* **ui:** surface skills, workflow memory, and setup events in TUI (PR6) ([e75bc65](https://github.com/Viniciuscarvalho/monozukuri/commit/e75bc65fbf7010c8d012727b9e4ab1850b8385e1))
* **ui:** surface skills, workflow memory, and setup events in TUI (PR6) ([8116c7b](https://github.com/Viniciuscarvalho/monozukuri/commit/8116c7b98e37ef27df2f35c88e988e90908d0f78))
* **ux:** execution visibility — phase events, tool stream, web dashboard ([#120](https://github.com/Viniciuscarvalho/monozukuri/issues/120)) ([981c1d4](https://github.com/Viniciuscarvalho/monozukuri/commit/981c1d4967ee738af4a47743d5eaaa92ae57183d))
* **v1.0:** hardening — full_auto contract, crash recovery, skill versioning, CI gate, cosmetic fixes ([#159](https://github.com/Viniciuscarvalho/monozukuri/issues/159)) ([1635003](https://github.com/Viniciuscarvalho/monozukuri/commit/163500306dcc08c55b1015f090b6c7b03e36a78b))
* **v1:** launch-prep gap fixes — doctor, skill overrides, design tokens, web log pane ([#152](https://github.com/Viniciuscarvalho/monozukuri/issues/152)) ([bbeef30](https://github.com/Viniciuscarvalho/monozukuri/commit/bbeef30004fa47e7dd5c4f20219185a6e76f2b07))
* **validator:** couple validate.sh to skills/*-validation.md aliases (PR2) ([d52a25a](https://github.com/Viniciuscarvalho/monozukuri/commit/d52a25a0909e9488fe9bb0f7e08219a3b943dbef))
* **validator:** couple validate.sh to skills/*-validation.md aliases (PR2) ([20a55ef](https://github.com/Viniciuscarvalho/monozukuri/commit/20a55efcc5f0324a4a390bf581439cb513db59a9))


### Bug Fixes

* **adapters:** event stream parity for Codex, Gemini, Kiro, Aider ([#122](https://github.com/Viniciuscarvalho/monozukuri/issues/122)) ([ca80cef](https://github.com/Viniciuscarvalho/monozukuri/commit/ca80cef0717db3c2293ac6b02d129b8c2fabb0c0))
* **agent:** close mz-open-pr full_auto hang and expose hidden CLI commands ([#205](https://github.com/Viniciuscarvalho/monozukuri/issues/205)) ([6857eed](https://github.com/Viniciuscarvalho/monozukuri/commit/6857eed27e1fb50d6977cbd077d630076cf5eee7))
* **agent:** run Codex through rendered phase prompts ([#221](https://github.com/Viniciuscarvalho/monozukuri/issues/221)) ([49f264d](https://github.com/Viniciuscarvalho/monozukuri/commit/49f264d6f6d2e0d6aa44a3b7df7b7583e426b176))
* bleed-stop bundle ([#84](https://github.com/Viniciuscarvalho/monozukuri/issues/84)) ([f2b90ff](https://github.com/Viniciuscarvalho/monozukuri/commit/f2b90ff415108a03767e578308c5e8362a290ffd))
* **ci:** extract PR number from release-please JSON output for auto-merge ([#72](https://github.com/Viniciuscarvalho/monozukuri/issues/72)) ([bf87666](https://github.com/Viniciuscarvalho/monozukuri/commit/bf87666ddb51517cc7d0f6c04470baa932c5ecc3))
* **ci:** pass --repo to gh pr merge to avoid missing git context ([#74](https://github.com/Viniciuscarvalho/monozukuri/issues/74)) ([6e3e325](https://github.com/Viniciuscarvalho/monozukuri/commit/6e3e3251717359442b7fb799c7dab3f3df33e3f8))
* **ci:** suppress monozukuri-vX prefix in release-please v5 tags ([8a7d11e](https://github.com/Viniciuscarvalho/monozukuri/commit/8a7d11e78715df6ea844998bc87e2b97bc853192))
* **ci:** suppress monozukuri-vX prefix in release-please v5 tags ([64fe15d](https://github.com/Viniciuscarvalho/monozukuri/commit/64fe15decd1e43018c36b230484b96753f47f92b))
* **ci:** use PAT for release-please to trigger Actions on release commits ([#141](https://github.com/Viniciuscarvalho/monozukuri/issues/141)) ([a561359](https://github.com/Viniciuscarvalho/monozukuri/commit/a5613596df4e26145157ddb3cc86503a92f3e565))
* create bump branch before writing formula in homebrew-tap workflow ([e7ee2e8](https://github.com/Viniciuscarvalho/monozukuri/commit/e7ee2e836e03159d6c8d652011183d899a5ad566))
* export MONOZUKURI_PHASE, clarify Phase 0 log label, capture schema mismatches ([#88](https://github.com/Viniciuscarvalho/monozukuri/issues/88)) ([daa83fa](https://github.com/Viniciuscarvalho/monozukuri/commit/daa83facafbb4ab6cc1c3359a269e706ff023318))
* fold error status into failed counter across all three reporters ([e6e5762](https://github.com/Viniciuscarvalho/monozukuri/commit/e6e57626e308e2079fef48ed51ca8f1729e46f62))
* fold error status into failed counter across all three reporters ([05093f4](https://github.com/Viniciuscarvalho/monozukuri/commit/05093f48ecbd84acb9beaea5db87056c471ad701))
* **homebrew:** remove missing ui/dist/package.json from install step ([#82](https://github.com/Viniciuscarvalho/monozukuri/issues/82)) ([8d06c6a](https://github.com/Viniciuscarvalho/monozukuri/commit/8d06c6ac32a448db5a0d996d2e9cb9f6e4e3e786))
* **memory:** workflow_memory_prepare crash — exports lost in subshell ([747c8e7](https://github.com/Viniciuscarvalho/monozukuri/commit/747c8e78403022b41c0d776d2cca2e8ef98de6c8))
* **memory:** workflow_memory_prepare must export to parent process ([23f629a](https://github.com/Viniciuscarvalho/monozukuri/commit/23f629a45db412ad0de2c8cf5f172e9dcffd05c6))
* mermaid diagram + homebrew formula v1.0.0 checksum ([52dba02](https://github.com/Viniciuscarvalho/monozukuri/commit/52dba0231b62e735ea173e8606c79747b7f9c997))
* **metrics:** fix 8 pre-existing test failures in metrics module ([fff0494](https://github.com/Viniciuscarvalho/monozukuri/commit/fff0494c86cd22e656d0c8cbb7d76797c170293a))
* **metrics:** remove comment drift from linter revert in metrics.sh ([4a1a628](https://github.com/Viniciuscarvalho/monozukuri/commit/4a1a628bac077a629b7bdb31abcafc110049e203))
* MONOZUKURI_PHASE export, Phase 0 log label, learning store schema capture ([#86](https://github.com/Viniciuscarvalho/monozukuri/issues/86)) ([9b07df5](https://github.com/Viniciuscarvalho/monozukuri/commit/9b07df58839f16888e6bc4ed522d9133273d51cc))
* **prompt:** add MONOZUKURI_WORKTREE, _AUTONOMY, _FEATURE_ID to context pack ([#189](https://github.com/Viniciuscarvalho/monozukuri/issues/189)) ([72d9398](https://github.com/Viniciuscarvalho/monozukuri/commit/72d93984b687f9170bb9adbf52edd17912c833c7))
* **prompt:** pre-render MONOZUKURI_* env vars into context before rich render ([#191](https://github.com/Viniciuscarvalho/monozukuri/issues/191)) ([a314a21](https://github.com/Viniciuscarvalho/monozukuri/commit/a314a213cefa30fbcff4891e9a3719c10a924b5b))
* **qa:** fix release gate layer 2 failures ([#146](https://github.com/Viniciuscarvalho/monozukuri/issues/146)) ([097504b](https://github.com/Viniciuscarvalho/monozukuri/commit/097504b0817319ff17dfdee3e7dac7b31dac6e18))
* **qa:** skip doctor check in CI — gh/claude absent on runners ([#148](https://github.com/Viniciuscarvalho/monozukuri/issues/148)) ([0e9fb20](https://github.com/Viniciuscarvalho/monozukuri/commit/0e9fb2020482dfbf6c97d5b52da9a6883be98b1c))
* **qa:** unblock Release gate — three pre-existing Layer 2 bugs ([#162](https://github.com/Viniciuscarvalho/monozukuri/issues/162)) ([e2f406e](https://github.com/Viniciuscarvalho/monozukuri/commit/e2f406e28ad66a3a48387e43c338c9a7832ea34b))
* resolve 8 runtime bugs in full-auto PR creation flow ([33ec376](https://github.com/Viniciuscarvalho/monozukuri/commit/33ec3764f69f888446618595996149ed1aec64d0))
* **resume,learning:** close determinism gaps ([#96](https://github.com/Viniciuscarvalho/monozukuri/issues/96)) ([5c38d56](https://github.com/Viniciuscarvalho/monozukuri/commit/5c38d56a221a87db709d1825b618ba935d66fb0e))
* **run:** cycle-gate skips feature instead of aborting run + TUI unified grid ([#193](https://github.com/Viniciuscarvalho/monozukuri/issues/193)) ([a86dcc4](https://github.com/Viniciuscarvalho/monozukuri/commit/a86dcc449eab15d99176b78ac9b35e2c3775cfc2))
* **run:** hard-block run when known-incompatible skill is configured ([#187](https://github.com/Viniciuscarvalho/monozukuri/issues/187)) ([7770915](https://github.com/Viniciuscarvalho/monozukuri/commit/7770915d6f235649cef64bea81681ff441a5b8c3))
* **setup:** stop TUI from eating keystrokes; accept bare positional verbs ([#129](https://github.com/Viniciuscarvalho/monozukuri/issues/129)) ([69999ba](https://github.com/Viniciuscarvalho/monozukuri/commit/69999bab363560d4a4bb0ea1361d7db6915a4915))
* **site:** set GitHub Pages base path and fix asset URLs ([#213](https://github.com/Viniciuscarvalho/monozukuri/issues/213)) ([2368810](https://github.com/Viniciuscarvalho/monozukuri/commit/23688106b8edb919dae434420f6b64c711f25101))
* stream-json --verbose and retry --all reason filter ([#144](https://github.com/Viniciuscarvalho/monozukuri/issues/144)) ([9f639f0](https://github.com/Viniciuscarvalho/monozukuri/commit/9f639f07b0dbb58c5eea80bed4292d2b3d29e3dc))
* symlink .claude/skills into worktrees and wire Ink TUI ([#139](https://github.com/Viniciuscarvalho/monozukuri/issues/139)) ([b7e05e6](https://github.com/Viniciuscarvalho/monozukuri/commit/b7e05e6d7bc2bb625a9e9f18a8531d9cb16f89e0))
* three bugs in orchestrator ↔ skill contract (diff gate, path alignment, doctor warning) ([#185](https://github.com/Viniciuscarvalho/monozukuri/issues/185)) ([e47371c](https://github.com/Viniciuscarvalho/monozukuri/commit/e47371cf68ade19069381293920bbafeeab1e180))
* **tui:** stop EIO crash on exit and mislabeled paused runs ([#150](https://github.com/Viniciuscarvalho/monozukuri/issues/150)) ([9856ecf](https://github.com/Viniciuscarvalho/monozukuri/commit/9856ecfa10de0ec569c9a8ac23fbb67963c380ee))
* **ui:** inject createRequire banner to fix CJS dynamic-require failure in ESM bundle ([#68](https://github.com/Viniciuscarvalho/monozukuri/issues/68)) ([59a5985](https://github.com/Viniciuscarvalho/monozukuri/commit/59a59856943207866c8221e41417e915e3a46d73))
* **ui:** open /dev/tty for Ink keyboard input; avoid raw mode error in non-TTY context ([7ca35f5](https://github.com/Viniciuscarvalho/monozukuri/commit/7ca35f5054542c1f10becd9b9e3004e45868ef93))
* **ui:** open /dev/tty for Ink keyboard input; avoid raw mode error in non-TTY context ([82ee32b](https://github.com/Viniciuscarvalho/monozukuri/commit/82ee32b855700edb878a8469b2cda147c4e89a7a))
* **ui:** stub react-devtools-core to eliminate missing-package error at runtime ([#66](https://github.com/Viniciuscarvalho/monozukuri/issues/66)) ([f312c48](https://github.com/Viniciuscarvalho/monozukuri/commit/f312c48aca50a837116301f472b54980f24af534))
* **ui:** three-PR sequence — build, polish, signals ([#70](https://github.com/Viniciuscarvalho/monozukuri/issues/70)) ([13fcbb2](https://github.com/Viniciuscarvalho/monozukuri/commit/13fcbb24ee18dd45673efc5d5fb7c32bfdf5db8e))
* use injected github client in github-script, drop manual Octokit ([824c82e](https://github.com/Viniciuscarvalho/monozukuri/commit/824c82ea179c88cd5cafec6909b739417cd65cb4))
* v1.0 pre-launch — canary jq fix, draft PR UX, docs ([#210](https://github.com/Viniciuscarvalho/monozukuri/issues/210)) ([5983e33](https://github.com/Viniciuscarvalho/monozukuri/commit/5983e337c824c3f18034305d2f3d4f952546acb6))


### Refactoring

* **arch:** deepen modules C2-C8 + fix pricing budget ceiling ([#134](https://github.com/Viniciuscarvalho/monozukuri/issues/134)) ([821453e](https://github.com/Viniciuscarvalho/monozukuri/commit/821453e8ff39f696a3687eb0da5a4a0fb8d761a4))
* consolidate scripts/lib/ into lib/ canonical tree ([165a9f2](https://github.com/Viniciuscarvalho/monozukuri/commit/165a9f2fd6b1ff9634368625e0d0b41950b633d6))
* **conventions:** consolidate file-IO seam and add learning entry contract ([835a651](https://github.com/Viniciuscarvalho/monozukuri/commit/835a651b3f313b6c54c7ae0992d0e4465a444cca))
* **conventions:** consolidate file-IO seam and add learning entry contract ([9fe0af4](https://github.com/Viniciuscarvalho/monozukuri/commit/9fe0af4da43f46794de9d03d8cd1dfd7767a07ef))
* deepen architecture ([453e7f9](https://github.com/Viniciuscarvalho/monozukuri/commit/453e7f9c2aa9f63761f16c1acf3b0903db9cac70))
* deepen architecture — 5 seams extracted from pipeline.sh ([19c7ca0](https://github.com/Viniciuscarvalho/monozukuri/commit/19c7ca042f2309acb5758e0028635bef4fc78653))
* M1.1 directory restructure — cmd/ + lib/ split ([97da855](https://github.com/Viniciuscarvalho/monozukuri/commit/97da8559c8e7d5a654051579778948fda1945e07))
* **render:** replace node-based renderer with jq/awk/bash implementation ([dee9786](https://github.com/Viniciuscarvalho/monozukuri/commit/dee9786347554bd78b8c92ed7bd5a3203bf101e0))


### Documentation

* add ADR template ([bb47263](https://github.com/Viniciuscarvalho/monozukuri/commit/bb472632d61257ee96eb59b6799843da5c71a473))
* add user-facing reference docs and simplify README ([#197](https://github.com/Viniciuscarvalho/monozukuri/issues/197)) ([435c231](https://github.com/Viniciuscarvalho/monozukuri/commit/435c2314893369f2407ccd0c8d6b906819000229))
* add vision, capability ladder, and roadmap ([42d85e5](https://github.com/Viniciuscarvalho/monozukuri/commit/42d85e554a5d253865be472ad6a8753bbb9d3918))
* **adr:** 012 — adapter contract & phase artifact schemas ([d40fce6](https://github.com/Viniciuscarvalho/monozukuri/commit/d40fce66990d61fe5aa48f1df11a3d82530358d3))
* **adr:** 013 — failure handling, idempotent resumption, rate-limit policy ([a35763b](https://github.com/Viniciuscarvalho/monozukuri/commit/a35763bc9a1601ad52a3be0511c88e7d5ccb188d))
* **adr:** 014 — terminal state (CI-green PR) & L5 metric ([b919274](https://github.com/Viniciuscarvalho/monozukuri/commit/b919274c54273db964234959895d018c840051c6))
* **adr:** 015 — routing, implicit deps, and review surface ([66dad9a](https://github.com/Viniciuscarvalho/monozukuri/commit/66dad9a309aff70d3767f32ba4f9ceb49dd04441))
* **adr:** 016 — 13-week plan & capability ladder commitments ([3ddbe6d](https://github.com/Viniciuscarvalho/monozukuri/commit/3ddbe6df6253c66de7727a03ca462a80e1c98664))
* **agent:** add project workflow skills ([#275](https://github.com/Viniciuscarvalho/monozukuri/issues/275)) ([b209c65](https://github.com/Viniciuscarvalho/monozukuri/commit/b209c65a6930b4ced681de6fe0343f6d76cf6952))
* **assets:** add hero GIF and dashboard screenshot to README ([#203](https://github.com/Viniciuscarvalho/monozukuri/issues/203)) ([776ba4b](https://github.com/Viniciuscarvalho/monozukuri/commit/776ba4b1a4254d9e2d8ff8d2592248d86e6f3b51))
* document retry, resume-paused, stop, and 7 other undocumented subcommands ([#136](https://github.com/Viniciuscarvalho/monozukuri/issues/136)) ([197a3c5](https://github.com/Viniciuscarvalho/monozukuri/commit/197a3c59e1f589f745940c00e2c92e44b525073a))
* **execution:** clarify supervised mode ([#282](https://github.com/Viniciuscarvalho/monozukuri/issues/282)) ([8bbb7ea](https://github.com/Viniciuscarvalho/monozukuri/commit/8bbb7eabd308bacbac9a3c7561de1b5fad3f56da))
* expand README with highlights, models, project layout, dev, and contributing sections ([789b943](https://github.com/Viniciuscarvalho/monozukuri/commit/789b9438da9dd9362c07d601f174fbd88c2b96a7))
* land grilled vision decisions (vision, ladder, ADRs 012-016) ([9ab089e](https://github.com/Viniciuscarvalho/monozukuri/commit/9ab089ed32476f9c55e693aa06e08908201ee35c))
* **planning:** v2.0 gap-closure PRD + ADRs 018-023 ([#216](https://github.com/Viniciuscarvalho/monozukuri/issues/216)) ([d839452](https://github.com/Viniciuscarvalho/monozukuri/commit/d839452e99f7159ae0956aaa817296f2c2f8e34a))
* rewrite README and CHANGELOG for multi-agent v1.2.0 ([a72f6e9](https://github.com/Viniciuscarvalho/monozukuri/commit/a72f6e93d91388913bd6287aaf4bc04e12dc01e6))
* rewrite README and CHANGELOG for multi-agent v1.2.0 (Phase 9) ([1b88919](https://github.com/Viniciuscarvalho/monozukuri/commit/1b8891966874c637343f8a0dd114c1a27cd3e50d))
* unify on AGENTS.md (symlink CLAUDE/GEMINI) + verified content ([#163](https://github.com/Viniciuscarvalho/monozukuri/issues/163)) ([7cdb12a](https://github.com/Viniciuscarvalho/monozukuri/commit/7cdb12a97d407efde8502e6e4b468c332b65a0e2))
* use agent-agnostic language across README and docs ([#201](https://github.com/Viniciuscarvalho/monozukuri/issues/201)) ([03e3f98](https://github.com/Viniciuscarvalho/monozukuri/commit/03e3f98c6a35eaca01347baf592648e271599798))

## [2.0.0-alpha.1] - 2026-05-26

### Highlights

- Added the v2 selection flow: `monozukuri backlog list`, deterministic
  priority scoring, filtering by label/status/agent, `pick --top`, `pick
  --json`, TUI selection, selection history, and replay.
- Added the v2 loop foundation: sequential `monozukuri loop`, stdin
  composition, worktree isolation, cost/time/token caps, failure modes, circuit
  breaker, checkpoint schema, resume, progress status, and final summary
  reports.
- Added Memory v2: provenance schema, `memory lint`, `memory migrate`, prompt
  injection tracking, `memory why`, deterministic compaction, summary cache,
  `<request-memory id="..."/>` escalation, `memory trace`, and
  agent-specific learning filters.
- Added v2 verification and release preparation: MRP token-saving matrix, loop
  conformance suite, live canary harness documentation, migration guide, README
  rewrite, and v2 alpha readiness checklist.

### Breaking changes

- None expected for existing v1 project configuration. v2 adds state under
  `.monozukuri/state/` and Memory v2 stores under `.monozukuri/memory-v2.json`.

### New commands

- `monozukuri backlog list`
- `monozukuri backlog validate <ids...>`
- `monozukuri pick`
- `monozukuri pick --top N`
- `monozukuri pick --json`
- `monozukuri pick --history`
- `monozukuri pick --replay [N]`
- `monozukuri loop <ids...>`
- `monozukuri loop --resume [run-id]`
- `monozukuri loop --list-runs`
- `monozukuri loop status [run-id]`
- `monozukuri memory lint`
- `monozukuri memory migrate`
- `monozukuri memory why [lrn-id]`
- `monozukuri memory trace <run-id>`
- `monozukuri memory compact`

### Migration

- See [docs/v2-migration.md](docs/v2-migration.md) for the v1 to v2 upgrade
  path, Memory v2 migration steps, schema reading guide, and troubleshooting
  checklist.

## [1.62.2](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.62.1...v1.62.2) (2026-05-26)


### Documentation

* **execution:** clarify supervised mode ([#282](https://github.com/Viniciuscarvalho/monozukuri/issues/282)) ([8bbb7ea](https://github.com/Viniciuscarvalho/monozukuri/commit/8bbb7eabd308bacbac9a3c7561de1b5fad3f56da))

## [1.62.1](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.62.0...v1.62.1) (2026-05-26)


### Documentation

* **agent:** add project workflow skills ([#275](https://github.com/Viniciuscarvalho/monozukuri/issues/275)) ([b209c65](https://github.com/Viniciuscarvalho/monozukuri/commit/b209c65a6930b4ced681de6fe0343f6d76cf6952))

## [1.62.0](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.61.0...v1.62.0) (2026-05-22)


### Features

* **cli:** persist loop checkpoints ([#259](https://github.com/Viniciuscarvalho/monozukuri/issues/259)) ([6b843a1](https://github.com/Viniciuscarvalho/monozukuri/commit/6b843a1bb6d7c2a067de1a9680a2967fc3da916b))

## [1.61.0](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.60.0...v1.61.0) (2026-05-22)


### Features

* **cli:** add loop circuit breaker ([#257](https://github.com/Viniciuscarvalho/monozukuri/issues/257)) ([3dbb10e](https://github.com/Viniciuscarvalho/monozukuri/commit/3dbb10ee2dbf1a24279c3d72dac458c62f2f097c))

## [1.60.0](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.59.0...v1.60.0) (2026-05-22)


### Features

* **cli:** add loop failure modes ([#255](https://github.com/Viniciuscarvalho/monozukuri/issues/255)) ([4cd1770](https://github.com/Viniciuscarvalho/monozukuri/commit/4cd1770b13cc94c723260ab07a42ac7290cb21a8))

## [1.59.0](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.58.0...v1.59.0) (2026-05-22)


### Features

* **cli:** add loop budget caps ([#253](https://github.com/Viniciuscarvalho/monozukuri/issues/253)) ([5dbf41d](https://github.com/Viniciuscarvalho/monozukuri/commit/5dbf41d0a9b44c9b063059d3b3e7d36748f83808))

## [1.58.0](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.57.0...v1.58.0) (2026-05-22)


### Features

* **cli:** add selected backlog loop command ([#251](https://github.com/Viniciuscarvalho/monozukuri/issues/251)) ([ad6d3da](https://github.com/Viniciuscarvalho/monozukuri/commit/ad6d3dac7968ed087aa56f2661f5c9a05bd84705))

## [1.57.0](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.56.0...v1.57.0) (2026-05-19)


### Features

* **cli:** add json backlog pick command ([#236](https://github.com/Viniciuscarvalho/monozukuri/issues/236)) ([4fc67ea](https://github.com/Viniciuscarvalho/monozukuri/commit/4fc67ea8155c1dea2b1df5c2327a462c943cb892))

## [1.56.0](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.55.0...v1.56.0) (2026-05-19)


### Features

* **cli:** score backlog priority ranking ([#234](https://github.com/Viniciuscarvalho/monozukuri/issues/234)) ([3d0bd66](https://github.com/Viniciuscarvalho/monozukuri/commit/3d0bd66c00544225d113442229481f28925854dc))

## [1.55.0](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.54.0...v1.55.0) (2026-05-18)


### Features

* **cli:** validate backlog selection dependencies ([#232](https://github.com/Viniciuscarvalho/monozukuri/issues/232)) ([587a6b8](https://github.com/Viniciuscarvalho/monozukuri/commit/587a6b81c017f83dac6afe5c35f1249cf94012a6))

## [1.54.0](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.53.0...v1.54.0) (2026-05-17)


### Features

* **cli:** filter backlog list output ([#229](https://github.com/Viniciuscarvalho/monozukuri/issues/229)) ([02a4f8b](https://github.com/Viniciuscarvalho/monozukuri/commit/02a4f8b8779113878807cff447c74f5c98637d0b))

## [1.53.0](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.52.0...v1.53.0) (2026-05-17)


### Features

* **adapter:** add skill-native invocation path to adapter-claude-code (PR4) ([8ff8c15](https://github.com/Viniciuscarvalho/monozukuri/commit/8ff8c15513bcd3a580dbbd2b9a442338a7dffda7))
* **adapter:** skill-native invocation path + release-please v5 (PR4) ([2b26d3d](https://github.com/Viniciuscarvalho/monozukuri/commit/2b26d3d3cb6bb4a198846434592e82f89af0f33e))
* **adapters:** use CLI session auth for codex and gemini (drop API key requirement) ([#103](https://github.com/Viniciuscarvalho/monozukuri/issues/103)) ([9f88467](https://github.com/Viniciuscarvalho/monozukuri/commit/9f884676d28609779255687e1d3077857dd90d7d))
* add agent-blocker channel (EXIT_AGENT_BLOCKED=21) ([93b4697](https://github.com/Viniciuscarvalho/monozukuri/commit/93b46974489d34bc920544ea3a1b6caf7f055dc3))
* add agent-blocker channel (EXIT_AGENT_BLOCKED=21) ([ed75473](https://github.com/Viniciuscarvalho/monozukuri/commit/ed754733d93eda21bc884a96cb6ff674fa573422))
* add Codex, Gemini, Kiro adapters + pricing.yaml (Phases 4-6) ([f2ac1f6](https://github.com/Viniciuscarvalho/monozukuri/commit/f2ac1f606ddd4b0bf604dd9f0dcb360b43b40dd4))
* add doctor command improvements, exit-codes, and errors.sh ([e5ea5e9](https://github.com/Viniciuscarvalho/monozukuri/commit/e5ea5e937673476fed0576b728874f4cf9e208e7))
* add monozukuri agent subcommands + wizard init (Phase 7) ([877bf0b](https://github.com/Viniciuscarvalho/monozukuri/commit/877bf0b4ba768d2944cd12c1674805ec8491792c))
* add monozukuri doctor command ([e7cd75e](https://github.com/Viniciuscarvalho/monozukuri/commit/e7cd75e0fd903c313171ea255f8d4a28072f9067))
* add phase prompt templates and render.sh for multi-agent support ([cc163dd](https://github.com/Viniciuscarvalho/monozukuri/commit/cc163ddef66fb66cb761d0cf1a40e7471ef4f828))
* add promotional site + GitHub Pages deployment ([#207](https://github.com/Viniciuscarvalho/monozukuri/issues/207)) ([a5cf1dd](https://github.com/Viniciuscarvalho/monozukuri/commit/a5cf1ddb151c6311814499aace67cb17f3276d71))
* agent conformance suite + mock fixtures (Phase 3) ([008a996](https://github.com/Viniciuscarvalho/monozukuri/commit/008a996231b80f1a4747493659b06c6ba5864077))
* **agent:** add portable skill injection ([#218](https://github.com/Viniciuscarvalho/monozukuri/issues/218)) ([a1f4a77](https://github.com/Viniciuscarvalho/monozukuri/commit/a1f4a77032f747e7e356548f137540660db9f289))
* **agent:** ADR-017 multi-turn session for claude-code adapter ([#208](https://github.com/Viniciuscarvalho/monozukuri/issues/208)) ([7d6f981](https://github.com/Viniciuscarvalho/monozukuri/commit/7d6f9818965d651405278dd80e11982fc75929ed))
* **agent:** discover project + global skills, route phase_to_skill via manifest ([#167](https://github.com/Viniciuscarvalho/monozukuri/issues/167)) ([aa03ee8](https://github.com/Viniciuscarvalho/monozukuri/commit/aa03ee8a9e5d59ed0334f5b265b36896d3fa26d1))
* **agent:** record allowed-tools in manifest and log at invocation ([#172](https://github.com/Viniciuscarvalho/monozukuri/issues/172)) ([115f25c](https://github.com/Viniciuscarvalho/monozukuri/commit/115f25cfc9ba9bd3258803c40077907c89d13773))
* **agent:** scan GEMINI.md as a project-conventions source ([#165](https://github.com/Viniciuscarvalho/monozukuri/issues/165)) ([ecb5633](https://github.com/Viniciuscarvalho/monozukuri/commit/ecb5633fdf6a828cc1571039ed4023af6581ae5a))
* **agent:** walk nested AGENTS.md in subpackages (depth ≤ 3) ([#166](https://github.com/Viniciuscarvalho/monozukuri/issues/166)) ([46f87ac](https://github.com/Viniciuscarvalho/monozukuri/commit/46f87acef552c6713d574b71e0dd89396f9e397f))
* bundle to-prd and grill-me skills (pre-flight workflow) ([045c467](https://github.com/Viniciuscarvalho/monozukuri/commit/045c4673df2e2bee17082dd2fb9bf9a20db4f33e))
* bundle to-prd and grill-me skills from mattpocock/skills ([a113324](https://github.com/Viniciuscarvalho/monozukuri/commit/a113324fb24eaf9e3c9d1cc84dc7b8d8dd1c6fd3))
* **ci-guard:** add CI watcher skill and scripts ([#125](https://github.com/Viniciuscarvalho/monozukuri/issues/125)) ([20425e4](https://github.com/Viniciuscarvalho/monozukuri/commit/20425e4be38c7ef4bdda75090f73d2340b53a557))
* **ci:** RC release channel — [@next](https://github.com/next) npm + monozukuri-next brew + promotion scripts ([#195](https://github.com/Viniciuscarvalho/monozukuri/issues/195)) ([b361919](https://github.com/Viniciuscarvalho/monozukuri/commit/b36191972bf6f25ee936628f91e3bc5956701395))
* **cli:** add ranked backlog list command ([#227](https://github.com/Viniciuscarvalho/monozukuri/issues/227)) ([d57ef92](https://github.com/Viniciuscarvalho/monozukuri/commit/d57ef921f34c8aaf0dbe4895fbcd569a3fccc299))
* **cli:** surface skills manifest in doctor + status ([#171](https://github.com/Viniciuscarvalho/monozukuri/issues/171)) ([0cf8de2](https://github.com/Viniciuscarvalho/monozukuri/commit/0cf8de289fddb02e9918af4d5ec6834d2bebf698))
* **cli:** TUI Day 1 — emit phase.token_update + phase.completed from stream-parse ([#176](https://github.com/Viniciuscarvalho/monozukuri/issues/176)) ([c399003](https://github.com/Viniciuscarvalho/monozukuri/commit/c3990034bb01be9f4e36f414c9ff3d126b2ac0b3))
* configurable schema reprompt budget + human escalation ([682f63f](https://github.com/Viniciuscarvalho/monozukuri/commit/682f63fb4ef31c79c83678741eaef8f5cf76c6ca))
* configurable schema reprompt budget + human escalation path ([6d974f5](https://github.com/Viniciuscarvalho/monozukuri/commit/6d974f5d3e2a228d0419cea7a80e21f3c01da92f))
* **contract:** close full_auto blocker contract gaps ([#95](https://github.com/Viniciuscarvalho/monozukuri/issues/95)) ([d9f158d](https://github.com/Viniciuscarvalho/monozukuri/commit/d9f158d0aa5dfff778caecf8b0d5a0295af4d82d))
* **contract:** gap 3 — adapter contract v1.0.0, claude-code improvements, aider adapter (ADR-012) ([cdfee8e](https://github.com/Viniciuscarvalho/monozukuri/commit/cdfee8ea67cd894caead3f164401542c0d822aa4))
* **contract:** gap 3 — adapter contract v1.0.0, claude-code improvements, aider adapter (ADR-012) ([0edde5d](https://github.com/Viniciuscarvalho/monozukuri/commit/0edde5d59905161f8b7ae75e7805ac9fb0e8346d))
* **conventions:** auto-sync AGENTS.md after each run (PR4) ([793a678](https://github.com/Viniciuscarvalho/monozukuri/commit/793a6787943ad6a58da78737ec13c290724e6e45))
* **conventions:** generate AGENTS.md from learning store (PR3) ([801ec1e](https://github.com/Viniciuscarvalho/monozukuri/commit/801ec1e893770dcf028ae4517a02c1910f84b279))
* **conventions:** read and inject project convention files ([0da6119](https://github.com/Viniciuscarvalho/monozukuri/commit/0da611918f5f6a83689a9110d7c70de975ec5587))
* **conventions:** read and inject project convention files (PR1) ([a02f7c8](https://github.com/Viniciuscarvalho/monozukuri/commit/a02f7c88e6fbd4c1925a048616aec21e83dd3897))
* **conventions:** seed AGENTS.md and add it to Claude Code adapter native context ([b987513](https://github.com/Viniciuscarvalho/monozukuri/commit/b9875133641939cbe606ad1b8f562ceb6ba7ed6c))
* **conventions:** seed AGENTS.md and align Claude Code adapter with multi-agent convention surface ([d1e8f7a](https://github.com/Viniciuscarvalho/monozukuri/commit/d1e8f7a64630c6c2f3a1d6d74a7105f1c1a5e032))
* **conventions:** suppress duplicate context per adapter (PR2) ([2437140](https://github.com/Viniciuscarvalho/monozukuri/commit/2437140f934295ae8135b5391f020b4ab3863507))
* **conventions:** surface promotion candidates as convention entries (PR5) ([7782e3a](https://github.com/Viniciuscarvalho/monozukuri/commit/7782e3abd47528d53b52472f578499d89b0c7e31))
* **conventions:** surface promotion candidates as convention entries (PR5) ([629488f](https://github.com/Viniciuscarvalho/monozukuri/commit/629488fd240414948a65141705ba3fd555aff40e))
* enable Ink terminal UI via Node dispatcher in Homebrew ([3a9e226](https://github.com/Viniciuscarvalho/monozukuri/commit/3a9e226006585d425701b1253141df58f881adf6))
* enable Ink terminal UI via Node dispatcher in Homebrew ([8c12967](https://github.com/Viniciuscarvalho/monozukuri/commit/8c12967d1158674256e426b53752bf46d14c95d2))
* **failure:** gap 2 — stratified failure handling, idempotent resumption, CI poll (ADR-013/014) ([92a4ceb](https://github.com/Viniciuscarvalho/monozukuri/commit/92a4ceb155d17bb3f175e98c28bd1d8187a08250))
* **failure:** gap 2 — stratified failure handling, idempotent resumption, CI poll (ADR-013/014) ([e63d1eb](https://github.com/Viniciuscarvalho/monozukuri/commit/e63d1eba70459021c4a57a8374ce55a1783ae21d))
* Gap 5 - L5 Measurability Infrastructure ([a86f766](https://github.com/Viniciuscarvalho/monozukuri/commit/a86f76677d429c85b4e5a7250733ae4dd039ebf9))
* **gap3:** phase-aware templates, context-pack, registry, render node path ([d1396a9](https://github.com/Viniciuscarvalho/monozukuri/commit/d1396a941fb65babe0ee741e9492ec1773e078bb))
* **gap4:** per-phase routing config, routing_load, and threshold-gated routing suggest (ADR-015) ([30cec4f](https://github.com/Viniciuscarvalho/monozukuri/commit/30cec4f26e8b9341cfddfdbc6bc85e691126e96d))
* **gap4:** per-phase routing config, routing_load, and threshold-gated suggest (ADR-015) ([1272e08](https://github.com/Viniciuscarvalho/monozukuri/commit/1272e08128e4bc4dea41633bca256b3f36da0a20))
* **gap6:** run review — export, open, list subcommands (ADR-015) ([7b6e03c](https://github.com/Viniciuscarvalho/monozukuri/commit/7b6e03ca322f4ede636fcbac96f460caef175b17))
* **gap6:** run review — export, open, list subcommands (ADR-015) ([8af8917](https://github.com/Viniciuscarvalho/monozukuri/commit/8af8917b5fb201e1230d43cf9a9de8acac132e4b))
* **gap7:** implicit-dep detection + ingestion validator (ADR-015) ([5852a39](https://github.com/Viniciuscarvalho/monozukuri/commit/5852a392597df28ce150a65ee49ffd4ef3eb6d94))
* **gap7:** implicit-dep detection + ingestion validator (ADR-015) ([1a92ac9](https://github.com/Viniciuscarvalho/monozukuri/commit/1a92ac927d7b983979ca719c423321cd4c2cfa60))
* **gap8:** deferred status in FeatureList — yellow icon and label in completed list ([b25aaf1](https://github.com/Viniciuscarvalho/monozukuri/commit/b25aaf1676a8e8223fe4604bf10ae6d4ee0f181b))
* **gap8:** pricing and calibration — L5 cost honesty ([e930e07](https://github.com/Viniciuscarvalho/monozukuri/commit/e930e0763141eca52d999ab834c746a00a6144c9))
* **gap8:** pricing and calibration — L5 cost honesty (ADR-008) ([f066ffe](https://github.com/Viniciuscarvalho/monozukuri/commit/f066ffef006f07f16fa68eb05c7cb642ac850d1c))
* implement Gap 5 - L5 measurability infrastructure ([996c0e9](https://github.com/Viniciuscarvalho/monozukuri/commit/996c0e976dc3e986720cb305985ff679a755eea7))
* initial release — Monozukuri v1.0.0 ([d181a07](https://github.com/Viniciuscarvalho/monozukuri/commit/d181a07647388aa07f4042bd0d4ea7f032a8e234))
* Ink TUI, repo tooling, CI workflows, Bats harness, JSONL events ([1aa5caf](https://github.com/Viniciuscarvalho/monozukuri/commit/1aa5cafde4a7c452e2c53505726ca9fa1ffbc6a7))
* introduce multi-agent adapter contract (Phase 2) ([b143abd](https://github.com/Viniciuscarvalho/monozukuri/commit/b143abd84862c6fbb34ffedef3293c25b14fc162))
* M2 UX polish + M5 launch prep ([3a35c4f](https://github.com/Viniciuscarvalho/monozukuri/commit/3a35c4f6ad2ccb8483e96a6a577bb67ae63e0dfe))
* **memory:** workflow memory harness + README skills documentation (PR5) ([088a305](https://github.com/Viniciuscarvalho/monozukuri/commit/088a30590541702259e79ef2bfeda95587766c1d))
* **memory:** workflow memory harness + README skills documentation (PR5) ([7ced242](https://github.com/Viniciuscarvalho/monozukuri/commit/7ced242e2fa6205106e7597fc65ca527f938fd42))
* **orchestrator:** fix skill selection and add AGENTS.md discovery ([#90](https://github.com/Viniciuscarvalho/monozukuri/issues/90)) ([f3dd99e](https://github.com/Viniciuscarvalho/monozukuri/commit/f3dd99e42459b2b6493525d066a27b905c4b599c))
* **phase-a:** loop safety for unattended runs on codex/gemini ([#105](https://github.com/Viniciuscarvalho/monozukuri/issues/105)) ([2d27ddd](https://github.com/Viniciuscarvalho/monozukuri/commit/2d27ddd4b97a2838f5dcc740c4da7a8ebfa60251))
* **phase-b:** seed per-adapter context files on monozukuri init ([#106](https://github.com/Viniciuscarvalho/monozukuri/issues/106)) ([b92a614](https://github.com/Viniciuscarvalho/monozukuri/commit/b92a614e61c3cd6f7284c330816f93c7b7291c9a))
* **phase-c:** multi-project ops — budget ceiling, kill switch, summary, concurrency ([#109](https://github.com/Viniciuscarvalho/monozukuri/issues/109)) ([d164a8e](https://github.com/Viniciuscarvalho/monozukuri/commit/d164a8eb6c7bc99ff296c383e21a2c4d673c2df1))
* **phase-d:** release-gate truthfulness + CI enforcement ([#111](https://github.com/Viniciuscarvalho/monozukuri/issues/111)) ([e834c1c](https://github.com/Viniciuscarvalho/monozukuri/commit/e834c1c6088d9ba2b8c12b491a72a32cd0b876fc))
* **phase-e:** state-version stamping + opt-in telemetry ([#113](https://github.com/Viniciuscarvalho/monozukuri/issues/113)) ([975fdac](https://github.com/Viniciuscarvalho/monozukuri/commit/975fdacf97fde6837af4000015f96e6e72a78126))
* **phase-f:** schema render parity for codex/gemini ([#115](https://github.com/Viniciuscarvalho/monozukuri/issues/115)) ([14a1e77](https://github.com/Viniciuscarvalho/monozukuri/commit/14a1e770760bb3dbd6b1e5589ac88dfdd6e32bf7))
* **phase-g:** plan-doc reconciliation — env-var cleanup, CLAUDE.md, archive Path B ([#118](https://github.com/Viniciuscarvalho/monozukuri/issues/118)) ([f413fba](https://github.com/Viniciuscarvalho/monozukuri/commit/f413fba5049548d1337574d449da50274ebc641a))
* **phase3,adapters:** generalize Ralph Loop to all adapters via agent_run_phase ([#101](https://github.com/Viniciuscarvalho/monozukuri/issues/101)) ([462fd06](https://github.com/Viniciuscarvalho/monozukuri/commit/462fd0647e7c6e98a37120124a0078273b92be9e))
* **pipeline:** phase-split mz-* skills, schema compat, setup fix ([#124](https://github.com/Viniciuscarvalho/monozukuri/issues/124)) ([76be5b7](https://github.com/Viniciuscarvalho/monozukuri/commit/76be5b7d250a59e9a0418c1b736e6c2cd695ffc9))
* **qa:** Layer 4 backwards compat + fix cmd/resume.sh module loading ([#80](https://github.com/Viniciuscarvalho/monozukuri/issues/80)) ([07b0bc9](https://github.com/Viniciuscarvalho/monozukuri/commit/07b0bc9e4ca243e723d88091f2cb9e3d53e8fb68))
* **qa:** release gate harness — layers 1, 2 & 3 (PR 0→2) ([#78](https://github.com/Viniciuscarvalho/monozukuri/issues/78)) ([baac069](https://github.com/Viniciuscarvalho/monozukuri/commit/baac06929919eb7de747d1df8cc2a57009b30c2d))
* **qa:** replay-based mock infra + property tests + Layer 7 conformance (no CI cost) ([#161](https://github.com/Viniciuscarvalho/monozukuri/issues/161)) ([8edde0a](https://github.com/Viniciuscarvalho/monozukuri/commit/8edde0aa8df97a32f92bc65c274066f337733e7d))
* **resilience:** auto-mode schema resilience — paused recovery, retry command, UI visibility ([#132](https://github.com/Viniciuscarvalho/monozukuri/issues/132)) ([824b1bf](https://github.com/Viniciuscarvalho/monozukuri/commit/824b1bf0d800aed346e5757938a30d23aeafd258))
* **run:** auto-invoke skill-discovery on session start ([#170](https://github.com/Viniciuscarvalho/monozukuri/issues/170)) ([0c57136](https://github.com/Viniciuscarvalho/monozukuri/commit/0c5713622106a9e23faac6023b836251f3c76857))
* **schema:** gap 1 — phase artifact schemas and validation (ADR-012) ([6103b82](https://github.com/Viniciuscarvalho/monozukuri/commit/6103b826a7150338c6985bbeac169beb5130fb7b))
* **schema:** Gap 1 — phase artifact schemas and validation (ADR-012) ([1e1ae12](https://github.com/Viniciuscarvalho/monozukuri/commit/1e1ae12003a623dc4a07f34c47d36efd74ac03ae))
* **setup:** add monozukuri setup installer command (PR3) ([62f83b3](https://github.com/Viniciuscarvalho/monozukuri/commit/62f83b3f374960f79a949b1aba3a86ed00074e68))
* **setup:** add monozukuri setup installer command (PR3) ([9fde8bc](https://github.com/Viniciuscarvalho/monozukuri/commit/9fde8bc3f7bd04eaee0067015120efc653de3286))
* **skills:** publishable mz-* skill versioning and packaging ([#94](https://github.com/Viniciuscarvalho/monozukuri/issues/94)) ([c8090da](https://github.com/Viniciuscarvalho/monozukuri/commit/c8090da622b7e11eeed8bdf47c1c19906425e3d2))
* **skills:** scaffold 8 mz-* phase skills (PR1 of skills plan) ([200cc90](https://github.com/Viniciuscarvalho/monozukuri/commit/200cc90a3ee2cf6afc2b0af3b77620946c55a6e3))
* **skills:** scaffold 8 mz-* phase skills (PR1 of skills plan) ([ebf01a9](https://github.com/Viniciuscarvalho/monozukuri/commit/ebf01a9276f4bb7dcdf62748f93fcba047642f78))
* surface agent identity in TUI + stand up Jest test infra (Phase 8) ([95ec400](https://github.com/Viniciuscarvalho/monozukuri/commit/95ec40024841084a81b7dea12ca4f2ea8c50af0c))
* **tui:** TUI by default, silence bash render layer ([#92](https://github.com/Viniciuscarvalho/monozukuri/issues/92)) ([e79a683](https://github.com/Viniciuscarvalho/monozukuri/commit/e79a683042d614111e98eee2b1fea8039e99067b))
* **tui:** visual polish pass — unified border, token enforcement, braille spinner ([#198](https://github.com/Viniciuscarvalho/monozukuri/issues/198)) ([5f43ae4](https://github.com/Viniciuscarvalho/monozukuri/commit/5f43ae45890966b19cce846285c182dba7675fac))
* **ui:** consolidate TUI Days 2-5 + composite screenshot into main ([#182](https://github.com/Viniciuscarvalho/monozukuri/issues/182)) ([e7a0c64](https://github.com/Viniciuscarvalho/monozukuri/commit/e7a0c64948345fff758e05946b0f6640ea480d13))
* **ui:** surface skills, workflow memory, and setup events in TUI (PR6) ([e75bc65](https://github.com/Viniciuscarvalho/monozukuri/commit/e75bc65fbf7010c8d012727b9e4ab1850b8385e1))
* **ui:** surface skills, workflow memory, and setup events in TUI (PR6) ([8116c7b](https://github.com/Viniciuscarvalho/monozukuri/commit/8116c7b98e37ef27df2f35c88e988e90908d0f78))
* **ux:** execution visibility — phase events, tool stream, web dashboard ([#120](https://github.com/Viniciuscarvalho/monozukuri/issues/120)) ([981c1d4](https://github.com/Viniciuscarvalho/monozukuri/commit/981c1d4967ee738af4a47743d5eaaa92ae57183d))
* **v1.0:** hardening — full_auto contract, crash recovery, skill versioning, CI gate, cosmetic fixes ([#159](https://github.com/Viniciuscarvalho/monozukuri/issues/159)) ([1635003](https://github.com/Viniciuscarvalho/monozukuri/commit/163500306dcc08c55b1015f090b6c7b03e36a78b))
* **v1:** launch-prep gap fixes — doctor, skill overrides, design tokens, web log pane ([#152](https://github.com/Viniciuscarvalho/monozukuri/issues/152)) ([bbeef30](https://github.com/Viniciuscarvalho/monozukuri/commit/bbeef30004fa47e7dd5c4f20219185a6e76f2b07))
* **validator:** couple validate.sh to skills/*-validation.md aliases (PR2) ([d52a25a](https://github.com/Viniciuscarvalho/monozukuri/commit/d52a25a0909e9488fe9bb0f7e08219a3b943dbef))
* **validator:** couple validate.sh to skills/*-validation.md aliases (PR2) ([20a55ef](https://github.com/Viniciuscarvalho/monozukuri/commit/20a55efcc5f0324a4a390bf581439cb513db59a9))


### Bug Fixes

* **adapters:** event stream parity for Codex, Gemini, Kiro, Aider ([#122](https://github.com/Viniciuscarvalho/monozukuri/issues/122)) ([ca80cef](https://github.com/Viniciuscarvalho/monozukuri/commit/ca80cef0717db3c2293ac6b02d129b8c2fabb0c0))
* **agent:** close mz-open-pr full_auto hang and expose hidden CLI commands ([#205](https://github.com/Viniciuscarvalho/monozukuri/issues/205)) ([6857eed](https://github.com/Viniciuscarvalho/monozukuri/commit/6857eed27e1fb50d6977cbd077d630076cf5eee7))
* **agent:** run Codex through rendered phase prompts ([#221](https://github.com/Viniciuscarvalho/monozukuri/issues/221)) ([49f264d](https://github.com/Viniciuscarvalho/monozukuri/commit/49f264d6f6d2e0d6aa44a3b7df7b7583e426b176))
* bleed-stop bundle ([#84](https://github.com/Viniciuscarvalho/monozukuri/issues/84)) ([f2b90ff](https://github.com/Viniciuscarvalho/monozukuri/commit/f2b90ff415108a03767e578308c5e8362a290ffd))
* **ci:** extract PR number from release-please JSON output for auto-merge ([#72](https://github.com/Viniciuscarvalho/monozukuri/issues/72)) ([bf87666](https://github.com/Viniciuscarvalho/monozukuri/commit/bf87666ddb51517cc7d0f6c04470baa932c5ecc3))
* **ci:** pass --repo to gh pr merge to avoid missing git context ([#74](https://github.com/Viniciuscarvalho/monozukuri/issues/74)) ([6e3e325](https://github.com/Viniciuscarvalho/monozukuri/commit/6e3e3251717359442b7fb799c7dab3f3df33e3f8))
* **ci:** suppress monozukuri-vX prefix in release-please v5 tags ([8a7d11e](https://github.com/Viniciuscarvalho/monozukuri/commit/8a7d11e78715df6ea844998bc87e2b97bc853192))
* **ci:** suppress monozukuri-vX prefix in release-please v5 tags ([64fe15d](https://github.com/Viniciuscarvalho/monozukuri/commit/64fe15decd1e43018c36b230484b96753f47f92b))
* **ci:** use PAT for release-please to trigger Actions on release commits ([#141](https://github.com/Viniciuscarvalho/monozukuri/issues/141)) ([a561359](https://github.com/Viniciuscarvalho/monozukuri/commit/a5613596df4e26145157ddb3cc86503a92f3e565))
* create bump branch before writing formula in homebrew-tap workflow ([e7ee2e8](https://github.com/Viniciuscarvalho/monozukuri/commit/e7ee2e836e03159d6c8d652011183d899a5ad566))
* export MONOZUKURI_PHASE, clarify Phase 0 log label, capture schema mismatches ([#88](https://github.com/Viniciuscarvalho/monozukuri/issues/88)) ([daa83fa](https://github.com/Viniciuscarvalho/monozukuri/commit/daa83facafbb4ab6cc1c3359a269e706ff023318))
* fold error status into failed counter across all three reporters ([e6e5762](https://github.com/Viniciuscarvalho/monozukuri/commit/e6e57626e308e2079fef48ed51ca8f1729e46f62))
* fold error status into failed counter across all three reporters ([05093f4](https://github.com/Viniciuscarvalho/monozukuri/commit/05093f48ecbd84acb9beaea5db87056c471ad701))
* **homebrew:** remove missing ui/dist/package.json from install step ([#82](https://github.com/Viniciuscarvalho/monozukuri/issues/82)) ([8d06c6a](https://github.com/Viniciuscarvalho/monozukuri/commit/8d06c6ac32a448db5a0d996d2e9cb9f6e4e3e786))
* **memory:** workflow_memory_prepare crash — exports lost in subshell ([747c8e7](https://github.com/Viniciuscarvalho/monozukuri/commit/747c8e78403022b41c0d776d2cca2e8ef98de6c8))
* **memory:** workflow_memory_prepare must export to parent process ([23f629a](https://github.com/Viniciuscarvalho/monozukuri/commit/23f629a45db412ad0de2c8cf5f172e9dcffd05c6))
* mermaid diagram + homebrew formula v1.0.0 checksum ([52dba02](https://github.com/Viniciuscarvalho/monozukuri/commit/52dba0231b62e735ea173e8606c79747b7f9c997))
* **metrics:** fix 8 pre-existing test failures in metrics module ([fff0494](https://github.com/Viniciuscarvalho/monozukuri/commit/fff0494c86cd22e656d0c8cbb7d76797c170293a))
* **metrics:** remove comment drift from linter revert in metrics.sh ([4a1a628](https://github.com/Viniciuscarvalho/monozukuri/commit/4a1a628bac077a629b7bdb31abcafc110049e203))
* MONOZUKURI_PHASE export, Phase 0 log label, learning store schema capture ([#86](https://github.com/Viniciuscarvalho/monozukuri/issues/86)) ([9b07df5](https://github.com/Viniciuscarvalho/monozukuri/commit/9b07df58839f16888e6bc4ed522d9133273d51cc))
* **prompt:** add MONOZUKURI_WORKTREE, _AUTONOMY, _FEATURE_ID to context pack ([#189](https://github.com/Viniciuscarvalho/monozukuri/issues/189)) ([72d9398](https://github.com/Viniciuscarvalho/monozukuri/commit/72d93984b687f9170bb9adbf52edd17912c833c7))
* **prompt:** pre-render MONOZUKURI_* env vars into context before rich render ([#191](https://github.com/Viniciuscarvalho/monozukuri/issues/191)) ([a314a21](https://github.com/Viniciuscarvalho/monozukuri/commit/a314a213cefa30fbcff4891e9a3719c10a924b5b))
* **qa:** fix release gate layer 2 failures ([#146](https://github.com/Viniciuscarvalho/monozukuri/issues/146)) ([097504b](https://github.com/Viniciuscarvalho/monozukuri/commit/097504b0817319ff17dfdee3e7dac7b31dac6e18))
* **qa:** skip doctor check in CI — gh/claude absent on runners ([#148](https://github.com/Viniciuscarvalho/monozukuri/issues/148)) ([0e9fb20](https://github.com/Viniciuscarvalho/monozukuri/commit/0e9fb2020482dfbf6c97d5b52da9a6883be98b1c))
* **qa:** unblock Release gate — three pre-existing Layer 2 bugs ([#162](https://github.com/Viniciuscarvalho/monozukuri/issues/162)) ([e2f406e](https://github.com/Viniciuscarvalho/monozukuri/commit/e2f406e28ad66a3a48387e43c338c9a7832ea34b))
* resolve 8 runtime bugs in full-auto PR creation flow ([33ec376](https://github.com/Viniciuscarvalho/monozukuri/commit/33ec3764f69f888446618595996149ed1aec64d0))
* **resume,learning:** close determinism gaps ([#96](https://github.com/Viniciuscarvalho/monozukuri/issues/96)) ([5c38d56](https://github.com/Viniciuscarvalho/monozukuri/commit/5c38d56a221a87db709d1825b618ba935d66fb0e))
* **run:** cycle-gate skips feature instead of aborting run + TUI unified grid ([#193](https://github.com/Viniciuscarvalho/monozukuri/issues/193)) ([a86dcc4](https://github.com/Viniciuscarvalho/monozukuri/commit/a86dcc449eab15d99176b78ac9b35e2c3775cfc2))
* **run:** hard-block run when known-incompatible skill is configured ([#187](https://github.com/Viniciuscarvalho/monozukuri/issues/187)) ([7770915](https://github.com/Viniciuscarvalho/monozukuri/commit/7770915d6f235649cef64bea81681ff441a5b8c3))
* **setup:** stop TUI from eating keystrokes; accept bare positional verbs ([#129](https://github.com/Viniciuscarvalho/monozukuri/issues/129)) ([69999ba](https://github.com/Viniciuscarvalho/monozukuri/commit/69999bab363560d4a4bb0ea1361d7db6915a4915))
* **site:** set GitHub Pages base path and fix asset URLs ([#213](https://github.com/Viniciuscarvalho/monozukuri/issues/213)) ([2368810](https://github.com/Viniciuscarvalho/monozukuri/commit/23688106b8edb919dae434420f6b64c711f25101))
* stream-json --verbose and retry --all reason filter ([#144](https://github.com/Viniciuscarvalho/monozukuri/issues/144)) ([9f639f0](https://github.com/Viniciuscarvalho/monozukuri/commit/9f639f07b0dbb58c5eea80bed4292d2b3d29e3dc))
* symlink .claude/skills into worktrees and wire Ink TUI ([#139](https://github.com/Viniciuscarvalho/monozukuri/issues/139)) ([b7e05e6](https://github.com/Viniciuscarvalho/monozukuri/commit/b7e05e6d7bc2bb625a9e9f18a8531d9cb16f89e0))
* three bugs in orchestrator ↔ skill contract (diff gate, path alignment, doctor warning) ([#185](https://github.com/Viniciuscarvalho/monozukuri/issues/185)) ([e47371c](https://github.com/Viniciuscarvalho/monozukuri/commit/e47371cf68ade19069381293920bbafeeab1e180))
* **tui:** stop EIO crash on exit and mislabeled paused runs ([#150](https://github.com/Viniciuscarvalho/monozukuri/issues/150)) ([9856ecf](https://github.com/Viniciuscarvalho/monozukuri/commit/9856ecfa10de0ec569c9a8ac23fbb67963c380ee))
* **ui:** inject createRequire banner to fix CJS dynamic-require failure in ESM bundle ([#68](https://github.com/Viniciuscarvalho/monozukuri/issues/68)) ([59a5985](https://github.com/Viniciuscarvalho/monozukuri/commit/59a59856943207866c8221e41417e915e3a46d73))
* **ui:** open /dev/tty for Ink keyboard input; avoid raw mode error in non-TTY context ([7ca35f5](https://github.com/Viniciuscarvalho/monozukuri/commit/7ca35f5054542c1f10becd9b9e3004e45868ef93))
* **ui:** open /dev/tty for Ink keyboard input; avoid raw mode error in non-TTY context ([82ee32b](https://github.com/Viniciuscarvalho/monozukuri/commit/82ee32b855700edb878a8469b2cda147c4e89a7a))
* **ui:** stub react-devtools-core to eliminate missing-package error at runtime ([#66](https://github.com/Viniciuscarvalho/monozukuri/issues/66)) ([f312c48](https://github.com/Viniciuscarvalho/monozukuri/commit/f312c48aca50a837116301f472b54980f24af534))
* **ui:** three-PR sequence — build, polish, signals ([#70](https://github.com/Viniciuscarvalho/monozukuri/issues/70)) ([13fcbb2](https://github.com/Viniciuscarvalho/monozukuri/commit/13fcbb24ee18dd45673efc5d5fb7c32bfdf5db8e))
* use injected github client in github-script, drop manual Octokit ([824c82e](https://github.com/Viniciuscarvalho/monozukuri/commit/824c82ea179c88cd5cafec6909b739417cd65cb4))
* v1.0 pre-launch — canary jq fix, draft PR UX, docs ([#210](https://github.com/Viniciuscarvalho/monozukuri/issues/210)) ([5983e33](https://github.com/Viniciuscarvalho/monozukuri/commit/5983e337c824c3f18034305d2f3d4f952546acb6))


### Refactoring

* **arch:** deepen modules C2-C8 + fix pricing budget ceiling ([#134](https://github.com/Viniciuscarvalho/monozukuri/issues/134)) ([821453e](https://github.com/Viniciuscarvalho/monozukuri/commit/821453e8ff39f696a3687eb0da5a4a0fb8d761a4))
* consolidate scripts/lib/ into lib/ canonical tree ([165a9f2](https://github.com/Viniciuscarvalho/monozukuri/commit/165a9f2fd6b1ff9634368625e0d0b41950b633d6))
* **conventions:** consolidate file-IO seam and add learning entry contract ([835a651](https://github.com/Viniciuscarvalho/monozukuri/commit/835a651b3f313b6c54c7ae0992d0e4465a444cca))
* **conventions:** consolidate file-IO seam and add learning entry contract ([9fe0af4](https://github.com/Viniciuscarvalho/monozukuri/commit/9fe0af4da43f46794de9d03d8cd1dfd7767a07ef))
* deepen architecture ([453e7f9](https://github.com/Viniciuscarvalho/monozukuri/commit/453e7f9c2aa9f63761f16c1acf3b0903db9cac70))
* deepen architecture — 5 seams extracted from pipeline.sh ([19c7ca0](https://github.com/Viniciuscarvalho/monozukuri/commit/19c7ca042f2309acb5758e0028635bef4fc78653))
* M1.1 directory restructure — cmd/ + lib/ split ([97da855](https://github.com/Viniciuscarvalho/monozukuri/commit/97da8559c8e7d5a654051579778948fda1945e07))
* **render:** replace node-based renderer with jq/awk/bash implementation ([dee9786](https://github.com/Viniciuscarvalho/monozukuri/commit/dee9786347554bd78b8c92ed7bd5a3203bf101e0))


### Documentation

* add ADR template ([bb47263](https://github.com/Viniciuscarvalho/monozukuri/commit/bb472632d61257ee96eb59b6799843da5c71a473))
* add user-facing reference docs and simplify README ([#197](https://github.com/Viniciuscarvalho/monozukuri/issues/197)) ([435c231](https://github.com/Viniciuscarvalho/monozukuri/commit/435c2314893369f2407ccd0c8d6b906819000229))
* add vision, capability ladder, and roadmap ([42d85e5](https://github.com/Viniciuscarvalho/monozukuri/commit/42d85e554a5d253865be472ad6a8753bbb9d3918))
* **adr:** 012 — adapter contract & phase artifact schemas ([d40fce6](https://github.com/Viniciuscarvalho/monozukuri/commit/d40fce66990d61fe5aa48f1df11a3d82530358d3))
* **adr:** 013 — failure handling, idempotent resumption, rate-limit policy ([a35763b](https://github.com/Viniciuscarvalho/monozukuri/commit/a35763bc9a1601ad52a3be0511c88e7d5ccb188d))
* **adr:** 014 — terminal state (CI-green PR) & L5 metric ([b919274](https://github.com/Viniciuscarvalho/monozukuri/commit/b919274c54273db964234959895d018c840051c6))
* **adr:** 015 — routing, implicit deps, and review surface ([66dad9a](https://github.com/Viniciuscarvalho/monozukuri/commit/66dad9a309aff70d3767f32ba4f9ceb49dd04441))
* **adr:** 016 — 13-week plan & capability ladder commitments ([3ddbe6d](https://github.com/Viniciuscarvalho/monozukuri/commit/3ddbe6df6253c66de7727a03ca462a80e1c98664))
* **assets:** add hero GIF and dashboard screenshot to README ([#203](https://github.com/Viniciuscarvalho/monozukuri/issues/203)) ([776ba4b](https://github.com/Viniciuscarvalho/monozukuri/commit/776ba4b1a4254d9e2d8ff8d2592248d86e6f3b51))
* document retry, resume-paused, stop, and 7 other undocumented subcommands ([#136](https://github.com/Viniciuscarvalho/monozukuri/issues/136)) ([197a3c5](https://github.com/Viniciuscarvalho/monozukuri/commit/197a3c59e1f589f745940c00e2c92e44b525073a))
* expand README with highlights, models, project layout, dev, and contributing sections ([789b943](https://github.com/Viniciuscarvalho/monozukuri/commit/789b9438da9dd9362c07d601f174fbd88c2b96a7))
* land grilled vision decisions (vision, ladder, ADRs 012-016) ([9ab089e](https://github.com/Viniciuscarvalho/monozukuri/commit/9ab089ed32476f9c55e693aa06e08908201ee35c))
* **planning:** v2.0 gap-closure PRD + ADRs 018-023 ([#216](https://github.com/Viniciuscarvalho/monozukuri/issues/216)) ([d839452](https://github.com/Viniciuscarvalho/monozukuri/commit/d839452e99f7159ae0956aaa817296f2c2f8e34a))
* rewrite README and CHANGELOG for multi-agent v1.2.0 ([a72f6e9](https://github.com/Viniciuscarvalho/monozukuri/commit/a72f6e93d91388913bd6287aaf4bc04e12dc01e6))
* rewrite README and CHANGELOG for multi-agent v1.2.0 (Phase 9) ([1b88919](https://github.com/Viniciuscarvalho/monozukuri/commit/1b8891966874c637343f8a0dd114c1a27cd3e50d))
* unify on AGENTS.md (symlink CLAUDE/GEMINI) + verified content ([#163](https://github.com/Viniciuscarvalho/monozukuri/issues/163)) ([7cdb12a](https://github.com/Viniciuscarvalho/monozukuri/commit/7cdb12a97d407efde8502e6e4b468c332b65a0e2))
* use agent-agnostic language across README and docs ([#201](https://github.com/Viniciuscarvalho/monozukuri/issues/201)) ([03e3f98](https://github.com/Viniciuscarvalho/monozukuri/commit/03e3f98c6a35eaca01347baf592648e271599798))

## [1.52.0](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.51.0...v1.52.0) (2026-05-17)


### Features

* **cli:** add ranked backlog list command ([#227](https://github.com/Viniciuscarvalho/monozukuri/issues/227)) ([d57ef92](https://github.com/Viniciuscarvalho/monozukuri/commit/d57ef921f34c8aaf0dbe4895fbcd569a3fccc299))


### Bug Fixes

* **agent:** run Codex through rendered phase prompts ([#221](https://github.com/Viniciuscarvalho/monozukuri/issues/221)) ([49f264d](https://github.com/Viniciuscarvalho/monozukuri/commit/49f264d6f6d2e0d6aa44a3b7df7b7583e426b176))

## [1.51.0](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.50.2...v1.51.0) (2026-05-15)


### Features

* **agent:** add portable skill injection ([#218](https://github.com/Viniciuscarvalho/monozukuri/issues/218)) ([a1f4a77](https://github.com/Viniciuscarvalho/monozukuri/commit/a1f4a77032f747e7e356548f137540660db9f289))

## [1.50.2](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.50.1...v1.50.2) (2026-05-14)


### Documentation

* **planning:** v2.0 gap-closure PRD + ADRs 018-023 ([#216](https://github.com/Viniciuscarvalho/monozukuri/issues/216)) ([d839452](https://github.com/Viniciuscarvalho/monozukuri/commit/d839452e99f7159ae0956aaa817296f2c2f8e34a))

## [1.50.1](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.50.0...v1.50.1) (2026-05-14)


### Bug Fixes

* **site:** set GitHub Pages base path and fix asset URLs ([#213](https://github.com/Viniciuscarvalho/monozukuri/issues/213)) ([2368810](https://github.com/Viniciuscarvalho/monozukuri/commit/23688106b8edb919dae434420f6b64c711f25101))

## [1.50.0](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.49.1...v1.50.0) (2026-05-14)


### Features

* add promotional site + GitHub Pages deployment ([#207](https://github.com/Viniciuscarvalho/monozukuri/issues/207)) ([a5cf1dd](https://github.com/Viniciuscarvalho/monozukuri/commit/a5cf1ddb151c6311814499aace67cb17f3276d71))

## [1.49.1](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.49.0...v1.49.1) (2026-05-13)


### Bug Fixes

* v1.0 pre-launch — canary jq fix, draft PR UX, docs ([#210](https://github.com/Viniciuscarvalho/monozukuri/issues/210)) ([5983e33](https://github.com/Viniciuscarvalho/monozukuri/commit/5983e337c824c3f18034305d2f3d4f952546acb6))

## [1.49.0](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.48.3...v1.49.0) (2026-05-13)


### Features

* **agent:** ADR-017 multi-turn session for claude-code adapter ([#208](https://github.com/Viniciuscarvalho/monozukuri/issues/208)) ([7d6f981](https://github.com/Viniciuscarvalho/monozukuri/commit/7d6f9818965d651405278dd80e11982fc75929ed))

## [1.48.3](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.48.2...v1.48.3) (2026-05-13)


### Bug Fixes

* **agent:** close mz-open-pr full_auto hang and expose hidden CLI commands ([#205](https://github.com/Viniciuscarvalho/monozukuri/issues/205)) ([6857eed](https://github.com/Viniciuscarvalho/monozukuri/commit/6857eed27e1fb50d6977cbd077d630076cf5eee7))

## [1.48.2](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.48.1...v1.48.2) (2026-05-12)


### Documentation

* **assets:** add hero GIF and dashboard screenshot to README ([#203](https://github.com/Viniciuscarvalho/monozukuri/issues/203)) ([776ba4b](https://github.com/Viniciuscarvalho/monozukuri/commit/776ba4b1a4254d9e2d8ff8d2592248d86e6f3b51))

## [1.48.1](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.48.0...v1.48.1) (2026-05-12)


### Documentation

* use agent-agnostic language across README and docs ([#201](https://github.com/Viniciuscarvalho/monozukuri/issues/201)) ([03e3f98](https://github.com/Viniciuscarvalho/monozukuri/commit/03e3f98c6a35eaca01347baf592648e271599798))

## [1.48.0](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.47.1...v1.48.0) (2026-05-12)


### Features

* **tui:** visual polish pass — unified border, token enforcement, braille spinner ([#198](https://github.com/Viniciuscarvalho/monozukuri/issues/198)) ([5f43ae4](https://github.com/Viniciuscarvalho/monozukuri/commit/5f43ae45890966b19cce846285c182dba7675fac))

## [1.47.1](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.47.0...v1.47.1) (2026-05-12)


### Documentation

* add user-facing reference docs and simplify README ([#197](https://github.com/Viniciuscarvalho/monozukuri/issues/197)) ([435c231](https://github.com/Viniciuscarvalho/monozukuri/commit/435c2314893369f2407ccd0c8d6b906819000229))

## [1.47.0](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.46.3...v1.47.0) (2026-05-12)


### Features

* **ci:** RC release channel — [@next](https://github.com/next) npm + monozukuri-next brew + promotion scripts ([#195](https://github.com/Viniciuscarvalho/monozukuri/issues/195)) ([b361919](https://github.com/Viniciuscarvalho/monozukuri/commit/b36191972bf6f25ee936628f91e3bc5956701395))

## [1.46.3](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.46.2...v1.46.3) (2026-05-11)


### Bug Fixes

* **run:** cycle-gate skips feature instead of aborting run + TUI unified grid ([#193](https://github.com/Viniciuscarvalho/monozukuri/issues/193)) ([a86dcc4](https://github.com/Viniciuscarvalho/monozukuri/commit/a86dcc449eab15d99176b78ac9b35e2c3775cfc2))

## [1.46.2](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.46.1...v1.46.2) (2026-05-11)


### Bug Fixes

* **prompt:** pre-render MONOZUKURI_* env vars into context before rich render ([#191](https://github.com/Viniciuscarvalho/monozukuri/issues/191)) ([a314a21](https://github.com/Viniciuscarvalho/monozukuri/commit/a314a213cefa30fbcff4891e9a3719c10a924b5b))

## [1.46.1](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.46.0...v1.46.1) (2026-05-11)


### Bug Fixes

* **prompt:** add MONOZUKURI_WORKTREE, _AUTONOMY, _FEATURE_ID to context pack ([#189](https://github.com/Viniciuscarvalho/monozukuri/issues/189)) ([72d9398](https://github.com/Viniciuscarvalho/monozukuri/commit/72d93984b687f9170bb9adbf52edd17912c833c7))

## [1.46.0](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.45.1...v1.46.0) (2026-05-11)


### Features

* **adapter:** add skill-native invocation path to adapter-claude-code (PR4) ([8ff8c15](https://github.com/Viniciuscarvalho/monozukuri/commit/8ff8c15513bcd3a580dbbd2b9a442338a7dffda7))
* **adapter:** skill-native invocation path + release-please v5 (PR4) ([2b26d3d](https://github.com/Viniciuscarvalho/monozukuri/commit/2b26d3d3cb6bb4a198846434592e82f89af0f33e))
* **adapters:** use CLI session auth for codex and gemini (drop API key requirement) ([#103](https://github.com/Viniciuscarvalho/monozukuri/issues/103)) ([9f88467](https://github.com/Viniciuscarvalho/monozukuri/commit/9f884676d28609779255687e1d3077857dd90d7d))
* add agent-blocker channel (EXIT_AGENT_BLOCKED=21) ([93b4697](https://github.com/Viniciuscarvalho/monozukuri/commit/93b46974489d34bc920544ea3a1b6caf7f055dc3))
* add agent-blocker channel (EXIT_AGENT_BLOCKED=21) ([ed75473](https://github.com/Viniciuscarvalho/monozukuri/commit/ed754733d93eda21bc884a96cb6ff674fa573422))
* add Codex, Gemini, Kiro adapters + pricing.yaml (Phases 4-6) ([f2ac1f6](https://github.com/Viniciuscarvalho/monozukuri/commit/f2ac1f606ddd4b0bf604dd9f0dcb360b43b40dd4))
* add doctor command improvements, exit-codes, and errors.sh ([e5ea5e9](https://github.com/Viniciuscarvalho/monozukuri/commit/e5ea5e937673476fed0576b728874f4cf9e208e7))
* add monozukuri agent subcommands + wizard init (Phase 7) ([877bf0b](https://github.com/Viniciuscarvalho/monozukuri/commit/877bf0b4ba768d2944cd12c1674805ec8491792c))
* add monozukuri doctor command ([e7cd75e](https://github.com/Viniciuscarvalho/monozukuri/commit/e7cd75e0fd903c313171ea255f8d4a28072f9067))
* add phase prompt templates and render.sh for multi-agent support ([cc163dd](https://github.com/Viniciuscarvalho/monozukuri/commit/cc163ddef66fb66cb761d0cf1a40e7471ef4f828))
* agent conformance suite + mock fixtures (Phase 3) ([008a996](https://github.com/Viniciuscarvalho/monozukuri/commit/008a996231b80f1a4747493659b06c6ba5864077))
* **agent:** discover project + global skills, route phase_to_skill via manifest ([#167](https://github.com/Viniciuscarvalho/monozukuri/issues/167)) ([aa03ee8](https://github.com/Viniciuscarvalho/monozukuri/commit/aa03ee8a9e5d59ed0334f5b265b36896d3fa26d1))
* **agent:** record allowed-tools in manifest and log at invocation ([#172](https://github.com/Viniciuscarvalho/monozukuri/issues/172)) ([115f25c](https://github.com/Viniciuscarvalho/monozukuri/commit/115f25cfc9ba9bd3258803c40077907c89d13773))
* **agent:** scan GEMINI.md as a project-conventions source ([#165](https://github.com/Viniciuscarvalho/monozukuri/issues/165)) ([ecb5633](https://github.com/Viniciuscarvalho/monozukuri/commit/ecb5633fdf6a828cc1571039ed4023af6581ae5a))
* **agent:** walk nested AGENTS.md in subpackages (depth ≤ 3) ([#166](https://github.com/Viniciuscarvalho/monozukuri/issues/166)) ([46f87ac](https://github.com/Viniciuscarvalho/monozukuri/commit/46f87acef552c6713d574b71e0dd89396f9e397f))
* bundle to-prd and grill-me skills (pre-flight workflow) ([045c467](https://github.com/Viniciuscarvalho/monozukuri/commit/045c4673df2e2bee17082dd2fb9bf9a20db4f33e))
* bundle to-prd and grill-me skills from mattpocock/skills ([a113324](https://github.com/Viniciuscarvalho/monozukuri/commit/a113324fb24eaf9e3c9d1cc84dc7b8d8dd1c6fd3))
* **ci-guard:** add CI watcher skill and scripts ([#125](https://github.com/Viniciuscarvalho/monozukuri/issues/125)) ([20425e4](https://github.com/Viniciuscarvalho/monozukuri/commit/20425e4be38c7ef4bdda75090f73d2340b53a557))
* **cli:** surface skills manifest in doctor + status ([#171](https://github.com/Viniciuscarvalho/monozukuri/issues/171)) ([0cf8de2](https://github.com/Viniciuscarvalho/monozukuri/commit/0cf8de289fddb02e9918af4d5ec6834d2bebf698))
* **cli:** TUI Day 1 — emit phase.token_update + phase.completed from stream-parse ([#176](https://github.com/Viniciuscarvalho/monozukuri/issues/176)) ([c399003](https://github.com/Viniciuscarvalho/monozukuri/commit/c3990034bb01be9f4e36f414c9ff3d126b2ac0b3))
* configurable schema reprompt budget + human escalation ([682f63f](https://github.com/Viniciuscarvalho/monozukuri/commit/682f63fb4ef31c79c83678741eaef8f5cf76c6ca))
* configurable schema reprompt budget + human escalation path ([6d974f5](https://github.com/Viniciuscarvalho/monozukuri/commit/6d974f5d3e2a228d0419cea7a80e21f3c01da92f))
* **contract:** close full_auto blocker contract gaps ([#95](https://github.com/Viniciuscarvalho/monozukuri/issues/95)) ([d9f158d](https://github.com/Viniciuscarvalho/monozukuri/commit/d9f158d0aa5dfff778caecf8b0d5a0295af4d82d))
* **contract:** gap 3 — adapter contract v1.0.0, claude-code improvements, aider adapter (ADR-012) ([cdfee8e](https://github.com/Viniciuscarvalho/monozukuri/commit/cdfee8ea67cd894caead3f164401542c0d822aa4))
* **contract:** gap 3 — adapter contract v1.0.0, claude-code improvements, aider adapter (ADR-012) ([0edde5d](https://github.com/Viniciuscarvalho/monozukuri/commit/0edde5d59905161f8b7ae75e7805ac9fb0e8346d))
* **conventions:** auto-sync AGENTS.md after each run (PR4) ([793a678](https://github.com/Viniciuscarvalho/monozukuri/commit/793a6787943ad6a58da78737ec13c290724e6e45))
* **conventions:** generate AGENTS.md from learning store (PR3) ([801ec1e](https://github.com/Viniciuscarvalho/monozukuri/commit/801ec1e893770dcf028ae4517a02c1910f84b279))
* **conventions:** read and inject project convention files ([0da6119](https://github.com/Viniciuscarvalho/monozukuri/commit/0da611918f5f6a83689a9110d7c70de975ec5587))
* **conventions:** read and inject project convention files (PR1) ([a02f7c8](https://github.com/Viniciuscarvalho/monozukuri/commit/a02f7c88e6fbd4c1925a048616aec21e83dd3897))
* **conventions:** seed AGENTS.md and add it to Claude Code adapter native context ([b987513](https://github.com/Viniciuscarvalho/monozukuri/commit/b9875133641939cbe606ad1b8f562ceb6ba7ed6c))
* **conventions:** seed AGENTS.md and align Claude Code adapter with multi-agent convention surface ([d1e8f7a](https://github.com/Viniciuscarvalho/monozukuri/commit/d1e8f7a64630c6c2f3a1d6d74a7105f1c1a5e032))
* **conventions:** suppress duplicate context per adapter (PR2) ([2437140](https://github.com/Viniciuscarvalho/monozukuri/commit/2437140f934295ae8135b5391f020b4ab3863507))
* **conventions:** surface promotion candidates as convention entries (PR5) ([7782e3a](https://github.com/Viniciuscarvalho/monozukuri/commit/7782e3abd47528d53b52472f578499d89b0c7e31))
* **conventions:** surface promotion candidates as convention entries (PR5) ([629488f](https://github.com/Viniciuscarvalho/monozukuri/commit/629488fd240414948a65141705ba3fd555aff40e))
* enable Ink terminal UI via Node dispatcher in Homebrew ([3a9e226](https://github.com/Viniciuscarvalho/monozukuri/commit/3a9e226006585d425701b1253141df58f881adf6))
* enable Ink terminal UI via Node dispatcher in Homebrew ([8c12967](https://github.com/Viniciuscarvalho/monozukuri/commit/8c12967d1158674256e426b53752bf46d14c95d2))
* **failure:** gap 2 — stratified failure handling, idempotent resumption, CI poll (ADR-013/014) ([92a4ceb](https://github.com/Viniciuscarvalho/monozukuri/commit/92a4ceb155d17bb3f175e98c28bd1d8187a08250))
* **failure:** gap 2 — stratified failure handling, idempotent resumption, CI poll (ADR-013/014) ([e63d1eb](https://github.com/Viniciuscarvalho/monozukuri/commit/e63d1eba70459021c4a57a8374ce55a1783ae21d))
* Gap 5 - L5 Measurability Infrastructure ([a86f766](https://github.com/Viniciuscarvalho/monozukuri/commit/a86f76677d429c85b4e5a7250733ae4dd039ebf9))
* **gap3:** phase-aware templates, context-pack, registry, render node path ([d1396a9](https://github.com/Viniciuscarvalho/monozukuri/commit/d1396a941fb65babe0ee741e9492ec1773e078bb))
* **gap4:** per-phase routing config, routing_load, and threshold-gated routing suggest (ADR-015) ([30cec4f](https://github.com/Viniciuscarvalho/monozukuri/commit/30cec4f26e8b9341cfddfdbc6bc85e691126e96d))
* **gap4:** per-phase routing config, routing_load, and threshold-gated suggest (ADR-015) ([1272e08](https://github.com/Viniciuscarvalho/monozukuri/commit/1272e08128e4bc4dea41633bca256b3f36da0a20))
* **gap6:** run review — export, open, list subcommands (ADR-015) ([7b6e03c](https://github.com/Viniciuscarvalho/monozukuri/commit/7b6e03ca322f4ede636fcbac96f460caef175b17))
* **gap6:** run review — export, open, list subcommands (ADR-015) ([8af8917](https://github.com/Viniciuscarvalho/monozukuri/commit/8af8917b5fb201e1230d43cf9a9de8acac132e4b))
* **gap7:** implicit-dep detection + ingestion validator (ADR-015) ([5852a39](https://github.com/Viniciuscarvalho/monozukuri/commit/5852a392597df28ce150a65ee49ffd4ef3eb6d94))
* **gap7:** implicit-dep detection + ingestion validator (ADR-015) ([1a92ac9](https://github.com/Viniciuscarvalho/monozukuri/commit/1a92ac927d7b983979ca719c423321cd4c2cfa60))
* **gap8:** deferred status in FeatureList — yellow icon and label in completed list ([b25aaf1](https://github.com/Viniciuscarvalho/monozukuri/commit/b25aaf1676a8e8223fe4604bf10ae6d4ee0f181b))
* **gap8:** pricing and calibration — L5 cost honesty ([e930e07](https://github.com/Viniciuscarvalho/monozukuri/commit/e930e0763141eca52d999ab834c746a00a6144c9))
* **gap8:** pricing and calibration — L5 cost honesty (ADR-008) ([f066ffe](https://github.com/Viniciuscarvalho/monozukuri/commit/f066ffef006f07f16fa68eb05c7cb642ac850d1c))
* implement Gap 5 - L5 measurability infrastructure ([996c0e9](https://github.com/Viniciuscarvalho/monozukuri/commit/996c0e976dc3e986720cb305985ff679a755eea7))
* initial release — Monozukuri v1.0.0 ([d181a07](https://github.com/Viniciuscarvalho/monozukuri/commit/d181a07647388aa07f4042bd0d4ea7f032a8e234))
* Ink TUI, repo tooling, CI workflows, Bats harness, JSONL events ([1aa5caf](https://github.com/Viniciuscarvalho/monozukuri/commit/1aa5cafde4a7c452e2c53505726ca9fa1ffbc6a7))
* introduce multi-agent adapter contract (Phase 2) ([b143abd](https://github.com/Viniciuscarvalho/monozukuri/commit/b143abd84862c6fbb34ffedef3293c25b14fc162))
* M2 UX polish + M5 launch prep ([3a35c4f](https://github.com/Viniciuscarvalho/monozukuri/commit/3a35c4f6ad2ccb8483e96a6a577bb67ae63e0dfe))
* **memory:** workflow memory harness + README skills documentation (PR5) ([088a305](https://github.com/Viniciuscarvalho/monozukuri/commit/088a30590541702259e79ef2bfeda95587766c1d))
* **memory:** workflow memory harness + README skills documentation (PR5) ([7ced242](https://github.com/Viniciuscarvalho/monozukuri/commit/7ced242e2fa6205106e7597fc65ca527f938fd42))
* **orchestrator:** fix skill selection and add AGENTS.md discovery ([#90](https://github.com/Viniciuscarvalho/monozukuri/issues/90)) ([f3dd99e](https://github.com/Viniciuscarvalho/monozukuri/commit/f3dd99e42459b2b6493525d066a27b905c4b599c))
* **phase-a:** loop safety for unattended runs on codex/gemini ([#105](https://github.com/Viniciuscarvalho/monozukuri/issues/105)) ([2d27ddd](https://github.com/Viniciuscarvalho/monozukuri/commit/2d27ddd4b97a2838f5dcc740c4da7a8ebfa60251))
* **phase-b:** seed per-adapter context files on monozukuri init ([#106](https://github.com/Viniciuscarvalho/monozukuri/issues/106)) ([b92a614](https://github.com/Viniciuscarvalho/monozukuri/commit/b92a614e61c3cd6f7284c330816f93c7b7291c9a))
* **phase-c:** multi-project ops — budget ceiling, kill switch, summary, concurrency ([#109](https://github.com/Viniciuscarvalho/monozukuri/issues/109)) ([d164a8e](https://github.com/Viniciuscarvalho/monozukuri/commit/d164a8eb6c7bc99ff296c383e21a2c4d673c2df1))
* **phase-d:** release-gate truthfulness + CI enforcement ([#111](https://github.com/Viniciuscarvalho/monozukuri/issues/111)) ([e834c1c](https://github.com/Viniciuscarvalho/monozukuri/commit/e834c1c6088d9ba2b8c12b491a72a32cd0b876fc))
* **phase-e:** state-version stamping + opt-in telemetry ([#113](https://github.com/Viniciuscarvalho/monozukuri/issues/113)) ([975fdac](https://github.com/Viniciuscarvalho/monozukuri/commit/975fdacf97fde6837af4000015f96e6e72a78126))
* **phase-f:** schema render parity for codex/gemini ([#115](https://github.com/Viniciuscarvalho/monozukuri/issues/115)) ([14a1e77](https://github.com/Viniciuscarvalho/monozukuri/commit/14a1e770760bb3dbd6b1e5589ac88dfdd6e32bf7))
* **phase-g:** plan-doc reconciliation — env-var cleanup, CLAUDE.md, archive Path B ([#118](https://github.com/Viniciuscarvalho/monozukuri/issues/118)) ([f413fba](https://github.com/Viniciuscarvalho/monozukuri/commit/f413fba5049548d1337574d449da50274ebc641a))
* **phase3,adapters:** generalize Ralph Loop to all adapters via agent_run_phase ([#101](https://github.com/Viniciuscarvalho/monozukuri/issues/101)) ([462fd06](https://github.com/Viniciuscarvalho/monozukuri/commit/462fd0647e7c6e98a37120124a0078273b92be9e))
* **pipeline:** phase-split mz-* skills, schema compat, setup fix ([#124](https://github.com/Viniciuscarvalho/monozukuri/issues/124)) ([76be5b7](https://github.com/Viniciuscarvalho/monozukuri/commit/76be5b7d250a59e9a0418c1b736e6c2cd695ffc9))
* **qa:** Layer 4 backwards compat + fix cmd/resume.sh module loading ([#80](https://github.com/Viniciuscarvalho/monozukuri/issues/80)) ([07b0bc9](https://github.com/Viniciuscarvalho/monozukuri/commit/07b0bc9e4ca243e723d88091f2cb9e3d53e8fb68))
* **qa:** release gate harness — layers 1, 2 & 3 (PR 0→2) ([#78](https://github.com/Viniciuscarvalho/monozukuri/issues/78)) ([baac069](https://github.com/Viniciuscarvalho/monozukuri/commit/baac06929919eb7de747d1df8cc2a57009b30c2d))
* **qa:** replay-based mock infra + property tests + Layer 7 conformance (no CI cost) ([#161](https://github.com/Viniciuscarvalho/monozukuri/issues/161)) ([8edde0a](https://github.com/Viniciuscarvalho/monozukuri/commit/8edde0aa8df97a32f92bc65c274066f337733e7d))
* **resilience:** auto-mode schema resilience — paused recovery, retry command, UI visibility ([#132](https://github.com/Viniciuscarvalho/monozukuri/issues/132)) ([824b1bf](https://github.com/Viniciuscarvalho/monozukuri/commit/824b1bf0d800aed346e5757938a30d23aeafd258))
* **run:** auto-invoke skill-discovery on session start ([#170](https://github.com/Viniciuscarvalho/monozukuri/issues/170)) ([0c57136](https://github.com/Viniciuscarvalho/monozukuri/commit/0c5713622106a9e23faac6023b836251f3c76857))
* **schema:** gap 1 — phase artifact schemas and validation (ADR-012) ([6103b82](https://github.com/Viniciuscarvalho/monozukuri/commit/6103b826a7150338c6985bbeac169beb5130fb7b))
* **schema:** Gap 1 — phase artifact schemas and validation (ADR-012) ([1e1ae12](https://github.com/Viniciuscarvalho/monozukuri/commit/1e1ae12003a623dc4a07f34c47d36efd74ac03ae))
* **setup:** add monozukuri setup installer command (PR3) ([62f83b3](https://github.com/Viniciuscarvalho/monozukuri/commit/62f83b3f374960f79a949b1aba3a86ed00074e68))
* **setup:** add monozukuri setup installer command (PR3) ([9fde8bc](https://github.com/Viniciuscarvalho/monozukuri/commit/9fde8bc3f7bd04eaee0067015120efc653de3286))
* **skills:** publishable mz-* skill versioning and packaging ([#94](https://github.com/Viniciuscarvalho/monozukuri/issues/94)) ([c8090da](https://github.com/Viniciuscarvalho/monozukuri/commit/c8090da622b7e11eeed8bdf47c1c19906425e3d2))
* **skills:** scaffold 8 mz-* phase skills (PR1 of skills plan) ([200cc90](https://github.com/Viniciuscarvalho/monozukuri/commit/200cc90a3ee2cf6afc2b0af3b77620946c55a6e3))
* **skills:** scaffold 8 mz-* phase skills (PR1 of skills plan) ([ebf01a9](https://github.com/Viniciuscarvalho/monozukuri/commit/ebf01a9276f4bb7dcdf62748f93fcba047642f78))
* surface agent identity in TUI + stand up Jest test infra (Phase 8) ([95ec400](https://github.com/Viniciuscarvalho/monozukuri/commit/95ec40024841084a81b7dea12ca4f2ea8c50af0c))
* **tui:** TUI by default, silence bash render layer ([#92](https://github.com/Viniciuscarvalho/monozukuri/issues/92)) ([e79a683](https://github.com/Viniciuscarvalho/monozukuri/commit/e79a683042d614111e98eee2b1fea8039e99067b))
* **ui:** consolidate TUI Days 2-5 + composite screenshot into main ([#182](https://github.com/Viniciuscarvalho/monozukuri/issues/182)) ([e7a0c64](https://github.com/Viniciuscarvalho/monozukuri/commit/e7a0c64948345fff758e05946b0f6640ea480d13))
* **ui:** surface skills, workflow memory, and setup events in TUI (PR6) ([e75bc65](https://github.com/Viniciuscarvalho/monozukuri/commit/e75bc65fbf7010c8d012727b9e4ab1850b8385e1))
* **ui:** surface skills, workflow memory, and setup events in TUI (PR6) ([8116c7b](https://github.com/Viniciuscarvalho/monozukuri/commit/8116c7b98e37ef27df2f35c88e988e90908d0f78))
* **ux:** execution visibility — phase events, tool stream, web dashboard ([#120](https://github.com/Viniciuscarvalho/monozukuri/issues/120)) ([981c1d4](https://github.com/Viniciuscarvalho/monozukuri/commit/981c1d4967ee738af4a47743d5eaaa92ae57183d))
* **v1.0:** hardening — full_auto contract, crash recovery, skill versioning, CI gate, cosmetic fixes ([#159](https://github.com/Viniciuscarvalho/monozukuri/issues/159)) ([1635003](https://github.com/Viniciuscarvalho/monozukuri/commit/163500306dcc08c55b1015f090b6c7b03e36a78b))
* **v1:** launch-prep gap fixes — doctor, skill overrides, design tokens, web log pane ([#152](https://github.com/Viniciuscarvalho/monozukuri/issues/152)) ([bbeef30](https://github.com/Viniciuscarvalho/monozukuri/commit/bbeef30004fa47e7dd5c4f20219185a6e76f2b07))
* **validator:** couple validate.sh to skills/*-validation.md aliases (PR2) ([d52a25a](https://github.com/Viniciuscarvalho/monozukuri/commit/d52a25a0909e9488fe9bb0f7e08219a3b943dbef))
* **validator:** couple validate.sh to skills/*-validation.md aliases (PR2) ([20a55ef](https://github.com/Viniciuscarvalho/monozukuri/commit/20a55efcc5f0324a4a390bf581439cb513db59a9))


### Bug Fixes

* **adapters:** event stream parity for Codex, Gemini, Kiro, Aider ([#122](https://github.com/Viniciuscarvalho/monozukuri/issues/122)) ([ca80cef](https://github.com/Viniciuscarvalho/monozukuri/commit/ca80cef0717db3c2293ac6b02d129b8c2fabb0c0))
* bleed-stop bundle ([#84](https://github.com/Viniciuscarvalho/monozukuri/issues/84)) ([f2b90ff](https://github.com/Viniciuscarvalho/monozukuri/commit/f2b90ff415108a03767e578308c5e8362a290ffd))
* **ci:** extract PR number from release-please JSON output for auto-merge ([#72](https://github.com/Viniciuscarvalho/monozukuri/issues/72)) ([bf87666](https://github.com/Viniciuscarvalho/monozukuri/commit/bf87666ddb51517cc7d0f6c04470baa932c5ecc3))
* **ci:** pass --repo to gh pr merge to avoid missing git context ([#74](https://github.com/Viniciuscarvalho/monozukuri/issues/74)) ([6e3e325](https://github.com/Viniciuscarvalho/monozukuri/commit/6e3e3251717359442b7fb799c7dab3f3df33e3f8))
* **ci:** suppress monozukuri-vX prefix in release-please v5 tags ([8a7d11e](https://github.com/Viniciuscarvalho/monozukuri/commit/8a7d11e78715df6ea844998bc87e2b97bc853192))
* **ci:** suppress monozukuri-vX prefix in release-please v5 tags ([64fe15d](https://github.com/Viniciuscarvalho/monozukuri/commit/64fe15decd1e43018c36b230484b96753f47f92b))
* **ci:** use PAT for release-please to trigger Actions on release commits ([#141](https://github.com/Viniciuscarvalho/monozukuri/issues/141)) ([a561359](https://github.com/Viniciuscarvalho/monozukuri/commit/a5613596df4e26145157ddb3cc86503a92f3e565))
* create bump branch before writing formula in homebrew-tap workflow ([e7ee2e8](https://github.com/Viniciuscarvalho/monozukuri/commit/e7ee2e836e03159d6c8d652011183d899a5ad566))
* export MONOZUKURI_PHASE, clarify Phase 0 log label, capture schema mismatches ([#88](https://github.com/Viniciuscarvalho/monozukuri/issues/88)) ([daa83fa](https://github.com/Viniciuscarvalho/monozukuri/commit/daa83facafbb4ab6cc1c3359a269e706ff023318))
* fold error status into failed counter across all three reporters ([e6e5762](https://github.com/Viniciuscarvalho/monozukuri/commit/e6e57626e308e2079fef48ed51ca8f1729e46f62))
* fold error status into failed counter across all three reporters ([05093f4](https://github.com/Viniciuscarvalho/monozukuri/commit/05093f48ecbd84acb9beaea5db87056c471ad701))
* **homebrew:** remove missing ui/dist/package.json from install step ([#82](https://github.com/Viniciuscarvalho/monozukuri/issues/82)) ([8d06c6a](https://github.com/Viniciuscarvalho/monozukuri/commit/8d06c6ac32a448db5a0d996d2e9cb9f6e4e3e786))
* **memory:** workflow_memory_prepare crash — exports lost in subshell ([747c8e7](https://github.com/Viniciuscarvalho/monozukuri/commit/747c8e78403022b41c0d776d2cca2e8ef98de6c8))
* **memory:** workflow_memory_prepare must export to parent process ([23f629a](https://github.com/Viniciuscarvalho/monozukuri/commit/23f629a45db412ad0de2c8cf5f172e9dcffd05c6))
* mermaid diagram + homebrew formula v1.0.0 checksum ([52dba02](https://github.com/Viniciuscarvalho/monozukuri/commit/52dba0231b62e735ea173e8606c79747b7f9c997))
* **metrics:** fix 8 pre-existing test failures in metrics module ([fff0494](https://github.com/Viniciuscarvalho/monozukuri/commit/fff0494c86cd22e656d0c8cbb7d76797c170293a))
* **metrics:** remove comment drift from linter revert in metrics.sh ([4a1a628](https://github.com/Viniciuscarvalho/monozukuri/commit/4a1a628bac077a629b7bdb31abcafc110049e203))
* MONOZUKURI_PHASE export, Phase 0 log label, learning store schema capture ([#86](https://github.com/Viniciuscarvalho/monozukuri/issues/86)) ([9b07df5](https://github.com/Viniciuscarvalho/monozukuri/commit/9b07df58839f16888e6bc4ed522d9133273d51cc))
* **qa:** fix release gate layer 2 failures ([#146](https://github.com/Viniciuscarvalho/monozukuri/issues/146)) ([097504b](https://github.com/Viniciuscarvalho/monozukuri/commit/097504b0817319ff17dfdee3e7dac7b31dac6e18))
* **qa:** skip doctor check in CI — gh/claude absent on runners ([#148](https://github.com/Viniciuscarvalho/monozukuri/issues/148)) ([0e9fb20](https://github.com/Viniciuscarvalho/monozukuri/commit/0e9fb2020482dfbf6c97d5b52da9a6883be98b1c))
* **qa:** unblock Release gate — three pre-existing Layer 2 bugs ([#162](https://github.com/Viniciuscarvalho/monozukuri/issues/162)) ([e2f406e](https://github.com/Viniciuscarvalho/monozukuri/commit/e2f406e28ad66a3a48387e43c338c9a7832ea34b))
* resolve 8 runtime bugs in full-auto PR creation flow ([33ec376](https://github.com/Viniciuscarvalho/monozukuri/commit/33ec3764f69f888446618595996149ed1aec64d0))
* **resume,learning:** close determinism gaps ([#96](https://github.com/Viniciuscarvalho/monozukuri/issues/96)) ([5c38d56](https://github.com/Viniciuscarvalho/monozukuri/commit/5c38d56a221a87db709d1825b618ba935d66fb0e))
* **run:** hard-block run when known-incompatible skill is configured ([#187](https://github.com/Viniciuscarvalho/monozukuri/issues/187)) ([7770915](https://github.com/Viniciuscarvalho/monozukuri/commit/7770915d6f235649cef64bea81681ff441a5b8c3))
* **setup:** stop TUI from eating keystrokes; accept bare positional verbs ([#129](https://github.com/Viniciuscarvalho/monozukuri/issues/129)) ([69999ba](https://github.com/Viniciuscarvalho/monozukuri/commit/69999bab363560d4a4bb0ea1361d7db6915a4915))
* stream-json --verbose and retry --all reason filter ([#144](https://github.com/Viniciuscarvalho/monozukuri/issues/144)) ([9f639f0](https://github.com/Viniciuscarvalho/monozukuri/commit/9f639f07b0dbb58c5eea80bed4292d2b3d29e3dc))
* symlink .claude/skills into worktrees and wire Ink TUI ([#139](https://github.com/Viniciuscarvalho/monozukuri/issues/139)) ([b7e05e6](https://github.com/Viniciuscarvalho/monozukuri/commit/b7e05e6d7bc2bb625a9e9f18a8531d9cb16f89e0))
* three bugs in orchestrator ↔ skill contract (diff gate, path alignment, doctor warning) ([#185](https://github.com/Viniciuscarvalho/monozukuri/issues/185)) ([e47371c](https://github.com/Viniciuscarvalho/monozukuri/commit/e47371cf68ade19069381293920bbafeeab1e180))
* **tui:** stop EIO crash on exit and mislabeled paused runs ([#150](https://github.com/Viniciuscarvalho/monozukuri/issues/150)) ([9856ecf](https://github.com/Viniciuscarvalho/monozukuri/commit/9856ecfa10de0ec569c9a8ac23fbb67963c380ee))
* **ui:** inject createRequire banner to fix CJS dynamic-require failure in ESM bundle ([#68](https://github.com/Viniciuscarvalho/monozukuri/issues/68)) ([59a5985](https://github.com/Viniciuscarvalho/monozukuri/commit/59a59856943207866c8221e41417e915e3a46d73))
* **ui:** open /dev/tty for Ink keyboard input; avoid raw mode error in non-TTY context ([7ca35f5](https://github.com/Viniciuscarvalho/monozukuri/commit/7ca35f5054542c1f10becd9b9e3004e45868ef93))
* **ui:** open /dev/tty for Ink keyboard input; avoid raw mode error in non-TTY context ([82ee32b](https://github.com/Viniciuscarvalho/monozukuri/commit/82ee32b855700edb878a8469b2cda147c4e89a7a))
* **ui:** stub react-devtools-core to eliminate missing-package error at runtime ([#66](https://github.com/Viniciuscarvalho/monozukuri/issues/66)) ([f312c48](https://github.com/Viniciuscarvalho/monozukuri/commit/f312c48aca50a837116301f472b54980f24af534))
* **ui:** three-PR sequence — build, polish, signals ([#70](https://github.com/Viniciuscarvalho/monozukuri/issues/70)) ([13fcbb2](https://github.com/Viniciuscarvalho/monozukuri/commit/13fcbb24ee18dd45673efc5d5fb7c32bfdf5db8e))
* use injected github client in github-script, drop manual Octokit ([824c82e](https://github.com/Viniciuscarvalho/monozukuri/commit/824c82ea179c88cd5cafec6909b739417cd65cb4))


### Refactoring

* **arch:** deepen modules C2-C8 + fix pricing budget ceiling ([#134](https://github.com/Viniciuscarvalho/monozukuri/issues/134)) ([821453e](https://github.com/Viniciuscarvalho/monozukuri/commit/821453e8ff39f696a3687eb0da5a4a0fb8d761a4))
* consolidate scripts/lib/ into lib/ canonical tree ([165a9f2](https://github.com/Viniciuscarvalho/monozukuri/commit/165a9f2fd6b1ff9634368625e0d0b41950b633d6))
* **conventions:** consolidate file-IO seam and add learning entry contract ([835a651](https://github.com/Viniciuscarvalho/monozukuri/commit/835a651b3f313b6c54c7ae0992d0e4465a444cca))
* **conventions:** consolidate file-IO seam and add learning entry contract ([9fe0af4](https://github.com/Viniciuscarvalho/monozukuri/commit/9fe0af4da43f46794de9d03d8cd1dfd7767a07ef))
* deepen architecture ([453e7f9](https://github.com/Viniciuscarvalho/monozukuri/commit/453e7f9c2aa9f63761f16c1acf3b0903db9cac70))
* deepen architecture — 5 seams extracted from pipeline.sh ([19c7ca0](https://github.com/Viniciuscarvalho/monozukuri/commit/19c7ca042f2309acb5758e0028635bef4fc78653))
* M1.1 directory restructure — cmd/ + lib/ split ([97da855](https://github.com/Viniciuscarvalho/monozukuri/commit/97da8559c8e7d5a654051579778948fda1945e07))
* **render:** replace node-based renderer with jq/awk/bash implementation ([dee9786](https://github.com/Viniciuscarvalho/monozukuri/commit/dee9786347554bd78b8c92ed7bd5a3203bf101e0))


### Documentation

* add ADR template ([bb47263](https://github.com/Viniciuscarvalho/monozukuri/commit/bb472632d61257ee96eb59b6799843da5c71a473))
* add vision, capability ladder, and roadmap ([42d85e5](https://github.com/Viniciuscarvalho/monozukuri/commit/42d85e554a5d253865be472ad6a8753bbb9d3918))
* **adr:** 012 — adapter contract & phase artifact schemas ([d40fce6](https://github.com/Viniciuscarvalho/monozukuri/commit/d40fce66990d61fe5aa48f1df11a3d82530358d3))
* **adr:** 013 — failure handling, idempotent resumption, rate-limit policy ([a35763b](https://github.com/Viniciuscarvalho/monozukuri/commit/a35763bc9a1601ad52a3be0511c88e7d5ccb188d))
* **adr:** 014 — terminal state (CI-green PR) & L5 metric ([b919274](https://github.com/Viniciuscarvalho/monozukuri/commit/b919274c54273db964234959895d018c840051c6))
* **adr:** 015 — routing, implicit deps, and review surface ([66dad9a](https://github.com/Viniciuscarvalho/monozukuri/commit/66dad9a309aff70d3767f32ba4f9ceb49dd04441))
* **adr:** 016 — 13-week plan & capability ladder commitments ([3ddbe6d](https://github.com/Viniciuscarvalho/monozukuri/commit/3ddbe6df6253c66de7727a03ca462a80e1c98664))
* document retry, resume-paused, stop, and 7 other undocumented subcommands ([#136](https://github.com/Viniciuscarvalho/monozukuri/issues/136)) ([197a3c5](https://github.com/Viniciuscarvalho/monozukuri/commit/197a3c59e1f589f745940c00e2c92e44b525073a))
* expand README with highlights, models, project layout, dev, and contributing sections ([789b943](https://github.com/Viniciuscarvalho/monozukuri/commit/789b9438da9dd9362c07d601f174fbd88c2b96a7))
* land grilled vision decisions (vision, ladder, ADRs 012-016) ([9ab089e](https://github.com/Viniciuscarvalho/monozukuri/commit/9ab089ed32476f9c55e693aa06e08908201ee35c))
* rewrite README and CHANGELOG for multi-agent v1.2.0 ([a72f6e9](https://github.com/Viniciuscarvalho/monozukuri/commit/a72f6e93d91388913bd6287aaf4bc04e12dc01e6))
* rewrite README and CHANGELOG for multi-agent v1.2.0 (Phase 9) ([1b88919](https://github.com/Viniciuscarvalho/monozukuri/commit/1b8891966874c637343f8a0dd114c1a27cd3e50d))
* unify on AGENTS.md (symlink CLAUDE/GEMINI) + verified content ([#163](https://github.com/Viniciuscarvalho/monozukuri/issues/163)) ([7cdb12a](https://github.com/Viniciuscarvalho/monozukuri/commit/7cdb12a97d407efde8502e6e4b468c332b65a0e2))

## [1.45.1](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.45.0...v1.45.1) (2026-05-11)


### Bug Fixes

* three bugs in orchestrator ↔ skill contract (diff gate, path alignment, doctor warning) ([#185](https://github.com/Viniciuscarvalho/monozukuri/issues/185)) ([e47371c](https://github.com/Viniciuscarvalho/monozukuri/commit/e47371cf68ade19069381293920bbafeeab1e180))

## [1.45.0](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.44.0...v1.45.0) (2026-05-11)


### Features

* **ui:** consolidate TUI Days 2-5 + composite screenshot into main ([#182](https://github.com/Viniciuscarvalho/monozukuri/issues/182)) ([e7a0c64](https://github.com/Viniciuscarvalho/monozukuri/commit/e7a0c64948345fff758e05946b0f6640ea480d13))

## [1.44.0](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.43.0...v1.44.0) (2026-05-11)


### Features

* **agent:** record allowed-tools in manifest and log at invocation ([#172](https://github.com/Viniciuscarvalho/monozukuri/issues/172)) ([115f25c](https://github.com/Viniciuscarvalho/monozukuri/commit/115f25cfc9ba9bd3258803c40077907c89d13773))
* **cli:** TUI Day 1 — emit phase.token_update + phase.completed from stream-parse ([#176](https://github.com/Viniciuscarvalho/monozukuri/issues/176)) ([c399003](https://github.com/Viniciuscarvalho/monozukuri/commit/c3990034bb01be9f4e36f414c9ff3d126b2ac0b3))

## [1.43.0](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.42.0...v1.43.0) (2026-05-11)


### Features

* **cli:** surface skills manifest in doctor + status ([#171](https://github.com/Viniciuscarvalho/monozukuri/issues/171)) ([0cf8de2](https://github.com/Viniciuscarvalho/monozukuri/commit/0cf8de289fddb02e9918af4d5ec6834d2bebf698))

## [1.42.0](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.41.0...v1.42.0) (2026-05-11)


### Features

* **run:** auto-invoke skill-discovery on session start ([#170](https://github.com/Viniciuscarvalho/monozukuri/issues/170)) ([0c57136](https://github.com/Viniciuscarvalho/monozukuri/commit/0c5713622106a9e23faac6023b836251f3c76857))

## [1.41.0](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.40.0...v1.41.0) (2026-05-11)


### Features

* **agent:** discover project + global skills, route phase_to_skill via manifest ([#167](https://github.com/Viniciuscarvalho/monozukuri/issues/167)) ([aa03ee8](https://github.com/Viniciuscarvalho/monozukuri/commit/aa03ee8a9e5d59ed0334f5b265b36896d3fa26d1))
* **agent:** walk nested AGENTS.md in subpackages (depth ≤ 3) ([#166](https://github.com/Viniciuscarvalho/monozukuri/issues/166)) ([46f87ac](https://github.com/Viniciuscarvalho/monozukuri/commit/46f87acef552c6713d574b71e0dd89396f9e397f))

## [1.40.0](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.39.1...v1.40.0) (2026-05-11)


### Features

* **agent:** scan GEMINI.md as a project-conventions source ([#165](https://github.com/Viniciuscarvalho/monozukuri/issues/165)) ([ecb5633](https://github.com/Viniciuscarvalho/monozukuri/commit/ecb5633fdf6a828cc1571039ed4023af6581ae5a))

## [1.39.1](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.39.0...v1.39.1) (2026-05-10)


### Documentation

* unify on AGENTS.md (symlink CLAUDE/GEMINI) + verified content ([#163](https://github.com/Viniciuscarvalho/monozukuri/issues/163)) ([7cdb12a](https://github.com/Viniciuscarvalho/monozukuri/commit/7cdb12a97d407efde8502e6e4b468c332b65a0e2))

## [1.39.0](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.38.0...v1.39.0) (2026-05-10)


### Features

* **qa:** replay-based mock infra + property tests + Layer 7 conformance (no CI cost) ([#161](https://github.com/Viniciuscarvalho/monozukuri/issues/161)) ([8edde0a](https://github.com/Viniciuscarvalho/monozukuri/commit/8edde0aa8df97a32f92bc65c274066f337733e7d))
* **v1.0:** hardening — full_auto contract, crash recovery, skill versioning, CI gate, cosmetic fixes ([#159](https://github.com/Viniciuscarvalho/monozukuri/issues/159)) ([1635003](https://github.com/Viniciuscarvalho/monozukuri/commit/163500306dcc08c55b1015f090b6c7b03e36a78b))


### Bug Fixes

* **qa:** unblock Release gate — three pre-existing Layer 2 bugs ([#162](https://github.com/Viniciuscarvalho/monozukuri/issues/162)) ([e2f406e](https://github.com/Viniciuscarvalho/monozukuri/commit/e2f406e28ad66a3a48387e43c338c9a7832ea34b))

## [1.38.0](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.37.8...v1.38.0) (2026-05-09)


### Features

* **v1:** launch-prep gap fixes — doctor, skill overrides, design tokens, web log pane ([#152](https://github.com/Viniciuscarvalho/monozukuri/issues/152)) ([bbeef30](https://github.com/Viniciuscarvalho/monozukuri/commit/bbeef30004fa47e7dd5c4f20219185a6e76f2b07))

## [1.37.8](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.37.7...v1.37.8) (2026-05-08)


### Bug Fixes

* **tui:** stop EIO crash on exit and mislabeled paused runs ([#150](https://github.com/Viniciuscarvalho/monozukuri/issues/150)) ([9856ecf](https://github.com/Viniciuscarvalho/monozukuri/commit/9856ecfa10de0ec569c9a8ac23fbb67963c380ee))

## [1.37.7](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.37.6...v1.37.7) (2026-05-08)


### Bug Fixes

* **qa:** skip doctor check in CI — gh/claude absent on runners ([#148](https://github.com/Viniciuscarvalho/monozukuri/issues/148)) ([0e9fb20](https://github.com/Viniciuscarvalho/monozukuri/commit/0e9fb2020482dfbf6c97d5b52da9a6883be98b1c))

## [1.37.6](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.37.5...v1.37.6) (2026-05-08)


### Bug Fixes

* **qa:** fix release gate layer 2 failures ([#146](https://github.com/Viniciuscarvalho/monozukuri/issues/146)) ([097504b](https://github.com/Viniciuscarvalho/monozukuri/commit/097504b0817319ff17dfdee3e7dac7b31dac6e18))

## [1.37.5](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.37.4...v1.37.5) (2026-05-08)


### Bug Fixes

* stream-json --verbose and retry --all reason filter ([#144](https://github.com/Viniciuscarvalho/monozukuri/issues/144)) ([9f639f0](https://github.com/Viniciuscarvalho/monozukuri/commit/9f639f07b0dbb58c5eea80bed4292d2b3d29e3dc))

## [1.37.4](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.37.3...v1.37.4) (2026-05-08)


### Bug Fixes

* **ci:** use PAT for release-please to trigger Actions on release commits ([#141](https://github.com/Viniciuscarvalho/monozukuri/issues/141)) ([a561359](https://github.com/Viniciuscarvalho/monozukuri/commit/a5613596df4e26145157ddb3cc86503a92f3e565))

## [1.37.3](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.37.2...v1.37.3) (2026-05-08)


### Bug Fixes

* symlink .claude/skills into worktrees and wire Ink TUI ([#139](https://github.com/Viniciuscarvalho/monozukuri/issues/139)) ([b7e05e6](https://github.com/Viniciuscarvalho/monozukuri/commit/b7e05e6d7bc2bb625a9e9f18a8531d9cb16f89e0))

## [1.37.2](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.37.1...v1.37.2) (2026-05-08)


### Documentation

* document retry, resume-paused, stop, and 7 other undocumented subcommands ([#136](https://github.com/Viniciuscarvalho/monozukuri/issues/136)) ([197a3c5](https://github.com/Viniciuscarvalho/monozukuri/commit/197a3c59e1f589f745940c00e2c92e44b525073a))

## [1.37.1](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.37.0...v1.37.1) (2026-05-08)


### Refactoring

* **arch:** deepen modules C2-C8 + fix pricing budget ceiling ([#134](https://github.com/Viniciuscarvalho/monozukuri/issues/134)) ([821453e](https://github.com/Viniciuscarvalho/monozukuri/commit/821453e8ff39f696a3687eb0da5a4a0fb8d761a4))

## [1.37.0](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.36.1...v1.37.0) (2026-05-07)


### Features

* **resilience:** auto-mode schema resilience — paused recovery, retry command, UI visibility ([#132](https://github.com/Viniciuscarvalho/monozukuri/issues/132)) ([824b1bf](https://github.com/Viniciuscarvalho/monozukuri/commit/824b1bf0d800aed346e5757938a30d23aeafd258))

## [1.36.1](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.36.0...v1.36.1) (2026-05-06)


### Bug Fixes

* **setup:** stop TUI from eating keystrokes; accept bare positional verbs ([#129](https://github.com/Viniciuscarvalho/monozukuri/issues/129)) ([69999ba](https://github.com/Viniciuscarvalho/monozukuri/commit/69999bab363560d4a4bb0ea1361d7db6915a4915))

## [1.36.0](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.35.0...v1.36.0) (2026-05-06)


### Features

* **pipeline:** phase-split mz-* skills, schema compat, setup fix ([#124](https://github.com/Viniciuscarvalho/monozukuri/issues/124)) ([76be5b7](https://github.com/Viniciuscarvalho/monozukuri/commit/76be5b7d250a59e9a0418c1b736e6c2cd695ffc9))

## [1.35.0](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.34.1...v1.35.0) (2026-05-06)


### Features

* **ci-guard:** add CI watcher skill and scripts ([#125](https://github.com/Viniciuscarvalho/monozukuri/issues/125)) ([20425e4](https://github.com/Viniciuscarvalho/monozukuri/commit/20425e4be38c7ef4bdda75090f73d2340b53a557))

## [1.34.1](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.34.0...v1.34.1) (2026-05-06)


### Bug Fixes

* **adapters:** event stream parity for Codex, Gemini, Kiro, Aider ([#122](https://github.com/Viniciuscarvalho/monozukuri/issues/122)) ([ca80cef](https://github.com/Viniciuscarvalho/monozukuri/commit/ca80cef0717db3c2293ac6b02d129b8c2fabb0c0))

## [1.34.0](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.33.0...v1.34.0) (2026-05-06)


### Features

* **ux:** execution visibility — phase events, tool stream, web dashboard ([#120](https://github.com/Viniciuscarvalho/monozukuri/issues/120)) ([981c1d4](https://github.com/Viniciuscarvalho/monozukuri/commit/981c1d4967ee738af4a47743d5eaaa92ae57183d))

## [1.33.0](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.32.0...v1.33.0) (2026-05-05)


### Features

* **phase-g:** plan-doc reconciliation — env-var cleanup, CLAUDE.md, archive Path B ([#118](https://github.com/Viniciuscarvalho/monozukuri/issues/118)) ([f413fba](https://github.com/Viniciuscarvalho/monozukuri/commit/f413fba5049548d1337574d449da50274ebc641a))

## [1.32.0](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.31.0...v1.32.0) (2026-05-05)


### Features

* **phase-f:** schema render parity for codex/gemini ([#115](https://github.com/Viniciuscarvalho/monozukuri/issues/115)) ([14a1e77](https://github.com/Viniciuscarvalho/monozukuri/commit/14a1e770760bb3dbd6b1e5589ac88dfdd6e32bf7))

## [1.31.0](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.30.0...v1.31.0) (2026-05-05)


### Features

* **phase-e:** state-version stamping + opt-in telemetry ([#113](https://github.com/Viniciuscarvalho/monozukuri/issues/113)) ([975fdac](https://github.com/Viniciuscarvalho/monozukuri/commit/975fdacf97fde6837af4000015f96e6e72a78126))

## [1.30.0](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.29.0...v1.30.0) (2026-05-05)


### Features

* **phase-d:** release-gate truthfulness + CI enforcement ([#111](https://github.com/Viniciuscarvalho/monozukuri/issues/111)) ([e834c1c](https://github.com/Viniciuscarvalho/monozukuri/commit/e834c1c6088d9ba2b8c12b491a72a32cd0b876fc))

## [1.29.0](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.28.0...v1.29.0) (2026-05-05)


### Features

* **phase-c:** multi-project ops — budget ceiling, kill switch, summary, concurrency ([#109](https://github.com/Viniciuscarvalho/monozukuri/issues/109)) ([d164a8e](https://github.com/Viniciuscarvalho/monozukuri/commit/d164a8eb6c7bc99ff296c383e21a2c4d673c2df1))

## [1.28.0](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.27.0...v1.28.0) (2026-05-05)


### Features

* **phase-b:** seed per-adapter context files on monozukuri init ([#106](https://github.com/Viniciuscarvalho/monozukuri/issues/106)) ([b92a614](https://github.com/Viniciuscarvalho/monozukuri/commit/b92a614e61c3cd6f7284c330816f93c7b7291c9a))

## [1.27.0](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.26.0...v1.27.0) (2026-05-04)


### Features

* **phase-a:** loop safety for unattended runs on codex/gemini ([#105](https://github.com/Viniciuscarvalho/monozukuri/issues/105)) ([2d27ddd](https://github.com/Viniciuscarvalho/monozukuri/commit/2d27ddd4b97a2838f5dcc740c4da7a8ebfa60251))

## [1.26.0](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.25.0...v1.26.0) (2026-05-04)


### Features

* **adapters:** use CLI session auth for codex and gemini (drop API key requirement) ([#103](https://github.com/Viniciuscarvalho/monozukuri/issues/103)) ([9f88467](https://github.com/Viniciuscarvalho/monozukuri/commit/9f884676d28609779255687e1d3077857dd90d7d))

## [1.25.0](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.24.1...v1.25.0) (2026-05-04)


### Features

* **phase3,adapters:** generalize Ralph Loop to all adapters via agent_run_phase ([#101](https://github.com/Viniciuscarvalho/monozukuri/issues/101)) ([462fd06](https://github.com/Viniciuscarvalho/monozukuri/commit/462fd0647e7c6e98a37120124a0078273b92be9e))

## [1.24.1](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.24.0...v1.24.1) (2026-04-30)


### Bug Fixes

* **resume,learning:** close determinism gaps ([#96](https://github.com/Viniciuscarvalho/monozukuri/issues/96)) ([5c38d56](https://github.com/Viniciuscarvalho/monozukuri/commit/5c38d56a221a87db709d1825b618ba935d66fb0e))

## [1.24.0](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.23.0...v1.24.0) (2026-04-30)


### Features

* **skills:** publishable mz-* skill versioning and packaging ([#94](https://github.com/Viniciuscarvalho/monozukuri/issues/94)) ([c8090da](https://github.com/Viniciuscarvalho/monozukuri/commit/c8090da622b7e11eeed8bdf47c1c19906425e3d2))

## [1.23.0](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.22.0...v1.23.0) (2026-04-30)


### Features

* **tui:** TUI by default, silence bash render layer ([#92](https://github.com/Viniciuscarvalho/monozukuri/issues/92)) ([e79a683](https://github.com/Viniciuscarvalho/monozukuri/commit/e79a683042d614111e98eee2b1fea8039e99067b))

## [1.22.0](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.21.4...v1.22.0) (2026-04-30)


### Features

* **orchestrator:** fix skill selection and add AGENTS.md discovery ([#90](https://github.com/Viniciuscarvalho/monozukuri/issues/90)) ([f3dd99e](https://github.com/Viniciuscarvalho/monozukuri/commit/f3dd99e42459b2b6493525d066a27b905c4b599c))

## [1.21.4](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.21.3...v1.21.4) (2026-04-30)


### Bug Fixes

* export MONOZUKURI_PHASE, clarify Phase 0 log label, capture schema mismatches ([#88](https://github.com/Viniciuscarvalho/monozukuri/issues/88)) ([daa83fa](https://github.com/Viniciuscarvalho/monozukuri/commit/daa83facafbb4ab6cc1c3359a269e706ff023318))

## [1.21.3](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.21.2...v1.21.3) (2026-04-29)


### Bug Fixes

* MONOZUKURI_PHASE export, Phase 0 log label, learning store schema capture ([#86](https://github.com/Viniciuscarvalho/monozukuri/issues/86)) ([9b07df5](https://github.com/Viniciuscarvalho/monozukuri/commit/9b07df58839f16888e6bc4ed522d9133273d51cc))

## [1.21.2](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.21.1...v1.21.2) (2026-04-29)


### Bug Fixes

* bleed-stop bundle ([#84](https://github.com/Viniciuscarvalho/monozukuri/issues/84)) ([f2b90ff](https://github.com/Viniciuscarvalho/monozukuri/commit/f2b90ff415108a03767e578308c5e8362a290ffd))

## [1.21.1](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.21.0...v1.21.1) (2026-04-28)


### Bug Fixes

* **homebrew:** remove missing ui/dist/package.json from install step ([#82](https://github.com/Viniciuscarvalho/monozukuri/issues/82)) ([8d06c6a](https://github.com/Viniciuscarvalho/monozukuri/commit/8d06c6ac32a448db5a0d996d2e9cb9f6e4e3e786))

## [1.21.0](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.20.0...v1.21.0) (2026-04-28)


### Features

* **qa:** Layer 4 backwards compat + fix cmd/resume.sh module loading ([#80](https://github.com/Viniciuscarvalho/monozukuri/issues/80)) ([07b0bc9](https://github.com/Viniciuscarvalho/monozukuri/commit/07b0bc9e4ca243e723d88091f2cb9e3d53e8fb68))

## [1.20.0](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.19.7...v1.20.0) (2026-04-28)


### Features

* **qa:** release gate harness — layers 1, 2 & 3 (PR 0→2) ([#78](https://github.com/Viniciuscarvalho/monozukuri/issues/78)) ([baac069](https://github.com/Viniciuscarvalho/monozukuri/commit/baac06929919eb7de747d1df8cc2a57009b30c2d))

## [1.19.7](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.19.6...v1.19.7) (2026-04-28)


### Bug Fixes

* **ci:** pass --repo to gh pr merge to avoid missing git context ([#74](https://github.com/Viniciuscarvalho/monozukuri/issues/74)) ([6e3e325](https://github.com/Viniciuscarvalho/monozukuri/commit/6e3e3251717359442b7fb799c7dab3f3df33e3f8))

## [1.19.6](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.19.5...v1.19.6) (2026-04-28)


### Bug Fixes

* **ci:** extract PR number from release-please JSON output for auto-merge ([#72](https://github.com/Viniciuscarvalho/monozukuri/issues/72)) ([bf87666](https://github.com/Viniciuscarvalho/monozukuri/commit/bf87666ddb51517cc7d0f6c04470baa932c5ecc3))

## [1.19.5](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.19.4...v1.19.5) (2026-04-28)


### Bug Fixes

* **ui:** three-PR sequence — build, polish, signals ([#70](https://github.com/Viniciuscarvalho/monozukuri/issues/70)) ([13fcbb2](https://github.com/Viniciuscarvalho/monozukuri/commit/13fcbb24ee18dd45673efc5d5fb7c32bfdf5db8e))

## [1.19.4](https://github.com/Viniciuscarvalho/monozukuri/compare/v1.19.3...v1.19.4) (2026-04-28)


### Bug Fixes

* **ui:** inject createRequire banner to fix CJS dynamic-require failure in ESM bundle ([#68](https://github.com/Viniciuscarvalho/monozukuri/issues/68)) ([59a5985](https://github.com/Viniciuscarvalho/monozukuri/commit/59a59856943207866c8221e41417e915e3a46d73))

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
