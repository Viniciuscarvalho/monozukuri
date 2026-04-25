import type {
  AppState,
  Feature,
  LogLine,
  MonozukuriEvent,
  Phase,
  PhaseStatus,
} from './types.js';

const PHASES: Phase[] = ['prd', 'techspec', 'tasks', 'code', 'tests', 'pr'];
const LOG_CAP = 200;

function makeDefaultPhases(): Record<Phase, PhaseStatus> {
  return {
    prd: 'pending',
    techspec: 'pending',
    tasks: 'pending',
    code: 'pending',
    tests: 'pending',
    pr: 'pending',
  };
}

function makeDefaultFeature(id: string, title: string): Feature {
  return {
    id,
    title,
    status: 'queued',
    phases: makeDefaultPhases(),
  };
}

function appendLog(log: LogLine[], entry: LogLine): LogLine[] {
  const next = [...log, entry];
  return next.length > LOG_CAP ? next.slice(next.length - LOG_CAP) : next;
}

export function initialState(): AppState {
  const budget = Number(process.env['MONOZUKURI_BUDGET'] ?? '40') || 40;
  return {
    runId: null,
    autonomy: '',
    model: '',
    source: '',
    featureCount: 0,
    budget,
    features: {},
    order: [],
    current: null,
    totals: { succeeded: 0, failed: 0, skipped: 0, costUsd: 0 },
    log: [],
    spinner: '',
  };
}

export function reducer(state: AppState, event: MonozukuriEvent): AppState {
  switch (event.type) {
    case 'run.started': {
      return {
        ...state,
        runId: event.run_id,
        autonomy: event.autonomy ?? '',
        model: event.model ?? '',
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
          status: 'active' as const,
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
          status: 'skipped' as const,
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
      const phases = { ...prev.phases, [phase]: 'in_progress' as PhaseStatus };
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
      const { feature_id, phase, tokens_used, cost_usd } = event;
      const prev = state.features[feature_id] ?? makeDefaultFeature(feature_id, feature_id);
      const phases = { ...prev.phases, [phase]: 'done' as PhaseStatus };
      const features = {
        ...state.features,
        [feature_id]: {
          ...prev,
          phases,
          tokens: tokens_used,
          costUsd: (prev.costUsd ?? 0) + (cost_usd ?? 0),
        },
      };
      return { ...state, features };
    }

    case 'phase.failed': {
      const { feature_id, phase, error } = event;
      const prev = state.features[feature_id] ?? makeDefaultFeature(feature_id, feature_id);
      const phases = { ...prev.phases, [phase]: 'failed' as PhaseStatus };
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
      const phases = Object.fromEntries(
        PHASES.map((p) => [p, 'done' as PhaseStatus])
      ) as Record<Phase, PhaseStatus>;
      const features = {
        ...state.features,
        [feature_id]: {
          ...prev,
          status: 'done' as const,
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
          status: 'failed' as const,
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

    case 'learning.captured': {
      // No state change needed; could extend to show learning count
      return state;
    }

    case 'log.line': {
      const { feature_id, stream, text, ts } = event;
      const entry: LogLine = {
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

    default:
      return state;
  }
}
