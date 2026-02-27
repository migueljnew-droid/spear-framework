# Adapter: Generic LLM

Use SPEAR with any LLM — ChatGPT, Gemini, local models, or any chat interface. No tool integration required. Copy-paste workflow.

---

## Installation

```bash
# Install SPEAR with generic adapter
./install.sh --adapter=generic
```

> **Note:** The `spear adapt` CLI commands shown in this guide are planned for v2.0.
> For now, use `install.sh` or manually copy adapter files from `adapters/generic/`.

This generates:
- `.spear/prompts/system-prompt.md` — System prompt for any LLM
- `.spear/prompts/phase-context.md` — Current phase context to paste
- `.spear/prompts/audit-prompt.md` — Audit prompt to paste after execution

---

## How It Works

No tool integration. You copy relevant context from generated files and paste it into your LLM conversation. SPEAR generates the prompts; you relay them.

### Workflow

```
1. spear adapt generic                    (generate prompts)
2. Copy system-prompt.md into LLM         (set context)
3. Copy phase-context.md into LLM         (start execution)
4. Build code with LLM assistance         (iterate)
5. Run fitness functions manually          (verify)
6. Copy audit-prompt.md into LLM          (get audit)
7. spear audit --manual < audit-input.md  (record results)
```

---

## System Prompt

Paste this at the start of every conversation:

```markdown
# .spear/prompts/system-prompt.md

You are a software developer following the SPEAR framework.
SPEAR enforces: Spec -> Plan -> Execute -> Audit -> Ratchet.

## Your Rules
1. Follow the spec's acceptance criteria exactly
2. Follow the plan's phase tasks in order
3. Run fitness functions after each task
4. Use commit convention: type(scope): description [spec-ID/phase-N]
5. Log any deviations from the plan
6. Do not implement features outside the current scope

## Coding Standards
- All exported functions need documentation
- All inputs must be validated before use
- Error responses must not contain internal details
- No secrets hardcoded in source code
- Use parameterized database queries

## When I Say "checkpoint"
Report:
- Tasks completed so far
- Fitness function results (if available)
- Any deviations from the plan
- Estimated completion percentage
```

---

## Phase Context Prompt

Paste this after the system prompt to set the current phase:

```markdown
# .spear/prompts/phase-context.md

## Current Spec: Payment Processing (spec-015)

### Acceptance Criteria
- [ ] POST /api/v2/payments creates a payment intent and returns 201
- [ ] POST /api/v2/payments/:id/confirm confirms payment and returns 200
- [ ] GET /api/v2/payments/:id returns payment status
- [ ] Stripe webhooks update payment status
- [ ] Invalid input returns 422 with error message
- [ ] Unauthorized requests return 401
- [ ] Rate limiter blocks after 20 requests per minute
- [ ] All mutations require idempotency key header

## Current Plan: Phase 2 — API Endpoints

### Tasks
1. POST /api/v2/payments — create payment intent
2. POST /api/v2/payments/:id/confirm — confirm payment
3. GET /api/v2/payments/:id — get payment status
4. Stripe webhook handler at POST /api/v2/webhooks/stripe
5. Integration tests (8+ tests)

### Fitness Functions (run manually after each task)
- `npm test -- --grep "payment endpoints"` must pass with 8+ tests
- `npm run lint` must pass with 0 errors

### Key Decisions
- Using Stripe API v2023-10-16
- Idempotency keys required on all payment mutations
- Webhook signatures verified using Stripe SDK

### Phase 1 Summary (completed)
- Payment model created with proper schema
- Migration tested and working
- 4 unit tests passing

Let's start with Task 1. Implement POST /api/v2/payments.
```

---

## During Execution

### Requesting Code

```
Implement Task 2: POST /api/v2/payments/:id/confirm.
Follow the same pattern as Task 1.
The endpoint should verify the payment exists, call Stripe to confirm,
and update the local status.
```

