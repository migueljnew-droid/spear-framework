# Phase 2: Plan

The Plan phase translates a spec's **what** into an actionable **how**. A plan breaks the work into ordered phases, defines fitness functions for each phase, and identifies unknowns that need research before execution.

---

## Breaking Specs into Phases

### Principles

1. **Each phase should be independently testable.** You should be able to verify phase 1 works before starting phase 2.
2. **Phases build on each other.** Phase 2 assumes phase 1 is complete and passing.
3. **Keep phases small.** 2-8 hours of work per phase. If a phase takes more than a day, split it.
4. **Data layer first, then logic, then integration, then hardening.** This ordering minimizes rework.

### Phase Sizing Guide

| Spec Type | Typical Phases | Phase Duration |
|-----------|---------------|----------------|
| Epic shard | 2-4 phases | 2-4 hours each |
| Full PRD | 5-10 phases | 4-8 hours each |
| Spike/research | 1-2 phases | 1-2 hours each |

### Common Phase Patterns

**CRUD Feature:**
1. Data model + migration
2. API endpoints (create, read)
3. API endpoints (update, delete)
4. Validation + error handling

**Integration Feature:**
1. Research + adapter interface
2. Core integration logic
3. Error handling + retry
4. Monitoring + logging

**Refactoring:**
1. Characterization tests for existing behavior
2. Extract new abstractions
3. Migrate consumers
4. Remove old code

---

## Defining Fitness Functions

A fitness function is a concrete, automatable check that tells you whether a phase meets its goals. Every phase must have at least one.

### Good Fitness Functions

```markdown
## Phase 1: Data Layer
**Fitness function:**
- `npm test -- --grep "User model"` passes (3+ tests)
- Migration runs without errors on empty database
- User.create() returns object with id, email, password_hash, created_at
- password_hash is exactly 60 characters (bcrypt format)
```

### Bad Fitness Functions

```markdown
## Phase 1: Data Layer
**Fitness function:**
- Code looks good
- Database works
- Model is correct
```

### Fitness Function Types

| Type | Example | When to Use |
|------|---------|-------------|
| Test suite | `npm test -- --grep "auth"` passes | Always — default choice |
| HTTP assertion | `POST /api/register` returns 201 | API endpoints |
| Script check | `node scripts/check-schema.js` exits 0 | Data layer validation |
| Performance | `autocannon /api/login` > 100 rps | Performance-sensitive code |
| Static analysis | `eslint src/auth/` returns 0 warnings | Code quality gates |

Write fitness functions that a machine can run. If a human has to look at output and decide "that seems right," it's not a fitness function — it's a review task.

---

## Research Briefs for Unknowns

When a plan includes technology or approaches the team hasn't used before, create a research brief instead of guessing.

```markdown
## Research Brief: Rate Limiting Strategy

### Question
What's the best rate limiting approach for Express.js with Redis?

### Options to Evaluate
1. express-rate-limit with rate-limit-redis store
2. Custom middleware with Redis INCR + EXPIRE
3. Nginx-level rate limiting (reverse proxy)

### Evaluation Criteria
- Supports per-IP limiting
- Supports custom windows (1 minute)
- Handles Redis connection failures gracefully
- Active maintenance (last commit < 6 months)

### Time Box
2 hours maximum. If no clear winner, default to option 1.

### Output
Decision logged to .spear/memory/decisions/ with rationale.
```

```bash
spear plan add-research --plan plan-001 --name "rate-limiting"
```

Research briefs prevent analysis paralysis. The time box forces a decision.

---

## Task Ordering and Dependencies

### Dependency Declaration

```markdown
## Phase 2: Auth Endpoints
**Depends on:** Phase 1 (User model must exist)
**Parallel with:** None
**Blocks:** Phase 3 (security hardening needs endpoints to test against)
```

### Parallel Phases

When phases don't depend on each other, mark them as parallelizable:

```markdown
## Phase 3a: Input Validation
**Depends on:** Phase 2
**Parallel with:** Phase 3b

## Phase 3b: Logging Setup
**Depends on:** Phase 2
**Parallel with:** Phase 3a
```

