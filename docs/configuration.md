# Configuration reference

Monozukuri is configured by a single file: `.monozukuri/config.yaml` in your project root. `monozukuri init` scaffolds it with sensible defaults. The full annotated reference lives at [`templates/config.yaml`](../templates/config.yaml) in this repository — this page explains what each block means, when you would change it, and which fields you almost certainly do not need to touch.

For the semantics of `autonomy:` see [autonomy.md](autonomy.md). For the recovery commands referenced below see [troubleshooting.md](troubleshooting.md).

---

## Top-level structure

```yaml
# .monozukuri/config.yaml
skill: # which Claude Code skill executes each feature
source: # where the backlog comes from
autonomy: # supervised | checkpoint | full_auto
model: # which Claude model and routing policy
gates: # size, cycle, and budget ceilings
phase: # per-phase circuit breaker
learnings: # 3-tier learning store
```

Every block has defaults. A minimal valid config only needs `skill`, `source`, and `autonomy` — everything else can be omitted and Monozukuri will use the defaults documented below.

---

## `skill`

```yaml
skill:
  command: feature-marker # any Claude Code slash-command, without the leading slash
  timeout_seconds: 1800 # max time a single skill invocation may run
  retry_on_timeout: false # whether to retry once if the skill hangs
```

The `command` field is the slash-command Monozukuri invokes for each feature. The default is [Feature-marker](https://github.com/Viniciuscarvalho/Feature-marker), which runs the full PRD → TechSpec → Tasks → Code → Tests → PR pipeline inside Claude Code. Any custom skill that accepts a feature description and produces the same six artifacts will work — Monozukuri does not parse the skill's internal output beyond verifying the artifacts exist.

You can also point this at a skill you wrote yourself, or even leave a well-tuned `CLAUDE.md` in your project and use a generic skill that follows it. The interface contract is documented under [adr/008-orchestrator-economy.md](adr/008-orchestrator-economy.md#skill-interface).

---

## `source`

```yaml
source:
  adapter: markdown # markdown | github | linear
  markdown:
    file: features.md
  github:
    repo: owner/repo
    label: monozukuri
  linear:
    team: ENG
    state: Backlog
```

Only the block matching the active `adapter` is read — the others can be present (commented or otherwise) without effect. Switching adapters is one config edit and a re-init away.

**`markdown`.** Reads features from a single file (`features.md` by default) where each feature is a top-level list item with optional front matter. The simplest source, and the one `monozukuri init` writes by default. See [adapters.md](adapters.md#markdown) for the file format.

**`github`.** Reads issues from a GitHub repository filtered by label. Requires `gh auth login` with `repo` scope. The repo defaults to `origin` if omitted. See [adapters.md](adapters.md#github).

**`linear`.** Reads issues from a Linear team filtered by state. Requires `LINEAR_API_KEY` in `.env` or in the environment. See [adapters.md](adapters.md#linear).

---

## `autonomy`

```yaml
autonomy: checkpoint # supervised | checkpoint | full_auto
```

A single string. The CLI flag `--autonomy <level>` overrides this value for the duration of the run. See [autonomy.md](autonomy.md) for the semantic differences.

---

## `model`

```yaml
model:
  default: opusplan # opus | sonnet | haiku | opusplan
  routing:
    prd: opus
    techspec: opus
    tasks: sonnet
    code: opusplan
    tests: sonnet
    pr: haiku
```

`default` is the model used for any phase not explicitly routed. `routing` lets you assign a different model per phase — useful for keeping cheap phases (PR description, task decomposition) on `haiku`/`sonnet` while reserving `opus` for phases that benefit from deeper reasoning.

`opusplan` is the planner-first routing strategy described in [ADR-008](adr/008-orchestrator-economy.md). It uses `opus` for planning phases (PRD, TechSpec) and falls back to `sonnet` for execution phases (Code, Tests) unless those phases hit a complexity threshold that warrants escalation.

For most projects the defaults are correct. Override routing when a specific phase is consistently underperforming or consistently overspending.

---

## `gates`

```yaml
gates:
  size:
    max_tokens: 100000 # estimated token ceiling per feature
    max_minutes: 30 # estimated wall time ceiling per feature
    on_exceed: skip # skip | escalate | proceed
  cycle:
    require_pr_url: true # cycle gate fails if the PR phase did not return a URL
    require_test_files: true # cycle gate fails if no test files were produced
  run:
    max_tokens: 2000000 # hard ceiling across the entire run
    max_minutes: 240 # hard wall time ceiling across the entire run
  merge_wait:
    poll_interval_seconds: 60
    max_wait_minutes: 1440 # 24h; how long checkpoint mode waits for a PR to merge
```

**Size gate.** Runs before each feature enters a worktree. The estimator compares projected cost against `max_tokens` / `max_minutes` and either approves the feature, marks it `skip`, or escalates for human review per `on_exceed`. In `supervised` mode, `on_exceed: skip` will pause for your override; in `checkpoint` and `full_auto` it is silent.

**Cycle gate.** Runs after the PR phase. The two checks above are the defaults; you can extend the gate with skill-specific artifact requirements. See [troubleshooting.md](troubleshooting.md#cycle-gate-failure) for what a failure looks like.

**Run budget.** The aggregate ceiling across the entire loop. When exceeded, the run stops gracefully — no new features start, in-flight features finish their current phase, and the state is left resumable. This is the safety net for `full_auto` runs.

**Merge wait.** Only applies in `checkpoint` mode. `max_wait_minutes` is generous by default because PRs often sit overnight before merge; lower it for tight feedback loops.

---

## `phase`

```yaml
phase:
  budget_seconds: 600 # circuit breaker: max wall time per phase
  max_attempts: 3 # circuit breaker: max retries per phase
  on_break: record_and_skip # record_and_skip | record_and_fail
```

The phase-level circuit breaker. Prevents a single phase from looping indefinitely against a validator it cannot satisfy. When the breaker trips, the failure is recorded as a learning regardless of `on_break`; the difference is whether the feature is marked skipped (loop continues) or failed (loop stops on this feature).

See [ADR-010](adr/010-stuck-state-elimination.md) for the rationale and the prior failure modes this replaced.

---

## `learnings`

```yaml
learnings:
  enabled: true
  tiers:
    feature: true # per-feature outcome capture
    project: true # aggregated across this project
    global: true # aggregated across all your projects
  store_dir: .monozukuri/learnings
  global_dir: ~/.monozukuri/learnings
```

The three-tier learning store. Defaults are correct for almost every project — disable a tier only if you are debugging the learning step itself or have a compliance reason to keep run history out of the repo. The `feature` and `project` tiers are committed by default (so the team benefits from prior runs); the `global` tier lives in your home directory and is per-user.

See [ADR-008](adr/008-orchestrator-economy.md#three-tier-learning-store) for the design.

---

## Environment variables

A small number of settings live in the environment rather than in `config.yaml`, either because they are secrets or because they affect process behavior before the config is read.

| Variable                | Purpose                                               | Required by                        |
| ----------------------- | ----------------------------------------------------- | ---------------------------------- |
| `LINEAR_API_KEY`        | Authenticates the Linear adapter                      | `source.adapter: linear`           |
| `MONOZUKURI_MEMORY_DIR` | Overrides the location of the global learning store   | Optional                           |
| `MONOZUKURI_LOG_LEVEL`  | `debug` / `info` / `warn` / `error` (default: `info`) | Optional                           |
| `GH_TOKEN`              | GitHub auth, if `gh auth login` is not used           | `source.adapter: github`, PR phase |
| `ANTHROPIC_API_KEY`     | Claude Code authentication                            | Always (via `claude` CLI)          |

Keep secrets in `.env` (gitignored). The `.env` file is loaded by the orchestrator at startup; it does not need to be exported manually.

---

## Validation and defaults

`monozukuri init` writes a config that is valid out of the box for a markdown-source, checkpoint-autonomy, opusplan-routed run. You can edit the file and re-run `monozukuri init --validate` to check the result without overwriting.

`monozukuri run` validates the config before any side effects. A malformed config will fail with a pointer to the offending field — no worktree is created, no skill is invoked. Common validation failures: an unknown adapter, an autonomy level outside the allowed set, a model name that is not recognized, or a missing secret for the selected adapter.

When in doubt about a field that is not documented here, the source of truth is [`templates/config.yaml`](../templates/config.yaml) in this repository. Every supported field appears there with a comment explaining its effect.
