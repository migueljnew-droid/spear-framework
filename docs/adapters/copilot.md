# Adapter: GitHub Copilot

Configure SPEAR to work with GitHub Copilot via `copilot-instructions.md` and Copilot Chat context.

---

## Installation

```bash
# Install SPEAR with Copilot adapter
./install.sh --adapter=copilot
```

> **Note:** The `spear adapt` CLI commands shown in this guide are planned for v2.0.
> For now, use `install.sh` or manually copy adapter files from `adapters/copilot/`.

This creates or updates:
- `.github/copilot-instructions.md` — Project-level Copilot instructions
- `.github/copilot-chat-context.md` — Additional context for Copilot Chat

---

## How SPEAR Maps to Copilot

| SPEAR Concept | Copilot Equivalent |
|---------------|-------------------|
| Spec | Section in `copilot-instructions.md` |
| Plan | Section in `copilot-instructions.md` |
| Fitness functions | Instructions in Copilot Chat context |
| Audit rules | Coding guidelines in instructions |
| Memory | Referenced in instructions |
| Phase execution | Copilot Chat workflow |

---

## Generated copilot-instructions.md

```markdown
# Project Coding Guidelines (SPEAR Framework)

## Active Context
Building: Payment Processing (spec-015)
Current phase: Phase 2 — API Endpoints

## Coding Standards
- TypeScript strict mode — no `any` types
- All exported functions need JSDoc with @param and @returns
- API inputs validated with Zod schemas
- Error responses: `{ "error": "message" }` format only
- No stack traces or internal paths in error responses
- Database queries use parameterized statements only
- Secrets from environment variables, never hardcoded

## Architecture
- Routes: `src/routes/v2/` (Express Router pattern)
- Services: `src/services/` (business logic, no HTTP concerns)
- Models: `src/models/` (database access layer)
- Middleware: `src/middleware/` (validation, auth, error handling)
- Tests: `tests/` (colocated with source when possible)

## Current Phase Tasks
1. POST /api/v2/payments — create payment intent
2. POST /api/v2/payments/:id/confirm — confirm payment
3. GET /api/v2/payments/:id — get payment status
4. Stripe webhook handler at POST /api/v2/webhooks/stripe
5. Integration tests for all endpoints

## Patterns to Follow
When creating a new endpoint, follow this pattern:
```javascript
// src/routes/v2/payments.js
const router = require('express').Router();
const { validate } = require('../../middleware/validate');
const { createPaymentSchema } = require('./schemas');
const paymentService = require('../../services/paymentService');

router.post('/', validate(createPaymentSchema), async (req, res, next) => {
  try {
    const result = await paymentService.createPayment(req.body);
    res.status(201).json(result);
  } catch (err) {
    next(err);
  }
});
```

## Do NOT Generate
- Subscription management code (out of scope)
- Refund processing (out of scope)
- Code using `any` type
- Raw SQL queries (use model layer)
- Console.log for production code (use logger)
```

---

## Copilot Chat Workflow

### Starting a Phase

In Copilot Chat:

```
@workspace I'm starting Phase 2 of spec-015 (Payment Processing).
Read .github/copilot-instructions.md for context.
Help me implement Task 1: POST /api/v2/payments endpoint.
```

### Mid-Phase Check

```
@workspace I've completed Tasks 1-3. Review my changes against
the plan in .github/copilot-instructions.md. Are there any
issues with the implementation pattern?
```

### Fitness Check

```
@workspace The fitness function is: npm test -- --grep "payment endpoints"
must have 8+ passing tests. I currently have 6. What tests am I missing
based on the spec requirements?
```

---

## Copilot Inline Suggestions

The `copilot-instructions.md` influences inline completions. When you type in a file within `src/routes/v2/`, Copilot will:

- Follow the Express Router pattern defined in instructions
- Use Zod for validation (not ad-hoc checks)
- Return proper status codes and error formats
- Include JSDoc on exported functions

### Example: Copilot Completes Based on Rules

When you type:

```javascript
router.post('/:id/confirm', validate(confirmPaymentSchema),
```

Copilot suggests:

```javascript
async (req, res, next) => {
  try {
    const result = await paymentService.confirmPayment(req.params.id, req.body);
    res.status(200).json(result);
  } catch (err) {
    next(err);
  }
});
```

This follows the pattern defined in the instructions.

---

## Phase Transitions

```bash
spear execute complete --plan plan-015 --phase 2
spear adapt copilot --phase plan-015/phase-3
# => Updated .github/copilot-instructions.md with Phase 3 context
```

---

## Copilot Workspace Integration

For Copilot Workspace (plan + implement flow):

```bash
spear adapt copilot --workspace
# => Generates workspace-compatible plan format
```

This creates a plan that Copilot Workspace can execute as a multi-file change set.

---

## Limitations

### No Command Execution

Copilot cannot run fitness functions or CLI commands. You must run them manually:

```bash
# After Copilot generates code
npm test -- --grep "payment endpoints"
spear fitness run --phase 2
```

### Context Window

Copilot's instruction context is limited. If instructions are too long:

```bash
spear adapt copilot --minimal
# => Only includes: coding standards, current phase tasks, patterns
```

### No Memory Access

Copilot doesn't read SPEAR's memory backend. Key decisions are injected into the instructions file:

```markdown
## Key Decisions (from SPEAR memory)
- Stripe API v2023-10-16 for payment intents
- Idempotency keys on all mutations
- Webhook signatures verified via Stripe SDK
```

---

## Troubleshooting

### Copilot generates code that violates rules

Copilot instructions are suggestions, not hard constraints. For enforcement:
1. Run `spear audit` after each phase to catch violations
2. Add ESLint rules that match SPEAR audit rules
3. Use pre-commit hooks for critical rules (no secrets, no `any` types)

### Instructions not taking effect

Ensure the file is at the correct path: `.github/copilot-instructions.md` (not root level). Restart VS Code after creating the file.

### Copilot suggests out-of-scope features

Add explicit exclusions in the instructions:

```markdown
## NEVER Generate Code For
- Subscription management (spec-016 — not this phase)
- Refund processing (spec-017 — not this phase)
- If prompted about these, respond: "Out of scope for current spec"
```
