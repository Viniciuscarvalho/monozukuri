import { jsx as _jsx, jsxs as _jsxs } from "react/jsx-runtime";
import { Box, Text } from 'ink';
import { tokens, statusColor } from '../tokens.js';
function normalizeMarkdownLine(line) {
    return line
        .replace(/^#{1,6}\s+/, '')
        .replace(/\*\*([^*]+)\*\*/g, '$1')
        .replace(/__([^_]+)__/g, '$1')
        .replace(/`([^`]+)`/g, '$1')
        .replace(/\[([^\]]+)\]\([^)]+\)/g, '$1')
        .replace(/^\s*[-*]\s+/, '• ')
        .trimEnd();
}
export function renderMarkdownPreview(markdown, maxLines = 8) {
    if (!markdown?.trim())
        return ['No description provided.'];
    return markdown
        .split(/\r?\n/)
        .map(normalizeMarkdownLine)
        .filter((line) => line.trim().length > 0)
        .slice(0, maxLines);
}
function truncate(value, maxLen) {
    if (value.length <= maxLen)
        return value;
    return `${value.slice(0, Math.max(0, maxLen - 1))}…`;
}
export function FeaturePreview({ item, innerWidth = 48, }) {
    if (!item) {
        return (_jsx(Box, { flexDirection: "column", paddingX: 1, children: _jsx(Text, { color: tokens.textSecondary, children: "No feature selected." }) }));
    }
    const descriptionLines = renderMarkdownPreview(item.description);
    const deps = item.deps ?? [];
    const contentWidth = Math.max(20, innerWidth - 2);
    return (_jsxs(Box, { flexDirection: "column", paddingX: 1, children: [_jsx(Text, { color: tokens.brand, bold: true, children: truncate(item.title, contentWidth) }), _jsxs(Box, { marginTop: 1, children: [_jsx(Text, { color: tokens.dim, children: "id " }), _jsx(Text, { color: tokens.textSecondary, children: item.id }), _jsx(Text, { color: tokens.dim, children: "  status " }), _jsx(Text, { color: statusColor(item.status), children: item.status })] }), _jsxs(Box, { children: [_jsx(Text, { color: tokens.dim, children: "priority " }), _jsx(Text, { color: tokens.warning, children: item.priority }), _jsx(Text, { color: tokens.dim, children: "  effort " }), _jsx(Text, { color: tokens.info, children: item.effort })] }), _jsx(Box, { marginTop: 1, flexDirection: "column", children: descriptionLines.map((line, index) => (_jsx(Text, { color: tokens.textSecondary, children: truncate(line, contentWidth) }, `${item.id}-description-${index}`))) }), _jsxs(Box, { marginTop: 1, flexDirection: "column", children: [_jsx(Text, { color: tokens.dim, children: "deps" }), deps.length === 0 ? (_jsx(Text, { color: tokens.textSecondary, children: "none" })) : (deps.map((dep) => (_jsxs(Text, { color: tokens.textSecondary, children: ["\u2022 ", dep] }, dep))))] })] }));
}
