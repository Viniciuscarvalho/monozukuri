<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Monozukuri Run Review</title>
  <style>
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }

    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
      max-width: 1400px;
      margin: 0 auto;
      padding: 20px;
      background: #f5f5f5;
      color: #333;
      line-height: 1.6;
    }

    header {
      background: #fff;
      padding: 30px;
      border-radius: 8px;
      box-shadow: 0 2px 4px rgba(0,0,0,0.1);
      margin-bottom: 30px;
    }

    h1 {
      font-size: 32px;
      margin-bottom: 10px;
      color: #1a1a1a;
    }

    h2 {
      font-size: 24px;
      margin: 20px 0 15px 0;
      color: #2c3e50;
    }

    .run-id {
      font-family: 'Monaco', 'Menlo', 'Courier New', monospace;
      color: #666;
      font-size: 14px;
    }

    .summary {
      background: #fff;
      padding: 30px;
      border-radius: 8px;
      box-shadow: 0 2px 4px rgba(0,0,0,0.1);
      margin-bottom: 30px;
    }

    .metrics {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      gap: 20px;
      margin-top: 20px;
    }

    .metric {
      background: #f9f9f9;
      padding: 20px;
      border-radius: 6px;
      border-left: 4px solid #3498db;
    }

    .metric-label {
      font-size: 12px;
      text-transform: uppercase;
      color: #7f8c8d;
      letter-spacing: 0.5px;
      margin-bottom: 5px;
    }

    .metric-value {
      font-size: 28px;
      font-weight: 600;
      color: #2c3e50;
    }

    .metric-unit {
      font-size: 14px;
      color: #95a5a6;
      margin-left: 4px;
    }

    .headline {
      font-size: 48px;
      color: #27ae60;
    }

    .headline.warn {
      color: #e67e22;
    }

    .headline.error {
      color: #e74c3c;
    }

    .features-section {
      background: #fff;
      padding: 30px;
      border-radius: 8px;
      box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }

    .table-container {
      overflow-x: auto;
      margin-top: 20px;
    }

    table {
      width: 100%;
      border-collapse: collapse;
      font-size: 14px;
    }

    thead {
      background: #34495e;
      color: #fff;
    }

    th {
      padding: 12px 15px;
      text-align: left;
      font-weight: 600;
      text-transform: uppercase;
      font-size: 11px;
      letter-spacing: 0.5px;
    }

    td {
      padding: 12px 15px;
      border-bottom: 1px solid #ecf0f1;
    }

    tbody tr:hover {
      background: #f8f9fa;
    }

    .status {
      display: inline-block;
      padding: 4px 12px;
      border-radius: 12px;
      font-size: 12px;
      font-weight: 600;
      text-transform: uppercase;
    }

    .status-done,
    .status-pr-created {
      background: #d4edda;
      color: #155724;
    }

    .status-failed {
      background: #f8d7da;
      color: #721c24;
    }

    .status-in-progress {
      background: #fff3cd;
      color: #856404;
    }

    .status-paused {
      background: #d1ecf1;
      color: #0c5460;
    }

    .feature-id {
      font-family: 'Monaco', 'Menlo', 'Courier New', monospace;
      font-size: 13px;
      color: #555;
    }

    .pr-link {
      color: #3498db;
      text-decoration: none;
      font-weight: 500;
    }

    .pr-link:hover {
      text-decoration: underline;
    }

    .cost-cell {
      font-family: 'Monaco', 'Menlo', 'Courier New', monospace;
      color: #27ae60;
    }

    .tokens-cell {
      font-family: 'Monaco', 'Menlo', 'Courier New', monospace;
      color: #7f8c8d;
      font-size: 12px;
    }

    .no-data {
      color: #95a5a6;
      font-style: italic;
    }

    footer {
      margin-top: 40px;
      padding: 20px;
      text-align: center;
      color: #7f8c8d;
      font-size: 12px;
    }

    @media (max-width: 768px) {
      body {
        padding: 10px;
      }

      header, .summary, .features-section {
        padding: 20px;
      }

      h1 {
        font-size: 24px;
      }

      .metrics {
        grid-template-columns: 1fr;
      }

      table {
        font-size: 12px;
      }

      th, td {
        padding: 8px 10px;
      }
    }
  </style>
