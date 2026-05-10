# Agent recordings

Captured outputs from real agent runs against the canary feature
(`.qa/fixtures/contexts/canary-feature.json`). The replay mock at
`.qa/fixtures/mocks/replay-claude` reads these verbatim.

## Layout

    recordings/
      metadata.json              # capture provenance (model, time, recorder version)
      <agent>/
        prd.md                   # PRD-phase artifact body
        prd.stream-json          # PRD-phase stream-json events (property tests)
        techspec.md
        techspec.stream-json
        tasks.json
        tasks.stream-json

## Re-recording

    make rerecord-fixtures              # claude-code only (default)
    make rerecord-fixtures AGENT=codex  # one specific agent
    make rerecord-fixtures AGENT=all    # every supported agent

This invokes `scripts/rerecord-fixtures.sh`, which runs each phase against the
real CLI and writes results into this directory. **Local action only — never
runs in CI.** Cost: roughly $0.50 per agent per full re-record.

## Cost & cadence

| Action | Cost | Where it runs |
|---|---|---|
| Property tests over recordings | $0 | every PR (CI) |
| Re-recording fixtures | ~$0.50 / agent | local, on demand |
| Layer 7 conformance vs live | ~$0.10 / phase | local pre-release only |

CI never spends money against live agents in this infrastructure. The release
gate's Layer 5 (live canary) and Layer 7 (conformance) both honor
`MONOZUKURI_SKIP_*` flags that CI sets to `1`.

## When to re-record

- Agent CLI version changes
- Layer 7 conformance reports drift
- Validator-required heading or schema changes
- A new agent adapter lands
