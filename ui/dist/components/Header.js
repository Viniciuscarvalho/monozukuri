import { jsx as _jsx, jsxs as _jsxs } from "react/jsx-runtime";
import { Box, Text } from 'ink';
import { CostMeter } from './CostMeter.js';
import { tokens } from '../tokens.js';
export function Header({ state, innerWidth }) {
    const { runId, autonomy, model, agent, source, featureCount, budget, features, totals } = state;
    const completed = totals.succeeded + totals.failed + totals.skipped;
    const totalCost = totals.costUsd;
    const sourceLabel = source || 'unknown';
    const runLabel = runId ? `run ${runId.slice(0, 8)}` : 'run —';
    const titleLeft = ' monozukuri ';
    const titleRight = ` ${runLabel} `;
    const dashes = '─'.repeat(Math.max(0, innerWidth - titleLeft.length - titleRight.length));
    return (_jsxs(Box, { flexDirection: "column", children: [_jsxs(Box, { paddingLeft: 1, children: [_jsx(Text, { bold: true, color: tokens.brand, children: titleLeft }), _jsx(Text, { dimColor: true, children: dashes }), _jsx(Text, { color: tokens.dim, children: titleRight })] }), _jsxs(Box, { paddingLeft: 2, children: [_jsx(Text, { color: tokens.dim, children: "autonomy: " }), _jsx(Text, { color: tokens.brand, children: autonomy || '—' }), _jsx(Text, { color: tokens.dim, children: "   model: " }), _jsx(Text, { color: tokens.warning, children: model || '—' }), _jsx(Text, { color: tokens.dim, children: "   agent: " }), _jsx(Text, { color: tokens.success, children: agent || '—' }), _jsx(Text, { color: tokens.dim, children: "   source: " }), _jsx(Text, { color: tokens.info, children: sourceLabel })] }), _jsx(Box, { paddingLeft: 2, children: _jsx(CostMeter, { completed: completed, total: featureCount || Object.keys(features).length, costUsd: totalCost, budget: budget, width: innerWidth }) })] }));
}
