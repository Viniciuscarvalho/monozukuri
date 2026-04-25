import React from 'react';
import { Box, Text } from 'ink';
import type { Phase, PhaseStatus } from '../types.js';

const PHASE_LABELS: Record<Phase, string> = {
  prd: 'PRD',
  techspec: 'TechSpec',
  tasks: 'Tasks',
  code: 'Code',
  tests: 'Tests',
  pr: 'PR',
};

const PHASES: Phase[] = ['prd', 'techspec', 'tasks', 'code', 'tests', 'pr'];

interface PhaseDotProps {
  status: PhaseStatus;
  label: string;
}

function PhaseDot({ status, label }: PhaseDotProps): React.ReactElement {
  switch (status) {
    case 'done':
      return (
        <Box marginRight={1}>
          <Text color="green">● </Text>
          <Text>{label}</Text>
        </Box>
      );
    case 'in_progress':
      return (
        <Box marginRight={1}>
          <Text color="yellow">◐ </Text>
          <Text color="yellow">{label}</Text>
        </Box>
      );
    case 'failed':
      return (
        <Box marginRight={1}>
          <Text color="red">✗ </Text>
          <Text color="red">{label}</Text>
        </Box>
      );
    case 'pending':
    default:
      return (
        <Box marginRight={1}>
          <Text dimColor>○ </Text>
          <Text dimColor>{label}</Text>
        </Box>
      );
  }
}

interface PhaseTimelineProps {
  phases: Record<Phase, PhaseStatus>;
}

export function PhaseTimeline({ phases }: PhaseTimelineProps): React.ReactElement {
  return (
    <Box flexDirection="row">
      {PHASES.map((phase) => (
        <PhaseDot key={phase} status={phases[phase]} label={PHASE_LABELS[phase]} />
      ))}
    </Box>
  );
}
