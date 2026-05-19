import React from 'react';
import { Box, Text } from 'ink';
import type { PickBacklogItem } from '../types.js';
import { tokens, statusColor } from '../tokens.js';

interface BacklogListProps {
  items: PickBacklogItem[];
  cursorIndex: number;
  selectedIds: ReadonlySet<string> | readonly string[];
  innerWidth?: number;
}

type Direction = 'up' | 'down';

function truncate(value: string, maxLen: number): string {
  if (value.length <= maxLen) return value;
  return `${value.slice(0, Math.max(0, maxLen - 1))}…`;
}

function pad(value: string, length: number): string {
  const truncated = truncate(value, length);
  return `${truncated}${' '.repeat(Math.max(0, length - truncated.length))}`;
}

function toSelectedSet(selectedIds: ReadonlySet<string> | readonly string[]): ReadonlySet<string> {
  return selectedIds instanceof Set ? selectedIds : new Set(selectedIds);
}

export function clampBacklogCursor(index: number, itemCount: number): number {
  if (itemCount <= 0) return 0;
  return Math.min(Math.max(index, 0), itemCount - 1);
}

export function moveBacklogCursor(currentIndex: number, direction: Direction, itemCount: number): number {
  if (itemCount <= 0) return 0;
  const next = direction === 'up' ? currentIndex - 1 : currentIndex + 1;
  return clampBacklogCursor(next, itemCount);
}

export function toggleBacklogSelection(selectedIds: ReadonlySet<string>, id: string): ReadonlySet<string> {
  const next = new Set(selectedIds);
  if (next.has(id)) {
    next.delete(id);
  } else {
    next.add(id);
  }
  return next;
}

export function backlogSelectionSummary(selectedCount: number, totalCount: number): string {
  return `${selectedCount} of ${totalCount} selected`;
}

function formatScore(score: number | undefined): string {
  if (typeof score !== 'number' || Number.isNaN(score)) return 'n/a';
  return score.toFixed(0);
}

export function BacklogList({
  items,
  cursorIndex,
  selectedIds,
  innerWidth = 80,
}: BacklogListProps): React.ReactElement {
  const selected = toSelectedSet(selectedIds);
  const safeCursor = clampBacklogCursor(cursorIndex, items.length);
  const titleWidth = Math.max(18, innerWidth - 48);

  return (
    <Box flexDirection="column">
      {items.length === 0 ? (
        <Box paddingLeft={2}>
          <Text color={tokens.textSecondary}>(no backlog items)</Text>
        </Box>
      ) : (
        items.map((item, index) => {
          const isCursor = index === safeCursor;
          const isSelected = selected.has(item.id);
          const rowColor = isCursor ? tokens.textPrimary : tokens.textSecondary;

          return (
            <Box key={item.id}>
              <Text color={isCursor ? tokens.brand : tokens.dim}>{isCursor ? '›' : ' '}{' '}</Text>
              <Text color={isSelected ? tokens.success : tokens.dim}>{isSelected ? '●' : '○'}{' '}</Text>
              <Text color={rowColor}>{pad(item.id, 12)}</Text>
              <Text color={tokens.dim}>{' '}</Text>
              <Text color={tokens.warning}>{pad(String(item.priority), 3)}</Text>
              <Text color={tokens.dim}>{' '}</Text>
              <Text color={tokens.info}>{pad(String(item.effort), 3)}</Text>
              <Text color={tokens.dim}>{' '}</Text>
              <Text color={statusColor(item.status)}>{pad(item.status, 11)}</Text>
              <Text color={tokens.dim}>{' '}</Text>
              <Text color={rowColor}>{pad(truncate(item.title, titleWidth), titleWidth)}</Text>
              <Text color={tokens.dim}>{' '}</Text>
              <Text color={tokens.dim}>{formatScore(item.score)}</Text>
            </Box>
          );
        })
      )}
      <Box marginTop={1} paddingLeft={2}>
        <Text color={tokens.textSecondary}>
          {backlogSelectionSummary(selected.size, items.length)}
        </Text>
      </Box>
    </Box>
  );
}

