import { jsx as _jsx, jsxs as _jsxs } from "react/jsx-runtime";
import { Box, Text } from 'ink';
import fuzzysort from 'fuzzysort';
import { tokens } from '../tokens.js';
const MIN_FUZZY_SCORE = 0.6;
function searchableText(item) {
    return [
        item.id,
        item.title,
        item.status,
        String(item.priority),
        String(item.effort),
        item.deps?.join(' ') ?? '',
    ].join(' ');
}
export function filterBacklogItems(items, query) {
    const trimmed = query.trim();
    if (!trimmed)
        return [...items];
    const targets = items.map((item) => ({
        item,
        haystack: searchableText(item),
    }));
    return fuzzysort
        .go(trimmed, targets, { key: 'haystack' })
        .filter((result) => result.score >= MIN_FUZZY_SCORE)
        .map((result) => result.obj.item);
}
export function clampFilteredCursor(cursorIndex, filteredCount) {
    if (filteredCount <= 0)
        return 0;
    return Math.min(Math.max(cursorIndex, 0), filteredCount - 1);
}
export function FilterBar({ query, totalCount, filteredCount, active = false, }) {
    const hasQuery = query.trim().length > 0;
    const countLabel = hasQuery ? `${filteredCount} of ${totalCount} matches` : `${totalCount} items`;
    return (_jsxs(Box, { children: [_jsx(Text, { color: active ? tokens.brand : tokens.dim, children: active ? '/' : 'filter' }), _jsx(Text, { color: tokens.dim, children: ' ' }), _jsx(Text, { color: hasQuery ? tokens.textPrimary : tokens.textSecondary, children: hasQuery ? query : 'all' }), _jsx(Text, { color: tokens.dim, children: '  ' }), _jsx(Text, { color: filteredCount === 0 && hasQuery ? tokens.warning : tokens.textSecondary, children: countLabel })] }));
}
