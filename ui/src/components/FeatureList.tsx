import React from 'react';
import { Box, Text } from 'ink';
import type { Feature, Phase, PhaseStatus } from '../types.js';
import { tokens, statusColor, statusSymbol } from '../tokens.js';
import { LAYOUT } from '../lib/layout.js';

interface FeatureListProps {
  features: Record<string, Feature>;
  order: string[];
  innerWidth?: number;
}

const PHASES: Phase[] = ['prd', 'techspec', 'tasks', 'code', 'tests', 'pr'];

function phaseChar(ps: PhaseStatus): string {
  if (ps === 'done') return '●';
  if (ps === 'in_progress') return '◐';
  if (ps === 'failed') return '✗';
  return '○';
}

function phaseCharColor(ps: PhaseStatus): string {
  if (ps === 'done') return tokens.success;
  if (ps === 'in_progress') return tokens.brand;
  if (ps === 'failed') return tokens.danger;
  return tokens.dim;
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
  const idLabel = pad(id, LAYOUT.featureIdWidth);
  const titleLabel = pad(title || id, titleLen);

  return (
    <Box flexDirection="column">
      <Box paddingLeft={2}>
        <Text color={color} bold={isActive}>{icon}{' '}</Text>
        <Text color={isActive ? tokens.textPrimary : tokens.textSecondary}>{idLabel}</Text>
        <Text color={tokens.dim}>{'  '}</Text>
        <Text color={isActive ? tokens.textPrimary : tokens.textSecondary}>{titleLabel}</Text>
        <Text color={tokens.dim}>{'  '}</Text>
        {PHASES.map((ph) => {
          const ps: PhaseStatus = phases?.[ph] ?? 'pending';
          return (
            <Text key={ph} color={phaseCharColor(ps)}>{phaseChar(ps)}</Text>
          );
        })}
        <Text color={tokens.dim}>{'  '}</Text>
        <Text color={color} bold={isActive}>{status}</Text>
        {isActive && currentPhase ? (
          <Text color={tokens.dim}> [{currentPhase}]</Text>
        ) : null}
      </Box>
      {(status === 'failed' || status === 'skipped' || status === 'pr_failed' || status === 'deferred') && error ? (
        <Box paddingLeft={4}>
          <Text color={color} dimColor>{truncate(error, Math.max(10, titleLen + 20))}</Text>
        </Box>
      ) : null}
    </Box>
  );
}

export function FeatureList({
  features,
  order,
  innerWidth = 80,
}: FeatureListProps): React.ReactElement {
  const all: Feature[] = order.map((id) => features[id]).filter(Boolean) as Feature[];

  // Fixed columns: [icon+space:2] [id:18] [2sp] [title] [2sp] [dots:6] [2sp] [status:~12] = 44
  const fixedCols = LAYOUT.featureIdWidth + LAYOUT.featureTitleWidth + 13;
  const titleLen = Math.max(10, innerWidth - fixedCols);

  return (
    <Box flexDirection="column">
      {all.length === 0 ? (
        <Box paddingLeft={2}>
          <Text dimColor>(no features loaded)</Text>
        </Box>
      ) : (
        all.map((f) => (
          <FeatureRow key={f.id} feature={f} titleLen={titleLen} />
        ))
      )}
    </Box>
  );
}
