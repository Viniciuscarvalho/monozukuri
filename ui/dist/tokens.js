// Compozy-aligned design tokens for the Ink TUI.
// Semantic names mirror lib/cli/tokens.sh and ui-web/tokens.css.
//
// Single source of truth for visual decisions: colors, symbols, spinner
// frames, tree-drawing chars. Components MUST import from here — never
// hardcode color="red" / color="green" / etc. Status colors and symbols
// are looked up via statusColor() / statusSymbol() so the mapping lives
// in exactly one place.
export const tokens = {
    brand: '#d6f24a',
    success: '#31d58b',
    danger: '#ff6b63',
    warning: '#f59e0b',
    info: '#3b82f6',
    muted: '#a8a29e',
    dim: '#57534e',
    border: '#292524',
    surfaceBase: '#1c1917',
    surfaceRaised: '#292524',
    // Text
    textPrimary: '#fafaf9',
    textSecondary: '#a8a29e',
    // Status tonal triplets (bg not applicable in terminal; use fg color)
    statusColor: {
        done: '#31d58b',
        'pr-created': '#31d58b',
        succeeded: '#31d58b',
        completed: '#31d58b',
        failed: '#ff6b63',
        failure: '#ff6b63',
        paused: '#f59e0b',
        deferred: '#f59e0b',
        retrying: '#a78bfa',
        pr_failed: '#a78bfa',
        running: '#d6f24a',
        in_progress: '#d6f24a',
        active: '#d6f24a',
        queued: '#a8a29e',
        pending: '#a8a29e',
        skipped: '#57534e',
    },
    // Status symbols — used together with statusColor() to render a single
    // glyph + colour for any feature/phase status.
    statusSymbol: {
        done: '✓',
        'pr-created': '✓',
        succeeded: '✓',
        completed: '✓',
        failed: '✗',
        failure: '✗',
        paused: '⏸',
        deferred: '⏸',
        retrying: '↻',
        pr_failed: '⚠',
        running: '▶',
        in_progress: '◐',
        active: '▶',
        queued: '○',
        pending: '○',
        skipped: '⊘',
    },
    // Phase-pipeline symbols (used by the active feature panel).
    phaseSymbol: {
        done: '●',
        active: '◐',
        pending: '○',
    },
    // Charm-style Braille spinner — same family Bubble Tea uses.
    spinner: {
        frames: ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'],
        intervalMs: 80,
    },
    // Tree-drawing characters for recent-activity lists.
    tree: {
        branch: '├─',
        last: '└─',
        vertical: '│ ',
    },
    // Decorative separators / arrows.
    glyphs: {
        bullet: '·',
        arrow: '→',
        middot: '·',
    },
};
/** Resolve the colour for a feature/phase status. Falls back to the muted
 *  colour for unknown statuses so a bad event can't render as a UI glitch. */
export function statusColor(status) {
    if (!status)
        return tokens.muted;
    return tokens.statusColor[status] ?? tokens.muted;
}
/** Resolve the glyph for a feature/phase status. Falls back to the pending
 *  symbol for unknown statuses. */
export function statusSymbol(status) {
    if (!status)
        return tokens.statusSymbol.pending;
    return tokens.statusSymbol[status] ?? tokens.statusSymbol.pending;
}
