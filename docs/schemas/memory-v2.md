# Memory v2 Schema

Memory v2 records one auditable learning per entry. The schema is designed to
answer why a learning exists, where it came from, how often it has been applied,
and whether it is specific to one coding agent.

Machine-readable validation lives in
[`schemas/learning-v2.schema.json`](../../schemas/learning-v2.schema.json).

## Entry Shape

```yaml
id: lrn-YYYY-MM-DD-NNN
scope: feature|project|global
insight: string # max 200 chars
rationale: string # max 1000 chars, optional
source:
  feature_id: string
  phase: prd|techspec|tasks|code|tests|pr
  run_id: string
  artifact: string # relative path
  line_range: [int, int] # optional, 1-based inclusive
applied_count: int
last_applied: ISO8601|null
promoted_from: feature|user_correction|manual|auto_detected
agent_specific: claude-code|codex|gemini|null
tags:
  - string
```

## Field Semantics

`id` uses `lrn-YYYY-MM-DD-NNN` so entries sort by creation date and remain stable
across tiers.

`scope` identifies the level where the learning is valid:

- `feature`: only useful within one feature run.
- `project`: reusable within the current project.
- `global`: reusable across projects.

`insight` is the short reusable lesson. It must be specific enough to apply
without rereading the source artifact.

`rationale` explains why the insight is true. Use it when a reviewer will need
context beyond the short insight.

`source` points to the provenance record. `artifact` must be relative to the
project or run root. `line_range` is optional because generated artifacts may be
rewritten, but include it when the cited lines are stable.

`applied_count` starts at `0` and increments each time the learning affects a
future run.

`last_applied` records the most recent ISO8601 timestamp when the learning was
created or applied. Migrated v1 entries may use `null` because the v1 store did
not track an equivalent application timestamp.

`promoted_from` distinguishes automatically observed feature learnings from user
corrections and manual maintainer decisions.

`agent_specific` is `null` for portable learnings, or an adapter id when the
learning should only be injected for that agent.

`tags` supports filtering and future retrieval strategies.

## Example

```json
{
  "id": "lrn-2026-05-24-001",
  "scope": "project",
  "insight": "Use direct Bats for loop verification before full release gates.",
  "rationale": "Loop regressions are easiest to isolate with targeted Bats before running the full release suite.",
  "source": {
    "feature_id": "LOOP-09",
    "phase": "tests",
    "run_id": "loop-2026-05-24-a1b2c3",
    "artifact": "test/integration/loop_command.bats",
    "line_range": [290, 340]
  },
  "applied_count": 0,
  "last_applied": "2026-05-24T16:00:00Z",
  "promoted_from": "feature",
  "agent_specific": null,
  "tags": ["loop", "testing"]
}
```

## Validation

Validate one or more Memory v2 files with:

```bash
monozukuri memory lint path/to/learning-v2.json
monozukuri memory lint path/to/learning-v2.yaml
monozukuri memory migrate --dry-run
monozukuri memory migrate
monozukuri memory migrate --reverse
monozukuri memory why lrn-2026-05-24-001
monozukuri memory why lrn-2026-05-24-001 --format json
```

The validator accepts a single entry object, an array of entries, or JSONL files
with one entry per line. YAML support is intentionally limited to the documented
entry shape and exists for human-authored fixtures and audits, not arbitrary YAML
processing.

Without file arguments, `memory lint` searches common project store locations and
prints a no-store message when none exist.

`memory migrate` reads the existing v1 learning stores, writes
`.monozukuri/memory-v2.json`, and backs up the original v1 stores under
`.monozukuri/memory.v1.bak/`. `--dry-run` reports the migration plan without
writing files. `--reverse` writes `.monozukuri/memory-v1.roundtrip.json` for
roundtrip verification and compatibility checks.

`memory why <lrn-id>` inspects one learning's provenance and recent application
history. It prints the ID, insight, scope, source artifact, counters, and the
last 10 prompt injections that referenced the learning. Without an ID, it lists
the 10 most-applied learnings as suggestions for inspection.

## Injection Tracking

When a Memory v2 learning is injected into a phase prompt, the markdown context
uses a deterministic compact summary. The compactor groups relevant learnings by
`scope`, orders each group by `applied_count` descending, keeps at most five
entries per group, and renders each included learning as:

```markdown
<!-- learning: lrn-2026-05-24-001 --> [lrn-2026-05-24-001, applied 7x] Use direct Bats for CLI behavior changes.
```

The summary target is 500 `cl100k_base` tokens using `js-tiktoken`. If the
summary would exceed the cap, extra IDs are preserved in an
`available_on_request` context line so a future on-demand router can escalate to
full details without losing provenance. Summaries are cached by
`(phase, feature_id, hash(relevant_learnings))` under
`.monozukuri/cache/memory/` for seven days; content hash changes invalidate the
cache independently of file mtimes.

The marker makes rendered prompts auditable without changing how agents read the
natural-language instruction. Each rendered phase also appends a trace record to
`.monozukuri/runs/<feature-id>/memory-injections.jsonl`:

```json
{"phase":"prd","learnings":["lrn-2026-05-24-001"],"tokens":347,"timestamp":"2026-05-24T20:00:00.000Z"}
```

After a phase succeeds, each injected learning's `applied_count` increments and
`last_applied` is set to the success timestamp. Corrupt or unreadable Memory v2
stores are ignored for prompt injection so the pipeline can continue without
blocking the agent call.
