# Compozy Skills — Ground Truth Research (Phase 0)

Source: `/Users/viniciuscarvalho/Documents/compozy` read on 2026-04-27.
Purpose: lock in Compozy's real conventions before monozukuri's skill scaffolding (PR1). Where this contradicts `MONOZUKURI_SKILLS_PLAN.md`, this doc wins.

## TL;DR

- Skills are `SKILL.md` + `references/*.md` only. Nothing else ships.
- Frontmatter fields: `name`, `description`, optional `argument-hint`. No `version`, `allowed-tools`, `model`.
- Same SKILL.md installs byte-identical to all 44 supported agents. No per-agent variants.
- Skills do not invoke each other in code — only via prose to the reading agent.
- No install manifest is written. Drift is computed live by byte-equality comparison.
- `cy-final-verify` is a discipline contract, not a machine-enforced gate.
- `cy-workflow-memory` is harness-bootstrapped (Go) but agent-compacted (in-band).

---

## 1. Frontmatter fields

Compozy's parser (`internal/setup/catalog.go:50-60`) reads exactly three keys:

- `name` (required)
- `description` (required)
- `argument-hint` (optional; appears on `cy-create-prd`, `cy-create-tasks`, `cy-create-techspec` only)

Anything else is silently ignored. Empty `name` or `description` rejects the skill at catalog load (`catalog.go:58-60`: `"missing name or description"`).

Description style, consistent across all 9 `cy-*` skills:

> `<verb-phrase>. Use when <triggers>. Do not use for <anti-triggers>.`

**Monozukuri implication:** `MONOZUKURI_SKILLS_PLAN.md` specified `version: 1.0.0` in frontmatter. Drop it. The Compozy parser ignores unknown YAML keys, but version fields create false upgrade expectations. If monozukuri needs versioning, track it in a separate file (e.g. `skills/<name>/.version`) — not in frontmatter.

---

## 2. Skill-directory layout

`skills/embed.go` is the source of truth:

```go
//go:embed */SKILL.md */references/*
var FS embed.FS
```

Only two glob patterns are embedded. Files outside `*/SKILL.md` and `*/references/*` **never reach the install pipeline**.

Real examples from Compozy's skills:

| Skill                 | Files under references/                                                               |
| --------------------- | ------------------------------------------------------------------------------------- |
| `cy-create-prd/`      | `adr-template.md`, `prd-template.md`, `question-protocol.md`                          |
| `cy-create-tasks/`    | `task-context-schema.md`, `task-template.md`                                          |
| `cy-execute-task/`    | `tracking-checklist.md`                                                               |
| `cy-final-verify/`    | (none — SKILL.md only)                                                                |
| `cy-workflow-memory/` | `memory-guidelines.md`                                                                |
| `compozy/`            | `cli-reference.md`, `config-reference.md`, `skills-reference.md`, `workflow-guide.md` |

**Monozukuri implication:** The skills plan proposed `template.md`, `validation.md`, `examples/`, `schema.json` directly under each skill directory. None of these names match Compozy's pattern. Rename all helper content to `references/<descriptive-name>.md`:

| Plan proposed          | Use instead                                                                               |
| ---------------------- | ----------------------------------------------------------------------------------------- |
| `template.md`          | `references/prd-template.md`                                                              |
| `validation.md`        | `references/prd-validation.md`                                                            |
| `examples/good-prd.md` | `references/good-prd.md`                                                                  |
| `schema.json`          | pointer doc `references/tasks-schema.md` (canonical stays at `schemas/tasks.schema.json`) |

---

## 3. How templates are referenced from SKILL.md

Plain markdown body prose with relative paths. Pattern from all nine cy-\* skills:

> "Read `references/prd-template.md` and follow its structure."

No templating engine, no variable substitution at install time. The agent reads the reference files and follows their instructions.

---

## 4. Do skills invoke other skills?

**Not programmatically.** Searched all `cy-*/SKILL.md` for SlashCommand, Task agent, or Skill tool invocations — none exist. Cross-skill references are prose only:

