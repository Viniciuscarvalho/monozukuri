import React from 'react';
import { Box, Text } from 'ink';
import type { Feature, Phase, PhaseStatus } from '../types.js';
import { statusColor, statusSymbol } from '../tokens.js';

interface FeatureListProps {
  features: Record<string, Feature>;
  order: string[];
  terminalWidth?: number;
}

const PHASES: Phase[] = ['prd', 'techspec', 'tasks', 'code', 'tests', 'pr'];

function phaseChar(ps: PhaseStatus): string {
  if (ps === 'done') return '●';
  if (ps === 'in_progress') return '◐';
  if (ps === 'failed') return '✗';
  return '○';
}

function phaseCharColor(ps: PhaseStatus): string {
  if (ps === 'done') return '#31d58b';
  if (ps === 'in_progress') return '#d6f24a';
  if (ps === 'failed') return '#ff6b63';
  return '#57534e';
}

function truncate(str: string, maxLen: number): string {
  if (str.length <= maxLen) return str;
  return str.slice(0, maxLen - 1) + '…';
}

function pad(str: string, len: number): string {
  if (str.length >= len) return str.slice(0, len - 1) + '…';
  return str + ' '.repeat(len - str.length);
}

interface FeatureRowProps {
  feature: Feature;
  titleLen: number;
}

function FeatureRow({ feature, titleLen }: FeatureRowProps): React.ReactElement {
  const { id, title, status, phases, currentPhase, error } = feature;
  const icon = statusSymbol(status);
  const color = statusColor(status);
  const isActive = status === 'active';
  const idLabel = pad(id, 18);
  const titleLabel = pad(title || id, titleLen);

  return (
    <Box flexDirection="column">
      <Box>
        <Text>│  </Text>
        <Text color={color} bold={isActive}>{icon}{' '}</Text>
        <Text color={isActive ? '#fafaf9' : '#a8a29e'}>{idLabel}</Text>
        <Text color="#57534e">{'  '}</Text>
        <Text color={isActive ? '#fafaf9' : '#a8a29e'}>{titleLabel}</Text>
        <Text color="#57534e">{'  '}</Text>
        {PHASES.map((ph) => {
          const ps: PhaseStatus = phases?.[ph] ?? 'pending';
          return (
            <Text key={ph} color={phaseCharColor(ps)}>{phaseChar(ps)}</Text>
          );
        })}
        <Text color="#57534e">{'  '}</Text>
        <Text color={color} bold={isActive}>{status}</Text>
        {isActive && currentPhase ? (
          <Text color="#57534e"> [{currentPhase}]</Text>
        ) : null}
        <Text> │</Text>
      </Box>
      {(status === 'failed' || status === 'skipped' || status === 'pr_failed' || status === 'deferred') && error ? (
        <Box>
          <Text>│     </Text>
          <Text color={color} dimColor>{truncate(error, Math.max(10, titleLen + 20))}</Text>
          <Text> │</Text>
        </Box>
      ) : null}
    </Box>
  );
}

export function FeatureList({
  features,
  order,
  terminalWidth = 80,
}: FeatureListProps): React.ReactElement {
  const all: Feature[] = order.map((id) => features[id]).filter(Boolean) as Feature[];

  // Fixed columns: │  [icon] [id:18] [2sp] [title] [2sp] [dots:6] [2sp] [status] │
  // Fixed cost: 3 + 2 + 18 + 2 + 2 + 6 + 2 + 12 + 2 = 49
  const FIXED_COLS = 49;
  const titleLen = Math.max(10, terminalWidth - FIXED_COLS);

  const headerDashes = '─'.repeat(Math.max(0, terminalWidth - 16));

  return (
    <Box flexDirection="column">
      <Box>
        <Text>├─ features </Text>
        <Text dimColor>{headerDashes}</Text>
        <Text>┤</Text>
      </Box>

      {all.length === 0 ? (
        <Box>
          <Text>│  </Text>
          <Text dimColor>(no features loaded)</Text>
          <Text> │</Text>
        </Box>
      ) : (
        all.map((f) => (
          <FeatureRow key={f.id} feature={f} titleLen={titleLen} />
        ))
      )}
    </Box>
  );
}
