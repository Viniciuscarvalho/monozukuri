import { jsx as _jsx, jsxs as _jsxs } from "react/jsx-runtime";
import { useEffect, useMemo, useState } from 'react';
import { readFileSync } from 'node:fs';
import { Box, Text, render, useApp, useInput } from 'ink';
import { BacklogList, clampBacklogCursor, moveBacklogCursor, toggleBacklogSelection } from './components/BacklogList.js';
import { FeaturePreview } from './components/FeaturePreview.js';
import { FilterBar, clampFilteredCursor, filterBacklogItems } from './components/FilterBar.js';
import { tokens } from './tokens.js';
function orderedSelectedIds(items, selectedIds) {
    return items.map((item) => item.id).filter((id) => selectedIds.has(id));
}
export function PickApp({ items, onSubmit, onCancel }) {
    const { exit } = useApp();
    const [cursorIndex, setCursorIndex] = useState(0);
    const [selectedIds, setSelectedIds] = useState(new Set());
    const [filterActive, setFilterActive] = useState(false);
    const [query, setQuery] = useState('');
    const [confirmExit, setConfirmExit] = useState(false);
    const filteredItems = useMemo(() => filterBacklogItems(items, query), [items, query]);
    const current = filteredItems[clampBacklogCursor(cursorIndex, filteredItems.length)] ?? null;
    useEffect(() => {
        setCursorIndex((currentIndex) => clampFilteredCursor(currentIndex, filteredItems.length));
    }, [filteredItems.length]);
    useInput((input, key) => {
        if (confirmExit) {
            if (key.return || input.toLowerCase() === 'y') {
                onSubmit([]);
                exit();
                return;
            }
            if (key.escape || input.toLowerCase() === 'n') {
                setConfirmExit(false);
                return;
            }
        }
        if (filterActive) {
            if (key.escape || key.return) {
                setFilterActive(false);
                return;
            }
            if (key.backspace || key.delete) {
                setQuery((value) => value.slice(0, -1));
                return;
            }
            if (input && !key.ctrl && !key.meta) {
                setQuery((value) => `${value}${input}`);
            }
            return;
        }
        if (input === 'q') {
            onCancel();
            exit();
            return;
        }
        if (input === '/') {
            setFilterActive(true);
            setConfirmExit(false);
            return;
        }
        if (input === 'j' || key.downArrow) {
            setCursorIndex((value) => moveBacklogCursor(value, 'down', filteredItems.length));
            setConfirmExit(false);
            return;
        }
        if (input === 'k' || key.upArrow) {
            setCursorIndex((value) => moveBacklogCursor(value, 'up', filteredItems.length));
            setConfirmExit(false);
            return;
        }
        if (input === ' ' && current) {
            setSelectedIds((value) => toggleBacklogSelection(value, current.id));
            setConfirmExit(false);
            return;
        }
        if (key.return) {
            const selected = orderedSelectedIds(items, selectedIds);
            if (selected.length === 0) {
                setConfirmExit(true);
                return;
            }
            onSubmit(selected);
            exit();
        }
    });
    return (_jsxs(Box, { flexDirection: "column", children: [_jsx(FilterBar, { query: query, totalCount: items.length, filteredCount: filteredItems.length, active: filterActive }), _jsxs(Box, { marginTop: 1, children: [_jsx(Box, { width: "60%", flexDirection: "column", children: _jsx(BacklogList, { items: filteredItems, cursorIndex: cursorIndex, selectedIds: selectedIds, innerWidth: 72 }) }), _jsx(Box, { width: "40%", flexDirection: "column", borderStyle: "single", borderColor: tokens.border, children: _jsx(FeaturePreview, { item: current, innerWidth: 44 }) })] }), confirmExit ? (_jsx(Box, { marginTop: 1, children: _jsx(Text, { color: tokens.warning, children: "exit without picking?" }) })) : null] }));
}
function loadItems(path) {
    return JSON.parse(readFileSync(path, 'utf8'));
}
export function applyPickTestKeys(items, keys) {
    let cursor = 0;
    let selected = new Set();
    for (const key of keys.split(',').map((value) => value.trim()).filter(Boolean)) {
        if (key === 'j')
            cursor = moveBacklogCursor(cursor, 'down', items.length);
        if (key === 'k')
            cursor = moveBacklogCursor(cursor, 'up', items.length);
        if (key === 'space' && items[cursor])
            selected = toggleBacklogSelection(selected, items[cursor].id);
        if (key === 'q')
            return 130;
        if (key === 'enter') {
            if (selected.size > 0) {
                process.stdout.write(`${orderedSelectedIds(items, selected).join('\n')}\n`);
            }
            return 0;
        }
    }
    return 0;
}
const isPickCli = process.argv[1]?.endsWith('/pick.js') || process.argv[1]?.endsWith('\\pick.js');
const inputPath = process.argv[2];
if (isPickCli) {
    if (!inputPath) {
        process.stderr.write('Missing pick input JSON path\n');
        process.exit(2);
    }
    const items = loadItems(inputPath);
    if (process.env.MONOZUKURI_PICK_TEST_KEYS) {
        process.exit(applyPickTestKeys(items, process.env.MONOZUKURI_PICK_TEST_KEYS));
    }
    if (!process.stdin.isTTY) {
        process.stderr.write('Interactive pick requires a TTY. Use: monozukuri pick --json\n');
        process.exit(2);
    }
    render(_jsx(PickApp, { items: items, onSubmit: (ids) => {
            if (ids.length > 0)
                process.stdout.write(`${ids.join('\n')}\n`);
        }, onCancel: () => {
            process.exitCode = 130;
        } }), { stdout: process.stderr });
}
