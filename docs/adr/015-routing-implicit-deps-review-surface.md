# ADR-015: Per-Phase Routing, Implicit-Dep Detection & Run Review Surface

- **Status**: Accepted
- **Date**: 2026-04-26
- **Deciders**: Vinicius Carvalho
- **Supersedes**: —
- **Related**: ADR-008 (Orchestrator Economy), ADR-012 (Adapter Contract & Schemas), ADR-013 (Failure Handling)

---

## Context

Three gaps require coordinated design because they share the same data sources
(routing config, TechSpec schema, run-manifest):

1. **Per-phase routing** (Gap 4): ADR-008 routes by stack at the feature level.
   There is no per-phase adapter selection and no data-driven recommendation.
2. **Implicit-dep detection** (Gap 7): two features that touch the same files
   can run in parallel and produce merge conflicts. Explicit `depends_on` references
   are not validated at ingestion, so bad references silently corrupt topo-sort.
3. **Run review surface** (Gap 6): there is no way to inspect a completed or
   in-flight run beyond raw log files. The "trust surface" — the artifact you show
   a skeptical reviewer — does not exist.

Three grilling decisions (Q10, Q11, Q13 from the 2026-04-26 session) are
consolidated here.

---

## Decision

### 1. Per-phase routing configuration

`routing.yaml` per project (at `.monozukuri/routing.yaml`), with user-level
defaults at `~/.config/monozukuri/routing.yaml`. Project-level overrides user-level.

```yaml
# .monozukuri/routing.yaml
phases:
  prd: claude-code
  techspec: claude-code
  tasks: claude-code
  code: aider # override for this project
  tests: claude-code
  pr: claude-code
failover: false # cross-agent failover on rate-limit (see ADR-013)
```

The executor reads `routing.yaml` at run start and invokes the specified adapter
per phase. An adapter not installed or failing its health check causes a `fatal`
classification for that feature (per ADR-013).

### 2. `routing suggest` — data-threshold-gated recommendation

`monozukuri routing suggest` ships in Gap 4 but is gated on data:

- **Threshold**: ≥ 4 canary run results per (adapter, phase) pair before a
  recommendation is emitted.
- **Below threshold**: the command returns a structured "insufficient data"
  response listing current counts:
  ```
  routing suggest: insufficient data for Code phase.
  aider: 2 runs · claude-code: 7 runs · need ≥ 4 of each to recommend.
  run more canaries or wait for next scheduled run.
  ```
- **Above threshold**: recommendation formula:
  ```
  score(adapter, phase) = 0.6 × ci_pass_rate + 0.4 × (1 - cost_percentile)
  ```
  Both factors are computed from canary history (`docs/canary-history.md`). The
  formula and weights are documented and user-overridable in `routing.yaml`.

Routing data is sourced from the canary benchmark (ADR-014), not from real-world
runs. This prevents recommendation instability from noisy real-world variance.

### 3. Implicit-dep detection

**3a. Explicit-dep validation at ingestion (Phase 1)**

Every `depends_on: <feat-id>` reference in the backlog is validated against the
full feature list at ingestion time. A bad reference fails loud with file:line
rather than silently corrupting topo-sort:

```
error: backlog/features.md:47: depends_on references unknown feature "feat-099".
known features: feat-001 … feat-098, feat-100. fix the reference and re-run.
```

**3b. `files_likely_touched` — pre-Code gate**

The TechSpec schema (ADR-012) requires `files_likely_touched: string[]`. At the
start of the Code phase, monozukuri checks all currently in-flight worktrees for
file-set overlap:

- If overlap is detected: this feature is marked `deferred` until the overlapping
  feature reaches cycle-gate-complete. The topo-sort is updated in the manifest.
  The deferral is logged to the run report: _"feat-012 deferred: overlaps
  feat-008 on src/users/auth.ts."_
- If no overlap: proceed immediately.

