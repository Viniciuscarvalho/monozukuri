# TechSpec — feat-042: Add --verbose flag to status command

> **Token budget: 1200 words max.**

**Feature:** feat-042
**Inherits from:** `./prd.md`
**Date:** 2026-04-27
**Status:** draft

---

## Approach

Extend `cmd/status.sh` to accept a `--verbose` flag and pass it through to `lib/cli/output.sh`'s status renderer. The renderer will detect the flag and append truncated artifact content below each feature line. No new files; the change is localized to the two files in the render path.

### Key decisions

| Decision              | Choice                                    | Why                                                         |
| --------------------- | ----------------------------------------- | ----------------------------------------------------------- |
| Flag parsing location | `cmd/status.sh` argument loop             | Keeps CLI parsing in the cmd layer per existing conventions |
| Artifact read limit   | 20 lines via `head -n 20`                 | Bounded output; same pattern used in `cmd/review.sh:47`     |
| Output indentation    | 2-space prefix via `output_indent` helper | Matches existing `lib/cli/output.sh:indent_block` contract  |

---

## Existing codebase patterns this feature MUST follow

```bash
# Error handling pattern (lib/cli/output.sh:12-15)
output_error() { printf '[error] %s\n' "$1" >&2; }
```

```bash
# Flag parsing pattern (cmd/status.sh:18-22)
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --filter) FILTER="$2"; shift 2 ;;
    *) break ;;
  esac
done
```

**Naming:** functions `snake_case` · files `kebab-case.sh` · env vars `MONOZUKURI_UPPER_SNAKE`

---

## File change map

> **File budget: ≤ 3 files touched.**

### New files

_(none)_

### Modified files

| Path                | Change                                                                             | Risk | Implements     |
| ------------------- | ---------------------------------------------------------------------------------- | ---- | -------------- |
| `cmd/status.sh`     | Add `--verbose` flag parsing; pass `VERBOSE=1` to renderer                         | low  | FR-001, FR-002 |
| `lib/cli/output.sh` | Add `output_verbose_block` function; call it from `status_render` when `VERBOSE=1` | low  | FR-001         |

### Read for context only

| Path                  | Why                                          |
| --------------------- | -------------------------------------------- |
| `lib/run/pipeline.sh` | Understand run-dir layout for artifact paths |

---

## Components

### `output_verbose_block` (lib/cli/output.sh)

**Location:** `lib/cli/output.sh` (new function, ~15 lines)
**Implements:** FR-001

**Public interface:**

```bash
output_verbose_block <run_dir> <feature_id>
# Prints up to 20 lines from code.md and tests.md, indented 2 spaces.
# Silently skips missing files.
```

**Behavior:**

1. Check for `$run_dir/$feature_id/code.md` — if present, print `  code:` header then `head -n 20`.
2. Check for `$run_dir/$feature_id/tests.md` — same pattern.
3. Silently skip if either file is absent (FR-002).

---

## Testing

**Coverage target:** 90%

| Scope       | Test file                   | Covers                                                  |
| ----------- | --------------------------- | ------------------------------------------------------- |
| Unit        | `test/unit/cmd_status.bats` | `--verbose` flag present/absent, missing artifact files |
| Integration | `test/unit/cmd_status.bats` | end-to-end with fixture run dir                         |

### Validation commands

```bash
bats test/unit/cmd_status.bats
shellcheck cmd/status.sh lib/cli/output.sh
```

---

## Task ordering

1. Add `--verbose` flag parsing to `cmd/status.sh` — unblocks all downstream work
2. Implement `output_verbose_block` in `lib/cli/output.sh`
3. Wire `output_verbose_block` into `status_render`
4. Write tests

---

**Handoff to Tasks phase:** tasks must cover the two file changes and the two test scenarios above. Each task ≤ 5 files, ≤ 60 min.
