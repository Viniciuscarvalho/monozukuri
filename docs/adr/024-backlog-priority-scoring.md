# ADR-024: Backlog Priority Scoring

- **Status**: Accepted
- **Date**: 2026-05-18
- **Deciders**: Vinicius Carvalho
- **Supersedes**: —
- **Related**: ADR-008 (Orchestrator Economy), ADR-015 (Routing, Implicit Deps, Review Surface)

---

## Context

`monozukuri backlog list` started with a deterministic rank of priority descending
and age ascending as a tie-breaker. That is good enough for a first list view, but
solo-dev planning needs a single explainable score that can answer "why is this
next?" without introducing an opaque model.

The score must stay deterministic, cheap to compute from adapter output, and easy
to override per project. It must also keep blocked dependency chains near the end
so unattended runs do not spend tokens on work that cannot sensibly complete.

---

## Decision

Backlog ranking uses this additive heuristic:

```text
score = (priority_weight * P) + (age_weight * A) - (effort_weight * E) + D
```

Where:

- `P` is the declared priority value: `high = 3`, `medium = 2`, `low = 1`,
  `none/unknown = 0`.
- `A` is age in complete weeks since the feature creation timestamp. Missing or
  invalid timestamps produce `0`.
- `E` is estimated effort in story points. Numeric efforts are used directly.
  T-shirt efforts map to `XS/S/M/L/XL/XXL = 1/1/3/5/8/13`. Missing or unknown
  effort produces `0`.
- `D` is `0` when every declared dependency exists and is `done`; otherwise it is
  `-100`.

Default weights are:

```yaml
scoring:
  priority_weight: 10
  age_weight: 1
  effort_weight: 2
```

These weights are intentionally lopsided:

- One priority level is worth ten weeks of age by default.
- A medium effort item (`3` points) loses six points, enough to break close ties
  without making effort dominate priority.
- The dependency penalty is larger than normal priority/age/effort variation, so
  unresolved dependency chains naturally sink to the end.

`monozukuri backlog list --score-explain <id>` prints the score inputs and
calculation for one item. This is a debug affordance, not a second ranking mode.

Ties are deterministic: higher score first, then higher priority value, then older
creation timestamp, then original adapter order.

---

## Consequences

### Positive

- Users can reason about ranking without learning a statistical model.
- Projects can tune the relative value of urgency, age, and effort in config.
- Dependency-blocked items remain visible but are deprioritized automatically.
- `--score-explain` gives a concrete support/debug path when ranking feels wrong.

### Negative / Trade-offs

- The formula is a heuristic; it will not capture strategic value unless the user
  reflects that value in priority or future fields.
- Missing effort is treated as `0`, which avoids punishing incomplete metadata but
  can over-rank unspecified work.
- Complete-week age avoids noisy daily reorderings but means newly created items
  get no age contribution until week one.

### Neutral

- Adapter output stays the source of truth. The scorer does not fetch tracker
  metadata itself.
- Scoring is independent from SEL-03 validation: validation warns about a selected
  set, while scoring only applies a ranking penalty to unresolved dependencies.

---

## Implementation Notes

- Config keys are parsed from `.monozukuri/config.yaml` as:
  `CFG_SCORING_PRIORITY_WEIGHT`, `CFG_SCORING_AGE_WEIGHT`, and
  `CFG_SCORING_EFFORT_WEIGHT`.
- The list command passes those values to `lib/backlog/list.js`.
- Dependency satisfaction is computed against the full adapter output: a declared
  dependency is satisfied only when the referenced item exists and has status
  `done`.