Granularity: file-level. Function-level detection is deferred until file-level
false-serialisation is measured as a real problem.

**3c. Post-code verification**

After the Code phase commits, capture actual files touched via
`git diff --name-only $base_sha HEAD`. Store as `files_actually_touched` in
per-worktree state (ADR-013). Do not fail on mismatch; record the delta as a
learning signal (Gap 5) and a routing data point.

The run report includes: _"N features serialised due to file-overlap prediction;
M overlaps were confirmed by post-code verification; K were false positives."_

### 4. Run review surface

**Live runs** use the existing Ink TUI dashboard (the Plan A implementation). No
change.

**Past runs** — `monozukuri review` subcommand:

| Command                             | Behaviour                                                                              |
| ----------------------------------- | -------------------------------------------------------------------------------------- |
| `monozukuri review export <run-id>` | Writes a self-contained HTML+JS+JSON bundle to `runs/<run-id>/review/index.html`.      |
| `monozukuri review open <run-id>`   | Writes the bundle then opens it with the system default browser (`open` / `xdg-open`). |
| `monozukuri review list`            | Lists run IDs and their headline metrics.                                              |

The bundle is fully static — no server required. It can be opened with
`file://`, hosted on GitHub Pages, gisted, or attached to a PR comment. This
preserves the "no hosted runtime" property of the product.

Both the Ink TUI and the static bundle consume the same canonical data source:
`runs/<run-id>/manifest.json` (ADR-013), extended at run end with a
`report.json` containing headline metric, cost, duration, and per-feature
breakdown.

The honest-copy update: _"Local-first, open source, no hosted runtime — every
run produces a portable HTML report you can share or attach to a PR."_

---

## Consequences

### Positive

- Per-phase routing makes L4 (multi-agent) a config change, not a code change.
- `routing suggest` is honest about data sufficiency; it never recommends on
  noise.
- Explicit-dep validation at ingestion catches a class of silent topo-sort bugs
  before any feature runs.
- File-overlap serialisation prevents merge conflicts without requiring a
  dependency declaration the backlog author forgot.
- The static HTML bundle is a durable artifact — it survives the process, can be
  attached to issues, and cannot be misconstrued as "hosted infrastructure."

### Negative / Trade-offs

- TechSpec schema gains a required field (`files_likely_touched`); existing
  adapters need to populate it or emit validation failures until updated.
- File-overlap predictions may serialise independent features that touch the same
  file for unrelated reasons (e.g., two features add imports to `index.ts`). The
  false-serialisation rate is logged; if high, tighten the overlap heuristic.
- The static bundle SPA (a small Preact or vanilla-JS app) is a new frontend
  artifact inside a shell-heavy repo. Keep it minimal — no build pipeline beyond
  a single `esbuild` or `deno bundle` invocation.

### Neutral

- `routing suggest` formula weights (0.6 / 0.4) are explicit and overridable;
  they are not hidden hyperparameters.
- The `review` subcommand adds no new runtime dependencies; the bundle is generated
  from on-disk JSON and a bundled JS template.

---

## Implementation Notes

- `lib/run/routing.sh` — reads `routing.yaml`, exports `PHASE_ADAPTER_<PHASE>`
  env vars for the executor.
- `lib/run/dep-check.sh` — ingestion validator; run before topo-sort in
  `lib/run/ingest.sh`.
- `lib/run/implicit-dep.sh` — `overlap_check(feat_id, files_likely_touched[])`
  scans all `in_progress` worktrees' `files_likely_touched` arrays from their
  `state.json`. Returns overlapping feature IDs.
- `cmd/review.sh` — generates the static bundle. Template lives in
  `lib/review/template/`. Bundle written to `$PROJECT_ROOT/runs/<run-id>/review/`.
- Routing data store: append-only JSONL at
  `$STATE_DIR/routing-data/<adapter>/<phase>.jsonl`. One line per canary run
  result. `routing suggest` reads this file for the formula inputs.
