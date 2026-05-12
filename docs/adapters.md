# Backlog adapters

Monozukuri reads features from one of three sources: a markdown file in your repo, GitHub Issues, or Linear. Each source is implemented as an adapter behind a common contract — switching adapters is a single config edit. This page documents the three built-in adapters, their authentication requirements, and the conventions each expects from your backlog.

For the config schema see [configuration.md](configuration.md#source). For what happens after a feature is read see [execution.md](execution.md).

---

## The adapter contract

Every adapter returns the same shape to the orchestrator: an ordered list of features, each with an ID, a title, a description, and optional metadata (labels, priority, size hints). The orchestrator does not know or care where the list came from. Adapters are responsible for authentication, sorting, and filtering — by the time the orchestrator sees the list, it is ready to run.

A feature must have at minimum an ID and a title. Everything else is optional but recommended — descriptions feed the PRD phase, and labels can drive the size gate's escalation decisions.

---

## At a glance

| Adapter    | Source                                   | Auth                          | Best for                  |
| ---------- | ---------------------------------------- | ----------------------------- | ------------------------- |
| `markdown` | A file in your repo                      | None                          | Solo projects, OSS, demos |
| `github`   | GitHub Issues filtered by label          | `gh auth login` or `GH_TOKEN` | Teams already on GitHub   |
| `linear`   | Linear issues filtered by team and state | `LINEAR_API_KEY`              | Teams already on Linear   |

---

## Markdown

The simplest adapter. Reads features from a single file in your repo — `features.md` by default. The file is plain markdown with one top-level list item per feature and optional YAML front matter per item.

```yaml
# .monozukuri/config.yaml
source:
  adapter: markdown
  markdown:
    file: features.md
```

**File format.** Each feature is a top-level `-` list item. The first line is the title. An optional fenced front-matter block carries metadata. Everything between the front matter and the next list item is the description and feeds the PRD phase.

````markdown
<!-- features.md -->

- feat-001: Add OAuth login

  ```yaml
  priority: high
  labels: [auth, security]
  size_hint: medium
  ```
````

Users should be able to sign in with Google and GitHub. The existing email/password
flow stays as a fallback. Sessions live in Redis with a 30-day TTL.

- feat-002: Migrate logging to structured JSON
  ...

````

<!-- CONFIRM: exact front matter keys supported (priority, labels, size_hint, depends_on) -->

**Editing as the loop runs.** The file is re-read at the start of each feature, so you can edit `features.md` while a `checkpoint` or `full_auto` run is in progress. Features marked complete in `state.json` are skipped on the next pass; new features added below the cursor are picked up. This makes the markdown adapter convenient for OSS projects where the maintainer wants to steer the backlog mid-run.

**When to use it.** Solo projects, demos, OSS repos where the backlog should live next to the code, and any case where you want full diff history of what the agent was asked to build.

---

## GitHub

Reads issues from a GitHub repository, filtered by label. Requires `gh auth login` with `repo` scope, or `GH_TOKEN` exported in the environment.

```yaml
# .monozukuri/config.yaml
source:
  adapter: github
  github:
    repo: viniciuscarvalho/my-project   # defaults to `origin` if omitted
    label: monozukuri                   # only issues with this label are picked up
    state: open                         # open | closed | all (default: open)
````

**Setup.** Run `gh auth login` once per machine and grant `repo` scope. The adapter uses the same credentials the GitHub CLI uses; you do not configure a separate token unless you want to (in which case set `GH_TOKEN`).

**Issue conventions.** The issue title is the feature title. The issue body is the feature description and feeds the PRD phase verbatim. Labels other than the filter label are passed through to the orchestrator as metadata — you can use them to drive size-gate escalation (e.g. label an issue `large` and configure the size gate to always escalate on that label).

**PR linkage.** The pull request the agent opens is linked to the source issue with `Closes #N` in the PR body. Merging the PR closes the issue automatically, which is what most teams want. If you prefer not to auto-close, set `auto_close_issue: false` in the `github` block.

<!-- CONFIRM: auto_close_issue flag — verify against adapter implementation -->

**When to use it.** Teams whose backlog already lives in GitHub Issues and who want the agent to consume that backlog without copying it elsewhere. Pairs well with GitHub Projects for prioritization.

---

## Linear

Reads issues from a Linear team, filtered by state. Requires a Linear API key.

```yaml
# .monozukuri/config.yaml
source:
  adapter: linear
  linear:
    team: ENG # team key (the part before the issue number, e.g. ENG-123)
    state: Backlog # state name as it appears in your Linear workflow
    label: monozukuri # optional additional filter
```

**Setup.** Generate a personal API key from your Linear account settings and put it in `.env` as `LINEAR_API_KEY=lin_api_...`. The key needs read access to the team you configure. Do not commit `.env` — `monozukuri init` adds it to `.gitignore` by default.

**Issue conventions.** The Linear issue title is the feature title. The Linear description (markdown) is the feature description. Labels on the issue are passed through as metadata. Priority is mapped from Linear's 0–4 scale to the orchestrator's `low` / `normal` / `high` scale.

<!-- CONFIRM: priority mapping table — verify against adapter implementation -->

**State transitions.** When the agent opens a PR for a feature, the source Linear issue is moved to `In Review` (or whatever state you configure under `in_review_state`). When the PR merges, it moves to `Done`. Both transitions are configurable.

```yaml
linear:
  team: ENG
  state: Backlog
  in_review_state: In Review
  done_state: Done
  transition_on_pr: true # set false to keep states manual
```

**When to use it.** Teams whose product / engineering planning lives in Linear. The state transitions keep Linear honest as the source of truth for what is shipped.

---

## Switching adapters

Switching adapters is a single config edit. The other adapter blocks can stay in `config.yaml` — only the block matching the active `adapter` is read.

```yaml
source:
  adapter: github # was: markdown
  markdown:
    file: features.md # kept for reference, ignored while adapter is github
  github:
    repo: owner/repo
    label: monozukuri
```

State carries across adapter switches. Features that were marked complete under the previous adapter stay complete — Monozukuri keys completion on the feature ID, so as long as IDs are stable across sources you can move a backlog from markdown to Linear without losing progress. If the IDs differ between sources (which they usually will), run `monozukuri cleanup` before switching to start fresh.

---

## Custom adapters

The adapter interface is intentionally narrow — a custom adapter is a script that prints a JSON array of features to stdout. If the built-in three do not cover your source (Jira, Notion, a database, a spreadsheet), you can point Monozukuri at a custom command and let it handle the fetch.

```yaml
source:
  adapter: command
  command:
    exec: ./scripts/fetch-features.sh
    timeout_seconds: 30
```

<!-- CONFIRM: custom command adapter — verify whether this is shipped today or planned.
     If planned, link to the tracking issue. -->

The custom adapter contract and a worked example for Jira live at [adr/008-orchestrator-economy.md](adr/008-orchestrator-economy.md#adapter-contract).
