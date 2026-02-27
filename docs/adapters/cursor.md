# Adapter: Cursor

Configure SPEAR to work with Cursor via `.cursorrules` and project-level settings.

---

## Installation

```bash
# Install SPEAR with Cursor adapter
./install.sh --adapter=cursor
```

> **Note:** The `spear adapt` CLI commands shown in this guide are planned for v2.0.
> For now, use `install.sh` or manually copy adapter files from `adapters/cursor/`.

This creates or updates:
- `.cursorrules` — Project rules with SPEAR context
- `.cursor/settings.json` — Cursor-specific settings (optional)

---

## How SPEAR Maps to Cursor

| SPEAR Concept | Cursor Equivalent |
|---------------|-------------------|
| Spec | Section in `.cursorrules` |
| Plan | Section in `.cursorrules` |
| Fitness functions | Instructions to run commands |
| Audit rules | Rules in `.cursorrules` |
| Memory | Referenced file paths |
| Phase execution | Composer session context |

---

## Generated .cursorrules Structure

```markdown
# SPEAR Framework — Active Configuration

## Current Context
Spec: spec-015 (Payment Processing)
Plan: plan-015
Phase: 2 (API Endpoints)

## Phase 2 Tasks
1. POST /api/v2/payments — create payment intent
2. POST /api/v2/payments/:id/confirm — confirm payment
3. GET /api/v2/payments/:id — get payment status
4. POST /api/v2/webhooks/stripe — handle Stripe webhooks
5. Integration tests for all endpoints

## Fitness Functions
After making changes, run these commands and verify they pass:
- `npm test -- --grep "payment endpoints"` — must have 8+ passing tests
- `curl -s localhost:3000/api/v2/payments -X POST -d '{"amount":100}'` — must return 201

## Rules (Non-Negotiable)
- All exported functions must have JSDoc with @param and @returns
- All API inputs must be validated with Joi/Zod schema before processing
- Error responses must use format: { "error": "message" } — no stack traces
- Secrets must come from environment variables, never hardcoded
- All database queries must use parameterized statements

## Commit Convention
Every commit must follow: `type(scope): description [spec-015/phase-2]`
Valid types: feat, fix, refactor, test, docs, chore

## Key Decisions
- DEC-030: Stripe API v2023-10-16 for payment intents
- DEC-031: Idempotency keys required for all payment mutations
- DEC-032: Webhook signatures verified with Stripe SDK

## Architecture Constraints
- All new endpoints go in src/routes/v2/
- Business logic in src/services/, not in route handlers
- Database access only through models in src/models/

## Out of Scope (Do NOT implement)
- Subscription management (spec-016)
- Refund processing (spec-017)
- Multi-currency support (spec-018)
```

---

## Composer Integration

When starting a Cursor Composer session for SPEAR work:

1. Cursor automatically reads `.cursorrules`
2. The active phase context is loaded
3. Rules are enforced throughout the session

### Effective Prompts

```
Implement Phase 2, Task 1: POST /api/v2/payments endpoint.
Follow the plan in .cursorrules. Run fitness functions after.
```

```
I've completed Task 3. Run the fitness functions and report results.
Then commit with the convention: feat(payments): add payment status endpoint [spec-015/phase-2]
```

---

## Phase Transitions

```bash
# Complete phase 2, update .cursorrules for phase 3
spear execute complete --plan plan-015 --phase 2
spear adapt cursor --phase plan-015/phase-3
```

Cursor picks up the new `.cursorrules` on the next Composer session or file edit.

---

## Multi-File Context

For phases that span many files, point Cursor to the relevant context:

```markdown
## Relevant Files for Phase 2
Read these files for context before making changes:
- src/routes/v2/payments.js (create this)
- src/services/paymentService.js (create this)
- src/models/payment.js (exists — review before using)
- src/middleware/validatePayment.js (create this)
- tests/payments.test.js (create this)
- src/routes/v2/index.js (modify — add payment routes)
```

---

## Combining with Cursor Rules Files

If you already have a `.cursorrules` file, SPEAR appends to it:

```bash
spear adapt cursor --append
# => SPEAR section appended to existing .cursorrules
# => Existing rules preserved above SPEAR section
```

To replace entirely:

```bash
spear adapt cursor --replace
# => .cursorrules replaced with SPEAR-only content
# => Backup saved to .cursorrules.bak
```

---

## Troubleshooting

### Cursor ignores some rules

Cursor has a context window limit. If `.cursorrules` is too long:

```bash
spear adapt cursor --minimal
# => Only includes: current phase tasks, top 5 rules, fitness functions
```

### Rules conflict with existing .cursorrules

Review the merged file and remove duplicates:

```bash
spear adapt cursor --dry-run
# => Shows what would be generated without writing
```

### Cursor doesn't run fitness functions

Cursor cannot execute commands directly in all contexts. Add explicit instructions:

```markdown
## After Each Task
Tell the user to run: `spear fitness run`
Or run in the terminal: `npm test -- --grep "payment"`
```
