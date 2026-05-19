import { useEffect, useReducer } from 'react';
import { initialState, reducer } from '../reducer.js';
export function useEventStream() {
    const [state, dispatch] = useReducer(reducer, undefined, initialState);
    useEffect(() => {
        process.stdin.setEncoding('utf8');
        process.stdin.resume();
        let buffer = '';
        const onData = (chunk) => {
            buffer += chunk;
            const lines = buffer.split('\n');
            // Keep the last (potentially incomplete) segment in the buffer
            buffer = lines.pop() ?? '';
            for (const line of lines) {
                const trimmed = line.trim();
                if (!trimmed)
                    continue;
                try {
                    const event = JSON.parse(trimmed);
                    dispatch(event);
                }
                catch {
                    // Skip malformed lines silently
                }
            }
        };
        const onEnd = () => {
            // Process any remaining buffered data
            if (buffer.trim()) {
                try {
                    const event = JSON.parse(buffer.trim());
                    dispatch(event);
                }
                catch {
                    // Skip malformed final line
                }
                buffer = '';
            }
        };
        process.stdin.on('data', onData);
        process.stdin.on('end', onEnd);
        return () => {
            process.stdin.off('data', onData);
            process.stdin.off('end', onEnd);
        };
    }, []);
    return state;
}
