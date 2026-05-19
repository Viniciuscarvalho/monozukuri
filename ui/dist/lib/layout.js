// Terminal width utilities for adaptive Ink layouts.
import { useState, useEffect } from 'react';
import { useStdout } from 'ink';
export function useTerminalWidth(maxWidth = 120) {
    const { stdout } = useStdout();
    const [columns, setColumns] = useState(stdout?.columns ?? 80);
    useEffect(() => {
        if (!stdout)
            return;
        const handler = () => setColumns(stdout.columns ?? 80);
        stdout.on('resize', handler);
        return () => { stdout.off('resize', handler); };
    }, [stdout]);
    return Math.min(columns || 80, maxWidth);
}
export function clamp(value, min, max) {
    return Math.max(min, Math.min(max, value));
}
// Produces a full-width separator string of exactly innerWidth chars.
// Place as a <Text> row directly inside a borderStyle Box — no padding —
// so it touches the │ borders on both sides, creating a ├── label ──┤ visual.
export function sep(label, innerWidth) {
    const core = label ? `── ${label} ` : '';
    return core + '─'.repeat(Math.max(0, innerWidth - core.length));
}
// Named layout constants — extracted from magic numbers across components.
export const LAYOUT = {
    featureIdWidth: 18, // padded ID column in FeatureList
    featureTitleWidth: 30, // padded title column in FeatureList
    featureCardTitleMax: 42, // truncation limit for active feature title in FeatureCard
    logChromeCols: 26, // time + id prefix width in LogPane
    logMsgMax: 50, // truncated message length in LogPane
};