- `cy-execute-task/SKILL.md:45`: "Use the installed `cy-final-verify` skill"
- `cy-fix-reviews/SKILL.md:39`: same pattern
- `cy-review-round/SKILL.md:113`: produces output that `cy-fix-reviews` reads

Compozy's Go runtime dispatches skills (e.g. `compozy tasks run` → `cy-execute-task`). The skills themselves only tell the agent to invoke the next one.

**Monozukuri implication:** Do not design a skill→skill composition runtime. The monozukuri orchestrator (`lib/run/pipeline.sh`) is the dispatcher. Skills are leaves in the call graph.

---

## 5. How `cy-final-verify` enforces verification

**Honor system, not code.** `cy-final-verify/SKILL.md` (155 lines, no `references/`):

- **Freshness rule** (line 23): if a verification command was not run in the **current message**, the result cannot be claimed. Same-message, not same-session.
- **Verification Report Template** (lines 121-132): the agent must complete Claim / Command / Executed / Exit code / Output summary / Warnings / Errors / Verdict (PASS|FAIL).
- **Evidence requirement** (line 117): "Verification is not complete until the agent **cites actual command output** in their response. 'I ran it and it passed' is not evidence."
- **Failure protocol** (lines 138-154): full re-verify from scratch. No partial success, no skipping the failing subset.

No sentinel files, no exit-code captures, no hashes. Compozy's gate command is `make verify` (fmt + lint + test + build); enforcement is via CLAUDE.md ("zero tolerance"), not a machine-readable result file.

**Monozukuri implication:** `mz-validate-artifact` is a discipline contract on the agent, not a machine-enforced gate. The machine enforcement lives in `lib/schema/validate.sh`, which runs in the harness. The skill instructs the agent to self-verify before the harness runs. PR2 couples the validator to `references/*-validation.md` files so the rules are a shared source of truth — that is the real fix for the 40% failure rate, separate from the skill.

---

## 6. How `cy-workflow-memory` bootstraps

Bootstrapped by **Go code**, not the agent. `internal/core/memory/store.go`:

- `Prepare(tasksDir, taskFileName)` (line 118) called per task invocation.
- `MkdirAll` on `<repo>/.compozy/tasks/<feature-slug>/memory/` (lines 124-127).
- `writeIfMissing` for `MEMORY.md` and `task_NN.md` from in-Go templates (lines 129-137, 155-166). `MEMORY.md` is written once (subsequent calls skip); per-task files written per task.

Layout:

```
<repo>/.compozy/tasks/<feature-slug>/memory/
  MEMORY.md                # shared across all tasks of this feature
  task_06.md               # one file per task
  task_09.md
```

Scope is per-feature (shared `MEMORY.md`) with per-task files inside. **Files persist across runs** — not per-run.

