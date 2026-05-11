import React from 'react';
import { Box, Text } from 'ink';
import { PhaseTimeline } from './PhaseTimeline.js';
import type { Feature } from '../types.js';
import { tokens } from '../tokens.js';

interface FeatureCardProps {
  feature: Feature | null;
  spinner: string;
  now: Date;
}

function formatElapsed(startedAt: string | undefined, now: Date): string {
  if (!startedAt) return '—';
  const start = new Date(startedAt).getTime();
  const elapsed = Math.max(0, Math.floor((now.getTime() - start) / 1000));
  const m = Math.floor(elapsed / 60);
  const s = elapsed % 60;
  return m > 0 ? `${m}m ${s}s` : `${s}s`;
}

function formatTokens(tokens: number | undefined): string {
  if (tokens === undefined) return '—';
  if (tokens >= 1000) return `${Math.round(tokens / 1000)}k`;
  return String(tokens);
}

function formatRate(rate: number | undefined): string | null {
  if (typeof rate !== 'number' || !Number.isFinite(rate) || rate <= 0) return null;
  if (rate >= 1000) return `${(rate / 1000).toFixed(1)}k/min`;
  return `${Math.round(rate)}/min`;
}

function formatRelativeTime(ts: number, now: Date): string {
  const elapsed = Math.max(0, Math.floor((now.getTime() - ts) / 1000));
  if (elapsed < 60) return `${elapsed}s`;
  const m = Math.floor(elapsed / 60);
  return `${m}m`;
}

function truncate(str: string, maxLen: number): string {
  if (str.length <= maxLen) return str;
  return str.slice(0, maxLen - 1) + '…';
}

interface WaitingCardProps {
  // Empty state
}

function WaitingCard(_props: WaitingCardProps): React.ReactElement {
  return (
    <Box flexDirection="column" paddingLeft={2} paddingY={1}>
      <Text color={tokens.dim}>waiting for run...</Text>
    </Box>
  );
}

export function FeatureCard({ feature, spinner, now }: FeatureCardProps): React.ReactElement {
  if (!feature) {
    return <WaitingCard />;
  }

  if (feature.status === 'deferred') {
    const reason = feature.error ?? 'no reason given';
    return (
      <Box flexDirection="column" paddingLeft={1}>
        <Box>
          <Text>│ </Text>
          <Text color={tokens.warning}>⏸ </Text>
          <Text bold color={tokens.warning}>{feature.id}</Text>
          <Text>  </Text>
          <Text color={tokens.dim}>{truncate(feature.title || feature.id, 42)}</Text>
          <Text> │</Text>
        </Box>
        <Box>
          <Text>│   </Text>
          <Text color={tokens.warning}>deferred: </Text>
          <Text>{truncate(reason, 50)}</Text>
          <Text> │</Text>
        </Box>
      </Box>
    );
  }

  const elapsed = formatElapsed(feature.startedAt, now);
  // Prefer the live cumulative output counter from phase.token_update; fall
  // back to the legacy aggregate `tokens` field for back-compat.
  const liveTokens = feature.tokensOut ?? feature.tokens;
  const tokenCount = formatTokens(liveTokens);
  const estTokens = feature.estimatedTokens ? formatTokens(feature.estimatedTokens) : '~?';
  const rateLabel = formatRate(feature.tokenRate);
  const title = truncate(feature.title || feature.id, 42);
  const spinnerText = spinner ? truncate(spinner, 50) : '';
  const recentEvents = feature.recentEvents ?? [];

  return (
    <Box flexDirection="column" paddingLeft={1}>
      {/* Feature header line */}
      <Box>
        <Text>│ </Text>
        <Text color={tokens.brand}>▸ </Text>
        <Text bold color={tokens.brand}>{feature.id}</Text>
        <Text>  </Text>
        <Text>{title}</Text>
        <Text color={tokens.dim}>  elapsed: </Text>
        <Text color={tokens.warning}>{elapsed}</Text>
        <Text> │</Text>
      </Box>

      {/* Skill / memory subtitle */}
      {feature.currentSkill && (
        <Box>
          <Text>│   </Text>
          <Text color={tokens.dim}>{'skill: '}</Text>
          <Text color={feature.compaction && feature.compaction !== 'none' ? tokens.warning : tokens.success}>
            {feature.currentSkill}
          </Text>
          <Text color={tokens.dim}>{' · tier '}</Text>
          <Text>{feature.currentTier ?? '—'}</Text>
          <Text color={tokens.dim}>{' · mem: '}</Text>
          <Text color={feature.compaction && feature.compaction !== 'none' ? tokens.warning : tokens.success}>
            {feature.compaction && feature.compaction !== 'none'
              ? `compaction:${feature.compaction}`
              : 'ok'}
          </Text>
          <Text> │</Text>
        </Box>
      )}

      {/* Phase timeline */}
      <Box>
        <Text>│   </Text>
        <PhaseTimeline phases={feature.phases} />
        <Text> │</Text>
      </Box>

      {/* Tokens + rate + spinner */}
      <Box>
        <Text>│   </Text>
        <Text color={tokens.dim}>tokens: </Text>
        <Text>{tokenCount}</Text>
        <Text color={tokens.dim}> / {estTokens} est.</Text>
        {rateLabel ? (
          <>
            <Text color={tokens.dim}> · </Text>
            <Text color={tokens.brand}>{rateLabel}</Text>
          </>
        ) : null}
        {spinnerText ? (
          <>
            <Text color={tokens.dim}>   </Text>
            <Text color={tokens.warning}>{spinnerText}</Text>
          </>
        ) : null}
        <Text> │</Text>
      </Box>

      {/* Recent activity tree — last 3 tool/file events */}
      {recentEvents.length > 0 ? (
        <Box flexDirection="column">
          <Box>
            <Text>│   </Text>
            <Text color={tokens.dim}>recent activity</Text>
            <Text> │</Text>
          </Box>
          {recentEvents.slice(-3).map((ev, i, arr) => (
            <Box key={`${ev.ts}-${i}`}>
              <Text>│   </Text>
              <Text color={tokens.dim}>
                {i === arr.length - 1 ? tokens.tree.last : tokens.tree.branch}
                {' '}
                {formatRelativeTime(ev.ts, now)}
                {'  '}
              </Text>
              <Text color={tokens.textSecondary}>{ev.tool}</Text>
              {ev.target ? (
                <>
                  <Text color={tokens.dim}>{' '}</Text>
                  <Text color={tokens.dim}>{truncate(ev.target, 40)}</Text>
                </>
              ) : null}
              <Text> │</Text>
            </Box>
          ))}
        </Box>
      ) : null}
    </Box>
  );
}
