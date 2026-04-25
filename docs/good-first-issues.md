# Good-First-Issues — v1.0 Launch Batch

12 issues to file on launch Monday. Each gets labels: `good-first-issue` + `help-wanted`.
File via `.github/ISSUE_TEMPLATE/feature_request.yml`.

---

## Issue 1 — `monozukuri export` command

**Title:** Add `monozukuri export --format json|markdown` for learnings

**Why:** Power users want to pipe learning entries into other tools (dashboards, Notion, scripts) without screen-scraping the terminal output.

**Scope:**

- New `cmd/export.sh` with `sub_export()`
- `--format json` (default) — emit `~/.claude/monozukuri/learned/learned.json` to stdout
- `--format markdown` — render a table of entries (ID, tier, created, summary)
- Wire into `orchestrate.sh` dispatch and help text

**Acceptance:**

- `monozukuri export --format json | jq '.entries | length'` returns a number
- `monozukuri export --format markdown` renders a readable table
- Non-TTY-safe (no interactive prompts)

---

## Issue 2 — Bash completion

**Title:** Add bash tab-completion for `monozukuri` subcommands and flags

**Why:** Tab completion reduces friction for first-time users discovering commands.

**Scope:**

- `scripts/completions/monozukuri.bash`
- Completes: subcommands, `--autonomy` values, `--adapter` values, `--model` values
- Installation instructions in `CONTRIBUTING.md`

**Acceptance:**

- `source scripts/completions/monozukuri.bash` + `monozukuri <TAB>` shows subcommands
- `monozukuri run --autonomy <TAB>` shows `supervised checkpoint full_auto`

---

## Issue 3 — Zsh completion

**Title:** Add zsh tab-completion for `monozukuri` subcommands and flags

**Why:** Most macOS developers use zsh (default since Catalina).

**Scope:**

- `scripts/completions/_monozukuri` (zsh completion function)
- Same coverage as Issue 2: subcommands + flag values

**Acceptance:**

- With `fpath` configured, `monozukuri <TAB>` shows completions with descriptions
- `monozukuri run --autonomy <TAB>` completes autonomy values

---

## Issue 4 — Fish completion

**Title:** Add fish shell completion for `monozukuri`

**Why:** Fish users are common in the developer community and expect first-class completion support.

**Scope:**

- `scripts/completions/monozukuri.fish`
- Same coverage as Issues 2–3

**Acceptance:**

- `monozukuri <TAB>` shows completions in fish
- `monozukuri run --model <TAB>` shows model options

---

## Issue 5 — `--verbose` / `--quiet` flags

**Title:** Add `--verbose` and `--quiet` flags to `monozukuri run`

**Why:** `--quiet` is useful in CI pipelines (suppress info/debug output); `--verbose` helps debug adapter and worktree issues.

**Scope:**

- Add `OPT_VERBOSE` and `OPT_QUIET` to `orchestrate.sh` CLI parser
- `--quiet`: suppress `info`/`log` calls (keep `err`/`warn`)
- `--verbose`: print sourced modules, worktree operations, adapter raw output
- Both flags passed through to `lib/cli/output.sh`

**Acceptance:**

- `monozukuri run --dry-run --quiet 2>/dev/null` produces no output
- `monozukuri run --dry-run --verbose` shows module load lines

---

## Issue 6 — `features.yaml` support

**Title:** Support `features.yaml` alongside `features.md` for the markdown adapter

**Why:** YAML backlogs are easier to parse programmatically and support richer metadata (due dates, links, sub-tasks).

**Scope:**

- Update `scripts/adapters/markdown.js` to detect `.yaml`/`.yml` extension
- YAML schema: list of objects with `id`, `title`, `why`, `scope`, `acceptance`, optional `labels`/`priority`
- Update `lib/config/schema.json` to document `source.markdown.file` accepting `.yaml`

**Acceptance:**

- `features.yaml` with 2 entries → `monozukuri run --dry-run` shows 2 features
- `features.md` still works unchanged

---

## Issue 7 — GitLab adapter

**Title:** Add GitLab Issues adapter (`scripts/adapters/gitlab.js`)

**Why:** Teams using GitLab self-hosted can't currently use the GitHub adapter.

**Scope:**

- `lib/plan/adapters/gitlab.js` — reads issues via GitLab REST API (requires `GITLAB_TOKEN` + `GITLAB_PROJECT_ID`)
- Filter by label (default `feature-marker`)
- Same output format as `github.js`: `[{id, title, body, priority, labels}]`
- Document env vars in `.env.example`

