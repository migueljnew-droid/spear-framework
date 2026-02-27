# Upgrade: Metrics Dashboard

SPEAR tracks quality data across every audit cycle. The metrics dashboard makes this data visible as trends, comparisons, and actionable insights.

---

## Built-In CLI Dashboard

No setup required. View metrics from the command line:

```bash
spear metrics
```

```
SPEAR Quality Dashboard — my-project
Period: Last 30 days (8 audit cycles)

Score Trends (sparkline):
  architecture:    [][][][][][][][] 72 -> 94 (+22)
  code_quality:    [][][][][][][][] 65 -> 91 (+26)
  security:        [][][][][][][][] 80 -> 95 (+15)
  performance:     [][][][][][][][] 70 -> 90 (+20)
  testing:         [][][][][][][][] 60 -> 85 (+25)
  spec_compliance: [][][][][][][][] 90 -> 100 (+10)

Ratchet History:
  Total tightenings: 42
  Average improvement per cycle: +3.2 points
  Categories at ceiling: 1 (spec_compliance)
  Largest gap to ceiling: testing (10 points)

Findings Trend:
  CRITICAL:  3 -> 0 (resolved)
  HIGH:      12 -> 2 (83% reduction)
  MEDIUM:    24 -> 8 (67% reduction)
  LOW:       15 -> 11 (27% reduction)

Top Recurring Issues:
  1. Missing JSDoc on public functions (5 occurrences) — Rule generated
  2. N+1 query patterns (3 occurrences) — Rule pending
  3. Insufficient error boundary tests (3 occurrences)
```

### Time Ranges

```bash
spear metrics --period 7d       # Last 7 days
spear metrics --period 30d      # Last 30 days (default)
spear metrics --period 90d      # Last 90 days
spear metrics --period all      # All time
spear metrics --from 2026-01-01 --to 2026-02-26  # Custom range
```

### Category Detail

```bash
spear metrics --category security
```

```
Security Audit Detail — Last 30 days

Score History:
  Cycle 1: 80  Cycle 2: 85  Cycle 3: 88  Cycle 4: 90
  Cycle 5: 92  Cycle 6: 93  Cycle 7: 95  Cycle 8: 95

Floor History:
  80 -> 85 -> 88 -> 90 -> 92 -> 93 -> 95 -> 95

Findings by Type:
  SQL Injection:           2 -> 0 (resolved cycle 3)
  Missing input validation: 3 -> 1 (improving)
  Hardcoded secrets:       1 -> 0 (resolved cycle 2)
  Dependency vulnerabilities: 2 -> 1 (improving)

Active Rules:
  SEC-R001: No secrets in source (gitleaks) — since cycle 2
  SEC-R002: All inputs validated (custom) — since cycle 4
  SEC-R003: Dependencies audited weekly — since cycle 5

Overrides:
  1 active override: PERF regression accepted for GraphQL migration
```

---

## HTML Dashboard

Generate a static HTML dashboard for sharing:

```bash
spear metrics dashboard --output ./metrics-report/
# => Generated: metrics-report/index.html
# => Open in browser: file:///path/to/metrics-report/index.html
```

The HTML dashboard includes:
- Interactive charts (score trends over time)
- Category comparison radar chart
- Findings heatmap (severity x category x time)
- Ratchet progression timeline
- Team member contribution stats (if team workflows are enabled)

### Hosting

Serve it from your project:

```bash
# Static file server
npx serve ./metrics-report

# Or add to your documentation site
cp -r metrics-report/ docs/quality/
```

### Auto-Regenerate in CI

```yaml
- name: Generate metrics dashboard
  run: spear metrics dashboard --output ./metrics-report/

- name: Deploy to GitHub Pages
  uses: peaceiris/actions-gh-pages@v3
  with:
    github_token: ${{ secrets.GITHUB_TOKEN }}
    publish_dir: ./metrics-report
```

---

## JSON Export

Export raw metrics data for custom dashboards:

