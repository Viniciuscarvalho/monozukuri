# Contributing to Monozukuri

Thank you for taking the time to contribute. This guide covers everything you need
to get from zero to a working local setup and through to a merged pull request.

---

## 1. Setup

```bash
git clone https://github.com/Viniciuscarvalho/monozukuri.git
cd monozukuri

# Runtime dependencies
brew install jq node gh

# Install pre-commit hooks and (future) ui/ npm deps
make install

# Verify your environment
monozukuri doctor
```

`monozukuri doctor` will tell you about any missing tools or misconfigured paths.

---

## 2. Running Locally

The main entry point is `scripts/orchestrate.sh`. You need a project to point it at:

```bash
# Use the bundled stub project for safe experimentation
./scripts/orchestrate.sh --project fm-validation/stub-project

# Point at a real project
./scripts/orchestrate.sh --project /path/to/your-project
```

Set `MONOZUKURI_DRY_RUN=1` to trace agent routing without executing anything.

---

## 3. Testing

Tests use [bats-core](https://bats-core.readthedocs.io/):

```bash
# Run all tests
make test

# Run a specific suite
bats test/unit
bats test/integration
```

New behavior should ship with a test. Aim to keep coverage above 80%.

---

## 4. Code Style

- All shell scripts must pass `shellcheck` with no warnings (`make lint`).
- Comments are only necessary when the _why_ is non-obvious. Avoid restating what
  the code does.
- JavaScript adapters in `scripts/adapters/` follow the surrounding style: no
  semicolons, single quotes, 2-space indent.
- Run `make fmt` to auto-format shell files with `shfmt`.

---

## 5. Commits

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add linear adapter retry logic
fix(router): handle empty task list gracefully
refactor(lib/runner): extract timeout helper
docs: add ADR for stuck-state elimination
test: cover cycle_gate edge cases
chore: bump pre-commit hook revisions
perf: cache project inventory between cycles
ci: add shellcheck step to workflow
```

Commitlint enforces this via the pre-commit hook installed by `make install`.

---

## 6. Pull Requests

1. Open an issue first for non-trivial changes so the approach can be agreed on.
2. Branch from `main`: `git checkout -b feat/your-feature`.
3. Push and open a PR using the template — fill in all sections.
4. PRs are squash-merged into `main`; link the relevant issue.
5. CI must be green before review is requested.

---

## 7. Release Process

Releases are automated via [release-please](https://github.com/googleapis/release-please):

1. Conventional commits on `main` accumulate in an open Release PR.
2. Merging the Release PR triggers the publish workflow, which:
   - Publishes the npm package (`npm/`) to the npm registry.
   - Updates the Homebrew tap formula.
3. The `HOMEBREW_TAP_TOKEN` secret must be set in repository settings for the
   Homebrew step to succeed — contact a maintainer if you need access.
