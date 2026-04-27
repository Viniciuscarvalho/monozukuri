import React from 'react';
import { Box, Text } from 'ink';
import type { AppState } from '../types.js';

interface SetupPanelProps {
  state: AppState;
}

export function SetupPanel({ state }: SetupPanelProps): React.ReactElement {
  const agentEntries = Object.entries(state.setupAgents);
  const skills = state.setupSkills;

  return (
    <Box flexDirection="column" paddingX={2} paddingY={1}>
      <Text bold>monozukuri setup</Text>
      <Text> </Text>

      {agentEntries.length === 0 && skills.length === 0 ? (
        <Text dimColor>waiting for install events...</Text>
      ) : (
        <>
          {agentEntries.length > 0 && (
            <>
              <Text bold dimColor>Agents</Text>
              {agentEntries.map(([agent, status]) => (
                <Box key={agent}>
                  <Text color={status === 'ok' ? 'green' : 'yellow'}>
                    {status === 'ok' ? '✓' : '→'}
                  </Text>
                  <Text>  {agent}</Text>
                  <Text dimColor>  {status}</Text>
                </Box>
              ))}
              <Text> </Text>
            </>
          )}

          {skills.length > 0 && (
            <>
              <Text bold dimColor>Skills installed</Text>
              {skills.map((s, i) => (
                <Box key={i}>
                  <Text color="green">✓</Text>
                  <Text>  {s.skill}</Text>
                  <Text dimColor>  → {s.agent}</Text>
                </Box>
              ))}
            </>
          )}
        </>
      )}
    </Box>
  );
}
