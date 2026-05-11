import { tokens, statusColor, statusSymbol } from '../src/tokens.js';

describe('tokens', () => {
  it('exposes core palette entries', () => {
    expect(tokens.brand).toBeDefined();
    expect(tokens.success).toBeDefined();
    expect(tokens.danger).toBeDefined();
    expect(tokens.warning).toBeDefined();
    expect(tokens.muted).toBeDefined();
    expect(tokens.dim).toBeDefined();
  });

  it('exposes spinner frames + interval', () => {
    expect(tokens.spinner.frames.length).toBe(10);
    expect(tokens.spinner.intervalMs).toBe(80);
  });

  it('exposes tree-drawing chars', () => {
    expect(tokens.tree.branch).toBe('├─');
    expect(tokens.tree.last).toBe('└─');
    expect(tokens.tree.vertical).toBe('│ ');
  });

  it('exposes phase pipeline symbols', () => {
    expect(tokens.phaseSymbol.done).toBe('●');
    expect(tokens.phaseSymbol.active).toBe('◐');
    expect(tokens.phaseSymbol.pending).toBe('○');
  });
});

describe('statusColor', () => {
  it.each<[string, string]>([
    ['done', tokens.success],
    ['pr-created', tokens.success],
    ['succeeded', tokens.success],
    ['failed', tokens.danger],
    ['failure', tokens.danger],
    ['running', tokens.brand],
    ['active', tokens.brand],
    ['paused', tokens.warning],
    ['queued', tokens.muted],
    ['skipped', tokens.dim],
  ])('maps %s → expected color', (status, expected) => {
    expect(statusColor(status)).toBe(expected);
  });

  it('falls back to muted for unknown status', () => {
    expect(statusColor('bogus')).toBe(tokens.muted);
  });

  it('handles null/undefined gracefully', () => {
    expect(statusColor(undefined)).toBe(tokens.muted);
    expect(statusColor(null)).toBe(tokens.muted);
  });
});

describe('statusSymbol', () => {
  it.each<[string, string]>([
    ['done', '✓'],
    ['failed', '✗'],
    ['running', '▶'],
    ['paused', '⏸'],
    ['queued', '○'],
    ['skipped', '⊘'],
    ['retrying', '↻'],
  ])('maps %s → expected symbol', (status, expected) => {
    expect(statusSymbol(status)).toBe(expected);
  });

  it('falls back to pending glyph for unknown status', () => {
    expect(statusSymbol('bogus')).toBe('○');
    expect(statusSymbol(undefined)).toBe('○');
  });
});
