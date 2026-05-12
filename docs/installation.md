# Installation

Monozukuri is a CLI orchestrator that invokes a coding agent — Claude Code, Codex, Gemini, or Kiro — for each feature in your backlog. It is shipped through three channels — Homebrew, NPX, and source. This page covers the requirements, the three install paths, how to verify the install worked, and platform-specific notes.

The [Quick start](../README.md#quick-start) in the README is enough for a fresh macOS or Linux machine with the prerequisites already installed. If you are setting up from scratch, start here.

---

## Requirements

Monozukuri assumes four tools are on your `PATH`:

| Tool      | Minimum | Why                                                                                                                                                       |
| --------- | ------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `node`    | `>=18`  | Runtime for the Ink TUI bundle and the NPX install path                                                                                                   |
| `jq`      | `>=1.6` | Shell state parsing — used throughout the orchestrator scripts                                                                                            |
| `gh`      | `>=2.0` | GitHub CLI; required for PR creation in the PR phase                                                                                                      |
| Agent CLI | latest  | The coding agent that executes each feature — `claude` (Claude Code), `codex`, `gemini`, or `kiro`. Install the one that matches `agent:` in your config. |

If you install via Homebrew, `node`, `jq`, and `gh` are pulled in as Homebrew dependencies — you only need to install your chosen agent CLI separately. The NPX and source paths assume the prerequisites are already present.

**Authentication.** `gh auth login` must be completed once per machine (or `GH_TOKEN` exported) before the PR phase will succeed. Each agent CLI has its own auth flow — for Claude Code set `ANTHROPIC_API_KEY`; for Codex set `OPENAI_API_KEY`; for Gemini run `gemini auth login`; for Kiro follow the Kiro setup guide. See your agent's documentation for the current auth flow.

---

## Homebrew (recommended)

The Homebrew tap is the supported install path. Updates are delivered through `brew upgrade` and the formula tracks the npm release.

```bash
brew tap viniciuscarvalho/tap
brew install monozukuri
```

That gives you the `monozukuri` command on `PATH`, plus the prerequisites the formula declares as dependencies. Install your chosen agent CLI (`claude`, `codex`, `gemini`, or `kiro`) separately following its own documentation.

To upgrade later:

```bash
brew update
brew upgrade monozukuri
```

To uninstall:

```bash
brew uninstall monozukuri
brew untap viniciuscarvalho/tap
```

---

## NPX (no install)

If you do not want to install Monozukuri globally, you can invoke it through NPX. Every invocation downloads and runs the latest published version, which is the right choice for trying it out or for CI environments where you do not want global state.

```bash
npx @viniciuscarvalho/monozukuri run --dry-run
npx @viniciuscarvalho/monozukuri run --autonomy checkpoint
```

You can alias it locally for convenience:

```bash
alias monozukuri="npx @viniciuscarvalho/monozukuri"
```

Pin a specific version when you want reproducibility:

```bash
npx @viniciuscarvalho/monozukuri@1.0.0 run
```

The NPX path does not install the `node` / `jq` / `gh` / agent CLI prerequisites — you need those on your machine first.

---

## From source

For development, customization, or environments where Homebrew is not available.

```bash
git clone https://github.com/Viniciuscarvalho/monozukuri.git
cd monozukuri
./scripts/orchestrate.sh --help
```

The source install runs from the cloned directory — there is no global `monozukuri` command. Either invoke `./scripts/orchestrate.sh` directly from inside the repo, or add a symlink to `~/.local/bin`:

```bash
ln -s "$(pwd)/scripts/orchestrate.sh" ~/.local/bin/monozukuri
```

The from-source path is also the right choice if you are contributing — fork, clone, branch, and the orchestrator runs against your local changes immediately.

---

## Verifying the install

After any install method, confirm everything is wired up:

```bash
monozukuri --version
monozukuri doctor
```

```
<!-- CAPTURE: paste output of `monozukuri doctor` against a correctly-configured machine.
     Should show: version, node version, jq version, gh auth status, claude CLI status,
     and a summary line. -->
```

<!-- CONFIRM: `monozukuri doctor` command — verify it exists. If not, document the manual
     verification (which version checks the user should run for each prereq). -->

`monozukuri doctor` checks each prerequisite, verifies `gh` authentication and your configured agent CLI, and reports the version of each tool. A green report means you can run `monozukuri init` in a project.

If `doctor` reports an issue, the most common causes are:

- **Agent CLI not found.** Install the CLI for your configured agent (`claude`, `codex`, `gemini`, or `kiro`) per its documentation, then re-run.
- **`gh` not authenticated.** Run `gh auth login` with `repo` scope.
- **`node` too old.** Upgrade to Node 18 or later. On macOS with Homebrew: `brew install node@20`.
- **`jq` not found.** `brew install jq` (macOS), `apt install jq` (Debian/Ubuntu), or equivalent for your distro.

---

## Platform notes

**macOS.** The supported platform. Homebrew is the recommended install path. Ink TUI rendering is tested against Terminal.app, iTerm2, Ghostty, and Alacritty.

**Linux.** Supported. Use the NPX or from-source path — there is no Linux Homebrew formula yet, though `brew` on Linux will also work if you have it set up. The Ink TUI requires a TTY-capable terminal; tested against GNOME Terminal, Konsole, and Alacritty.

**Windows.** Use WSL2. Monozukuri's orchestrator scripts are POSIX shell and assume a Unix environment. Native Windows is not supported and is unlikely to be — the cost of supporting it well is high and the value is low for the target audience. Inside WSL2, follow the Linux install path.

**CI environments.** Use NPX with a pinned version. The CI environment must have `node`, `jq`, `gh`, and your chosen agent CLI available — the standard `ubuntu-latest` GitHub Actions image has the first three; install the agent CLI as a separate step. Run with `--autonomy full_auto` and a tight `run_budget_minutes` so a misbehaving run cannot exhaust CI minutes.

---

## Next steps

Once `monozukuri doctor` is green:

1. `cd` into the project you want to run against.
2. `monozukuri init` to scaffold `.monozukuri/config.yaml`.
3. Edit the config — at minimum, pick a [source adapter](adapters.md) and confirm the [autonomy level](autonomy.md).
4. `monozukuri run --dry-run` to preview the plan.
5. `monozukuri run` to execute.

See [execution.md](execution.md) for what to expect during the run, and [troubleshooting.md](troubleshooting.md) if anything looks off.
