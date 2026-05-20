import React from 'react';
import { render } from 'ink-testing-library';
import {
  BacklogList,
  backlogSelectionSummary,
  clampBacklogCursor,
  moveBacklogCursor,
  toggleBacklogSelection,
} from '../src/components/BacklogList.js';
import type { PickBacklogItem } from '../src/types.js';

const items: PickBacklogItem[] = [
  {
    id: 'feat-001',
    title: 'Add ranked backlog picker list',
    priority: 5,
    effort: 3,
    status: 'ready',
    score: 71,
  },
  {
    id: 'feat-002',
    title: 'Render feature preview panel',
    priority: 4,
    effort: 5,
    status: 'blocked',
    score: -43,
  },
  {
    id: 'feat-003',
    title: 'Wire keybind integration',
    priority: 3,
    effort: 2,
    status: 'in-progress',
    score: 25,
  },
];

describe('BacklogList state helpers', () => {
  it('moves cursor down and clamps at the last item', () => {
    expect(moveBacklogCursor(0, 'down', items.length)).toBe(1);
    expect(moveBacklogCursor(2, 'down', items.length)).toBe(2);
  });

  it('moves cursor up and clamps at the first item', () => {
    expect(moveBacklogCursor(2, 'up', items.length)).toBe(1);
    expect(moveBacklogCursor(0, 'up', items.length)).toBe(0);
  });

  it('clamps cursor for empty lists', () => {
    expect(clampBacklogCursor(5, 0)).toBe(0);
    expect(moveBacklogCursor(5, 'down', 0)).toBe(0);
  });

  it('toggles selection without mutating the previous set', () => {
    const selected = new Set(['feat-001']);
    const added = toggleBacklogSelection(selected, 'feat-002');
    const removed = toggleBacklogSelection(added, 'feat-001');

    expect([...selected]).toEqual(['feat-001']);
    expect([...added].sort()).toEqual(['feat-001', 'feat-002']);
    expect([...removed]).toEqual(['feat-002']);
  });

  it('formats the visible selection counter', () => {
    expect(backlogSelectionSummary(3, 30)).toBe('3 of 30 selected');
  });
});

describe('BacklogList component', () => {
  it('renders rows, cursor, metadata, and selected counter', () => {
    const { lastFrame } = render(
      <BacklogList
        items={items}
        cursorIndex={1}
        selectedIds={new Set(['feat-001', 'feat-003'])}
        innerWidth={86}
      />
    );

    const frame = lastFrame() ?? '';
    expect(frame).toContain('feat-001');
    expect(frame).toContain('feat-002');
    expect(frame).toContain('blocked');
    expect(frame).toContain('Render feature preview panel');
    expect(frame).toContain('2 of 3 selected');
    expect(frame).toContain('›');
    expect(frame).toContain('●');
  });

  it('renders a helpful empty state', () => {
    const { lastFrame } = render(
      <BacklogList items={[]} cursorIndex={0} selectedIds={[]} />
    );

    const frame = lastFrame() ?? '';
    expect(frame).toContain('(no backlog items)');
    expect(frame).toContain('0 of 0 selected');
  });

  it('truncates long titles to fit the configured width', () => {
    const { lastFrame } = render(
      <BacklogList
        items={[{ ...items[0], title: 'A very long backlog title that needs to be truncated inside the table row' }]}
        cursorIndex={0}
        selectedIds={[]}
        innerWidth={64}
      />
    );

    expect(lastFrame() ?? '').toContain('…');
  });
});

