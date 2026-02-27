# Phase 5: Ratchet

The Ratchet phase is what makes SPEAR self-improving. After a successful audit, the ratchet automatically tightens quality floors so that future work must meet or exceed current standards. Quality only goes up.

---

## What Is the Ratchet?

A ratchet is a mechanism that allows movement in one direction only. In SPEAR, it applies to quality metrics:

- If your security audit scores 95, the new security floor is 95.
- If your test coverage reaches 88%, the new coverage floor is 88%.
- If your architecture score hits 92, the new architecture floor is 92.

The next feature you build must meet or exceed these floors. If it doesn't, the audit fails.

---

## Auto-Tightening Mechanics

### How Floors Update

When you run `spear ratchet`:

```bash
spear ratchet --plan plan-001
```

SPEAR compares the audit scores against current floors:

```
Ratchet Update — plan-001

Category          Current Floor    Audit Score    New Floor    Change
architecture      0                92             92           +92
code_quality      0                88             88           +88
security          0                95             95           +95
performance       0                90             90           +90
testing           0                85             85           +85
spec_compliance   0                100            100          +100

Floors updated. Committed to .spear/ratchet.json
```

On subsequent audits:

```
Category          Current Floor    Audit Score    New Floor    Change
architecture      92               94             94           +2
code_quality      88               91             91           +3
security          95               95             95           (unchanged)
performance       90               88             90           FAIL — below floor
```

The performance score of 88 is below the floor of 90. This audit **fails** even though there are no CRITICAL findings. The ratchet enforces that you don't regress.

### The Tightening Formula

```
new_floor = max(current_floor, audit_score)
```

That's it. Simple and predictable. The floor never decreases automatically.

### Incremental Tightening (Optional)

For teams that want gentler progression, enable incremental mode:

```json
{
  "ratchet": {
    "mode": "incremental",
    "increment": 2
  }
}
```

In incremental mode:

```
new_floor = min(current_floor + increment, audit_score)
```

If the floor is 85 and you score 92, the new floor is 87 (not 92). Next cycle, if you score 92 again, the floor becomes 89. This prevents a single exceptional audit from setting an unreachably high bar.

---

## Floor vs Ceiling Thresholds

### Floors (Enforced)

Floors are minimums. Dropping below a floor fails the audit.

```json
{
  "floors": {
    "architecture": 92,
    "code_quality": 88,
    "security": 95,
    "performance": 90,
    "testing": 85,
    "spec_compliance": 100
  }
}
```

### Ceilings (Aspirational)

Ceilings are targets. They don't fail audits but they drive improvements.

```json
{
  "ceilings": {
    "architecture": 98,
    "code_quality": 95,
    "security": 100,
    "performance": 95,
    "testing": 95,
    "spec_compliance": 100
  }
}
```

When a floor meets or exceeds its ceiling, the category is considered "mastered":

```bash
spear ratchet status
```

```
Category          Floor    Ceiling    Gap    Status
architecture      92       98         6      Improving
code_quality      91       95         4      Improving
security          100      100        0      MASTERED
performance       90       95         5      Improving
testing           85       95         10     Needs focus
spec_compliance   100      100        0      MASTERED
```

---

## Rule Generation from Findings

The ratchet phase doesn't just update numbers — it generates rules from recurring audit findings.

### How Rules Are Generated

After three audits, SPEAR analyzes patterns:

```bash
spear ratchet --plan plan-003
```

```
Pattern detected: JSDoc missing on public functions
  Found in: plan-001 audit (CQ-001), plan-002 audit (CQ-003), plan-003 audit (CQ-001)
  Frequency: 3/3 audits (100%)

Generating rule:
  Rule: All exported functions must have JSDoc with @param and @returns
  Category: code_quality
  Severity: HIGH
  Auto-check: eslint rule jsdoc/require-jsdoc

Add this rule to .spear/audit-rules/? [y/n]
```

Generated rules are stored in `.spear/audit-rules/`:

```yaml
# .spear/audit-rules/cq-jsdoc-required.yaml
id: cq-jsdoc-required
category: code_quality
severity: HIGH
description: All exported functions must have JSDoc with @param and @returns
auto_check: "npx eslint --rule 'jsdoc/require-jsdoc: error' {files}"
generated_from:
  - plan-001/CQ-001
  - plan-002/CQ-003
  - plan-003/CQ-001
created: 2026-02-26
```

These rules become part of future audits automatically.

