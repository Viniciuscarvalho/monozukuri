import { jsx as _jsx, jsxs as _jsxs, Fragment as _Fragment } from "react/jsx-runtime";
import { useState, useEffect } from 'react';
import { Box, Text } from 'ink';
import { PhaseTimeline } from './PhaseTimeline.js';
import { tokens } from '../tokens.js';
import { LAYOUT } from '../lib/layout.js';
function formatElapsed(startedAt, now) {
    if (!startedAt)
        return '—';
    const start = new Date(startedAt).getTime();
    const elapsed = Math.max(0, Math.floor((now.getTime() - start) / 1000));
    const m = Math.floor(elapsed / 60);
    const s = elapsed % 60;
    return m > 0 ? `${m}m ${s}s` : `${s}s`;
}
function formatTokens(tokens) {
    if (tokens === undefined)
        return '—';
    if (tokens >= 1000)
        return `${Math.round(tokens / 1000)}k`;
    return String(tokens);
}
function formatRate(rate) {
    if (typeof rate !== 'number' || !Number.isFinite(rate) || rate <= 0)
        return null;
    if (rate >= 1000)
        return `${(rate / 1000).toFixed(1)}k/min`;
    return `${Math.round(rate)}/min`;
}
function formatRelativeTime(ts, now) {
    const elapsed = Math.max(0, Math.floor((now.getTime() - ts) / 1000));
    if (elapsed < 60)
        return `${elapsed}s`;
    const m = Math.floor(elapsed / 60);
    return `${m}m`;
}
function truncate(str, maxLen) {
    if (str.length <= maxLen)
        return str;
    return str.slice(0, maxLen - 1) + '…';
}
function WaitingCard(_props) {
    return (_jsx(Box, { flexDirection: "column", paddingLeft: 2, paddingY: 1, children: _jsx(Text, { color: tokens.dim, children: "waiting for run..." }) }));
}
export function FeatureCard({ feature, now, innerWidth = 80 }) {
    const [spinnerFrame, setSpinnerFrame] = useState(0);
    useEffect(() => {
        if (!feature || !['running', 'in_progress', 'active'].includes(feature.status ?? ''))
            return;
        const id = setInterval(() => setSpinnerFrame(f => (f + 1) % tokens.spinner.frames.length), tokens.spinner.intervalMs);
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        id.unref?.();
        return () => clearInterval(id);
    }, [feature?.status]);
    const spinner = tokens.spinner.frames[spinnerFrame];
    if (!feature) {
        return _jsx(WaitingCard, {});
    }
    if (feature.status === 'deferred') {
        const reason = feature.error ?? 'no reason given';
        return (_jsxs(Box, { flexDirection: "column", paddingLeft: 2, children: [_jsxs(Box, { children: [_jsx(Text, { color: tokens.warning, children: "\u23F8 " }), _jsx(Text, { bold: true, color: tokens.warning, children: feature.id }), _jsx(Text, { children: "  " }), _jsx(Text, { color: tokens.dim, children: truncate(feature.title || feature.id, LAYOUT.featureCardTitleMax) })] }), _jsxs(Box, { children: [_jsx(Text, { color: tokens.warning, children: "deferred: " }), _jsx(Text, { children: truncate(reason, 50) })] })] }));
    }
    const elapsed = formatElapsed(feature.startedAt, now);
    // Prefer the live cumulative output counter from phase.token_update; fall
    // back to the legacy aggregate `tokens` field for back-compat.
    const liveTokens = feature.tokensOut ?? feature.tokens;
    const tokenCount = formatTokens(liveTokens);
    const estTokens = feature.estimatedTokens ? formatTokens(feature.estimatedTokens) : '~?';
    const rateLabel = formatRate(feature.tokenRate);
    const title = truncate(feature.title || feature.id, LAYOUT.featureCardTitleMax);
    const recentEvents = feature.recentEvents ?? [];
    const isActive = ['running', 'in_progress', 'active'].includes(feature.status ?? '');
    return (_jsxs(Box, { flexDirection: "column", paddingLeft: 2, children: [_jsxs(Box, { children: [_jsx(Text, { color: tokens.brand, children: "\u25B8 " }), _jsx(Text, { bold: true, color: tokens.brand, children: feature.id }), _jsx(Text, { children: "  " }), _jsx(Text, { children: title }), _jsx(Text, { color: tokens.dim, children: "  elapsed: " }), _jsx(Text, { color: tokens.warning, children: elapsed })] }), feature.currentSkill && (_jsxs(Box, { children: [_jsx(Text, { color: tokens.dim, children: "skill: " }), _jsx(Text, { color: feature.compaction && feature.compaction !== 'none' ? tokens.warning : tokens.success, children: feature.currentSkill }), _jsx(Text, { color: tokens.dim, children: ' · tier ' }), _jsx(Text, { children: feature.currentTier ?? '—' }), _jsx(Text, { color: tokens.dim, children: ' · mem: ' }), _jsx(Text, { color: feature.compaction && feature.compaction !== 'none' ? tokens.warning : tokens.success, children: feature.compaction && feature.compaction !== 'none'
                            ? `compaction:${feature.compaction}`
                            : 'ok' })] })), _jsx(Box, { children: _jsx(PhaseTimeline, { phases: feature.phases }) }), _jsxs(Box, { children: [_jsx(Text, { color: tokens.dim, children: "tokens: " }), _jsx(Text, { children: tokenCount }), _jsxs(Text, { color: tokens.dim, children: [" / ", estTokens, " est."] }), rateLabel ? (_jsxs(_Fragment, { children: [_jsx(Text, { color: tokens.dim, children: " \u00B7 " }), _jsx(Text, { color: tokens.brand, children: rateLabel })] })) : null, isActive ? (_jsxs(_Fragment, { children: [_jsx(Text, { color: tokens.dim, children: "   " }), _jsx(Text, { color: tokens.brand, children: spinner })] })) : null] }), recentEvents.length > 0 ? (_jsxs(Box, { flexDirection: "column", children: [_jsx(Box, { children: _jsx(Text, { color: tokens.dim, children: "recent activity" }) }), recentEvents.slice(-3).map((ev, i, arr) => (_jsxs(Box, { children: [_jsxs(Text, { color: tokens.dim, children: [i === arr.length - 1 ? tokens.tree.last : tokens.tree.branch, ' ', formatRelativeTime(ev.ts, now), '  '] }), _jsx(Text, { color: tokens.textSecondary, children: ev.tool }), ev.target ? (_jsxs(_Fragment, { children: [_jsx(Text, { color: tokens.dim, children: ' ' }), _jsx(Text, { color: tokens.dim, children: truncate(ev.target, 40) })] })) : null] }, `${ev.ts}-${i}`)))] })) : null] }));
}
