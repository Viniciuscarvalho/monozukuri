# Monozukuri Adapter Contract — v1.0.0

Published: 2026-04-26  
Status: Stable  
ADR: [ADR-012](adr/012-adapter-contract-and-schemas.md), [ADR-013](adr/013-failure-handling-resumption-rate-limits.md)

---

## Overview

An **adapter** is a shell script at `lib/agent/adapter-<name>.sh` that bridges
Monozukuri's orchestrator to a specific coding agent CLI (Claude Code, Aider, Codex,
Gemini, Kiro, …). Monozukuri owns the artifact schemas and the failure-policy table.
Adapters own the prompt strategy and tool-use approach.

**Conformance** = valid schema output on all canary features within the one-reprompt
budget. Non-conformant adapters are not listed as supported until they pass the
conformance suite (`test/conformance/`).

---

## 1. Required functions (the six-function contract)

Every adapter MUST define all six functions. `agent_verify` checks this at load time.

### `agent_name`

```bash
agent_name()
# → stdout: adapter name string (e.g. "claude-code")
# No arguments.
```

### `agent_capabilities`

```bash
agent_capabilities()
# → stdout: JSON capability declaration (see §1.1)
# No arguments.
```

### `agent_doctor`

```bash
agent_doctor()
# Checks binary availability and authentication.
# → exit 0: all checks pass
# → exit 1: failure; human-readable fix instruction printed to stderr
```

### `agent_estimate_tokens`

```bash
agent_estimate_tokens()
# stdin: prompt text
# → stdout: integer token count estimate
```

### `agent_run_phase`

```bash
agent_run_phase()
# Executes the current feature phase. Reads MONOZUKURI_* env vars (see §2).
# → exit 0: phase completed; artifacts written to MONOZUKURI_RUN_DIR
# → exit non-zero: failure; MONOZUKURI_ERROR_FILE written (see §3)
```

### `agent_report_cost`

```bash
agent_report_cost()
# stdin: trace JSON (optional; adapter may ignore)
# → stdout: USD cost float (e.g. "0.42")
```

### 1.1 Capability declaration schema

```json
{
  "agent": "<name>",
  "supports": {
    "phases": ["prd", "techspec", "tasks", "code", "tests", "pr"],
    "skills": true,
    "native_edit": true,
    "shell_access": false,
    "mcp": false,
    "streaming": true,
    "token_counting": "estimate",
    "approval_modes": ["auto"]
  },
  "models": {
    "aliases": { "default": "<model-id>" },
    "default": "<alias-or-id>"
  },
  "auth": {
    "methods": ["api_key:ENV_VAR_NAME"],
    "verify": "<command to run for auth check>"
  }
}
```

`additionalProperties` is allowed; Monozukuri reads only the fields above.

---

## 2. Environment variables consumed by `agent_run_phase`

These are set by `lib/run/pipeline.sh` before calling `agent_run_phase`.

| Variable                | Required | Description                                                      |
| ----------------------- | -------- | ---------------------------------------------------------------- |
| `MONOZUKURI_FEATURE_ID` | ✅       | Feature identifier (e.g. `feat-login`)                           |
| `MONOZUKURI_WORKTREE`   | ✅       | Absolute path to the isolated git worktree                       |
| `MONOZUKURI_AUTONOMY`   | ✅       | `supervised` \| `checkpoint` \| `full_auto`                      |
| `MONOZUKURI_MODEL`      | —        | Model alias (empty = adapter default)                            |
| `MONOZUKURI_LOG_FILE`   | —        | File path for agent output tee                                   |
| `MONOZUKURI_RUN_DIR`    | —        | `$CONFIG_DIR/runs/<run-id>` for artifact writes                  |
| `MONOZUKURI_ERROR_FILE` | —        | Path where adapter MUST write error envelope on failure (see §3) |
| `SKILL_COMMAND`         | —        | Override for Claude Code skill name (back-compat)                |
| `SKILL_TIMEOUT_SECONDS` | —        | Wall-clock budget for the invocation (default: 1800)             |

