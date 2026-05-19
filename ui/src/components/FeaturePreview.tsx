import React from 'react';
import { Box, Text } from 'ink';
import type { PickBacklogItem } from '../types.js';
import { tokens, statusColor } from '../tokens.js';

interface FeaturePreviewProps {
  item: PickBacklogItem | null;
  innerWidth?: number;
}

function normalizeMarkdownLine(line: string): string {
  return line
    .replace(/^#{1,6}\s+/, '')
    .replace(/\*\*([^*]+)\*\*/g, '$1')
    .replace(/__([^_]+)__/g, '$1')
    .replace(/`([^`]+)`/g, '$1')
    .replace(/\[([^\]]+)\]\([^)]+\)/g, '$1')
    .replace(/^\s*[-*]\s+/, '• ')
    .trimEnd();
}

export function renderMarkdownPreview(markdown: string | undefined, maxLines = 8): string[] {
  if (!markdown?.trim()) return ['No description provided.'];

  return markdown
    .split(/\r?\n/)
    .map(normalizeMarkdownLine)
    .filter((line) => line.trim().length > 0)
    .slice(0, maxLines);
}

function truncate(value: string, maxLen: number): string {
  if (value.length <= maxLen) return value;
  return `${value.slice(0, Math.max(0, maxLen - 1))}…`;
}

export function FeaturePreview({
  item,
  innerWidth = 48,
}: FeaturePreviewProps): React.ReactElement {
  if (!item) {
    return (
      <Box flexDirection="column" paddingX={1}>
        <Text color={tokens.textSecondary}>No feature selected.</Text>
      </Box>
    );
  }

  const descriptionLines = renderMarkdownPreview(item.description);
  const deps = item.deps ?? [];
  const contentWidth = Math.max(20, innerWidth - 2);

  return (
    <Box flexDirection="column" paddingX={1}>
      <Text color={tokens.brand} bold>{truncate(item.title, contentWidth)}</Text>
      <Box marginTop={1}>
        <Text color={tokens.dim}>id </Text>
        <Text color={tokens.textSecondary}>{item.id}</Text>
        <Text color={tokens.dim}>  status </Text>
        <Text color={statusColor(item.status)}>{item.status}</Text>
      </Box>
      <Box>
        <Text color={tokens.dim}>priority </Text>
        <Text color={tokens.warning}>{item.priority}</Text>
        <Text color={tokens.dim}>  effort </Text>
        <Text color={tokens.info}>{item.effort}</Text>
      </Box>
      <Box marginTop={1} flexDirection="column">
        {descriptionLines.map((line, index) => (
          <Text key={`${item.id}-description-${index}`} color={tokens.textSecondary}>
            {truncate(line, contentWidth)}
          </Text>
        ))}
      </Box>
      <Box marginTop={1} flexDirection="column">
        <Text color={tokens.dim}>deps</Text>
        {deps.length === 0 ? (
          <Text color={tokens.textSecondary}>none</Text>
        ) : (
          deps.map((dep) => (
            <Text key={dep} color={tokens.textSecondary}>• {dep}</Text>
          ))
        )}
      </Box>
    </Box>
  );
}

