'use strict';
// dag.js — Static workflow DAG rendered with Cytoscape.js.
// Nodes: PRD → TechSpec → Tasks → Code → Tests → PR
// Active node is highlighted based on phase.started events.
// Clicking a node emits a 'dag:phase-click' custom event on the container.

const PHASES = [
  { id: 'prd',      label: 'PRD' },
  { id: 'techspec', label: 'TechSpec' },
  { id: 'tasks',    label: 'Tasks' },
  { id: 'code',     label: 'Code' },
  { id: 'tests',    label: 'Tests' },
  { id: 'pr',       label: 'PR' },
];

const EDGES = PHASES.slice(1).map((p, i) => ({
  data: { id: `e-${PHASES[i].id}-${p.id}`, source: PHASES[i].id, target: p.id },
}));

class DAG {
  constructor(container) {
    this.container = container;
    this.cy = null;
    this._activeFeature = null;
    this._phaseStatus = {};   // phase → 'pending' | 'active' | 'done' | 'failed'
    PHASES.forEach(p => { this._phaseStatus[p.id] = 'pending'; });
    this._init();
  }

  _init() {
    if (!window.cytoscape) {
      this.container.innerHTML = '<p class="dag-unavailable">Cytoscape not loaded — add ui-web/vendor/cytoscape.min.js</p>';
      return;
    }
    this.cy = window.cytoscape({
      container: this.container,
      elements: [
        ...PHASES.map(p => ({ data: { id: p.id, label: p.label }, classes: 'phase-node pending' })),
        ...EDGES,
      ],
      style: [
        { selector: 'node.phase-node', style: {
          label: 'data(label)',
          'font-family': 'monospace',
          'font-size': 13,
          width: 80, height: 40,
          shape: 'roundrectangle',
          'background-color': '#1e293b',
          'border-color': '#475569',
          'border-width': 1,
          color: '#cbd5e1',
          'text-valign': 'center',
          'text-halign': 'center',
        }},
        { selector: 'node.active', style: {
          'background-color': '#3b82f6',
          'border-color': '#93c5fd',
          color: '#fff',
          'border-width': 2,
        }},
        { selector: 'node.done', style: {
          'background-color': '#064e3b',
          'border-color': '#10b981',
          color: '#6ee7b7',
        }},
        { selector: 'node.failed', style: {
          'background-color': '#7f1d1d',
          'border-color': '#ef4444',
          color: '#fca5a5',
        }},
        { selector: 'edge', style: {
          'line-color': '#334155',
          'target-arrow-color': '#334155',
          'target-arrow-shape': 'triangle',
          'curve-style': 'bezier',
          width: 1.5,
        }},
      ],
      layout: { name: 'grid', rows: 1 },
      userZoomingEnabled: false,
      userPanningEnabled: false,
      boxSelectionEnabled: false,
    });

    this.cy.on('tap', 'node', (evt) => {
      const phase = evt.target.id();
      this.container.dispatchEvent(new CustomEvent('dag:phase-click', { bubbles: true, detail: { phase } }));
    });
  }

  _applyStatus(phase, status) {
    if (!this.cy) return;
    const node = this.cy.$(`#${phase}`);
    node.removeClass('pending active done failed');
    node.addClass(status);
  }

  handle(ev) {
    if (ev.type === 'feature.started' && !this._activeFeature) {
      this._activeFeature = ev.feature_id;
      PHASES.forEach(p => { this._phaseStatus[p.id] = 'pending'; this._applyStatus(p.id, 'pending'); });
    }

    if (ev.type === 'phase.started') {
      this._phaseStatus[ev.phase] = 'active';
      this._applyStatus(ev.phase, 'active');
    }

    if (ev.type === 'phase.completed') {
      this._phaseStatus[ev.phase] = 'done';
      this._applyStatus(ev.phase, 'done');
    }

    if (ev.type === 'phase.failed') {
      this._phaseStatus[ev.phase] = 'failed';
      this._applyStatus(ev.phase, 'failed');
    }

    if (ev.type === 'feature.completed' || ev.type === 'feature.failed') {
      this._activeFeature = null;
    }
  }
}

window.DAG = DAG;