---

## 3. Error envelope (ADR-013)

When `agent_run_phase` exits non-zero and `MONOZUKURI_ERROR_FILE` is set, the adapter
MUST write a JSON error envelope to that path. If the adapter cannot determine a more
specific class, it MUST write `"class":"unknown"`.

```json
{
  "class": "transient | phase | fatal | unknown",
  "code": "<short machine-readable code>",
  "message": "<human-readable description>",
  "retryable_after": 300
}
```

`retryable_after` (seconds) is required only when `class = "transient"` and there is
a known retry window (e.g. a `Retry-After` header from a rate-limit response).

### Class semantics

| Class       | Meaning                                             | Policy                          |
| ----------- | --------------------------------------------------- | ------------------------------- |
| `transient` | Temporary failure (rate-limit, timeout, network)    | Retry after back-off            |
| `phase`     | Agent ran but produced invalid or incomplete output | One reprompt, then abort        |
| `fatal`     | Unrecoverable (auth failure, missing binary)        | Abort immediately               |
| `unknown`   | Cannot classify                                     | Treat as `phase` (conservative) |

### Common codes

| Code             | Class     | Trigger                                        |
| ---------------- | --------- | ---------------------------------------------- |
| `rate-limit`     | transient | HTTP 429 or "rate limit exceeded" in output    |
| `timeout`        | transient | Exit 124 (op_timeout) or 137 (SIGKILL)         |
| `auth-failure`   | fatal     | HTTP 401, "unauthorized", "invalid API key"    |
| `tool-missing`   | fatal     | Binary not found in PATH                       |
| `schema-invalid` | phase     | Output failed schema validation after reprompt |
| `exit-N`         | unknown   | Non-zero exit code with no pattern match       |

The fallback classifier in `lib/agent/error.sh` covers these patterns automatically.
Adapters that write a valid envelope take priority over the fallback.

---

## 4. Schema-in-prompt requirement (ADR-012)

Every adapter MUST make the relevant phase output schema available to the agent before
or during each phase invocation. This ensures the agent knows the expected output
format without relying solely on prose descriptions.

### Requirement

Before invoking the agent for any phase, the adapter MUST:

1. Copy the phase schema JSON to `$MONOZUKURI_WORKTREE/.monozukuri-schemas/`.
2. Reference the schema path in the agent's prompt or system context.

### Claude Code reference implementation

The Claude Code adapter writes all schemas to the worktree and references them in the
system context injected before the `feature-marker` skill run:

```bash
# Copies schemas/prd.schema.json, techspec.schema.json, tasks.schema.json,
# commit-summary.schema.json to $wt_path/.monozukuri-schemas/
_cc_inject_schemas "$wt_path"
```

The feature-marker skill prompt templates reference `.monozukuri-schemas/` so the
agent can read the expected format.

### Alternative implementations

- **Aider**: pass `--read .monozukuri-schemas/*.json` before the code phase prompt.
- **Codex / Gemini / Kiro**: prepend schema content to the `--message` or system
  prompt block using the adapter's native mechanism.

---

## 5. Routing config interface (ADR-015)

Per-project, per-phase adapter routing is configured in `.monozukuri/routing.yaml`:

```yaml
routing:
  default: claude-code
  phases:
    prd: claude-code
    techspec: claude-code
    tasks: claude-code
    code: aider
    tests: claude-code
    pr: claude-code
failover: false
```

`routing.yaml` is optional. When absent, all phases use the `default` adapter from
`config.yaml`. Per-phase overrides from `routing.yaml` take precedence over the
global default.

`routing suggest` (Gap 4) computes per-(adapter, phase) recommendations from canary
data; it requires ≥4 completed canary runs per (adapter, phase) pair before making
any suggestion.

---

## 6. Conformance suite

Location: `test/conformance/`

An adapter is conformant if it passes all checks in the suite.