### Checkpoint

```
Checkpoint. What's our status?
```

Expected LLM response:

```
Checkpoint: Phase 2 at 60%

Completed:
- Task 1: POST /api/v2/payments (create intent) ✓
- Task 2: POST /api/v2/payments/:id/confirm ✓
- Task 3: GET /api/v2/payments/:id ✓

Remaining:
- Task 4: Stripe webhook handler
- Task 5: Integration tests

Fitness functions:
- npm test -- --grep "payment endpoints": 5 tests passing (need 8+)

Deviations:
- None so far
```

### Logging Deviations

```
Deviation: I'm adding a retry mechanism for Stripe API calls that wasn't
in the plan. The Stripe SDK occasionally returns 503 during peak times.
Log this as an addition deviation.
```

---

## Audit Prompt

After completing all tasks, paste the audit prompt:

```markdown
# .spear/prompts/audit-prompt.md

Review all the code we've written in this session against the spec
and plan. Perform a SPEAR audit across six categories.

For each category, provide:
- Score (0-100)
- Findings with severity (CRITICAL, HIGH, MEDIUM, LOW)
- File and line references where applicable

## Categories

### 1. Architecture
Does the code follow established patterns? Are modules properly separated?

### 2. Code Quality
Is the code readable? Are functions documented? Is complexity reasonable?

### 3. Security
Any OWASP issues? Input validation? Secret handling? Injection risks?

### 4. Performance
N+1 queries? Unbounded operations? Memory leaks? Response time concerns?

### 5. Testing
Coverage of critical paths? Edge cases? Test isolation?

### 6. Spec Compliance
Does every acceptance criterion have a corresponding implementation and test?

Format your response as:
=== Category (Score: X/100) ===
[SEVERITY] ID: Description
  File: path:line
  Recommendation: ...

End with a summary: total findings by severity, pass/fail, recommendations.
```

---

## Recording Results

After the LLM produces an audit, save it:

```bash
# Create the audit result file manually
cat > .spear/audits/plan-015-manual-audit.md << 'EOF'
[paste LLM audit output here]
EOF

# Or use SPEAR's manual audit intake
spear audit --manual --plan plan-015 < audit-output.txt
```

---

## Tips for Effective Generic Use

### 1. Keep Conversations Focused

One conversation per phase. Start fresh for each phase with the updated context prompt. Long conversations cause LLMs to lose track of rules.

### 2. Re-Paste Rules Periodically

In long conversations, re-paste the coding standards every 10-15 messages:

```
Reminder: Follow these rules for the next code block:
- JSDoc on all exports
- Zod validation on inputs
- No stack traces in error responses
```

### 3. Run Fitness Functions Yourself

The LLM cannot execute commands. After it generates code:

```bash
# You run this in your terminal
npm test -- --grep "payment endpoints"
```

Then report back:

```
Fitness function results: 7/8 tests passing.
The failing test is "should return 429 on rate limit exceeded."
Fix this.
```

### 4. Use Code Blocks for Copy-Paste

Ask the LLM to output complete files in code blocks:

```
Output the complete src/routes/v2/payments.js file.
Include all imports, all endpoints, and JSDoc on every exported function.
Output as a single code block I can copy directly.
```

### 5. Commit Manually

```bash
git add src/routes/v2/payments.js src/services/paymentService.js
git commit -m "feat(payments): add payment CRUD endpoints [spec-015/phase-2]"
```

---

## Supported LLMs

This adapter works with any text-based LLM:

| LLM | Notes |
|-----|-------|
| ChatGPT (GPT-4) | Works well with structured prompts |
| Claude (web/API) | Follows system prompts closely |
| Gemini | Good at multi-file generation |
| Llama 3 (local) | Works, may need simpler prompts |
| Mistral | Works, test with your model size |
| DeepSeek | Good code generation, follows rules |

The key is the prompt quality, not the model. The generated prompts work across all of them.
