const PHASES = ['prd', 'techspec', 'tasks', 'code', 'tests', 'pr'];
const RECENT_EVENT_CAP = 8;
const LOG_CAP = 200;
function makeDefaultPhases() {
    return {
        prd: 'pending',
        techspec: 'pending',
        tasks: 'pending',
        code: 'pending',
        tests: 'pending',
        pr: 'pending',
    };
}
function makeDefaultFeature(id, title) {
    return {
        id,
        title,
        status: 'queued',
        phases: makeDefaultPhases(),
    };
}
function appendLog(log, entry) {
    const next = [...log, entry];
    return next.length > LOG_CAP ? next.slice(next.length - LOG_CAP) : next;
}
export function initialState() {
    const budget = Number(process.env['MONOZUKURI_BUDGET'] ?? '40') || 40;
    return {
        runId: null,
        autonomy: '',
        model: '',
        agent: '',
        source: '',
        featureCount: 0,
        budget,
        features: {},
        order: [],
        current: null,
        totals: { succeeded: 0, failed: 0, skipped: 0, costUsd: 0 },
        log: [],
        spinner: '',
        setupMode: false,
        setupAgents: {},
        setupSkills: [],
    };
}
export function reducer(state, event) {
    switch (event.type) {
        case 'run.started': {
            return {
                ...state,
                runId: event.run_id,
                autonomy: event.autonomy ?? '',
                model: event.model ?? '',
                agent: event.agent ?? '',
                source: event.source ?? '',
                featureCount: event.feature_count ?? 0,
            };
        }
        case 'backlog.loaded': {
            const features = { ...state.features };
            const order = [...state.order];
            for (const f of event.features ?? []) {
                if (!features[f.id]) {
                    features[f.id] = makeDefaultFeature(f.id, f.title);
                    order.push(f.id);
                }
            }
            return { ...state, features, order };
        }
        case 'feature.queued': {
            const { feature_id } = event;
            const features = { ...state.features };
            if (!features[feature_id]) {
                features[feature_id] = makeDefaultFeature(feature_id, feature_id);
            }
            const order = state.order.includes(feature_id)
                ? state.order
                : [...state.order, feature_id];
            return { ...state, features, order };
        }
        case 'feature.started': {
            const { feature_id } = event;
            const prev = state.features[feature_id] ?? makeDefaultFeature(feature_id, feature_id);
            const features = {
                ...state.features,
                [feature_id]: {
                    ...prev,
                    status: 'active',
                    startedAt: event.ts,
                },
            };
            return { ...state, features, current: feature_id };
        }
        case 'feature.skipped': {
            const { feature_id, reason } = event;
            const prev = state.features[feature_id] ?? makeDefaultFeature(feature_id, feature_id);
            const features = {
                ...state.features,
                [feature_id]: {
                    ...prev,
                    status: 'skipped',
                    error: reason,
                },
            };
            const totals = {
                ...state.totals,
                skipped: state.totals.skipped + 1,
            };
            return { ...state, features, totals };
        }
        case 'phase.started': {
            const { feature_id, phase } = event;
            const prev = state.features[feature_id] ?? makeDefaultFeature(feature_id, feature_id);
            // Mark earlier phases as done if they are still pending
            const phases = { ...prev.phases };
            for (const p of PHASES) {
                if (p === phase) {
                    phases[p] = 'in_progress';
                    break;
                }
                if (phases[p] === 'pending') {
                    phases[p] = 'done';
                }
            }
            const features = {
                ...state.features,
                [feature_id]: {
                    ...prev,
                    phases,
                    currentPhase: phase,
                    currentSkill: undefined,
                    currentTier: undefined,
                },
            };
            return {
                ...state,
                features,
                spinner: `${phase}: starting...`,
            };
        }
        case 'phase.progress': {
            const { feature_id, phase, tokens_used } = event;
            const prev = state.features[feature_id] ?? makeDefaultFeature(feature_id, feature_id);
            const phases = { ...prev.phases, [phase]: 'in_progress' };
            const features = {
                ...state.features,
                [feature_id]: {
                    ...prev,
                    phases,
                    tokens: tokens_used,
                    currentPhase: phase,
                },
            };
            return {
                ...state,
                features,
                spinner: `${phase}: working...`,
            };
        }
        case 'phase.completed': {
            const { feature_id, phase, tokens_used, cost_usd, tokens_in, tokens_out, tokens_total, cache_creation_input_tokens, cache_read_input_tokens, } = event;
            const prev = state.features[feature_id] ?? makeDefaultFeature(feature_id, feature_id);
            const phases = { ...prev.phases, [phase]: 'done' };
            // Prefer the new fine-grained counters from stream-parse; fall back to
            // the legacy `tokens_used` aggregate when older producers emit only that.
            const resolvedTokens = tokens_total ?? tokens_used ?? prev.tokens;
            const features = {
                ...state.features,
                [feature_id]: {
                    ...prev,
                    phases,
                    tokens: resolvedTokens,
                    tokensIn: tokens_in ?? prev.tokensIn,
                    tokensOut: tokens_out ?? prev.tokensOut,
                    tokensTotal: tokens_total ?? prev.tokensTotal,
                    cacheCreationTokens: cache_creation_input_tokens ?? prev.cacheCreationTokens,
                    cacheReadTokens: cache_read_input_tokens ?? prev.cacheReadTokens,
                    costUsd: (prev.costUsd ?? 0) + (cost_usd ?? 0),
                    // Phase ended — clear the live rate so the UI stops showing it.
                    tokenRate: undefined,
                    tokensSampledAt: undefined,
                },
            };
            return { ...state, features };
        }
        case 'phase.token_update': {
            const { feature_id, tokens_out, tokens_in } = event;
            const prev = state.features[feature_id] ?? makeDefaultFeature(feature_id, feature_id);
            const now = Date.now();
            // Compute tokens-per-minute by diffing against the previous sample.
            // Only meaningful when we have a prior sample within a 60s window.
            let tokenRate = prev.tokenRate;
            if (typeof prev.tokensOut === 'number' &&
                typeof prev.tokensSampledAt === 'number') {
                const dtMs = now - prev.tokensSampledAt;
                const dTokens = tokens_out - prev.tokensOut;
                if (dtMs > 0 && dtMs < 60_000 && dTokens > 0) {
                    tokenRate = (dTokens / dtMs) * 60_000;
                }
            }
            const features = {
                ...state.features,
                [feature_id]: {
                    ...prev,
                    tokensOut: tokens_out,
                    tokensIn: tokens_in ?? prev.tokensIn,
                    tokensSampledAt: now,
                    tokenRate,
                },
            };
            return { ...state, features };
        }
        case 'phase.failed': {
            const { feature_id, phase, error } = event;
            const prev = state.features[feature_id] ?? makeDefaultFeature(feature_id, feature_id);
            const phases = { ...prev.phases, [phase]: 'failed' };
            const features = {
                ...state.features,
                [feature_id]: {
                    ...prev,
                    phases,
                    error,
                },
            };
            return { ...state, features };
        }
        case 'feature.completed': {
            const { feature_id, pr_url, total_tokens, total_cost_usd } = event;
            const prev = state.features[feature_id] ?? makeDefaultFeature(feature_id, feature_id);
            // Mark all phases done
            const phases = Object.fromEntries(PHASES.map((p) => [p, 'done']));
            const features = {
                ...state.features,
                [feature_id]: {
                    ...prev,
                    status: 'done',
                    phases,
                    prUrl: pr_url,
                    tokens: total_tokens,
                    costUsd: total_cost_usd,
                },
            };
            const totals = {
                ...state.totals,
                succeeded: state.totals.succeeded + 1,
                costUsd: state.totals.costUsd + (total_cost_usd ?? 0),
            };
            const current = state.current === feature_id ? null : state.current;
            return { ...state, features, totals, current };
        }
        case 'feature.failed': {
            const { feature_id, error } = event;
            const prev = state.features[feature_id] ?? makeDefaultFeature(feature_id, feature_id);
            const features = {
                ...state.features,
                [feature_id]: {
                    ...prev,
                    status: 'failed',
                    error,
                },
            };
            const totals = {
                ...state.totals,
                failed: state.totals.failed + 1,
            };
            const current = state.current === feature_id ? null : state.current;
            return { ...state, features, totals, current };
        }
        case 'feature.deferred': {
            const { feature_id, reason } = event;
            const prev = state.features[feature_id] ?? makeDefaultFeature(feature_id, feature_id);
            const features = {
                ...state.features,
                [feature_id]: {
                    ...prev,
                    status: 'deferred',
                    error: reason,
                },
            };
            const current = state.current === feature_id ? null : state.current;
            return { ...state, features, current };
        }
        case 'learning.captured': {
            // No state change needed; could extend to show learning count
            return state;
        }
        case 'tool.invoked': {
            const { feature_id, tool, input_summary } = event;
            if (!feature_id)
                return state;
            const prev = state.features[feature_id];
            if (!prev)
                return state;
            const next = {
                ts: Date.now(),
                tool: tool ?? '',
                target: input_summary ?? undefined,
            };
            const recent = [...(prev.recentEvents ?? []), next].slice(-RECENT_EVENT_CAP);
            return {
                ...state,
                features: { ...state.features, [feature_id]: { ...prev, recentEvents: recent } },
            };
        }
        case 'file.touched': {
            const { feature_id, path, op } = event;
            if (!feature_id)
                return state;
            const prev = state.features[feature_id];
            if (!prev)
                return state;
            const next = {
                ts: Date.now(),
                tool: op ? op.charAt(0).toUpperCase() + op.slice(1) : 'File',
                target: path ?? undefined,
            };
            const recent = [...(prev.recentEvents ?? []), next].slice(-RECENT_EVENT_CAP);
            return {
                ...state,
                features: { ...state.features, [feature_id]: { ...prev, recentEvents: recent } },
            };
        }
        case 'tool.completed':
            // We synthesise completion at invocation time; the upstream signal is
            // currently redundant. Keep the case to satisfy exhaustiveness.
            return state;
        case 'log.line': {
            const { feature_id, stream, text, ts } = event;
            const entry = {
                ts,
                featureId: feature_id ?? '',
                phase: stream ?? '',
                text: text ?? '',
            };
            const log = appendLog(state.log, entry);
            return { ...state, log, spinner: text ?? state.spinner };
        }
        case 'run.completed': {
            const totals = {
                succeeded: event.succeeded ?? state.totals.succeeded,
                failed: event.failed ?? state.totals.failed,
                skipped: event.skipped ?? state.totals.skipped,
                costUsd: event.total_cost_usd ?? state.totals.costUsd,
            };
            return { ...state, totals, current: null };
        }
        case 'skill.invoked': {
            const { feature_id, phase, tier, skill } = event;
            const prev = state.features[feature_id] ?? makeDefaultFeature(feature_id, feature_id);
            return {
                ...state,
                features: {
                    ...state.features,
                    [feature_id]: { ...prev, currentSkill: skill, currentTier: tier },
                },
                spinner: `${phase}: ${skill} (tier ${tier})`,
            };
        }
        case 'skill.completed':
        case 'skill.failed': {
            // Leave currentSkill/currentTier populated for display continuity
            return state;
        }
        case 'memory.bootstrap': {
            const { feature_id, memory_dir, compaction } = event;
            const prev = state.features[feature_id] ?? makeDefaultFeature(feature_id, feature_id);
            return {
                ...state,
                features: {
                    ...state.features,
                    [feature_id]: { ...prev, memoryDir: memory_dir, compaction },
                },
            };
        }
        case 'memory.note': {
            return state; // informational; no state change needed
        }
        case 'setup.started': {
            return { ...state, setupMode: true };
        }
        case 'setup.agent_progress': {
            return {
                ...state,
                setupAgents: { ...state.setupAgents, [event.agent]: event.status },
            };
        }
        case 'setup.skill_installed': {
            return {
                ...state,
                setupSkills: [...state.setupSkills, { agent: event.agent, skill: event.skill, status: event.status }],
            };
        }
        case 'setup.completed': {
            return state; // just keep the accumulated state visible
        }
        case 'cycle_gate.skipped': {
            const { feature_id } = event;
            const prev = state.features[feature_id] ?? makeDefaultFeature(feature_id, feature_id);
            return {
                ...state,
                features: {
                    ...state.features,
                    [feature_id]: {
                        ...prev,
                        status: 'skipped',
                        error: prev.error ?? 'cycle-gate: skipped this run',
                    },
                },
            };
        }
        case 'cycle_gate.passed':
            return state;
        case 'feature.pr_failed': {
            const { feature_id, reason } = event;
            const prev = state.features[feature_id] ?? makeDefaultFeature(feature_id, feature_id);
            return {
                ...state,
                features: {
                    ...state.features,
                    [feature_id]: {
                        ...prev,
                        status: 'pr_failed',
                        error: reason,
                    },
                },
            };
        }
        default:
            return state;
    }
}
