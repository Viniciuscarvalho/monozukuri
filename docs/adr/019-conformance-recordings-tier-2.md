# ADR-019: Conformance Recordings for Tier-2 Adapters

**Status:** Proposed
**Date:** 2026-05-14
**Related:** ADR-012 (Adapter Contract & Phase Artifact Schemas), ADR-016 (Thirteen-Week Plan)

---

`.qa/fixtures/recordings/codex/` and `.qa/fixtures/recordings/gemini/` are seeded from Claude recordings — they capture the right structural shape but not real tier-2 agent output. Layer 7 (`07-conformance.sh`) only compares claude-code recordings against a live Claude call; tier-2 agents are ignored entirely.

**Decision:** Two changes close this gap:

1. **`make rerecord-fixtures AGENT=codex` (and `AGENT=gemini`)** — runs the real CLI against the canary feature and writes real responses to `.qa/fixtures/recordings/<agent>/`. Updates `metadata.json` field `captured_with` from `"seed"` to `"real"` and populates `captured_at` and `model`.

2. **Extend Layer 7 to check tier-2 agents.** `run_layer7` gains a per-agent loop. For each agent where the CLI is available (`command -v codex`, `command -v gemini`) and recordings exist with `captured_with: "real"`, Layer 7 runs the same tiny canary prompt against the live CLI and compares structural properties. When the CLI is absent, it skips with `~ skipped (codex CLI not installed)`. Layer 7 remains local-only (`MONOZUKURI_SKIP_CONFORMANCE=1` in all CI runs) — this constraint does not change.

**Why extend Layer 7 rather than relying on re-recording alone?** Re-recording detects drift only when the maintainer manually remembers to run it. Layer 7 detects drift automatically on every pre-release run once a real recording exists. The two mechanisms are complementary: re-recording establishes the baseline; Layer 7 watches for future drift. Seeded recordings (`captured_with: "seed"`) are skipped by the drift check — Layer 7 can only compare structure when a real baseline is available.

**Constraint:** The `metadata.json` field that distinguishes real from seeded recordings is `captured_with` (not a new field — already present; value changes from `"seed"` to `"real"`).
