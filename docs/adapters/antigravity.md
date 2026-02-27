# Adapter: Antigravity

Configure SPEAR to work with Antigravity's rules, workflows, and agent system.

---

## Installation

```bash
# Install SPEAR with Antigravity adapter
./install.sh --adapter=antigravity
```

> **Note:** The `spear adapt` CLI commands shown in this guide are planned for v2.0.
> For now, use `install.sh` or manually copy adapter files from `adapters/antigravity/`.

This creates or updates:
- `.antigravity/rules.md` — Project rules with SPEAR context
- `.antigravity/workflows/spear-execute.yml` — Execution workflow
- `.antigravity/workflows/spear-audit.yml` — Audit workflow
- `.antigravity/agents/spear-auditor.yml` — Auditor agent definition

---

## How SPEAR Maps to Antigravity

| SPEAR Concept | Antigravity Equivalent |
|---------------|----------------------|
| Spec | Section in `rules.md` |
| Plan | Workflow definition |
| Fitness functions | Workflow steps with assertions |
| Audit rules | Rules in `rules.md` |
| Audit categories | Agent specializations |
| Phase execution | Workflow execution |

---

## Generated Rules File

```markdown
# .antigravity/rules.md

## SPEAR Framework Active
Spec: spec-015 (Payment Processing)
Plan: plan-015, Phase: 2

## Phase 2 Tasks
1. POST /api/v2/payments — create payment intent
2. POST /api/v2/payments/:id/confirm — confirm payment
3. GET /api/v2/payments/:id — get payment status
4. Stripe webhook handler
5. Integration tests

## Coding Rules
- All exported functions require JSDoc
- API inputs validated with Zod before processing
- Error responses: { "error": "message" } only
- No stack traces in responses
- Secrets from environment variables only
- Parameterized database queries only

## Commit Convention
`type(scope): description [spec-015/phase-2]`

## Architecture
- Routes in src/routes/v2/
- Business logic in src/services/
- Database access in src/models/
- Validation in src/middleware/
```

---

## Execution Workflow

```yaml
# .antigravity/workflows/spear-execute.yml
name: SPEAR Execute Phase
description: Execute current SPEAR phase with checkpoint tracking

steps:
  - name: Load Phase Context
    action: read_file
    file: .spear/plans/plan-015.md
    extract: phase-2

  - name: Execute Tasks
    action: code_generation
    context: |
      Implement the tasks listed in Phase 2 of the plan.
      Follow the rules in .antigravity/rules.md.
    iterate: tasks

  - name: Run Fitness Functions
    action: run_command
    commands:
      - npm test -- --grep "payment endpoints"
    assert:
      exit_code: 0
      min_tests: 8

  - name: Checkpoint Report
    action: report
    template: |
      ## Checkpoint: Phase 2
      Tasks completed: {{ completed_tasks }}
      Fitness functions: {{ fitness_results }}
      Deviations: {{ deviations }}

  - name: Commit Changes
    action: git_commit
    message: "feat(payments): {{ task_summary }} [spec-015/phase-2]"
```

---

## Auditor Agent

```yaml
# .antigravity/agents/spear-auditor.yml
name: SPEAR Auditor
role: Independent code quality auditor
capabilities:
  - code_review
  - security_scan
  - performance_analysis

context:
  spec: .spear/specs/spec-015.md
  plan: .spear/plans/plan-015.md
  audit_rules: .spear/audit-rules/

instructions: |
  You are an independent auditor. Review the implementation against
  the spec and plan. Check all six SPEAR audit categories:

  1. Architecture — Does the code follow established patterns?
  2. Code Quality — Is the code readable, documented, and maintainable?
  3. Security — Are there OWASP vulnerabilities?
  4. Performance — Are there N+1 queries, unbounded operations?
  5. Testing — Is coverage adequate? Edge cases?
  6. Spec Compliance — Does the implementation match all acceptance criteria?

  Classify each finding as CRITICAL, HIGH, MEDIUM, or LOW.
  CRITICAL findings block deployment.

output_format: |
  ## Audit Results
  ### [Category] (Score: X/100)
  [SEVERITY] ID: Description
    File: path:line
    Recommendation: ...
```

---

## Audit Workflow

```yaml
# .antigravity/workflows/spear-audit.yml
name: SPEAR Audit
description: Run parallel audit across all six categories

steps:
  - name: Architecture Review
    agent: spear-auditor
    focus: architecture
    parallel: true

  - name: Code Quality Review
    agent: spear-auditor
    focus: code_quality
    parallel: true

  - name: Security Scan
    agent: spear-auditor
    focus: security
    parallel: true

  - name: Performance Review
    agent: spear-auditor
    focus: performance
    parallel: true

  - name: Testing Review
    agent: spear-auditor
    focus: testing
    parallel: true

  - name: Spec Compliance Check
    agent: spear-auditor
    focus: spec_compliance
    parallel: true

  - name: Aggregate Results
    action: merge_reports
    block_on: CRITICAL
    output: .spear/audits/plan-015-audit.md
```

---

## Phase Transitions

```bash
spear execute complete --plan plan-015 --phase 2
spear adapt antigravity --phase plan-015/phase-3
# => Updated rules.md, workflows, and agent context for Phase 3
```

---

## Combining with Existing Antigravity Config

```bash
# Append SPEAR to existing rules
spear adapt antigravity --append

# Preview without writing
spear adapt antigravity --dry-run
```

---

## Troubleshooting

### Workflow steps fail silently

Add explicit assertions to each step:

```yaml
- name: Run Fitness
  action: run_command
  commands:
    - npm test -- --grep "payment"
  assert:
    exit_code: 0
  on_failure: abort
```

### Agent generates findings inconsistently

Pin the auditor agent's instructions with specific examples:

```yaml
instructions: |
  Example CRITICAL finding:
  [CRITICAL] SEC-001: SQL injection in user input
    File: src/routes/users.js:45
    Code: db.query(`SELECT * FROM users WHERE id = ${req.params.id}`)
    Fix: Use parameterized query: db.query('SELECT * FROM users WHERE id = $1', [req.params.id])
```

### Rules file too large

```bash
spear adapt antigravity --minimal
# => Only current phase tasks and top rules
```