### Manual Rule Addition

Add rules without waiting for pattern detection:

```bash
spear ratchet add-rule \
  --category security \
  --severity CRITICAL \
  --description "No secrets in source code" \
  --check "gitleaks detect --source ."
```

---

## Memory Updates and Retrospectives

### Automatic Memory Updates

After each ratchet, SPEAR updates the decision log:

```markdown
# .spear/memory/decisions/DEC-025.md
---
id: DEC-025
date: 2026-02-26
type: ratchet-update
plan: plan-001
---

## Ratchet Update After User Authentication

### Floors Updated
- architecture: 0 -> 92
- code_quality: 0 -> 88
- security: 0 -> 95
- performance: 0 -> 90
- testing: 0 -> 85
- spec_compliance: 0 -> 100

### Key Findings
- JSDoc coverage needs attention (recurring HIGH finding)
- Concurrent operation testing was missing (added)
- Architecture pattern for middleware location established

### Rules Generated
- None (first cycle — need 3 audits for pattern detection)

### Lessons
- bcrypt cost factor 12 is the minimum for OWASP compliance
- JWT expiry of 1 hour is acceptable but refresh tokens recommended for future
```

### Retrospective Reports

Generate a retrospective after multiple cycles:

```bash
spear ratchet retro --last 5
```

```
SPEAR Retrospective — Last 5 Cycles

Quality Trajectory:
  architecture:    72 -> 78 -> 85 -> 90 -> 94  (trending up +5.5/cycle)
  code_quality:    65 -> 72 -> 80 -> 85 -> 91  (trending up +6.5/cycle)
  security:        80 -> 88 -> 92 -> 95 -> 95  (plateaued at 95)
  performance:     70 -> 75 -> 82 -> 88 -> 90  (trending up +5.0/cycle)
  testing:         60 -> 68 -> 75 -> 80 -> 85  (trending up +6.25/cycle)
  spec_compliance: 90 -> 95 -> 100 -> 100 -> 100 (mastered at cycle 3)

Recurring Issues:
  1. JSDoc coverage (4/5 cycles) — Rule generated, should resolve
  2. Missing edge case tests (3/5 cycles) — Consider test template
  3. N+1 query patterns (2/5 cycles) — Add ORM eager-loading rule

Overrides Used: 1
  PERF-003: Accepted 2x slower PDF generation (justified by accuracy requirement)

Recommendations:
  - Focus area: testing (largest gap to ceiling)
  - Security is plateaued — consider advanced audit rules
  - Architecture improvement is strong — current practices working well
```

---

## Example: Ratchet Updates After Auth Audit

Starting state (first project audit):

```json
{
  "floors": {
    "architecture": 0,
    "code_quality": 0,
    "security": 0,
    "performance": 0,
    "testing": 0,
    "spec_compliance": 0
  },
  "history": []
}
```

After auth audit:

```bash
spear ratchet --plan plan-001
```

```json
{
  "floors": {
    "architecture": 92,
    "code_quality": 88,
    "security": 95,
    "performance": 90,
    "testing": 85,
    "spec_compliance": 100
  },
  "history": [
    {
      "plan": "plan-001",
      "spec": "spec-001",
      "date": "2026-02-26",
      "scores": {
        "architecture": 92,
        "code_quality": 88,
        "security": 95,
        "performance": 90,
        "testing": 85,
        "spec_compliance": 100
      },
      "findings_summary": {
        "critical": 0,
        "high": 2,
        "medium": 4,
        "low": 0
      },
      "overrides": [],
      "rules_generated": []
    }
  ]
}
```

Next feature (API pagination, plan-002) must score at least these floors. If the pagination feature scores 87 on code quality, the audit fails — even if the code has zero CRITICAL findings. The ratchet enforces standards.

---

## Ratchet Override

In exceptional cases, a floor can be lowered:

```bash
spear ratchet override \
  --category performance \
  --new-floor 85 \
  --reason "Migrating from REST to GraphQL — temporary performance regression expected" \
  --expires 2026-04-01
```

Overrides:
- Are logged permanently (even after expiry)
- Have mandatory expiration dates
- Appear in retrospectives
- Trigger re-evaluation on expiry

```bash
spear ratchet status
```

```
Category          Floor    Override    Expires       Reason
performance       85*      90 -> 85   2026-04-01    GraphQL migration
```

After the expiration date, the override lapses and the original floor (or higher) is restored.