```bash
spear metrics export --format json > metrics.json
```

```json
{
  "project": "my-project",
  "generated": "2026-02-26T14:30:00Z",
  "period": {
    "from": "2026-01-27",
    "to": "2026-02-26"
  },
  "cycles": [
    {
      "plan": "plan-001",
      "spec": "spec-001",
      "date": "2026-02-01",
      "scores": {
        "architecture": 72,
        "code_quality": 65,
        "security": 80,
        "performance": 70,
        "testing": 60,
        "spec_compliance": 90
      },
      "findings": {
        "critical": 1,
        "high": 5,
        "medium": 12,
        "low": 8
      },
      "ratchet_changes": {
        "architecture": { "from": 0, "to": 72 }
      }
    }
  ],
  "current_floors": {
    "architecture": 94,
    "code_quality": 91,
    "security": 95,
    "performance": 90,
    "testing": 85,
    "spec_compliance": 100
  }
}
```

### CSV Export

For spreadsheet analysis:

```bash
spear metrics export --format csv > metrics.csv
```

```csv
date,plan,architecture,code_quality,security,performance,testing,spec_compliance,critical,high,medium,low
2026-02-01,plan-001,72,65,80,70,60,90,1,5,12,8
2026-02-05,plan-002,78,72,85,75,68,95,0,3,8,6
2026-02-10,plan-003,85,80,88,82,75,100,0,2,5,4
```

---

## Integration with External Tools

### Grafana

Push metrics to Prometheus/InfluxDB for Grafana dashboards:

```json
{
  "metrics": {
    "push": {
      "type": "prometheus",
      "endpoint": "http://prometheus:9091/metrics/job/spear",
      "interval": "on_audit"
    }
  }
}
```

Metrics exposed:
- `spear_audit_score{category="security"}` — Gauge
- `spear_ratchet_floor{category="security"}` — Gauge
- `spear_findings_count{severity="critical"}` — Counter
- `spear_cycle_duration_seconds` — Histogram

### Datadog

```json
{
  "metrics": {
    "push": {
      "type": "datadog",
      "api_key_env": "DD_API_KEY",
      "tags": ["project:my-project", "team:backend"]
    }
  }
}
```

### Custom Webhook

Send metrics to any endpoint:

```json
{
  "metrics": {
    "push": {
      "type": "webhook",
      "url": "https://your-dashboard.example.com/api/metrics",
      "headers": {
        "Authorization": "Bearer ${DASHBOARD_TOKEN}"
      }
    }
  }
}
```

---

## Team Metrics

When team workflows are enabled, track per-person metrics:

```bash
spear metrics --team
```

```
Team Quality Metrics — Last 30 days

Member        Specs  Plans  Phases  Audits  Avg Score  Trend
@sarah        3      0      0       4       -          (auditor)
@mike         0      3      0       0       -          (planner)
@alex         0      0      5       0       91.2       +3.4/cycle
@jordan       0      0      4       0       88.5       +4.1/cycle
@kim          0      0      3       0       90.0       +2.8/cycle

Phase Completion Rate:
  @alex:    5/5 (100%) — 0 deviations
  @jordan:  4/4 (100%) — 2 deviations
  @kim:     3/3 (100%) — 1 deviation
```

---

## Alerting

Set up alerts for quality regression:

```json
{
  "metrics": {
    "alerts": [
      {
        "condition": "score < floor",
        "category": "any",
        "action": "webhook",
        "url": "https://hooks.slack.com/services/..."
      },
      {
        "condition": "critical_findings > 0",
        "action": "webhook",
        "url": "https://hooks.slack.com/services/..."
      },
      {
        "condition": "score_delta < -5",
        "category": "any",
        "action": "webhook",
        "url": "https://hooks.slack.com/services/...",
        "message": "Quality dropped by more than 5 points"
      }
    ]
  }
}
```

Alerts fire after each audit completes. They don't block the pipeline — they notify.
