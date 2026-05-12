import React from 'react';
import { Box, Text } from 'ink';
import { CostMeter } from './CostMeter.js';
import type { AppState } from '../types.js';
import { tokens } from '../tokens.js';

interface HeaderProps {
  state: AppState;
  innerWidth: number;
}

export function Header({ state, innerWidth }: HeaderProps): React.ReactElement {
  const { runId, autonomy, model, agent, source, featureCount, budget, features, totals } = state;

  const completed = totals.succeeded + totals.failed + totals.skipped;
  const totalCost = totals.costUsd;

  const sourceLabel = source || 'unknown';
  const runLabel = runId ? `run ${runId.slice(0, 8)}` : 'run —';
  const titleLeft = ' monozukuri ';
  const titleRight = ` ${runLabel} `;
  const dashes = '─'.repeat(Math.max(0, innerWidth - titleLeft.length - titleRight.length));

  return (
    <Box flexDirection="column">
      {/* Title row with run id */}
      <Box paddingLeft={1}>
        <Text bold color={tokens.brand}>{titleLeft}</Text>
        <Text dimColor>{dashes}</Text>
        <Text color={tokens.dim}>{titleRight}</Text>
      </Box>

      {/* Metadata row */}
      <Box paddingLeft={2}>
        <Text color={tokens.dim}>autonomy: </Text>
        <Text color={tokens.brand}>{autonomy || '—'}</Text>
        <Text color={tokens.dim}>   model: </Text>
        <Text color={tokens.warning}>{model || '—'}</Text>
        <Text color={tokens.dim}>   agent: </Text>
        <Text color={tokens.success}>{agent || '—'}</Text>
        <Text color={tokens.dim}>   source: </Text>
        <Text color={tokens.info}>{sourceLabel}</Text>
      </Box>

      {/* Progress bar row */}
      <Box paddingLeft={2}>
        <CostMeter
          completed={completed}
          total={featureCount || Object.keys(features).length}
          costUsd={totalCost}
          budget={budget}
          width={innerWidth}
        />
      </Box>
    </Box>
  );
}