### Current checks (`agent_phase_outputs.bats`)

| Check                 | What it verifies                                                                     |
| --------------------- | ------------------------------------------------------------------------------------ |
| `agent_verify`        | All six contract functions are defined after `agent_load`                            |
| Phase heading tests   | `render_phase_prompt` for each phase contains required headings                      |
| Mock binary sanity    | Fixture binary is executable and exits 0 for basic commands                          |
| Error envelope test   | On mock failure exit, `MONOZUKURI_ERROR_FILE` contains valid JSON with `class` field |
| Schema injection test | `.monozukuri-schemas/` is populated before `agent_run_phase` is called               |

### Running the suite

```bash
make test                          # runs all tests including conformance
bats test/conformance/             # conformance only
```

### Adding an adapter to the suite

1. Create `test/fixtures/agents/mock-<name>/<binary>` that:
   - Exits 0 for `--version` / auth checks
   - Exits 1 for a `--fail` flag (for error envelope testing)
2. Add the adapter name to `AGENTS_UNDER_TEST` in `agent_phase_outputs.bats`
3. Run `make test` to verify

---

## 7. Building a new adapter

### Step 1: Create the file

```bash
touch lib/agent/adapter-<name>.sh
chmod +x lib/agent/adapter-<name>.sh
```

### Step 2: Implement the six functions

Use `lib/agent/adapter-aider.sh` as a template — it is the reference
second-adapter implementation.

### Step 3: Implement error envelope writing

In `agent_run_phase`, after the agent command exits non-zero:

```bash
if [ "$exit_code" -ne 0 ] && [ -n "${MONOZUKURI_ERROR_FILE:-}" ]; then
  if declare -f agent_error_classify &>/dev/null; then
    agent_error_classify "$exit_code" "$log_file" > "$MONOZUKURI_ERROR_FILE" 2>/dev/null || true
  else
    printf '{"class":"unknown","code":"exit-%d","message":"adapter exit %d"}\n' \
      "$exit_code" "$exit_code" > "$MONOZUKURI_ERROR_FILE"
  fi
fi
```

### Step 4: Implement schema injection

```bash
_<name>_inject_schemas() {
  local wt_path="$1"
  local schemas_dir
  # Navigate from lib/agent/ → repo root → schemas/
  schemas_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/schemas"
  local dest="$wt_path/.monozukuri-schemas"
  mkdir -p "$dest"
  for f in prd techspec tasks commit-summary; do
    [ -f "$schemas_dir/$f.schema.json" ] && \
      cp "$schemas_dir/$f.schema.json" "$dest/" 2>/dev/null || true
  done
}
```

Call `_<name>_inject_schemas "$wt_path"` at the start of `agent_run_phase`.

### Step 5: Add mock fixture

```bash
mkdir -p test/fixtures/agents/mock-<name>
cat > test/fixtures/agents/mock-<name>/<binary> <<'EOF'
#!/bin/bash
[ "${1:-}" = "--version" ] && echo "mock-<name> 0.0.0" && exit 0
[ "${1:-}" = "--fail" ] && echo "mock failure" >&2 && exit 1
echo "mock-<name>: $*"
exit 0
EOF
chmod +x test/fixtures/agents/mock-<name>/<binary>
```

### Step 6: Run the conformance suite

Add your adapter to `AGENTS_UNDER_TEST` in `test/conformance/agent_phase_outputs.bats`
and run `make test`.

---

## 8. Schema versioning

Schemas follow SemVer in `schemas/CHANGELOG.md`:

- **Patch** (0.x.Y → 0.x.Z): added optional field. Existing adapters unaffected.
- **Minor** (0.X.0 → 0.Y.0): added required field with migration guide.
- **Major** (X.0.0 → Y.0.0): removed or renamed field. Adapters must update.

When releasing a breaking schema change, bump the `$id` URI in the schema file and
add a migration note to `schemas/CHANGELOG.md`.
