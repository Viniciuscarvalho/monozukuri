import { jsx as _jsx, jsxs as _jsxs } from "react/jsx-runtime";
import { Box, Text } from 'ink';
import { tokens } from '../tokens.js';
const PHASE_LABELS = {
    prd: 'PRD',
    techspec: 'TechSpec',
    tasks: 'Tasks',
    code: 'Code',
    tests: 'Tests',
    pr: 'PR',
};
const PHASES = ['prd', 'techspec', 'tasks', 'code', 'tests', 'pr'];
function PhaseDot({ status, label }) {
    switch (status) {
        case 'done':
            return (_jsxs(Box, { marginRight: 1, children: [_jsx(Text, { color: tokens.success, children: "\u25CF " }), _jsx(Text, { children: label })] }));
        case 'in_progress':
            return (_jsxs(Box, { marginRight: 1, children: [_jsx(Text, { color: tokens.brand, children: "\u25D0 " }), _jsx(Text, { color: tokens.brand, children: label })] }));
        case 'failed':
            return (_jsxs(Box, { marginRight: 1, children: [_jsx(Text, { color: tokens.danger, children: "\u2717 " }), _jsx(Text, { color: tokens.danger, children: label })] }));
        case 'pending':
        default:
            return (_jsxs(Box, { marginRight: 1, children: [_jsx(Text, { color: tokens.dim, children: "\u25CB " }), _jsx(Text, { color: tokens.dim, children: label })] }));
    }
}
export function PhaseTimeline({ phases }) {
    return (_jsx(Box, { flexDirection: "row", children: PHASES.map((phase) => (_jsx(PhaseDot, { status: phases[phase], label: PHASE_LABELS[phase] }, phase))) }));
}
