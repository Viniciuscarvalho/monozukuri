import { jsx as _jsx, jsxs as _jsxs } from "react/jsx-runtime";
import { Box, Text } from 'ink';
import { tokens, statusColor } from '../tokens.js';
function truncate(value, maxLen) {
    if (value.length <= maxLen)
        return value;
    return `${value.slice(0, Math.max(0, maxLen - 1))}…`;
}
function pad(value, length) {
    const truncated = truncate(value, length);
    return `${truncated}${' '.repeat(Math.max(0, length - truncated.length))}`;
}
function toSelectedSet(selectedIds) {
    return selectedIds instanceof Set ? selectedIds : new Set(selectedIds);
}
export function clampBacklogCursor(index, itemCount) {
    if (itemCount <= 0)
        return 0;
    return Math.min(Math.max(index, 0), itemCount - 1);
}
export function moveBacklogCursor(currentIndex, direction, itemCount) {
    if (itemCount <= 0)
        return 0;
    const next = direction === 'up' ? currentIndex - 1 : currentIndex + 1;
    return clampBacklogCursor(next, itemCount);
}
export function toggleBacklogSelection(selectedIds, id) {
    const next = new Set(selectedIds);
    if (next.has(id)) {
        next.delete(id);
    }
    else {
        next.add(id);
    }
    return next;
}
export function backlogSelectionSummary(selectedCount, totalCount) {
    return `${selectedCount} of ${totalCount} selected`;
}
function formatScore(score) {
    if (typeof score !== 'number' || Number.isNaN(score))
        return 'n/a';
    return score.toFixed(0);
}
export function BacklogList({ items, cursorIndex, selectedIds, innerWidth = 80, }) {
    const selected = toSelectedSet(selectedIds);
    const safeCursor = clampBacklogCursor(cursorIndex, items.length);
    const titleWidth = Math.max(18, innerWidth - 48);
    return (_jsxs(Box, { flexDirection: "column", children: [items.length === 0 ? (_jsx(Box, { paddingLeft: 2, children: _jsx(Text, { color: tokens.textSecondary, children: "(no backlog items)" }) })) : (items.map((item, index) => {
                const isCursor = index === safeCursor;
                const isSelected = selected.has(item.id);
                const rowColor = isCursor ? tokens.textPrimary : tokens.textSecondary;
                return (_jsxs(Box, { children: [_jsxs(Text, { color: isCursor ? tokens.brand : tokens.dim, children: [isCursor ? '›' : ' ', ' '] }), _jsxs(Text, { color: isSelected ? tokens.success : tokens.dim, children: [isSelected ? '●' : '○', ' '] }), _jsx(Text, { color: rowColor, children: pad(item.id, 12) }), _jsx(Text, { color: tokens.dim, children: ' ' }), _jsx(Text, { color: tokens.warning, children: pad(String(item.priority), 3) }), _jsx(Text, { color: tokens.dim, children: ' ' }), _jsx(Text, { color: tokens.info, children: pad(String(item.effort), 3) }), _jsx(Text, { color: tokens.dim, children: ' ' }), _jsx(Text, { color: statusColor(item.status), children: pad(item.status, 11) }), _jsx(Text, { color: tokens.dim, children: ' ' }), _jsx(Text, { color: rowColor, children: pad(truncate(item.title, titleWidth), titleWidth) }), _jsx(Text, { color: tokens.dim, children: ' ' }), _jsx(Text, { color: tokens.dim, children: formatScore(item.score) })] }, item.id));
            })), _jsx(Box, { marginTop: 1, paddingLeft: 2, children: _jsx(Text, { color: tokens.textSecondary, children: backlogSelectionSummary(selected.size, items.length) }) })] }));
}
