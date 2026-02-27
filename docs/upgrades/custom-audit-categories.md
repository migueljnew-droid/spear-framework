# Upgrade: Custom Audit Categories

SPEAR ships with six audit categories: Security, Dependencies, Performance, Code Quality, Documentation, and Architecture. For domain-specific needs, you can add custom categories.

---

## When to Add Custom Categories

Add a custom category when:
- Your domain has quality dimensions the defaults don't cover
- Regulatory requirements mandate specific checks
- Your team wants to track a metric that doesn't fit existing categories

Examples:
- **Accessibility** (a11y) — WCAG compliance for web applications
- **Data Privacy** — GDPR/CCPA compliance checks
- **API Compatibility** — Breaking change detection for public APIs
- **Localization** — Translation coverage and formatting
- **Cost** — Cloud resource cost estimation for infrastructure changes

---

## Creating a Custom Category

### Step 1: Define the Category

```bash
spear audit add-category --name accessibility
```

This creates a category definition:

```yaml
# .spear/audit-categories/accessibility.yaml
id: accessibility
name: Accessibility
description: WCAG 2.1 AA compliance checks for web interfaces
weight: 1.0
enabled: true
checks:
  - id: a11y-axe-scan
    name: Axe accessibility scan
    severity_map:
      critical: CRITICAL
      serious: HIGH
      moderate: MEDIUM
      minor: LOW
    command: "npx axe-cli http://localhost:3000 --exit --json"
    parser: axe-json
  - id: a11y-color-contrast
    name: Color contrast ratios
    command: "node scripts/audit/check-contrast.js"
    severity: MEDIUM
  - id: a11y-keyboard-nav
    name: Keyboard navigation
    command: "npx playwright test tests/a11y/keyboard.spec.js"
    severity: HIGH
```

### Step 2: Configure the Checks

Each check needs:
- `id`: Unique identifier for findings
- `name`: Human-readable description
- `command`: What to run
- `severity` or `severity_map`: How to classify findings
- `parser` (optional): Output format parser (json, junit, custom)

### Step 3: Add to Config

```json
{
  "audit": {
    "categories": [
      "security",
      "dependencies",
      "performance",
      "code_quality",
      "documentation",
      "architecture",
      "accessibility"
    ]
  }
}
```

### Step 4: Set Initial Floor

```bash
spear ratchet set-floor --category accessibility --value 0
```

The ratchet will auto-tighten from here as audits run.

---

## Custom Check Parsers

### Built-In Parsers

| Parser | Format | Tools |
|--------|--------|-------|
| `exit-code` | Exit 0 = pass, non-zero = fail | Any CLI tool |
| `json-findings` | JSON array of findings | Custom scripts |
| `junit` | JUnit XML | Jest, pytest, etc. |
| `axe-json` | Axe accessibility JSON | axe-cli |
| `eslint-json` | ESLint JSON format | ESLint |
| `sarif` | SARIF format | CodeQL, Semgrep |

### Custom Parser

For non-standard output formats, write a parser:

```javascript
// .spear/parsers/my-tool-parser.js
module.exports = {
  parse(stdout, stderr, exitCode) {
    const findings = [];
    const lines = stdout.split('\n');

    for (const line of lines) {
      const match = line.match(/^(ERROR|WARN|INFO): (.+) at (.+):(\d+)$/);
      if (match) {
        findings.push({
          severity: match[1] === 'ERROR' ? 'HIGH' : match[1] === 'WARN' ? 'MEDIUM' : 'LOW',
          message: match[2],
          file: match[3],
          line: parseInt(match[4]),
        });
      }
    }

    return {
      score: Math.max(0, 100 - findings.length * 5),
      findings,
    };
  }
};
```

Register it:

```yaml
checks:
  - id: my-custom-check
    command: "my-tool scan src/"
    parser: custom
    parser_path: ".spear/parsers/my-tool-parser.js"
```

---

## Scoring Custom Categories

Each category produces a score from 0-100. The scoring method can be:

### Deduction-Based (Default)

Start at 100, deduct per finding:

```yaml
scoring:
  method: deduction
  deductions:
    CRITICAL: 25
    HIGH: 10
    MEDIUM: 3
    LOW: 1
  minimum: 0
```

### Percentage-Based

Score is the percentage of checks that pass:

```yaml
scoring:
  method: percentage
  # 8 out of 10 checks pass = 80
```

### Custom Script

For complex scoring logic:

```yaml
scoring:
  method: custom
  command: "node scripts/audit/score-accessibility.js"
  # Script outputs JSON: { "score": 85, "details": "..." }
```

---

## Example: Data Privacy Category

```yaml
# .spear/audit-categories/data-privacy.yaml
id: data_privacy
name: Data Privacy
description: GDPR and CCPA compliance checks
weight: 1.5  # Weighted higher for regulated industries
enabled: true

scoring:
  method: deduction
  deductions:
    CRITICAL: 30
    HIGH: 15
    MEDIUM: 5
    LOW: 1

checks:
  - id: dp-pii-detection
    name: PII in logs or debug output
    command: "node scripts/audit/check-pii-leaks.js"
    severity: CRITICAL
    description: "Scan for email, SSN, phone patterns in log statements"

  - id: dp-consent-tracking
    name: Data processing consent
    command: "grep -r 'userData\\|personalData' src/ | grep -v 'consent' | wc -l"
    severity: HIGH
    description: "Personal data access without consent check"

  - id: dp-retention-policy
    name: Data retention limits
    command: "node scripts/audit/check-retention.js"
    severity: HIGH
    description: "Data stored without expiry or cleanup policy"

  - id: dp-right-to-delete
    name: Deletion capability
    command: "grep -r 'deleteUser\\|removeUser\\|purgeUser' src/ | wc -l | awk '{if ($1 == 0) exit 1}'"
    severity: MEDIUM
    description: "User data deletion endpoint must exist"

  - id: dp-encryption-at-rest
    name: Sensitive data encryption
    command: "node scripts/audit/check-encryption.js"
    severity: CRITICAL
    description: "PII must be encrypted at rest"
```

---

## Category Interactions

Custom categories participate fully in the SPEAR cycle:
- Audit runs them in parallel with built-in categories
- Ratchet tracks their floors independently
- Findings from custom categories generate rules like any other
- Retrospectives include custom category trends

```bash
spear ratchet status
```

```
Category          Floor    Ceiling    Status
security          95       100        Improving
dependencies      98       100        Improving
performance       90       95         Improving
code_quality      88       95         Improving
documentation     85       95         Needs focus
architecture      92       98         Improving
accessibility     72       90         NEW — Needs focus
data_privacy      80       95         NEW — Improving
```

---

## Disabling Categories

For projects where a category doesn't apply:

```bash
spear audit disable-category --name accessibility
# => Accessibility category disabled. Will not run in audits.
# => Ratchet floor preserved (re-enable to enforce).
```

Disabled categories don't affect the audit pass/fail result but their floors are preserved if re-enabled later.
