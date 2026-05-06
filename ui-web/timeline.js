'use strict';
// timeline.js — Per-feature swim-lane timeline, driven by monozukuri SSE events.
// Each feature gets a horizontal lane. Phases render as colored bars.
// Tool/file events render as dots on the lane. Updates live via SSE.

const PHASE_COLORS = {
  prd:      '#6366f1',
  techspec: '#8b5cf6',
  tasks:    '#a855f7',
  code:     '#3b82f6',
  tests:    '#10b981',
  pr:       '#f59e0b',
};

const TOOL_COLORS = {
  Read:      '#64748b',
  Write:     '#22c55e',
  Edit:      '#f59e0b',
  MultiEdit: '#f97316',
  Bash:      '#ef4444',
  default:   '#94a3b8',
};

class Timeline {
  constructor(container) {
    this.container = container;
    this.features = {};   // feat_id → { lanes, phaseBar, dotCount }
    this.order = [];
    this._render();
  }

  _render() {
    this.container.innerHTML = `
      <div class="tl-header">
        <span class="tl-label">Feature</span>
        <span class="tl-bar-area">Execution timeline (→ time)</span>
      </div>
      <div id="tl-lanes"></div>
    `;
    this.lanesEl = document.getElementById('tl-lanes');
  }

  _ensureLane(featId) {
    if (this.features[featId]) return this.features[featId];
    const row = document.createElement('div');
    row.className = 'tl-row';
    row.innerHTML = `
      <div class="tl-feat-label" title="${featId}">${featId}</div>
      <div class="tl-track" id="track-${CSS.escape(featId)}"></div>
    `;
    this.lanesEl.appendChild(row);
    this.features[featId] = { track: row.querySelector('.tl-track'), phaseSegments: {}, startTime: Date.now() };
    this.order.push(featId);
    return this.features[featId];
  }

  handle(ev) {
    const lane = this._ensureLane(ev.feature_id);
    const elapsed = Date.now() - lane.startTime;

    if (ev.type === 'phase.started') {
      const seg = document.createElement('div');
      seg.className = 'tl-phase';
      seg.style.background = PHASE_COLORS[ev.phase] || '#6b7280';
      seg.style.left = `${Math.min(elapsed / 3600000 * 100, 95)}%`;
      seg.title = ev.phase;
      lane.track.appendChild(seg);
      lane.phaseSegments[ev.phase] = { el: seg, start: elapsed };
    }

    if (ev.type === 'phase.completed' || ev.type === 'phase.failed') {
      const s = lane.phaseSegments[ev.phase];
      if (s) {
        const width = Math.max((Date.now() - lane.startTime - s.start) / 3600000 * 100, 0.5);
        s.el.style.width = `${Math.min(width, 95 - parseFloat(s.el.style.left))}%`;
        s.el.classList.toggle('tl-phase-failed', ev.type === 'phase.failed');
      }
    }

    if (ev.type === 'tool.invoked') {
      const dot = document.createElement('span');
      dot.className = 'tl-dot';
      dot.style.left = `${Math.min(elapsed / 3600000 * 100, 98)}%`;
      dot.style.background = TOOL_COLORS[ev.tool] || TOOL_COLORS.default;
      dot.title = `${ev.tool}: ${ev.input_summary || ''}`;
      lane.track.appendChild(dot);
    }

    if (ev.type === 'file.touched') {
      const fp = document.createElement('span');
      fp.className = 'tl-file';
      fp.style.left = `${Math.min(elapsed / 3600000 * 100, 98)}%`;
      fp.style.background = ev.op === 'write' ? '#22c55e' : ev.op === 'edit' ? '#f59e0b' : '#64748b';
      fp.title = `${ev.op}: ${ev.path}`;
      lane.track.appendChild(fp);
    }

    if (ev.type === 'feature.completed' || ev.type === 'feature.failed') {
      const lane_ = this.features[ev.feature_id];
      if (lane_) {
        lane_.track.parentElement.classList.toggle('tl-row-done', ev.type === 'feature.completed');
        lane_.track.parentElement.classList.toggle('tl-row-failed', ev.type === 'feature.failed');
      }
    }
  }
}

window.Timeline = Timeline;
