import React from 'react';
import { Box, Text } from 'ink';

interface CostMeterProps {
  completed: number;
  total: number;
  costUsd: number;
  budget: number;
  width: number;
}

function formatCost(usd: number): string {
  return `$${usd.toFixed(2)}`;
}

export function CostMeter({ completed, total, costUsd, budget, width }: CostMeterProps): React.ReactElement {
  const barWidth = Math.max(10, width - 40);
  const ratio = total > 0 ? Math.min(completed / total, 1) : 0;
  const filled = Math.round(barWidth * ratio);
  const empty = barWidth - filled;

  const overBudget = budget > 0 && costUsd > budget;
  const barColor = overBudget ? 'red' : 'green';

  return (
    <Box>
      <Text color={barColor}>{'█'.repeat(filled)}</Text>
      <Text dimColor>{'░'.repeat(empty)}</Text>
      <Text> {completed} / {total}</Text>
      <Text dimColor>  {formatCost(costUsd)} / {formatCost(budget)} budget</Text>
    </Box>
  );
}
