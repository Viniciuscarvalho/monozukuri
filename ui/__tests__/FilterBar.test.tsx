import React from 'react';
import { render } from 'ink-testing-library';
import {
  FilterBar,
  clampFilteredCursor,
  filterBacklogItems,
} from '../src/components/FilterBar.js';
import type { PickBacklogItem } from '../src/types.js';

const items: PickBacklogItem[] = [
  {
    id: 'feat-001',
    title: 'Add ranked backlog picker list',
    priority: 5,
    effort: 3,
    status: 'ready',
    deps: [],
  },
  {
    id: 'feat-002',
    title: 'Render feature preview panel',
    priority: 4,
    effort: 5,
    status: 'blocked',
    deps: ['feat-001'],
  },
  {
    id: 'feat-003',
    title: 'Wire keybind integration',
    priority: 3,
    effort: 2,
    status: 'in-progress',
    deps: ['feat-002'],
  },
];

describe('filterBacklogItems', () => {
  it('returns all items for an empty query', () => {
    expect(filterBacklogItems(items, '').map((item) => item.id)).toEqual([
      'feat-001',
      'feat-002',
      'feat-003',
    ]);
  });

  it('fuzzy matches titles and ids', () => {
    expect(filterBacklogItems(items, 'prev').map((item) => item.id)).toEqual(['feat-002']);
    expect(filterBacklogItems(items, 'f003').map((item) => item.id)).toEqual(['feat-003']);
  });

  it('matches metadata such as status and deps', () => {
    expect(filterBacklogItems(items, 'blocked').map((item) => item.id)).toEqual(['feat-002']);
    expect(filterBacklogItems(items, 'feat-001').map((item) => item.id)).toEqual(['feat-001', 'feat-002']);
  });

  it('returns an empty list without throwing when there are no matches', () => {
    expect(filterBacklogItems(items, 'zzzzzz')).toEqual([]);
  });
});

describe('clampFilteredCursor', () => {
  it('keeps cursor within the filtered list bounds', () => {
    expect(clampFilteredCursor(5, 3)).toBe(2);
    expect(clampFilteredCursor(-1, 3)).toBe(0);
    expect(clampFilteredCursor(2, 0)).toBe(0);
  });
});

describe('FilterBar', () => {
  it('renders inactive all-items state', () => {
    const { lastFrame } = render(
      <FilterBar query="" totalCount={3} filteredCount={3} />
    );

    const frame = lastFrame() ?? '';
    expect(frame).toContain('filter');
    expect(frame).toContain('all');
    expect(frame).toContain('3 items');
  });

  it('renders active filtered state and no-match state', () => {
    const active = render(
      <FilterBar query="preview" totalCount={3} filteredCount={1} active />
    );
    expect(active.lastFrame() ?? '').toContain('/ preview  1 of 3 matches');

    const empty = render(
      <FilterBar query="zzzzzz" totalCount={3} filteredCount={0} active />
    );
    expect(empty.lastFrame() ?? '').toContain('0 of 3 matches');
  });
});

