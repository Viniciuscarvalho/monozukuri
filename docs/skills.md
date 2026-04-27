# Monozukuri Skills Catalog

Monozukuri ships 8 phase skills as installable packages. Each skill is a directory under `skills/mz-*/` containing a `SKILL.md` (agent instructions) and optional `references/*.md` (templates, validation rules, examples).

Installation support (`monozukuri setup`) arrives in PR3 of the skills plan. Until then, skills are available as files and can be read directly by agents configured to load from the `skills/` directory.

---

## Skills

### mz-create-prd

**Phase:** `prd`
**Files:** `SKILL.md` + `references/prd-template.md`, `prd-validation.md`, `good-prd.md`

Generate a PRD artifact for a monozukuri feature. Produces `prd.md` matching the template and validation rules.

| Input                                                 | Output                                   |
| ----------------------------------------------------- | ---------------------------------------- |
| Feature id, title, description; CLAUDE.md conventions | `$MONOZUKURI_RUN_DIR/$FEATURE_ID/prd.md` |

---

### mz-create-techspec

**Phase:** `techspec`
**Files:** `SKILL.md` + `references/techspec-template.md`, `techspec-validation.md`, `good-techspec.md`

Translate a PRD into a concrete implementation plan. Produces `techspec.md` with approach, file change map, components, and test plan.

| Input                           | Output                                        |
| ------------------------------- | --------------------------------------------- |
| `prd.md`; CLAUDE.md conventions | `$MONOZUKURI_RUN_DIR/$FEATURE_ID/techspec.md` |

---

### mz-create-tasks

**Phase:** `tasks`
**Files:** `SKILL.md` + `references/tasks-template.md`, `tasks-validation.md`, `tasks-schema.md`, `good-tasks.md`

Decompose a PRD and TechSpec into a structured `tasks.json` task list. Each task ≤ 60 min / ≤ 5 files / ≥ 1 verifiable AC.

| Input                   | Output                                       |
| ----------------------- | -------------------------------------------- |
| `prd.md`, `techspec.md` | `$MONOZUKURI_RUN_DIR/$FEATURE_ID/tasks.json` |

---

### mz-execute-task

**Phase:** `code`
**Files:** `SKILL.md`

Execute each task in `tasks.json` inside a git worktree — implement, verify acceptance criteria, and commit (one commit per task).

| Input                                 | Output                                            |
| ------------------------------------- | ------------------------------------------------- |
| `techspec.md`, `tasks.json`, worktree | `$MONOZUKURI_RUN_DIR/$FEATURE_ID/code.md` summary |

---

### mz-run-tests

**Phase:** `tests`
**Files:** `SKILL.md`

Run the existing test suite, add tests for each task's acceptance criteria, and emit a `tests.md` summary.

| Input                                              | Output                                     |
| -------------------------------------------------- | ------------------------------------------ |
| `techspec.md` (§ Testing), `code.md`, `tasks.json` | `$MONOZUKURI_RUN_DIR/$FEATURE_ID/tests.md` |

---

### mz-open-pr

**Phase:** `pr`
**Files:** `SKILL.md` + `references/pr-body-template.md`

Open a GitHub pull request via `gh pr create` with a body summarizing PRD goals, code changes, and test results.

| Input                           | Output                                                   |
| ------------------------------- | -------------------------------------------------------- |
| `prd.md`, `code.md`, `tests.md` | `$MONOZUKURI_RUN_DIR/$FEATURE_ID/pr.md` (URL + metadata) |

---

### mz-workflow-memory

**Phase:** (cross-cutting — invoked per-task by the orchestrator)
**Files:** `SKILL.md` + `references/memory-template.md`, `task-template.md`

Maintain feature-scoped workflow memory (`MEMORY.md` + `task_NN.md`) across tasks within one feature run. Soft caps: 150 lines / 12 KiB for `MEMORY.md`; 200 lines / 16 KiB for `task_NN.md`.

_Note: PR1 ships the prose contract and templates. Harness bootstrap and compaction flagging arrive in PR5._

| Input                                    | Output                                                              |
| ---------------------------------------- | ------------------------------------------------------------------- |
| Orchestrator bootstrap/compaction signal | `$MONOZUKURI_RUN_DIR/$FEATURE_ID/memory/MEMORY.md` and `task_NN.md` |

---

### mz-validate-artifact

**Phase:** (post-phase — invoked by the validator after each planning phase)
**Files:** `SKILL.md`

Validate a generated artifact (PRD, TechSpec, or Tasks) against its skill's `references/*-validation.md` rules before claiming the phase is complete.

_Note: PR1 ships the prose contract. PR2 couples `lib/schema/validate.sh` to read rules from `references/*-validation.md` files instead of hardcoded regexes._

---

## Installation

_Coming in PR3 of the skills plan (`monozukuri setup`)._

Until then, agents that support loading skills from a project directory can be pointed at `skills/` manually. See `docs/research/compozy-skills.md` §9 for the per-agent install path conventions.

## Invocation

_Native skill invocation arrives in PR4 (adapter skill-awareness)._

Until then, the orchestrator invokes phases via the existing raw-prompt path (`lib/prompt/render.sh:248` reads `lib/prompt/phases/*.tmpl.md`). The templates in `skills/mz-*/references/*-template.md` are byte-identical to the legacy templates; `test/unit/template_lift.bats` enforces this invariant.

## Authoring a new skill

1. Create `skills/<name>/SKILL.md` with minimal frontmatter: `name` + `description` (+ `argument-hint` if user-facing). No `version`, no `allowed-tools`.
2. Put helper content under `skills/<name>/references/<descriptive-name>.md`. No other paths are embedded by the install pipeline.
3. Description style: `<verb-phrase>. Use when <triggers>. Do not use for <anti-triggers>.`
4. Add the skill to this catalog and to `test/unit/skill_format.bats`.
