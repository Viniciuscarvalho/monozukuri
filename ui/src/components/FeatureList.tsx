import React from 'react';
import { Box, Text } from 'ink';
import type { Feature } from '../types.js';

interface FeatureListProps {
  features: Record<string, Feature>;
  order: string[];
  terminalWidth: number;
}

function truncate(str: string, maxLen: number): string {
  if (str.length <= maxLen) return str;
  return str.slice(0, maxLen - 1) + '…';
}

interface QueueItemProps {
  feature: Feature;
  maxTitleLen: number;
}

function QueueItem({ feature, maxTitleLen }: QueueItemProps): React.ReactElement {
  return (
    <Box>
      <Text>│  </Text>
      <Text dimColor>{feature.id}</Text>
      <Text>  </Text>
      <Text dimColor>{truncate(feature.title || feature.id, maxTitleLen)}</Text>
    </Box>
  );
}

interface DoneItemProps {
  feature: Feature;
  maxTitleLen: number;
}

function DoneItem({ feature, maxTitleLen }: DoneItemProps): React.ReactElement {
  const isDone = feature.status === 'done';
  const icon = isDone ? '✓' : '✗';
  const iconColor = isDone ? 'green' : 'red';

  return (
    <Box flexDirection="column">
      <Box>
        <Text>│  </Text>
        <Text color={iconColor}>{icon} </Text>
        <Text dimColor={!isDone}>{feature.id}</Text>
        <Text>  </Text>
        <Text dimColor={!isDone}>{truncate(feature.title || feature.id, maxTitleLen)}</Text>
      </Box>
      {!isDone && feature.error ? (
        <Box>
          <Text>│     </Text>
          <Text color="red" dimColor>
            ({truncate(feature.error, maxTitleLen + 8)})
          </Text>
        </Box>
      ) : null}
    </Box>
  );
}

export function FeatureList({
  features,
  order,
  terminalWidth,
}: FeatureListProps): React.ReactElement {
  const queued: Feature[] = [];
  const done: Feature[] = [];

  for (const id of order) {
    const f = features[id];
    if (!f) continue;
    if (f.status === 'queued') {
      queued.push(f);
    } else if (f.status === 'done' || f.status === 'failed' || f.status === 'skipped') {
      done.push(f);
    }
  }

  // Half-width for each column, accounting for border chars and padding
  const halfWidth = Math.max(10, Math.floor((terminalWidth - 4) / 2));
  const maxTitleLen = Math.max(8, halfWidth - 20);

  const maxRows = Math.max(queued.length, done.length, 1);
  const rows: React.ReactElement[] = [];

  // Separator row with section headers
  const queueDashes = '─'.repeat(Math.max(0, halfWidth - 8));
  const doneDashes = '─'.repeat(Math.max(0, halfWidth - 8));
  rows.push(
    <Box key="header">
      <Text>├─ queue </Text>
      <Text dimColor>{queueDashes}</Text>
      <Text>┬─ done </Text>
      <Text dimColor>{doneDashes}</Text>
      <Text>──┤</Text>
    </Box>
  );

  for (let i = 0; i < maxRows; i++) {
    const qf = queued[i];
    const df = done[i];

    rows.push(
      <Box key={`row-${i}`}>
        {/* Queue column */}
        {qf ? (
          <Box width={halfWidth}>
            <Text>│  </Text>
            <Text dimColor>{truncate(qf.id, 10)}</Text>
            <Text>  </Text>
            <Text dimColor>{truncate(qf.title || qf.id, maxTitleLen)}</Text>
          </Box>
        ) : (
          <Box width={halfWidth}>
            <Text>│</Text>
            <Text>{' '.repeat(halfWidth - 1)}</Text>
          </Box>
        )}

        {/* Done column */}
        {df ? (
          <Box flexDirection="column">
            <Box>
              <Text>│  </Text>
              <Text color={df.status === 'done' ? 'green' : 'red'}>
                {df.status === 'done' ? '✓' : '✗'}{' '}
              </Text>
              <Text dimColor={df.status !== 'done'}>
                {truncate(`${df.id}  ${df.title || df.id}`, maxTitleLen + 8)}
              </Text>
            </Box>
            {df.status !== 'done' && df.error ? (
              <Box>
                <Text>│     </Text>
                <Text color="red" dimColor>
                  ({truncate(df.error, maxTitleLen)})
                </Text>
              </Box>
            ) : null}
          </Box>
        ) : (
          <Box>
            <Text>│</Text>
          </Box>
        )}
      </Box>
    );
  }

  if (queued.length === 0 && done.length === 0) {
    rows.push(
      <Box key="empty">
        <Box width={halfWidth}>
          <Text>│</Text>
          <Text dimColor>  (empty)</Text>
        </Box>
        <Box>
          <Text>│</Text>
          <Text dimColor>  (empty)</Text>
        </Box>
      </Box>
    );
  }

  return <Box flexDirection="column">{rows}</Box>;
}
