import { jsx as _jsx, jsxs as _jsxs, Fragment as _Fragment } from "react/jsx-runtime";
import { Box, Text } from 'ink';
import { tokens } from '../tokens.js';
export function SetupPanel({ state }) {
    const agentEntries = Object.entries(state.setupAgents);
    const skills = state.setupSkills;
    return (_jsxs(Box, { flexDirection: "column", paddingX: 2, paddingY: 1, children: [_jsx(Text, { bold: true, children: "monozukuri setup" }), _jsx(Text, { children: " " }), agentEntries.length === 0 && skills.length === 0 ? (_jsx(Text, { dimColor: true, children: "waiting for install events..." })) : (_jsxs(_Fragment, { children: [agentEntries.length > 0 && (_jsxs(_Fragment, { children: [_jsx(Text, { bold: true, dimColor: true, children: "Agents" }), agentEntries.map(([agent, status]) => (_jsxs(Box, { children: [_jsx(Text, { color: status === 'ok' ? tokens.success : tokens.warning, children: status === 'ok' ? '✓' : '→' }), _jsxs(Text, { children: ["  ", agent] }), _jsxs(Text, { dimColor: true, children: ["  ", status] })] }, agent))), _jsx(Text, { children: " " })] })), skills.length > 0 && (_jsxs(_Fragment, { children: [_jsx(Text, { bold: true, dimColor: true, children: "Skills installed" }), skills.map((s, i) => (_jsxs(Box, { children: [_jsx(Text, { color: tokens.success, children: "\u2713" }), _jsxs(Text, { children: ["  ", s.skill] }), _jsxs(Text, { dimColor: true, children: ["  \u2192 ", s.agent] })] }, i)))] }))] }))] }));
}
