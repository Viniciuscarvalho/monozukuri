# Release Canary

VRF-03 promotes Layer 5 from a single prompt smoke test to a live loop canary.
Before a non-patch release, the release gate runs the dedicated sandbox repo
through the real selected agents:

```bash
scripts/verification/live-canary.sh --live --tasks 2 --max-cost 5
```

The harness clones `monozukuri/test-sandbox`, then runs:

```bash
monozukuri loop --tasks 2 --agent claude-code --max-cost <remaining>
monozukuri loop --tasks 2 --agent codex --max-cost <remaining>
monozukuri loop --tasks 2 --agent gemini --max-cost <remaining>
```

Success means each agent opens exactly two sandbox PRs and every opened PR has
green sandbox CI. Any missing PR, red check, agent failure, or cost overrun
blocks the release and requires investigation before retrying.

Layer 5 writes:

- `.qa/reports/live-canary/results.json`
- `.qa/reports/live-canary/summary.md`
- `.qa/reports/live-canary/<agent>/stdout.txt`
- `.qa/reports/live-canary/<agent>/stderr.txt`

The live run requires authenticated `gh`, `claude`, `codex`, and `gemini` CLIs.
Set `MONOZUKURI_SKIP_LIVE_CANARY=1` only for CI or explicitly cost-free dry
release checks. The total live cap is `$5`; the harness carries the remaining
budget into each agent run instead of giving every agent its own `$5`.

For local no-cost verification of the harness itself:

```bash
scripts/verification/live-canary.sh --mock --tasks 2 --max-cost 5
```
