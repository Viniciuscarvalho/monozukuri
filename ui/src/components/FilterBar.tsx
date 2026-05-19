import React from 'react';
import { Box, Text } from 'ink';
import fuzzysort from 'fuzzysort';
import type { PickBacklogItem } from '../types.js';
import { tokens } from '../tokens.js';

const MIN_FUZZY_SCORE = 0.6;

interface FilterBarProps {
  query: string;
  totalCount: number;
  filteredCount: number;
  active?: boolean;
}

function searchableText(item: PickBacklogItem): string {
  return [
    item.id,
    item.title,
    item.status,
    String(item.priority),
    String(item.effort),
    item.deps?.join(' ') ?? '',
  ].join(' ');
}

export function filterBacklogItems(items: readonly PickBacklogItem[], query: string): PickBacklogItem[] {
  const trimmed = query.trim();
  if (!trimmed) return [...items];

  const targets = items.map((item) => ({
    item,
    haystack: searchableText(item),
  }));

  return fuzzysort
    .go(trimmed, targets, { key: 'haystack' })
    .filter((result) => result.score >= MIN_FUZZY_SCORE)
    .map((result) => result.obj.item);
}

export function clampFilteredCursor(cursorIndex: number, filteredCount: number): number {
  if (filteredCount <= 0) return 0;
  return Math.min(Math.max(cursorIndex, 0), filteredCount - 1);
}

export function FilterBar({
  query,
  totalCount,
  filteredCount,
  active = false,
}: FilterBarProps): React.ReactElement {
  const hasQuery = query.trim().length > 0;
  const countLabel = hasQuery ? `${filteredCount} of ${totalCount} matches` : `${totalCount} items`;

  return (
    <Box>
      <Text color={active ? tokens.brand : tokens.dim}>{active ? '/' : 'filter'}</Text>
      <Text color={tokens.dim}>{' '}</Text>
      <Text color={hasQuery ? tokens.textPrimary : tokens.textSecondary}>
        {hasQuery ? query : 'all'}
      </Text>
      <Text color={tokens.dim}>{'  '}</Text>
      <Text color={filteredCount === 0 && hasQuery ? tokens.warning : tokens.textSecondary}>
        {countLabel}
      </Text>
    </Box>
  );
}