SPEAR tracks these dependencies and won't let you execute phase 2 before phase 1 is marked complete, unless you explicitly override.

### Reordering

If you discover during execution that the order is wrong:

```bash
spear plan reorder plan-001 --move 3 --before 2
# => Phase 3 moved before Phase 2. Dependencies updated.
# => Deviation logged: "Reordered phases — need validation before endpoints"
```

Always log the reason for reordering. The deviation becomes part of the audit trail.

---

## Example: Planning the Auth Feature

Starting from `spec-001` (User Authentication):

```bash
spear plan create --spec spec-001
```

```markdown
---
id: plan-001
spec: spec-001
status: draft
created: 2026-02-26
phases: 3
estimated_hours: 10
---

# Implementation Plan: User Authentication

## Research (Pre-Execution)

### Rate Limiting Library
- Evaluate express-rate-limit vs custom Redis middleware
- Time box: 1 hour
- Decision criteria: maintenance activity, Redis failure handling, per-IP support

## Phase 1: Data Layer (3 hours)

**Goal:** User model, migration, and hashing utility.

**Tasks:**
1. Create users table migration (id, email, password_hash, created_at, updated_at)
2. Create User model with findByEmail, create, verifyPassword methods
3. Create password hashing utility (bcrypt, cost factor 12)
4. Write unit tests for model and hashing

**Fitness Functions:**
- `npm test -- --grep "User model"` — 4 tests pass
- `npm run migrate` completes without errors
- `User.create({email, password})` stores 60-char bcrypt hash
- `User.findByEmail(email)` returns user object or null
- `User.verifyPassword(plain, hash)` returns boolean

**Depends on:** Nothing (first phase)

## Phase 2: Auth Endpoints (4 hours)

**Goal:** Register, login, and token verification middleware.

**Tasks:**
1. POST /api/v2/register — validate input, create user, return JWT
2. POST /api/v2/login — verify credentials, return JWT
3. verifyToken middleware — decode JWT, attach user to request
4. Apply middleware to existing protected routes
5. Write integration tests for all endpoints

**Fitness Functions:**
- `npm test -- --grep "auth endpoints"` — 8 tests pass
- POST /api/v2/register with valid data returns 201 + JWT
- POST /api/v2/register with duplicate email returns 409
- POST /api/v2/login with valid credentials returns 200 + JWT
- POST /api/v2/login with bad password returns 401
- GET /api/v2/protected without token returns 401
- GET /api/v2/protected with valid token returns 200

**Depends on:** Phase 1

## Phase 3: Security Hardening (3 hours)

**Goal:** Rate limiting, input sanitization, secure error responses.

**Tasks:**
1. Install and configure rate limiter (per research decision)
2. Add input validation (email format, password length)
3. Sanitize error responses (no stack traces, generic messages)
4. Add login attempt logging (IP, email, timestamp, success/fail)
5. Verify JWT secret comes from env var
6. Write security-focused tests

**Fitness Functions:**
- 6th login attempt within 60s returns 429
- Invalid email format returns 422 with message (no stack trace)
- Error responses contain no file paths or internal details
- Login failures logged with IP and sanitized email
- `process.env.JWT_SECRET` is the only source for signing key
- `npm audit` returns 0 critical vulnerabilities

**Depends on:** Phase 2
```

Finalize:

```bash
spear plan finalize plan-001
# => Validated: all phases have fitness functions
# => Validated: dependencies are acyclic
# => Validated: spec-001 acceptance criteria covered by phases
# => Estimated: 10 hours across 3 phases
# => Status: approved
```

---

## Plan Lifecycle

```
draft -> approved -> in_progress -> completed -> archived
                  -> revised (creates new version)
```

Plans can be revised mid-execution if discoveries require changes:

```bash
spear plan revise plan-001 --reason "Need Redis setup as separate phase"
# => Created plan-001-v2. Original preserved for audit trail.
```

Revisions are logged as deviations and visible in the audit phase.