**Soft caps** (`store.go:13-16` — plan author's guesses were correct):

| File         | Line cap  | Byte cap |
| ------------ | --------- | -------- |
| `MEMORY.md`  | 150 lines | 12 KiB   |
| `task_NN.md` | 200 lines | 16 KiB   |

`NeedsCompaction = lineCount > limit || byteCount > limit` — OR semantics.

**Compaction trigger:** harness flags, agent executes. `inspect()` (lines 227-241) computes `NeedsCompaction`; `Prepare()` returns it in `Context{Workflow, Task}`. The prompt builder (`internal/core/prompt/prd.go:16-17, 107-138`) injects `workflow_needs_compaction` / `task_needs_compaction` JSON and "over its soft limit" prose into the agent prompt. The agent then runs compaction in-band per SKILL.md §"Compaction Rules" (lines 64-71).

**Promotion rules** (SKILL.md:42-62): promote from task → shared workflow memory only when ALL three: another task needs it to avoid mistakes, durable across runs, not derivable from PRD/techspec/tasks/repo. Nothing escapes the feature directory — there is no longer-lived store in Compozy.

**Monozukuri implication:** monozukuri's existing 3-tier learning store (`lib/memory/learning.sh`, `~/.claude/monozukuri/learned/`) is a monozukuri-specific addition with no Compozy precedent. The SKILLS PLAN describes it as "complementary" — that framing is accurate. Do not claim it is "what Compozy does." The `mz-workflow-memory` skill covers only the feature-scoped transient layer. PR5 builds the harness bootstrap; PR1 ships only the prose contract and templates.

---

## 7. Per-agent skill variants

**None.** Confirmed:

- `find skills -name 'SKILL.*.md'` returns nothing — no Claude vs Codex overrides.
- `copyBundleDirectory` (`install.go:277-315`) does verbatim `io.Copy` — no templating, no rewriting.
- The catalog reads each SKILL.md once (`catalog.go:55`) only to extract `name`/`description`. Content is never modified.

---

## 8. Artifact YAML frontmatter (machine-readable metadata on outputs)

Skills produce different artifact types with different metadata:

**Task files** — `cy-create-tasks/references/task-context-schema.md` and `task-template.md`:

```yaml
status: pending
title: ...
type: frontend|backend|docs|test|infra|refactor|chore|bugfix|<override>
complexity: low|medium|high|critical
dependencies: [task_01, task_02] # [] when none, never omit
```

**Review issue files** — `cy-review-round/references/issue-template.md`:

```yaml
status: pending # → valid|invalid → resolved
file: path/to/file.go
line: 42
severity: critical|high|medium|low
author: claude-code
provider_ref:
```

**PRDs / TechSpecs / ADRs / MEMORY.md / task_NN.md memory files:** no YAML frontmatter. Pure-prose markdown starting with `# <Title>` directly.

**Monozukuri implication:** add machine-readable YAML frontmatter only on task files and review issue files. Do not add frontmatter to PRDs or TechSpecs — Compozy doesn't, and the plan's 40%-failure-rate fix doesn't require it.

---

## 9. How setup detects agents

Pure filesystem probing. `internal/setup/agents.go:169-176`:

```go
func (spec agentSpec) detected(env resolvedEnvironment) bool {
    for _, detectPath := range spec.detectPaths {
        if pathExists(detectPath.resolve(env)) { return true }
    }
    return false
}
```

`pathExists` = `os.Stat` + `err == nil`. **No PATH lookups, no env-var presence checks, no config parsing.** Detection only pre-selects agents in the interactive prompt; `--agent <id>` or `--all` bypasses detection entirely.

Five resolution roots (overridable via env): `cwd`, `home`, `XDG_CONFIG_HOME`, `CODEX_HOME`, `CLAUDE_CONFIG_DIR` (`cli/setup.go:177-182`).

**Full registry: 44 agents.** Notable entries relevant to monozukuri's v1 plan:

| Agent         | Project path             | Global path                         | Type      |
| ------------- | ------------------------ | ----------------------------------- | --------- |
| `claude-code` | `.claude/skills/<name>/` | `$CLAUDE_CONFIG_DIR/skills/<name>/` | specific  |
| `cursor`      | `.agents/skills/<name>/` | `~/.cursor/skills/<name>/`          | universal |
| `gemini-cli`  | `.agents/skills/<name>/` | `~/.gemini/skills/<name>/`          | universal |
| `codex`       | `.agents/skills/<name>/` | `$CODEX_HOME/skills/<name>/`        | universal |
| `opencode`    | `.agents/skills/<name>/` | `~/.agents/skills/<name>/`          | universal |

**Aider is not in Compozy's registry.** The skills plan's v1 list of 5 agents mentioned aider; drop it or build support net-new.

**Canonical install root:** `.agents/skills/` (project) or `~/.agents/skills/` (global) — `install.go:240-245`. Universal agents' target path IS the canonical path. Specific agents (e.g. `claude-code`) symlink from `.claude/skills/` back to `.agents/skills/`.

---

## 10. Install mode logic

Decided in `internal/cli/setup.go:439-486`:

1. `--copy` → `Copy`.
2. Compute unique target roots across selected agents.
3. **One unique root** → `Copy` (symlinking adds no value).
4. Multiple roots + `--yes` or explicit `--copy=false` → `Symlink`.
5. Otherwise prompt.

Symlink mode writes one canonical copy under `.agents/skills/<name>/` then `os.Symlink(relativeTarget, linkPath)` from each agent path. Failure (e.g. Windows without privileges) falls back to copy.

---

## 11. Validation at install time

- **Frontmatter validated at catalog-load** (`catalog.go:43-69`). Empty name or description → rejected.
- **No hashing.** Drift detection (`verify.go`) is raw `bytes.Equal`. Classifies each skill as `current` / `missing` / `drifted`.
- **No install manifest.** State is computed live by walking the embedded FS. No `~/.monozukuri/installed.json` equivalent is needed.

**Monozukuri implication:** Drop the tracking-file design from the skills plan. Use byte-equality drift detection instead.

---

## 12. Plan-author corrections (decisions that change as a result of Phase 0)

1. **Drop `version` from skill frontmatter.** Not in Compozy's parser. Creates false expectations without benefit.
2. **Replace `template.md` / `validation.md` / `examples/` / `schema.json` with `references/<name>.md`.** Anything outside `references/` doesn't ship through the embed pipeline.
3. **Drop the install-tracking-manifest design.** Use live byte-equality drift detection.
4. **Re-decide the v1 agent list.** Aider has no Compozy precedent. Recommended v1: `claude-code` (specific) + `cursor`, `gemini-cli`, `codex` (universal) — 4 agents, one specific + three universals, covering the most common installs with minimal per-agent code.
5. **Skills are leaves, not dispatchers.** No skill→skill composition runtime needed. The orchestrator dispatches.
6. **`mz-validate-artifact` is a discipline contract, not machine enforcement.** The machine enforcement is in `lib/schema/validate.sh`. The skill tells the agent to self-verify before the harness runs. The 40%-failure-rate fix is PR2 (coupling the validator to `references/*-validation.md`), not the skill itself.
7. **Compozy has no durable tier inside skills.** `cy-workflow-memory` is feature-scoped only. monozukuri's global learning store (`~/.claude/monozukuri/learned/`) is a monozukuri-specific addition. Don't conflate the two in the README.

---

## 13. Files cited

- `skills/embed.go` — embed glob (defines what ships)
- `skills/cy-*/SKILL.md` — frontmatter + body conventions
- `skills/cy-*/references/*.md` — companion file naming
- `internal/setup/catalog.go:50-60` — frontmatter parser
- `internal/setup/agents.go:150-176, 236-336` — agent registry, detection, universal flag
- `internal/setup/install.go:127-179, 205-245, 277-315` — copy vs symlink, root resolution, file writing
- `internal/setup/verify.go` — drift via `bytes.Equal`
- `internal/setup/types.go:11-16, 103-112` — install modes, drift states
- `internal/cli/setup.go:177-182, 439-486` — env resolution, mode decision
- `internal/core/memory/store.go:13-16, 118, 124-137, 155-166, 227-241` — memory bootstrap, soft caps, compaction trigger
- `internal/core/prompt/prd.go:16-17, 107-138` — compaction prompt injection
- `skills/cy-final-verify/SKILL.md:23, 117, 121-132, 138-154` — verification discipline
- `skills/cy-workflow-memory/SKILL.md:42-62, 64-71` — promotion test, compaction rules
- `skills/cy-workflow-memory/references/memory-guidelines.md:60-75` — default section headings
- `skills/cy-create-tasks/references/task-template.md` — task frontmatter
- `skills/cy-review-round/references/issue-template.md` — review-issue frontmatter

---

## 14. Out of Compozy's scope (monozukuri-specific decisions still pending)

- Aider support (no Compozy precedent).
- The 3-tier learning store (monozukuri-specific).
- Machine-enforced verification (Compozy is honor-system).
- `mz-validate-artifact`'s validator-reads-`validation.md` design (the actual fix for the 40% failure rate — this is net-new, not a Compozy feature).
- Skill versioning and upgrade prompts (Compozy has neither; the skills plan needs to decide approach independently).
