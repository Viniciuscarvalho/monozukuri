# Product Requirements Document (PRD)

**Project Name:** Monozukuri
**Feature:** Ink TUI Visual Polish — pre-launch UX pass
**Version:** 1.0
**Date:** 2026-05-12
**Status:** Approved

---

## Prompt Context

### Original User Prompt

> Quero agora fazer apenas questões visuais deixar mais polido para poder lançar essa versão para o público — não mexa na execução das tarefas.

### Enriched Prompt

> Perform a targeted visual polish pass on the Ink TUI (`ui/src/`) to fix accumulated drift between the `tokens.ts` design system and the actual component implementations. Changes are rendering-only: no reducer logic, no IPC, no pipeline. Scope confirmed via a throwaway Ink prototype (validated 2026-05-12) which answered "what should this look like?". Prototype lives at `ui/src/__prototype__/` (delete when absorbed).

### CLAUDE.md Constraints Applied

- No new npm or shell dependencies without explicit justification
- `tokens.ts` is the single source of truth — components MUST import from it, never hardcode `color="red"` or hex literals
- Do NOT write to `.claude/` (Claude Code's territory)
- `set -euo pipefail` and shellcheck clean — not relevant here (no shell changes)
- `make test` / `npm test` must pass before PR

### Codebase Context

| Attribute             | Value                                  |
| --------------------- | -------------------------------------- |
| Stack                 | Node 18+ with Ink/React (TUI)          |
| Language(s)           | TypeScript                             |
| Framework(s)          | Ink 5.x, React 18                      |
| Package Manager       | npm (workspace: `ui/`)                 |
| Test Framework        | Jest + ink-testing-library (snapshots) |
| Relevant Entry Points | `ui/src/index.tsx`, `ui/src/App.tsx`   |

### Environment Manifest

| Tool / MCP Server   | Available | Notes                             |
| ------------------- | --------- | --------------------------------- |
| Node 18+            | Yes       | Required for Ink ESM              |
| ink-testing-library | Yes       | Snapshot tests in `ui/__tests__/` |
| tsup                | Yes       | Build (`npm run build`)           |
| tsx                 | Yes (npx) | Used for prototype only           |

---

## Executive Summary

**Problem Statement:**
The Ink TUI has a design token system in `ui/src/tokens.ts` that is the declared single source of truth, but four components bypass it with inline hex codes or Ink color-name literals (`color="red"`, `color="green"`, `#31d58b`, etc.). Additionally, all main-view components draw borders manually with sharp corners (`┌─┐`) instead of using rounded corners (`╭─╮`), the right-side `│` characters are decorative and do not align with the header/footer ends, the braille spinner defined in `tokens.spinner.frames` is never consumed (a string label is rendered instead), and the layout does not react to terminal resize (SIGWINCH). These issues collectively produce a TUI that looks less polished than the design system intends, which is a blocker for public launch.

**Proposed Solution:**
Systematically fix the 7 specific drift categories identified in a codebase audit and validated via a throwaway Ink prototype. All changes are purely visual (rendering layer): token enforcement, border unification via Ink's `borderStyle="round"`, section-separator pattern, braille spinner wiring, resize reactivity, and magic-number extraction. No business logic, state machine, IPC, or pipeline code is touched.

**Business Value:**

- Removes the last "looks unfinished" barrier before public v1.0 launch
- Enforces the token contract so future drift is caught by existing `tokens.test.ts`
- Establishes `Panel.tsx` as the canonical border component so new screens stay consistent

**Success Metrics:**
| Metric | Baseline | Target | How to Measure |
|--------|----------|--------|----------------|
| Inline color violations | 10+ (4 components) | 0 | grep for `color="red\|green"` and hex literals outside tokens.ts |
| Border style consistency | Sharp corners (`┌`) in all main components | Rounded (`╭`) everywhere | Visual inspection + snapshot update |
| Spinner animation | Static string label | Braille frames cycling at 80ms | Visual inspection |
| Resize reactivity | None (width captured once) | Reacts to SIGWINCH | Manually resize terminal mid-run |

---

## Project Overview

### Background

The Ink TUI was built incrementally over several feature branches (`TUI Day 1-5`, `TUI unified grid`, etc.). Each iteration added visual elements but didn't always enforce the token contract, leading to color literal drift. The design token system (`tokens.ts`) was introduced in PR #152 with an explicit comment forbidding inline colors, but subsequent commits violated it. The braille spinner was designed in `tokens.ts` but never wired to the actual spinner state. Border drawing was always manual, leading to right-border misalignment when content length varies.

### Current State

- `FeatureList.tsx` — 6 inline hex codes
- `CostMeter.tsx` — `color="red"` and `color="green"` literals
- `LogPane.tsx` — Ink basic color names (`blue`, `yellow`, `cyan`, `magenta`)
- `SetupPanel.tsx` — `'green'`/`'yellow'` for agent status
- All main components: sharp corners `┌─┐` drawn manually; right `│` is decorative
- `tokens.spinner.frames` (braille): defined but never used; `FeatureCard` uses `state.spinner` as a raw string label
- `App.tsx` reads `stdout.columns` once per render; no SIGWINCH reaction
- `FIXED_COLS = 49` in `FeatureList.tsx:93`; magic numbers in FeatureCard, LogPane, Footer
- `Panel.tsx` exists with `borderStyle="round"` but is used by nothing in the main view

### Desired State

- Zero inline color literals in components — all from `tokens.ts` via named exports
- All border-drawing uses `borderStyle="round"` (Ink-managed, guaranteed alignment)
- Section separators follow the `── name ──` pattern inside the rounded border box
- `tokens.spinner.frames` consumed by `FeatureCard` via the existing `useTicker.ts` hook
- `useStdoutDimensions` (already imported in `layout.ts`) drives reactive width in `App.tsx`
- All layout constants extracted to `tokens.ts` or `layout.ts`
- `Panel.tsx` is the canonical border component used by all main sections
- Snapshots regenerated; `tokens.test.ts` still passes; `npm run build` clean

### Existing Codebase Patterns

- **Naming conventions:** `tokens.ts` exports `tokens` (const object), `statusColor()`, `statusSymbol()`, `phaseSymbol` — these are the utility functions components should call
- **File structure:** One component per file in `ui/src/components/`; hooks in `ui/src/hooks/`; layout helpers in `ui/src/lib/layout.ts`
- **Error handling:** N/A for rendering-only changes
- **Logging:** N/A
- **Config management:** Token values live in `tokens.ts`; layout constants belong in `layout.ts` or the `tokens` object's new `layout` section

---

## User Personas

### Primary Persona: CLI Developer / Operator

| Attribute       | Detail                                                                                                      |
| --------------- | ----------------------------------------------------------------------------------------------------------- |
| Role            | Developer running monozukuri on their own projects                                                          |
| Technical Level | High — comfortable with terminal, knows what a TUI is                                                       |
| Primary Goal    | See what monozukuri is doing at a glance without scrolling                                                  |
| Key Pain Point  | Right-side borders that don't align make the TUI feel unfinished; static spinner gives no sense of activity |
| Usage Context   | macOS / Linux terminal at 80–120 columns, dark theme                                                        |

---

## Functional Requirements

### FR-001: Token Enforcement [MUST]

**Description:**
Remove all inline color literals from components. Every color rendered in the TUI must be resolved through `tokens.ts` — either the `tokens.colors.*` constants, `statusColor(status)`, or `statusSymbol(status)`.

**Acceptance Criteria:**

1. **Given** `FeatureList.tsx`, **When** a feature row is rendered, **Then** no hex literal or bare Ink color name (`"red"`, `"green"`, etc.) appears in the source — only imports from `tokens.js`
2. **Given** `CostMeter.tsx`, **When** cost is at/over budget, **Then** the danger color comes from `tokens.danger`, not `color="red"`
3. **Given** `LogPane.tsx`, **When** a phase tag is rendered, **Then** the color comes from a `tokens.*` constant, not `"blue"` / `"yellow"` / etc.
4. **Given** `SetupPanel.tsx`, **When** an agent is installed/missing, **Then** `tokens.success`/`tokens.danger` are used

**Negative Cases:**

1. **Given** `grep -rn 'color="red\|green\|blue\|yellow\|cyan\|magenta"' ui/src/components/`, **When** run post-implementation, **Then** zero matches (excluding `tokens.ts` itself)

**Priority:** MUST

---

### FR-002: Unified Rounded Borders [MUST]

**Description:**
Replace manual sharp-corner border drawing (`┌─┐`, `│`) in `Header`, `FeatureCard`, `FeatureList`, `LogPane`, `Footer`, and `App.Separator` with Ink's `borderStyle="round"` managed by `Panel.tsx`. `Panel.tsx` becomes the canonical border component.

**Acceptance Criteria:**

1. **Given** the main dashboard at any terminal width, **When** rendered, **Then** the outer border uses `╭─╮` / `│` / `╰─╯` corners (not `┌─┐` / `└─┘`)
2. **Given** a section separator between Header and FeatureCard, **When** rendered, **Then** it uses the `── label ──` pattern (a full-width text row inside the border box, touching the `│` borders)
3. **Given** any terminal width 80–120 columns, **When** the right border `│` is visible, **Then** it aligns with the outer border — no dangling decorative `│` at arbitrary offsets
4. **Given** `Panel.tsx`, **When** used by Header/FeatureCard/FeatureList/LogPane/Footer, **Then** it is the only component that draws outer borders

**Negative Cases:**

1. **Given** `grep -rn '[┌┐└┘]' ui/src/components/`, **When** run post-implementation, **Then** zero matches

**Priority:** MUST

---

### FR-003: Braille Spinner Wire-up [MUST]

**Description:**
Wire `tokens.spinner.frames` to the active phase indicator in `FeatureCard`. The existing `useTicker.ts` hook (1 Hz clock) is not fast enough for the 80ms spinner interval — the spinner should have its own 80ms interval driven by local state, or `useTicker.ts` should be updated to accept a custom interval.

**Acceptance Criteria:**

1. **Given** a feature in an active phase (code, tests, pr), **When** the TUI is rendering, **Then** the spinner cycles through `tokens.spinner.frames` (`⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏`) at approximately 80ms per frame
2. **Given** a feature in a terminal phase (done, failed), **When** rendered, **Then** no spinner is shown
3. **Given** `tokens.spinner.frames`, **When** referenced from `FeatureCard`, **Then** it is the only place the spinner frame list is defined (no duplication)

**Priority:** MUST

---

### FR-004: Resize Reactivity [SHOULD]

**Description:**
The TUI width must react to terminal resize events (SIGWINCH). Currently `stdout.columns` is read once and never updates. `useStdoutDimensions` is already imported in `ui/src/lib/layout.ts` but not called in `App.tsx`.

**Acceptance Criteria:**

1. **Given** a running TUI, **When** the user resizes the terminal horizontally, **Then** within the next render cycle the layout reflows to the new width (no stale fixed width)
2. **Given** a terminal width of 80 columns, **When** the user resizes to 120, **Then** all sections expand without wrapping or overflow

**Priority:** SHOULD

---

### FR-005: Magic Numbers → Named Constants [SHOULD]

**Description:**
Extract hardcoded layout numbers to named constants in `tokens.ts` (visual constraints) or `layout.ts` (computed layout helpers).

**Acceptance Criteria:**

1. **Given** `FeatureList.tsx:93`, **When** refactored, **Then** `FIXED_COLS = 49` is replaced by a named export from `layout.ts` or `tokens.ts`
2. **Given** truncation limits (42 in `FeatureCard`, 42 in `LogPane`, 70 in `Footer`), **When** refactored, **Then** each is a named constant with a descriptive name
3. **Given** `App.tsx` and `Header.tsx`, **When** refactored, **Then** they both use the same `innerWidth` utility function from `layout.ts` rather than computing `width - 2` independently

**Priority:** SHOULD

---

## Non-Functional Requirements

### NFR-001: Rendering — No Regressions [MUST]

**Requirement:** All visual changes must leave the TUI rendering correctly at 80, 100, and 120 column widths
**Target:** Zero layout overflow or truncation artifacts at any of the three widths
**Measurement:** Visual inspection using `composite-screenshot.test.tsx` snapshots at three widths
**Validation Command:** `cd ui && npm test -- --updateSnapshot && npm run build`

### NFR-002: Test Snapshots [MUST]

**Requirement:** Snapshot tests must be regenerated and committed as part of this feature — failing snapshots are an expected side-effect of the visual changes, not a bug
**Constraints:** `tokens.test.ts` must pass without modification (palette values must not change)
**Validation:** `cd ui && npm test` passes with zero failures after `--updateSnapshot`

### NFR-003: Backward Compatibility [MUST]

**Backward Compatibility:** State machine, reducer, IPC, and pipeline behavior unchanged
**Breaking Changes Allowed:** No (rendering-only)
**Migration Path:** N/A — no consumer-visible API changes

### NFR-004: Code Quality [MUST]

**Test Coverage Target:** Snapshots regenerated; no new coverage required beyond what snapshots provide
**Lint Rules:** Follow existing eslint config; `tokens.ts` inline-color prohibition must be enforced
**Documentation:** Delete `ui/src/__prototype__/` after this PR is merged (it answered its question)

---

## Epics and User Stories

### EPIC-001: Token System Compliance

**Business Value:** Eliminates drift source — future components start from a clean baseline

#### STORY-001: Fix inline color literals in FeatureList, CostMeter, LogPane, SetupPanel

```
As a developer maintaining the TUI,
I want all component colors to come from tokens.ts,
So that changing a palette color is a one-line edit.
```

**Acceptance Criteria:**

1. Given any component in `ui/src/components/`, when read, then no hex literal or bare Ink color name appears outside of `tokens.ts`
   **Priority:** HIGH · **Complexity:** S

---

### EPIC-002: Border Unification

**Business Value:** Rounded corners + aligned right border — the single biggest visible quality jump

#### STORY-002: Replace manual border drawing with Panel.tsx / borderStyle="round"

```
As a user watching a run,
I want the TUI border to look finished and aligned,
So that I trust the tool is production-quality.
```

**Acceptance Criteria:**

1. Given the dashboard renders at 100 columns, when I look at the right border, then it aligns perfectly with the top and bottom border corners
2. Given section separators, when rendered, then they visually connect to the side borders
   **Priority:** HIGH · **Complexity:** M

---

### EPIC-003: Animation & Reactivity

**Business Value:** Braille spinner gives live feedback that something is happening; resize means it works on any window size

#### STORY-003: Wire braille spinner to tokens.spinner.frames

```
As a user watching code generation,
I want to see a cycling braille spinner,
So that I know the agent is actively working.
```

**Priority:** HIGH · **Complexity:** S

#### STORY-004: React to terminal resize

```
As a user who resizes their terminal mid-run,
I want the TUI to reflow immediately,
So that I don't have to restart monozukuri after resizing.
```

**Priority:** MEDIUM · **Complexity:** S

---

## Assumptions and Dependencies

### Assumptions

1. `Panel.tsx` with `borderStyle="round"` is already in `ui/src/components/Panel.tsx` and can be the base component
2. `useTicker.ts` can be extended or a local `useEffect`/`setInterval` can drive the 80ms spinner without breaking the existing 1Hz clock consumers
3. Snapshot regeneration (`--updateSnapshot`) is acceptable in this PR — the diff is pure visual improvement, not regression

### Dependencies

| Dependency                                        | Type     | Required Before | Risk if Unavailable                        |
| ------------------------------------------------- | -------- | --------------- | ------------------------------------------ |
| `Panel.tsx` (existing)                            | Internal | Implementation  | Low — can use borderStyle inline if needed |
| `useTicker.ts` (existing)                         | Internal | Spinner wire-up | Low — local setInterval fallback           |
| `useStdoutDimensions` from ink (already imported) | Internal | Resize task     | Low — already in layout.ts                 |

---

## Constraints

### Hard Constraints (Non-Negotiable)

- Do NOT modify: `ui/src/reducer.ts`, `ui/src/hooks/useEventStream.ts`, `lib/run/`, `lib/agent/`, `lib/core/`, `lib/schema/`, `lib/cli/emit.sh`
- Do NOT change token palette values (hex codes in `tokens.ts`) — `tokens.test.ts` will fail
- Do NOT add new npm packages

### Soft Constraints (Preferred)

- Keep `Panel.tsx` as the single border abstraction — avoid inline `borderStyle` in other components
- Keep the `── label ──` separator pattern consistent across all sections
- If `useTicker.ts` is modified, its 1Hz consumers must still work unchanged

---

## Out of Scope

| Feature / Capability                                                 | Reason                                                                              | Future Phase? |
| -------------------------------------------------------------------- | ----------------------------------------------------------------------------------- | ------------- |
| Redesigning the shell-side output (`lib/cli/output.sh`) corner style | Corner unification is a separate decision; shell output targets different renderers | Yes           |
| Adding new TUI screens (learnings, filter, search stubs)             | Those are stub placeholders; implementing them is a separate feature                | Yes           |
| Changing event protocol / IPC                                        | Out of visual scope                                                                 | No            |
| Adding new color tokens to palette                                   | Palette is stable for v1.0                                                          | After v1.0    |
| Adding bats smoke test for TUI render                                | Nice-to-have, not required for visual polish                                        | Yes           |

---

## Risks and Mitigations

| Risk                                                                 | Impact | Probability | Mitigation                                                                        |
| -------------------------------------------------------------------- | ------ | ----------- | --------------------------------------------------------------------------------- |
| Snapshot tests fail after visual changes                             | M      | H           | Expected — run `--updateSnapshot` and commit the new snapshots                    |
| `Panel.tsx` borderStyle="round" behaves differently at narrow widths | M      | L           | Test at 80 columns; fallback to inline borderStyle if Panel.tsx has issues        |
| Spinner setInterval leaks if component unmounts                      | L      | M           | Return cleanup function from useEffect; existing pattern in useTicker.ts          |
| Right-border alignment still off with Ink borderStyle                | M      | L           | Ink's Box manages its own border width — alignment is guaranteed by the framework |

---

## PRD Validation Checklist

- [x] All FRs have Given/When/Then acceptance criteria
- [x] All FRs have at least one negative/edge case
- [x] Every Story traces back to at least one FR
- [x] Codebase patterns section reflects actual project conventions (verified via audit)
- [x] No FR contradicts existing CLAUDE.md constraints
- [x] Out of scope items are explicit and justified
- [x] NFRs have measurable targets with validation methods
- [x] Backward compatibility: rendering-only, no breakage
- [x] Dependencies verified as available in the environment

---

## Glossary

| Term              | Definition                                                                               |
| ----------------- | ---------------------------------------------------------------------------------------- |
| tokens.ts         | Single source of truth for all TUI visual decisions (colors, symbols, spinner frames)    |
| Panel.tsx         | Reusable Ink Box with borderStyle="round" — the canonical border component               |
| Section separator | A full-width `── label ──` text row inside a border box, creating a visual `├──┤` effect |
| Braille spinner   | The cycling `⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏` animation from `tokens.spinner.frames`                          |
| SIGWINCH          | Terminal resize signal; triggers `useStdoutDimensions` update                            |
| innerWidth        | `containerWidth - 2` — the content area width inside a border box                        |

---

**Document End**
