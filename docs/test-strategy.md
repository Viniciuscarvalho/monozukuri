# Test strategy

Monozukuri tests AI-driven orchestration without burning model credits in CI.
The pattern is **record once, replay forever, conform on demand**.

## Layers and cost

| Layer | When | CI cost | What it catches |
|---|---|---|---|
| Mock-based unit/integration (Layer 2) | every PR | $0 | orchestration, error paths, tool selection |
| Property assertions on recordings | every PR | $0 | recording fixtures still satisfy validator contract |
| Layer 5 live canary | release-gate (local) | ~$0.01 | claude CLI authenticates and produces text |
| Layer 6 scale soak (mock variant) | every release | $0 | 3 projects × 5 features run-to-completion |
| Layer 7 conformance | release-gate (local) | ~$0.30 | mock fixtures haven't drifted from live agent shape |
| V2 MRP matrix | nightly CI | $0 | Memory v2 token-saving assertion and dashboard |
| V2 loop conformance | nightly CI | $0 | Claude/Codex/Gemini loop orchestration parity |
| Layer 6 scale soak (live variant) | manual pre-release | ≤ $50 | end-to-end against real models, full SLO check |

**CI never spends money.** Layers 5, 6-live, and 7 are skipped in CI via env
flags (`MONOZUKURI_SKIP_LIVE_CANARY=1`, `MONOZUKURI_SKIP_SCALE_SOAK_LIVE=1`,
`MONOZUKURI_SKIP_CONFORMANCE=1`) and only run when a maintainer invokes the
release gate locally before tagging.

## The pattern

Mocks are **recordings**, not hand-written canned text. Recordings live in
`.qa/fixtures/recordings/<agent>/<phase>.{md,json,stream-json}` and are
replayed verbatim by `.qa/fixtures/mocks/replay-claude` during tests.

To re-record (local only — never CI):

    make rerecord-fixtures              # claude-code
    make rerecord-fixtures AGENT=all    # every agent

Cost: ~$0.50 per agent per full re-record. Maintainers do this when:
- Layer 7 reports drift
- The agent CLI version changes
- Validator-required headings or schemas change
- A new agent adapter lands

## Mock modes

The replay binary supports five modes via `MOCK_CLAUDE_MODE`:

| Mode | Behaviour | Use case |
|---|---|---|
| `normal` (default) | Replay recording verbatim | Happy-path tests |
| `hang` | `sleep 3600` | Verify `op_timeout` kills runaway processes |
| `auth-expired` | Emit auth error, exit 1 | Verify auth-failure error envelope |
| `diverge` | Replay recording with first `## ` heading dropped | Verify validators catch structural drift |
| `build-fail` | Stdout normally, write no artifacts | Verify silent-failure detection |

`diverge` is the proxy for "what if the real agent's output shape shifts a
little?" — it's the failure mode Layer 7 catches against live agents.

## Property contract

`test/properties/agent_output.bats` asserts the structural properties every
recording must satisfy:

- PRD: problem-framing + solution + requirements + out-of-scope headings
- TechSpec: approach + file-list headings
- tasks.json: array shape with required keys per element
- stream-json: line-delimited JSON, contains `tool_use`, ends with `message_stop`

These match what the validator checks. If a recording stops satisfying a
property here, the next agent run in production would also fail validation —
re-record.

## Layer 7 conformance — when to run

Layer 7 is **opt-in only**. To run it locally before a release tag:

    make conformance                    # one-shot
    # or, as part of full gate:
    bash .qa/release-gate.sh v1.x.0     # MONOZUKURI_SKIP_CONFORMANCE=0 if you want it

Cost per run: ~$0.30 (PRD + TechSpec phases × tiny prompt × claude-sonnet).

Recommended cadence: weekly during active development, every minor release
otherwise. Patch releases skip Layer 7 entirely.

## V2 verification — nightly CI

The scheduled `V2 Verification` workflow runs two mock-only gates:

```bash
make mrp-v2
make loop-conformance
```

`mrp-v2` writes `.qa/reports/mrp-v2-results.json` and
`.qa/reports/mrp-v2-dashboard.md`. It runs five deterministic iterations for
Claude Code, Codex, and Gemini, records total tokens, Code-phase tokens, total
time, first-pass success rate by phase, and Memory v2 summary-cache hit rate.
The gate fails when iteration 5 Code-phase tokens are not below 75% of
iteration 1 for every agent.

`loop-conformance` runs `monozukuri loop` over three mock backlog tasks for the
same three agents, then compares normalized orchestration events, checkpoint
shape, and summary report structure. Adapter-specific structured log text is
ignored; orchestration behavior drift fails the gate.

## What this does NOT cover

- **Performance regression.** Mocks can't catch "phase X got 30% slower."
  Defer until live canary baselines exist.
- **Prompt quality.** Use Layer 5 canary (`CANARY_OK` echo) for sanity, not
  quality.
- **Token economy claims.** Measure during real Layer 6-live runs.
- **Validator itself.** Validator is deterministic; doesn't need mocking.

## Relationship to PR #159

PR #159 shipped `MOCK_*_MODE` flags for codex/gemini and Layer 5/6
infrastructure. This document describes the additions that turn that into a
drift-resistant pattern: recordings, replay binary, property assertions, and
Layer 7. **No CI cost expansion** — every layer that calls a real agent is
gated behind a `SKIP` env var that CI sets to 1.
