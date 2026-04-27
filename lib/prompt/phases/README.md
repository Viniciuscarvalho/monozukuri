# DEPRECATED: phase prompt templates

The artifact templates for `prd`, `techspec`, `tasks`, and `pr` have been duplicated into `skills/mz-*/references/*-template.md` (PR1 of the monozukuri skills plan).

**For now**, the renderer at `lib/prompt/render.sh:248` still loads from this directory — these files remain the active load path. PR4 of the skills plan will rewire adapters to invoke skills natively, after which this directory becomes obsolete.

Until PR4 ships, **edits to a template MUST be applied to BOTH locations** to keep the byte-equality invariant tested by `test/unit/template_lift.bats`:

| Legacy path                          | Canonical path                                              |
| ------------------------------------ | ----------------------------------------------------------- |
| `lib/prompt/phases/prd.tmpl.md`      | `skills/mz-create-prd/references/prd-template.md`           |
| `lib/prompt/phases/techspec.tmpl.md` | `skills/mz-create-techspec/references/techspec-template.md` |
| `lib/prompt/phases/tasks.tmpl.md`    | `skills/mz-create-tasks/references/tasks-template.md`       |
| `lib/prompt/phases/pr.tmpl.md`       | `skills/mz-open-pr/references/pr-body-template.md`          |

Treat `skills/mz-*/references/<name>-template.md` as the canonical source going forward. This directory mirrors it.

`code.tmpl.md` and `tests.tmpl.md` remain here only; they will be lifted into `mz-execute-task` and `mz-run-tests` in PR4 when the adapter wiring is ready.
