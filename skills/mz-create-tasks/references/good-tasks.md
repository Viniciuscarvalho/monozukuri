# Good Tasks Example — feat-042: Add --verbose flag to status command

This file shows what a well-formed `tasks.json` looks like for a small feature. All tasks satisfy the ≤ 60 min / ≤ 5 files / ≥ 1 AC invariants.

## tasks.json

```json
[
  {
    "id": "task-001",
    "title": "Add --verbose flag parsing to cmd/status.sh",
    "description": "Parse the --verbose flag in cmd/status.sh's argument loop and export MONOZUKURI_STATUS_VERBOSE=1 when present. Follows the flag-parsing pattern at cmd/status.sh:18-22.",
    "files_touched": ["cmd/status.sh"],
    "acceptance_criteria": [
      "monozukuri status --verbose sets MONOZUKURI_STATUS_VERBOSE=1 in the process environment",
      "monozukuri status (without flag) does not set MONOZUKURI_STATUS_VERBOSE"
    ]
  },
  {
    "id": "task-002",
    "title": "Implement output_verbose_block in lib/cli/output.sh",
    "description": "Add the output_verbose_block function that reads up to 20 lines from code.md and tests.md in a run directory, printing them indented with 2 spaces. Silently skips missing files.",
    "files_touched": ["lib/cli/output.sh"],
    "acceptance_criteria": [
      "output_verbose_block prints code.md content indented when the file exists",
      "output_verbose_block prints tests.md content indented when the file exists",
      "output_verbose_block exits 0 silently when both files are absent"
    ]
  },
  {
    "id": "task-003",
    "title": "Wire output_verbose_block into status_render",
    "description": "In lib/cli/output.sh's status_render function, call output_verbose_block after each feature summary line when MONOZUKURI_STATUS_VERBOSE=1.",
    "files_touched": ["lib/cli/output.sh"],
    "acceptance_criteria": [
      "monozukuri status --verbose prints artifact content below each feature summary",
      "monozukuri status (no flag) output is byte-identical to the pre-change baseline"
    ]
  },
  {
    "id": "task-004",
    "title": "Write bats tests for --verbose flag",
    "description": "Add tests to test/unit/cmd_status.bats covering: flag present shows artifact lines, flag absent shows no artifact lines, missing artifact files are handled gracefully.",
    "files_touched": ["test/unit/cmd_status.bats"],
    "acceptance_criteria": [
      "bats test/unit/cmd_status.bats exits 0 with all new tests passing",
      "shellcheck cmd/status.sh lib/cli/output.sh exits 0"
    ]
  }
]
```
