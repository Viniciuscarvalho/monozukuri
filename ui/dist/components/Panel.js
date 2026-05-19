import { jsx as _jsx, jsxs as _jsxs } from "react/jsx-runtime";
import { Box, Text } from 'ink';
import { tokens } from '../tokens.js';
export function Panel({ title, width, children }) {
    const effectiveWidth = width || 60;
    const sepLen = title ? Math.max(1, effectiveWidth - title.length - 3) : Math.max(1, effectiveWidth - 2);
    const sep = '─'.repeat(sepLen);
    return (_jsxs(Box, { flexDirection: "column", borderStyle: "round", borderColor: tokens.border, width: width, paddingX: 1, children: [title && (_jsxs(Box, { marginBottom: 0, children: [_jsx(Text, { bold: true, color: tokens.brand, children: title }), _jsxs(Text, { color: tokens.dim, children: [" ", sep] })] })), children] }));
}
