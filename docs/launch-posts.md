# Launch Posts — Mon–Fri schedule

## Channel order (locked)

| Day | Channel      | Risk | Fit    |
| --- | ------------ | ---- | ------ |
| Wed | r/ClaudeCode | Low  | High   |
| Thu | Dev.to       | Low  | Medium |
| Fri | Show HN      | High | High   |

---

## r/ClaudeCode — Wednesday self-post

**Title:** Monozukuri — autonomous backlog runner for Claude Code (runs your features.md → PRs while you're away)

**Body:**

I built Monozukuri after getting tired of manually shepherding Claude Code through my feature backlog one task at a time.

It reads a `features.md` (or Linear/GitHub Issues), creates isolated git worktrees, and invokes a Claude Code skill — `feature-marker` by default — for each feature. One `monozukuri run` until the backlog is empty.

**What it does:**

- Reads your backlog (markdown, GitHub Issues, or Linear)
- Opens a git worktree per feature (parallel, no branch ordering hell)
- Runs your Claude Code skill in each worktree
- Opens PRs automatically
- Learns across runs — patterns from feature N inform feature N+1

**Autonomy levels:** `supervised` (review each step), `checkpoint` (review before PR), `full_auto` (runs unattended)

**Install:**

```
brew install viniciuscarvalho/tap/monozukuri
```

Source: https://github.com/viniciuscarvalho/monozukuri

Would love feedback on the first-run experience — especially from anyone who tries it with a non-feature-marker skill.

---

## Dev.to — Thursday article (~1500 words)

**Title:** I built an autonomous backlog runner for Claude Code

**Tags:** claudeai, devtools, opensource, productivity

**Cover image:** `assets/banner.svg`

---

**Hook (first 2 paragraphs — visible in feed preview):**

Six months ago I started using Claude Code to implement features. It was great — until I realized I was spending more time _managing_ Claude Code than coding myself. Every feature meant: open terminal, invoke the skill, watch it run, open PR, repeat.

So I built Monozukuri. It reads my feature backlog and runs Claude Code autonomously — one command, all features, PRs at the end.

---

**Article outline:**

### The problem

- Claude Code is powerful but point-in-time: one task, one session
- Backlog has 20 features → 20 manual invocations → you become the orchestrator
- Opportunity: Claude Code can read CLAUDE.md, understand context, use skills — it just needs a wrapper that handles the backlog loop, git isolation, and state persistence

### What Monozukuri does

- Reads backlog (features.md, GitHub Issues, Linear)
- Creates a git worktree per feature — each feature runs on its own branch, parallel, no merge-ordering dependencies
- Invokes the configured Claude Code skill in each worktree
- Opens a PR on success, records the outcome in the learning store
- Autonomy knob: supervised → checkpoint → full_auto

### Architecture (diagram)

```
features.md → [adapter] → backlog JSON
                              ↓
              [router] assigns model (plan / execute)
                              ↓
         [worktree manager] creates branch + worktree
                              ↓
           [runner] invokes claude --skill feature-marker
                              ↓
              [gates] size check / cycle check
                              ↓
         [learning store] records patterns for next run
                              ↓
                      gh pr create
```

### The learning store

Three tiers: feature → project → global. Each run writes what worked and what didn't. The next feature starts with that context. After a few runs, the success rate improves noticeably — not because the model got smarter, but because the context window starts with relevant patterns.

### What it doesn't do

- It doesn't write your feature specs (that's your job, or Feature-marker's)
- It doesn't review code (that's `gh pr review`)
- It doesn't replace your CI pipeline (it triggers it)

### Live demo

[embed `assets/demo.svg` + link to docs/demo.md]

### Install and try it

```bash
brew install viniciuscarvalho/tap/monozukuri
cd your-project
monozukuri init
monozukuri run --dry-run   # see the plan
monozukuri run             # run it
```

### What's next

12 good-first-issues are open — completions, GitLab adapter, export command. If you try it and hit friction, open an issue or ping me here.

---

## Show HN — Friday morning PT

**Title:** Show HN: Monozukuri – autonomous backlog runner for Claude Code

**URL:** https://github.com/viniciuscarvalho/monozukuri

**Text (shown below link, 2–3 sentences max):**

Reads your features.md (or Linear/GitHub Issues), opens an isolated git worktree per feature, and invokes a Claude Code skill — by default feature-marker — for each one. One `monozukuri run` command; PRs come out the other end. Autonomy levels go from supervised (human reviews each step) to full_auto (runs overnight). Would love to hear from anyone running a different Claude Code skill.

---

## Response playbook

**When someone asks "how is this different from just running Claude Code in a loop?"**

> The loop part is easy. The hard parts are: (1) git isolation — each feature needs its own worktree so parallel work doesn't conflict, (2) state persistence — knowing which features are done, failed, or blocked across sessions, and (3) the learning store — carrying forward what worked and what didn't so feature N+1 starts smarter than feature 1. Monozukuri handles all three.

**When someone says "this is just a bash wrapper"**

> Yes, mostly. The shell orchestrator is deliberate — it means zero Node.js cold-start on every feature invocation and easy hackability (source a different adapter or skill with one line). The Ink TUI is the only Node process, and it's optional.

**When someone asks about cost / model selection**

> By default it uses `opusplan` — Opus for planning, Sonnet for execution. Size gates and cycle gates block runaway spend before it happens. The `--dry-run` flag shows you exactly what will run and what it'll cost before a single token is spent.

**When someone asks "does it work with X skill?"**

> Anything you can invoke as a Claude Code slash-command works. Change `skill.command` in `.monozukuri/config.yaml`. I'd love to hear what you're using it with.

**Rule for HN replies:** Acknowledge harsh feedback, ask what would change their mind, move on. No defensive replies. Max 3 exchanges per thread.
