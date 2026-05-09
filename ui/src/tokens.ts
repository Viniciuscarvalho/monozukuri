// Compozy-aligned design tokens for the Ink TUI.
// Semantic names mirror lib/cli/tokens.sh and ui-web/tokens.css.
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
    failed: '#ff6b63',
    paused: '#f59e0b',
    deferred: '#f59e0b',
    retrying: '#a78bfa',
    running: '#d6f24a',
    queued: '#a8a29e',
    skipped: '#57534e',
  } as Record<string, string>,
} as const;

export type StatusKey = keyof typeof tokens.statusColor;
