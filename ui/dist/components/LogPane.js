import { jsx as _jsx, jsxs as _jsxs } from "react/jsx-runtime";
import { Box, Text } from 'ink';
import { tokens } from '../tokens.js';
import { LAYOUT } from '../lib/layout.js';
const PHASE_LOG_COLOR = {
    prd: tokens.info,
    techspec: tokens.warning,
    tasks: tokens.brand,
    code: tokens.success,
    tests: tokens.danger,
    pr: '#a78bfa',
};
function formatTime(ts) {
    try {
        const d = new Date(ts);
        if (isNaN(d.getTime()))
            return ts.slice(0, 8);
        const hh = String(d.getHours()).padStart(2, '0');
        const mm = String(d.getMinutes()).padStart(2, '0');
        const ss = String(d.getSeconds()).padStart(2, '0');
        return `${hh}:${mm}:${ss}`;
    }
    catch {
        return '??:??:??';
    }
}
function truncate(str, maxLen) {
    if (str.length <= maxLen)
        return str;
    return str.slice(0, maxLen - 1) + '…';
}
export function LogPane({ log, innerWidth }) {
    const tail = log.slice(-12);
    const maxTextLen = Math.max(20, innerWidth - LAYOUT.logChromeCols);
    return (_jsx(Box, { flexDirection: "column", children: tail.length === 0 ? (_jsx(Box, { paddingLeft: 2, children: _jsx(Text, { dimColor: true, children: "(no log entries yet)" }) })) : (tail.map((line, i) => {
            const time = formatTime(line.ts);
            const phaseColor = PHASE_LOG_COLOR[line.phase] ?? tokens.muted;
            const text = truncate(line.text, maxTextLen);
            return (_jsxs(Box, { paddingLeft: 2, children: [_jsxs(Text, { dimColor: true, children: [time, " "] }), _jsx(Text, { dimColor: true, children: truncate(line.featureId, 10) }), _jsx(Text, { children: "  " }), _jsxs(Text, { color: phaseColor, children: ["[", line.phase, "]"] }), _jsx(Text, { children: "  " }), _jsx(Text, { children: text })] }, i));
        })) }));
}