**Acceptance:**

- `source.adapter: gitlab` in config → adapter fetches issues from GitLab
- Missing `GITLAB_TOKEN` → clear error message with fix instruction

---

## Issue 8 — `monozukuri doctor --fix`

**Title:** Add `--fix` flag to `doctor` to auto-install missing dependencies

**Why:** New users who see `✗ jq not found` shouldn't have to google the install command — `doctor --fix` should do it.

**Scope:**

- `cmd/doctor.sh`: detect package manager (Homebrew on macOS, apt on Linux)
- Install missing: `jq`, `gum` (optional)
- Skip `node`, `gh`, `claude` — too risky to auto-install
- Print what it's about to do and confirm before installing

**Acceptance:**

- On a machine missing `jq`: `monozukuri doctor --fix` installs it via `brew install jq`
- `doctor --fix` on a fully-configured machine: "Nothing to fix."
- `--non-interactive` skips confirmation and installs silently

---

## Issue 9 — Retry logic for transient API errors

**Title:** Add retry with backoff for transient Linear/GitHub adapter errors

**Why:** Flaky network or API rate limits cause entire runs to fail; a 3-attempt retry with exponential backoff would recover automatically.

**Scope:**

- Utility function `retry_with_backoff <max> <delay> <cmd>` in `lib/core/util.sh`
- Apply to adapter HTTP calls in `lib/plan/adapters/github.js` and `linear.js`
- Log retry attempts at `warn` level
- Give up after 3 attempts with `err`

**Acceptance:**

- Simulated 500 response → adapter retries 3 times before failing
- Successful retry → run continues normally
- `lib/core/util.sh` has unit test in `test/unit/`

---

## Issue 10 — Shellcheck zero-warning pass

**Title:** Shellcheck all scripts to zero warnings; enforce in `make lint`

**Why:** Shellcheck catches subtle bugs (unquoted variables, word-splitting, etc.) that are hard to catch in review.

**Scope:**

- Run `shellcheck` on all `.sh` files in `orchestrate.sh`, `cmd/`, `lib/`
- Fix all warnings (or add `# shellcheck disable=SCnnnn` with a comment explaining why)
- Add `shellcheck` step to `Makefile`'s `lint` target
- Document `shellcheck` as a dev dependency in `CONTRIBUTING.md`

**Acceptance:**

- `make lint` passes with zero shellcheck warnings
- CI `ci.yml` runs `make lint` on every PR

---

## Issue 11 — Man page generation

**Title:** Generate a `monozukuri(1)` man page via `help2man`

**Why:** Developers who live in the terminal expect `man monozukuri` to work.

**Scope:**

- `Makefile` target: `make man` generates `docs/monozukuri.1` via `help2man`
- Install target copies to `$(brew --prefix)/share/man/man1/` when Homebrew
- Homebrew formula update to install man page (follow-on PR to `homebrew-tap`)

**Acceptance:**

- `make man` produces `docs/monozukuri.1`
- `man ./docs/monozukuri.1` renders without errors
- All subcommands appear in the COMMANDS section

---

## Issue 12 — i18n scaffold for error messages

**Title:** Add i18n scaffold for error messages (English-only initially)

**Why:** Prepares for localization without blocking any current work; establishes the pattern for future translators.

**Scope:**

- `lib/i18n/en.sh` — associative array `MZ_MSG[key]="message"` for every string currently in `lib/cli/errors.sh` and key `err`/`warn` calls
- `monozukuri_error` reads from `MZ_MSG` if key exists, falls back to literal string
- `LANG` env var detection (use `en` as default; warn if unsupported locale)
- Document contribution guide for adding a new locale in `CONTRIBUTING.md`

**Acceptance:**

- All current error messages have a key in `lib/i18n/en.sh`
- `LANG=en_US.UTF-8 monozukuri run` — identical output to today
- Adding a new locale requires only a new `lib/i18n/<code>.sh` file

---

## Filing checklist

Before filing each issue:

- [ ] Add labels: `good-first-issue`, `help-wanted`
- [ ] Add note: ⭐ Mentor available — ping @viniciuscarvalho in the issue
- [ ] Verify `.github/ISSUE_TEMPLATE/feature_request.yml` is merged first
- [ ] Link related issues (e.g., Issues 2–4 are all "completions" — link them)
