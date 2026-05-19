import { jsx as _jsx, jsxs as _jsxs } from "react/jsx-runtime";
import { useEffect, useState } from 'react';
import { writeFileSync } from 'node:fs';
import { Box, Text } from 'ink';
import { cleanup } from './runtime.js';
import { tokens } from './tokens.js';
import { useTerminalWidth, sep } from './lib/layout.js';
import { Header } from './components/Header.js';
import { FeatureCard } from './components/FeatureCard.js';
import { FeatureList } from './components/FeatureList.js';
import { LogPane } from './components/LogPane.js';
import { SetupPanel } from './components/SetupPanel.js';
import { useEventStream } from './hooks/useEventStream.js';
import { useKeybindings } from './hooks/useKeybindings.js';
import { useTicker } from './hooks/useTicker.js';
export default function App() {
    const [view, setView] = useState('main');
    const [done, setDone] = useState(false);
    const state = useEventStream();
    const now = useTicker();
    const terminalWidth = useTerminalWidth();
    const innerWidth = terminalWidth - 2;
    useKeybindings({ setView });
    // When run.completed arrives, surface the summary frame briefly then exit
    useEffect(() => {
        if (state.current === null && state.totals.succeeded + state.totals.failed > 0) {
            setDone(true);
            // Write plain-text summary to /dev/tty so it persists in scrollback after Ink unmounts
            try {
                const summary = [
                    '',
                    `  Monozukuri run complete`,
                    `  ✓ done: ${state.totals.succeeded}   ✗ failed: ${state.totals.failed}   ~ skipped: ${state.totals.skipped}`,
                    `  cost: $${(state.totals.costUsd ?? 0).toFixed(4)}`,
                    '',
                ].join('\n');
                writeFileSync('/dev/tty', summary);
            }
            catch {
                // /dev/tty may not be writable in some environments
            }
            setTimeout(() => { cleanup?.(); process.exit(0); }, 200);
        }
    }, [state.current, state.totals]);
    if (done) {
        return (_jsxs(Box, { flexDirection: "column", paddingY: 1, children: [_jsx(Text, { bold: true, color: tokens.success, children: "Run complete" }), _jsxs(Text, { children: ['  ', _jsxs(Text, { color: tokens.success, children: ["\u2713 ", state.totals.succeeded, " done"] }), '  ', _jsxs(Text, { color: tokens.danger, children: ["\u2717 ", state.totals.failed, " failed"] }), '  ', _jsxs(Text, { dimColor: true, children: ["~ ", state.totals.skipped, " skipped"] })] }), _jsxs(Text, { dimColor: true, children: ["  cost: $", (state.totals.costUsd ?? 0).toFixed(4)] })] }));
    }
    const currentFeature = state.current ? (state.features[state.current] ?? null) : null;
    if (view === 'help') {
        return (_jsxs(Box, { flexDirection: "column", children: [_jsx(Text, { bold: true, children: "Monozukuri \u2014 Keyboard Shortcuts" }), _jsx(Text, { children: " " }), _jsx(Text, { children: '  q         Quit (sends SIGINT to orchestrator)' }), _jsx(Text, { children: '  p         Pause / resume orchestrator (SIGUSR1)' }), _jsx(Text, { children: '  l         View learnings' }), _jsx(Text, { children: '  f         Filter features' }), _jsx(Text, { children: '  /         Search' }), _jsx(Text, { children: '  ?         This help screen' }), _jsx(Text, { children: '  Escape    Return to main view' }), _jsx(Text, { children: " " }), _jsx(Text, { dimColor: true, children: "Press Escape to return." })] }));
    }
    if (view === 'learnings') {
        return (_jsxs(Box, { flexDirection: "column", children: [_jsx(Text, { bold: true, children: "Learnings view" }), _jsx(Text, { dimColor: true, children: "(not yet implemented \u2014 press Escape to return)" })] }));
    }
    if (view === 'filter') {
        return (_jsxs(Box, { flexDirection: "column", children: [_jsx(Text, { bold: true, children: "Filter view" }), _jsx(Text, { dimColor: true, children: "(not yet implemented \u2014 press Escape to return)" })] }));
    }
    if (view === 'search') {
        return (_jsxs(Box, { flexDirection: "column", children: [_jsx(Text, { bold: true, children: "Search view" }), _jsx(Text, { dimColor: true, children: "(not yet implemented \u2014 press Escape to return)" })] }));
    }
    // Main dashboard view
    if (state.setupMode) {
        return _jsx(SetupPanel, { state: state });
    }
    return (_jsxs(Box, { borderStyle: "round", borderColor: tokens.dim, width: terminalWidth, flexDirection: "column", children: [_jsx(Header, { state: state, innerWidth: innerWidth }), _jsx(Text, { color: tokens.dim, children: sep('active ▶', innerWidth) }), _jsx(FeatureCard, { feature: currentFeature, now: now, innerWidth: innerWidth }), _jsx(Text, { color: tokens.dim, children: sep('queue', innerWidth) }), _jsx(FeatureList, { features: state.features, order: state.order, innerWidth: innerWidth }), _jsx(Text, { color: tokens.dim, children: sep('log', innerWidth) }), _jsx(LogPane, { log: state.log, innerWidth: innerWidth }), _jsx(Text, { color: tokens.dim, children: sep('q quit · p pause · ? help', innerWidth) })] }));
}
