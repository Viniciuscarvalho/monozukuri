## Approach

Replay-based mock infrastructure: capture `claude --print` output once per phase against a tiny canary prompt, store as fixtures, replay verbatim from disk during tests.

## File change map

- `.qa/fixtures/recordings/<agent>/<phase>.md` — captured artifact bodies
- `.qa/fixtures/recordings/<agent>/<phase>.stream-json` — captured stream-json events (property tests only)
- `.qa/fixtures/recordings/metadata.json` — recorder version, model, captured-at
- `.qa/fixtures/mocks/replay-claude` — new replay binary
- `scripts/rerecord-fixtures.sh` — local-only re-recording driver

## Components

- **Replay binary**: reads stdin, picks recording by `MONOZUKURI_PHASE`, replays based on `MOCK_CLAUDE_MODE`.
- **Property bats**: structural assertions on every recording (every PR, free).
- **Layer 7 conformance**: opt-in only; not wired into CI.

## Testing

- Property assertions on every PR (no API calls)
- Conformance against live agent only when a maintainer runs `bash .qa/release-gate.sh <ver>` locally with `MONOZUKURI_SKIP_CONFORMANCE=0`
