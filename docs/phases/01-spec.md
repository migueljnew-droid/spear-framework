# Phase 1: Spec

The Spec phase defines **what** you're building and **why**, without prescribing **how**. A good spec is the single most important artifact in SPEAR — everything downstream references it.

---

## When to Use Full PRD vs Lightweight Epic Shard

### Full PRD

Use when:
- Starting a new project or major feature area
- Multiple developers or AI agents will work from this spec
- Stakeholders need to review and approve before work begins
- The feature touches multiple system boundaries

A full PRD includes: problem statement, user stories, acceptance criteria, technical constraints, architecture impact, non-functional requirements, and rollout plan.

```bash
spear spec create --name "payment-system" --type prd
```

### Epic Shard

Use when:
- Adding a focused feature to an existing system
- The scope is clear and bounded (1-5 days of work)
- One developer or agent will own the implementation
- Architecture decisions are already made

An epic shard includes: problem statement, acceptance criteria, constraints, and out-of-scope items.

```bash
spear spec create --name "add-stripe-webhook" --type epic-shard
```

### Rule of Thumb

If you can explain the feature in one paragraph, use an epic shard. If you need diagrams, use a PRD.

---

## How to Reference Memory and Decisions

SPEAR maintains a decision log in `.spear/memory/decisions/`. Reference past decisions in your spec to provide context:

```markdown
## Context

Per decision DEC-012 (2026-02-15), we chose PostgreSQL over MongoDB
for relational data. This spec assumes a PostgreSQL backend.

Per decision DEC-018 (2026-02-20), all new API endpoints must use
the v2 router pattern established in the orders service.
```

To find relevant decisions:

```bash
spear memory search "database choice"
# => DEC-012: Selected PostgreSQL for relational data (2026-02-15)
# => DEC-003: Evaluated database options for user service (2026-01-10)
```

Always reference decisions rather than re-explaining them. This keeps specs concise and traceable.

---

## Architecture Doc Patterns

For specs that affect system architecture, include an architecture section:

### Context Diagram (for new systems)

```markdown
## Architecture

### System Context
- User -> [Web App] -> [API Server] -> [Database]
- [API Server] -> [Email Service] (for verification)
- [API Server] -> [Redis] (for rate limiting + sessions)
```

### Change Diagram (for modifications)

```markdown
## Architecture Impact

### Before
- POST /api/login -> authController -> userModel -> DB

### After
- POST /api/login -> rateLimiter -> authController -> userModel -> DB
                                  -> sessionStore -> Redis

### New Components
- rateLimiter middleware (new file)
- sessionStore service (new file)
- Redis connection config (modify existing)
```

Keep architecture descriptions in text or simple ASCII. Avoid external diagramming tools — the spec must be self-contained and diffable in git.

---

## Common Mistakes

### 1. Over-specifying implementation

Bad:
```markdown
## Requirements
- Use bcrypt.hash() with salt rounds = 12
- Store hash in VARCHAR(60) column named password_hash
- Use jsonwebtoken.sign() with HS256 algorithm
```

Good:
```markdown
## Requirements
- Passwords must be hashed with an industry-standard algorithm (bcrypt, argon2)
- Cost factor must meet current OWASP recommendations (bcrypt 12+, argon2id default)
- Tokens must be signed and expire within a reasonable window
```

The spec defines **what** and **why**. The plan defines **how**.

### 2. Under-specifying acceptance criteria

Bad:
```markdown
## Acceptance Criteria
- Users can log in
- Authentication works correctly
```

Good:
```markdown
## Acceptance Criteria
- [ ] POST /api/register with valid email/password returns 201 and JWT
- [ ] POST /api/register with existing email returns 409
- [ ] POST /api/login with valid credentials returns 200 and JWT
- [ ] POST /api/login with invalid credentials returns 401
- [ ] Protected routes without token return 401
- [ ] Protected routes with expired token return 401
- [ ] Rate limiter blocks after 5 failed attempts within 60 seconds
```

Acceptance criteria must be testable. If you can't write a test for it, it's too vague.

### 3. Missing constraints

Always specify:
- What existing systems this must integrate with
- Performance requirements (response time, throughput)
- Security requirements (OWASP, encryption standards)
- What is explicitly out of scope

### 4. Scope creep in the spec itself

If you find yourself writing "and we should also..." — stop. Create a separate spec. One spec, one feature boundary.

---

## Example Walkthrough: User Authentication Spec

```bash
spear spec create --name "user-auth" --type epic-shard
```

```markdown
---
id: spec-001
title: User Authentication
type: epic-shard
status: draft
created: 2026-02-26
author: developer
priority: high
---

# User Authentication

## Problem

The application currently has no authentication. All API endpoints are
publicly accessible. We need email/password authentication to protect
user-specific resources.

## Context

- Per DEC-005, the API uses Express.js with the v2 router pattern
- Per DEC-008, PostgreSQL is the primary data store
- No existing user table — this is greenfield

## Acceptance Criteria

- [ ] Users can register with email (valid format) and password (8+ chars)
- [ ] Duplicate email registration returns 409 Conflict
- [ ] Passwords are hashed with bcrypt (cost factor 12+)
- [ ] Login with valid credentials returns a signed JWT (1h expiry)
- [ ] Login with invalid credentials returns 401 (generic message)
- [ ] Protected routes reject requests without a valid token (401)
- [ ] Protected routes reject requests with an expired token (401)
- [ ] Rate limiter blocks login after 5 failed attempts per IP per minute
- [ ] All auth endpoints return JSON (no HTML error pages)

## Constraints

- Must use existing Express.js server (no new services)
- Must use PostgreSQL (no additional databases except Redis for rate limiting)
- Must pass OWASP Authentication Cheat Sheet guidelines
- Response times under 500ms for auth endpoints

## Non-Functional Requirements

- Passwords must never appear in logs
- Failed login attempts must be logged (IP, email, timestamp)
- JWT secret must come from environment variable, not hardcoded

## Out of Scope

- OAuth / social login (tracked as spec-002)
- Two-factor authentication (tracked as spec-003)
- Password reset flow (tracked as spec-004)
- Email verification (tracked as spec-005)
```

Finalize:

```bash
spear spec finalize spec-001
# => Validated: 9 acceptance criteria, all testable
# => Validated: constraints reference existing architecture
# => Validated: out-of-scope items tracked
# => Status: approved
```

---

## Spec Lifecycle

```
draft -> review -> approved -> implemented -> archived
                -> rejected (with reason logged to decisions)
```

- **draft:** Author is still writing
- **review:** Shared for feedback (human or AI review)
- **approved:** Ready for planning
- **implemented:** All acceptance criteria met, audit passed
- **archived:** Superseded by a newer spec

Move between states:

```bash
spear spec status spec-001 review     # Submit for review
spear spec status spec-001 approved   # Approve after review
spear spec status spec-001 archived   # Archive after completion
```
