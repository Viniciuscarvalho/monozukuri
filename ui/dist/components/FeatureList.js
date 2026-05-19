import { jsxs as _jsxs, jsx as _jsx } from "react/jsx-runtime";
import { Box, Text } from 'ink';
import { tokens, statusColor, statusSymbol } from '../tokens.js';
import { LAYOUT } from '../lib/layout.js';
const PHASES = ['prd', 'techspec', 'tasks', 'code', 'tests', 'pr'];
function phaseChar(ps) {
    if (ps === 'done')
        return '●';
    if (ps === 'in_progress')
        return '◐';
    if (ps === 'failed')
        return '✗';
    return '○';
}
function phaseCharColor(ps) {
    if (ps === 'done')
        return tokens.success;
    if (ps === 'in_progress')
        return tokens.brand;
    if (ps === 'failed')
        return tokens.danger;
    return tokens.dim;
}
function truncate(str, maxLen) {
    if (str.length <= maxLen)
        return str;
    return str.slice(0, maxLen - 1) + '…';
}
function pad(str, len) {
    if (str.length >= len)
        return str.slice(0, len - 1) + '…';
    return str + ' '.repeat(len - str.length);
}
function FeatureRow({ feature, titleLen }) {
    const { id, title, status, phases, currentPhase, error } = feature;
    const icon = statusSymbol(status);
    const color = statusColor(status);
    const isActive = status === 'active';
    const idLabel = pad(id, LAYOUT.featureIdWidth);
    const titleLabel = pad(title || id, titleLen);
    return (_jsxs(Box, { flexDirection: "column", children: [_jsxs(Box, { paddingLeft: 2, children: [_jsxs(Text, { color: color, bold: isActive, children: [icon, ' '] }), _jsx(Text, { color: isActive ? tokens.textPrimary : tokens.textSecondary, children: idLabel }), _jsx(Text, { color: tokens.dim, children: '  ' }), _jsx(Text, { color: isActive ? tokens.textPrimary : tokens.textSecondary, children: titleLabel }), _jsx(Text, { color: tokens.dim, children: '  ' }), PHASES.map((ph) => {
                        const ps = phases?.[ph] ?? 'pending';
                        return (_jsx(Text, { color: phaseCharColor(ps), children: phaseChar(ps) }, ph));
                    }), _jsx(Text, { color: tokens.dim, children: '  ' }), _jsx(Text, { color: color, bold: isActive, children: status }), isActive && currentPhase ? (_jsxs(Text, { color: tokens.dim, children: [" [", currentPhase, "]"] })) : null] }), (status === 'failed' || status === 'skipped' || status === 'pr_failed' || status === 'deferred') && error ? (_jsx(Box, { paddingLeft: 4, children: _jsx(Text, { color: color, dimColor: true, children: truncate(error, Math.max(10, titleLen + 20)) }) })) : null] }));
}
export function FeatureList({ features, order, innerWidth = 80, }) {
    const all = order.map((id) => features[id]).filter(Boolean);
    // Fixed columns: [icon+space:2] [id:18] [2sp] [title] [2sp] [dots:6] [2sp] [status:~12] = 44
    const fixedCols = LAYOUT.featureIdWidth + LAYOUT.featureTitleWidth + 13;
    const titleLen = Math.max(10, innerWidth - fixedCols);
    return (_jsx(Box, { flexDirection: "column", children: all.length === 0 ? (_jsx(Box, { paddingLeft: 2, children: _jsx(Text, { dimColor: true, children: "(no features loaded)" }) })) : (all.map((f) => (_jsx(FeatureRow, { feature: f, titleLen: titleLen }, f.id)))) }));
}