</head>
<body>
  <header>
    <h1>Monozukuri Run Review</h1>
    <div class="run-id" id="run-id"></div>
  </header>

  <section class="summary">
    <h2>Summary</h2>
    <div class="metrics" id="metrics"></div>
  </section>

  <section class="features-section">
    <h2>Features</h2>
    <div class="table-container">
      <table id="features-table">
        <thead>
          <tr>
            <th>Feature ID</th>
            <th>Title</th>
            <th>Stack</th>
            <th>Status</th>
            <th>PR</th>
            <th>Tokens</th>
            <th>Cost</th>
            <th>Phases</th>
          </tr>
        </thead>
        <tbody id="features-body">
        </tbody>
      </table>
    </div>
  </section>

  <footer>
    <p>Generated by Monozukuri &mdash; Autonomous Feature Development Orchestrator</p>
  </footer>

  <script>
    // Data placeholders replaced by bundle.sh
    const REPORT = __REPORT_DATA__;

    // Render run ID
    function renderRunId() {
      document.getElementById('run-id').textContent = REPORT.run_id;
    }

    // Render summary metrics
    function renderSummary() {
      const container = document.getElementById('metrics');

      // Determine headline class
      let headlineClass = '';
      if (REPORT.headline_pct >= 80) headlineClass = '';
      else if (REPORT.headline_pct >= 50) headlineClass = 'warn';
      else headlineClass = 'error';

      const metrics = [
        {
          label: 'Headline',
          value: REPORT.headline_pct,
          unit: '%',
          className: 'headline ' + headlineClass
        },
        {
          label: 'Duration',
          value: formatDuration(REPORT.duration_seconds),
          unit: '',
          className: ''
        },
        {
          label: 'Features',
          value: REPORT.completed_features + ' / ' + REPORT.total_features,
          unit: '',
          className: ''
        },
        {
          label: 'Failed',
          value: REPORT.failed_features,
          unit: '',
          className: REPORT.failed_features > 0 ? 'error' : ''
        },
        {
          label: 'Total Tokens',
          value: formatNumber(REPORT.total_tokens),
          unit: '',
          className: ''
        },
        {
          label: 'Total Cost',
          value: '$' + REPORT.total_cost_usd.toFixed(2),
          unit: '',
          className: ''
        }
      ];

      container.innerHTML = metrics.map(m => `
        <div class="metric">
          <div class="metric-label">${m.label}</div>
          <div class="metric-value ${m.className}">${m.value}<span class="metric-unit">${m.unit}</span></div>
        </div>
      `).join('');
    }

    // Render features table
    function renderFeatures() {
      const tbody = document.getElementById('features-body');

      if (!REPORT.features || REPORT.features.length === 0) {
        tbody.innerHTML = '<tr><td colspan="8" class="no-data">No features in this run</td></tr>';
        return;
      }

      tbody.innerHTML = REPORT.features.map(f => `
        <tr>
          <td class="feature-id">${escapeHtml(f.id)}</td>
          <td>${escapeHtml(f.title || 'Untitled')}</td>
          <td>${escapeHtml(f.stack || '-')}</td>
          <td><span class="status status-${f.status}">${escapeHtml(f.status)}</span></td>
          <td>${f.pr_url ? '<a href="' + escapeHtml(f.pr_url) + '" class="pr-link" target="_blank">View PR</a>' : '<span class="no-data">-</span>'}</td>
          <td class="tokens-cell">${formatNumber(f.tokens || 0)}</td>
          <td class="cost-cell">$${(f.cost_usd || 0).toFixed(2)}</td>
          <td>${f.phases_completed || 0}${f.phase_retries > 0 ? ' (' + f.phase_retries + ' retries)' : ''}</td>
        </tr>
      `).join('');
    }

    // Utility: format duration
    function formatDuration(seconds) {
      if (seconds < 60) return seconds + 's';
      const minutes = Math.floor(seconds / 60);
      const secs = seconds % 60;
      if (minutes < 60) return minutes + 'm ' + secs + 's';
      const hours = Math.floor(minutes / 60);
      const mins = minutes % 60;
      return hours + 'h ' + mins + 'm';
    }

    // Utility: format number with thousands separator
    function formatNumber(num) {
      return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',');
    }

    // Utility: escape HTML
    function escapeHtml(text) {
      const div = document.createElement('div');
      div.textContent = text;
      return div.innerHTML;
    }

    // Initialize
    renderRunId();
    renderSummary();
    renderFeatures();
  </script>
</body>
</html>
