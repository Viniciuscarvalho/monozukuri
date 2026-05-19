import { jsx as _jsx, jsxs as _jsxs } from "react/jsx-runtime";
import { Box, Text } from 'ink';
import { tokens } from '../tokens.js';
function formatCost(usd) {
    return `$${usd.toFixed(2)}`;
}
export function CostMeter({ completed, total, costUsd, budget, width }) {
    const barWidth = Math.max(10, width - 40);
    const ratio = total > 0 ? Math.min(completed / total, 1) : 0;
    const filled = Math.round(barWidth * ratio);
    const empty = barWidth - filled;
    const overBudget = budget > 0 && costUsd > budget;
    const barColor = overBudget ? tokens.danger : tokens.success;
    return (_jsxs(Box, { children: [_jsx(Text, { color: barColor, children: '█'.repeat(filled) }), _jsx(Text, { dimColor: true, children: '░'.repeat(empty) }), _jsxs(Text, { children: [" ", completed, " / ", total] }), _jsxs(Text, { dimColor: true, children: ["  ", formatCost(costUsd), " / ", formatCost(budget), " budget"] })] }));
}
