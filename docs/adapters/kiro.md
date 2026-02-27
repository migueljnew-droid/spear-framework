# Adapter: Kiro

Configure SPEAR to work with Kiro's steering files, hooks, and spec system.

---

## Installation

```bash
# Generate Kiro adapter files
spear adapt kiro
```

This creates or updates:
- `.kiro/steering.md` — Project steering with SPEAR context
- `.kiro/specs/` — Kiro-format specs from SPEAR specs
- `.kiro/hooks/` — Pre/post hooks for SPEAR integration

---

## How SPEAR Maps to Kiro

| SPEAR Concept | Kiro Equivalent |
|---------------|----------------|
| Spec | Kiro spec (`.kiro/specs/`) |
| Plan | Tasks within Kiro spec |
| Fitness functions | Kiro hooks (post-task) |
| Audit rules | Steering instructions |
| Memory | Steering context |
| Phase execution | Kiro spec-driven development |

Kiro has native spec support, making it one of the most natural SPEAR adapters.

---

## Generated Steering File

```markdown
# .kiro/steering.md

## Project Context
Framework: SPEAR (Spec, Plan, Execute, Audit, Ratchet)
Active spec: spec-015 (Payment Processing)
Active phase: Phase 2 (API Endpoints)

## Development Rules
1. Follow the active spec's acceptance criteria exactly
2. Run fitness functions after each task completion
3. Commit with format: `type(scope): description [spec-015/phase-2]`
4. Log deviations from the plan immediately
5. Do not implement out-of-scope features

## Coding Standards
- All exported functions: JSDoc with @param and @returns
- API inputs: validated with Zod schemas
- Error responses: `{ "error": "message" }` format
- No stack traces or internal paths in responses
- Database: parameterized queries only
- Secrets: environment variables only

## Architecture
- src/routes/v2/ — Express route handlers
- src/services/ — business logic
- src/models/ — database access
- src/middleware/ — validation, auth, error handling

## Key Decisions
- DEC-030: Stripe API v2023-10-16
- DEC-031: Idempotency keys on mutations
- DEC-032: Webhook signature verification via Stripe SDK
```

---

## Spec Translation

SPEAR specs translate to Kiro spec format:

```bash
spear adapt kiro --spec spec-015
```

Creates `.kiro/specs/spec-015.md`:

```markdown
# Payment Processing

## Requirements
- Users can create payment intents with amount and currency
- Payments can be confirmed after creation
- Payment status is queryable by ID
- Stripe webhooks update payment status in real time
- All payment mutations require idempotency keys

## Design
### API Endpoints
- POST /api/v2/payments — create intent (returns payment object)
- POST /api/v2/payments/:id/confirm — confirm payment
- GET /api/v2/payments/:id — get status
- POST /api/v2/webhooks/stripe — webhook receiver

### Data Model
- payments table: id, stripe_intent_id, amount, currency, status, idempotency_key, created_at, updated_at

### Security
- Webhook signatures verified
- Idempotency keys prevent double charges
- Amount validated server-side (positive integer, cents)

## Tasks
- [ ] Create Payment model and migration
- [ ] Implement POST /api/v2/payments
- [ ] Implement POST /api/v2/payments/:id/confirm
- [ ] Implement GET /api/v2/payments/:id
- [ ] Implement Stripe webhook handler
- [ ] Write integration tests (8+ tests)
- [ ] Verify all fitness functions pass
```

Kiro's spec-driven development then executes tasks from this spec.

---

## Hooks

### Post-Task Hook (Fitness Check)

```javascript
// .kiro/hooks/post-task.js
const { execFileSync } = require('child_process');

module.exports = {
  name: 'SPEAR Fitness Check',
  trigger: 'after_task_complete',

  async run(context) {
    const { taskName } = context;

    console.log(`Running fitness functions after: ${taskName}`);

    try {
      // Run SPEAR fitness functions using execFileSync (safe from injection)
      const result = execFileSync('spear', ['fitness', 'run', '--current-phase'], {
        encoding: 'utf-8',
        timeout: 60000,
      });
      console.log(result);

      if (result.includes('[FAIL]')) {
        return {
          status: 'warning',
          message: 'Some fitness functions failed. Review before continuing.',
        };
      }

      return { status: 'pass', message: 'All fitness functions passing.' };
    } catch (err) {
      return {
        status: 'error',
        message: `Fitness check failed: ${err.message}`,
      };
    }
  },
};
```

### Pre-Commit Hook (Convention Check)

```javascript
// .kiro/hooks/pre-commit.js
module.exports = {
  name: 'SPEAR Commit Convention',
  trigger: 'before_commit',

  async run(context) {
    const { commitMessage } = context;
    const pattern = /^(feat|fix|refactor|test|docs|chore)\(.+\): .+ \[spec-\d+\/phase-\d+\]$/;

    if (!pattern.test(commitMessage)) {
      return {
        status: 'block',
        message: `Commit message must match: type(scope): description [spec-XXX/phase-N]\nGot: ${commitMessage}`,
      };
    }

    return { status: 'pass' };
  },
};
```

### Post-Spec Hook (Audit Trigger)

```javascript
// .kiro/hooks/post-spec-complete.js
const { execFileSync } = require('child_process');

module.exports = {
  name: 'SPEAR Auto-Audit',
  trigger: 'after_spec_complete',

  async run(context) {
    console.log('Spec complete — triggering SPEAR audit...');

    const result = execFileSync('spear', ['audit', '--plan', 'plan-015', '--ci'], {
      encoding: 'utf-8',
      timeout: 300000,
    });

    console.log(result);
    return { status: 'pass', message: 'Audit complete. Check results.' };
  },
};
```

---

## Phase Transitions

```bash
spear execute complete --plan plan-015 --phase 2
spear adapt kiro --phase plan-015/phase-3
# => Updated steering.md with Phase 3 context
# => Updated spec tasks for Phase 3
# => Hooks updated with new fitness functions
```

---

## Kiro Spec vs SPEAR Spec

Kiro and SPEAR both have specs, but they serve different purposes:

| Aspect | SPEAR Spec | Kiro Spec |
|--------|-----------|-----------|
| Purpose | Requirements + acceptance criteria | Requirements + tasks + design |
| Format | YAML frontmatter + Markdown | Markdown with task checkboxes |
| Tasks | In the Plan (separate phase) | Inline in the spec |
| Execution | Via SPEAR CLI + adapter | Via Kiro's spec-driven mode |

The SPEAR adapter translates SPEAR's spec + plan into Kiro's combined format, keeping both systems in sync.

---

## Troubleshooting

### Kiro modifies the spec during execution

Kiro may update task checkboxes in `.kiro/specs/`. This is fine — it tracks Kiro's progress. SPEAR's source of truth remains in `.spear/specs/`.

### Hooks don't fire

Ensure hooks are registered in Kiro's configuration:

```json
{
  "hooks": {
    "post_task": ".kiro/hooks/post-task.js",
    "pre_commit": ".kiro/hooks/pre-commit.js",
    "post_spec_complete": ".kiro/hooks/post-spec-complete.js"
  }
}
```

### Steering file conflicts with existing

```bash
spear adapt kiro --append
# => Appends SPEAR section to existing steering.md
```
