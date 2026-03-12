# SPEAR Quickstart: 5 Minutes to Your First Cycle

> **SPEAR v2.0** — Now with TDD enforcement, verification gates, Socratic specs, systematic debugging, subagent execution, and worktree isolation.
> The `spear` CLI is planned for a future release. This quickstart shows the target workflow.
> For the current manual workflow, see the [adapter guides](adapters/) or use `install.sh` directly.

## Prerequisites

- Git repository (new or existing)
- Node.js 18+ or Python 3.10+ (for the CLI)
- Any AI coding tool (Claude Code, Cursor, Copilot, or just a chat window)

---

## Step 1: Install SPEAR

```bash
# Install SPEAR into your project
curl -fsSL https://raw.githubusercontent.com/migueljnew-droid/spear-framework/main/install.sh | bash
```

Or install manually:

```bash
git clone https://github.com/migueljnew-droid/spear-framework.git
cp -r spear-framework/.spear your-project/.spear
cp -r spear-framework/hooks your-project/hooks
cd your-project && ./install.sh
```

> **Note:** `npm install -g @spear-framework/cli` is coming soon in v2.0.

---

## Step 2: Initialize Your Project

```bash
cd your-project
spear init
```

Expected output:

```
Initialized SPEAR in ./spear/
  Created: .spear/config.json        (project configuration)
  Created: .spear/ratchet/ratchet.json (quality floors — all at 0)
  Created: .spear/memory/            (decision log directory)
  Created: .spear/specs/             (specification directory)
  Created: .spear/plans/             (plan directory)
  Created: .spear/audits/            (audit results directory)
  Created: .spear/templates/         (document templates)

Next: Create a spec with 'spear spec create'
```

Review the generated config:

```bash
cat .spear/config.json
```

The defaults work for most projects. See `docs/reference/config-schema.md` for customization options.

---

## Step 3: Create Your First Spec

```bash
spear spec create --name "user-auth" --type epic-shard
```

This opens your editor with a template. Fill it in:

```markdown
---
id: spec-001
title: User Authentication
type: epic-shard
status: draft
created: 2026-02-26
---

# User Authentication

## Problem
Users cannot log in to the application. We need email/password authentication
with session management.

## Acceptance Criteria
- [ ] Users can register with email and password
- [ ] Passwords are hashed with bcrypt (cost factor 12+)
- [ ] Login returns a JWT token (1-hour expiry)
- [ ] Protected routes reject requests without valid tokens
- [ ] Failed login attempts are rate-limited (5 per minute)

## Constraints
- Must use existing Express.js server
- No third-party auth services (self-hosted)
- Must pass OWASP top-10 checks for authentication

## Out of Scope
- OAuth/social login (future spec)
- Two-factor authentication (future spec)
- Password reset flow (future spec)
```

Save and finalize:

```bash
spear spec finalize spec-001
# => Spec spec-001 finalized. Status: approved
# => Ready for planning.
```

---

## Step 4: Plan the Implementation

```bash
spear plan create --spec spec-001
```

SPEAR generates a plan skeleton from your spec:

```markdown
---
id: plan-001
spec: spec-001
phases: 3
status: draft
---

# Implementation Plan: User Authentication

## Phase 1: Data Layer
- Create User model with email, password_hash, created_at
- Set up bcrypt hashing utility
- Write migration script
- **Fitness function:** User model validates email format, password hash is 60 chars

## Phase 2: Auth Endpoints
- POST /api/register — create user, return JWT
- POST /api/login — verify credentials, return JWT
- Middleware: verifyToken for protected routes
- **Fitness function:** All endpoints return correct status codes (201, 200, 401)

## Phase 3: Security Hardening
- Rate limiter on /api/login (5 req/min per IP)
- Input validation and sanitization
- Error messages that don't leak information
- **Fitness function:** Rate limiter triggers on 6th request, no stack traces in responses
```

Finalize when ready:

```bash
spear plan finalize plan-001
# => Plan plan-001 finalized. 3 phases ready for execution.
```

---

## Step 5: Execute with Audit Gates

Execute phase by phase:

```bash
spear execute --plan plan-001 --phase 1
```

This sets your context and tracks progress. Build the code using your AI tool of choice.

At each checkpoint (25%, 50%, 75%, 100%), SPEAR prompts:

```
Checkpoint: Phase 1 at 50%
  Completed: User model, bcrypt utility
  Remaining: Migration script
  Fitness: User model validates email format [PASS]
  Deviations: None logged

Continue? [y/n]
```

After completing all phases, run the audit:

```bash
spear audit --plan plan-001
```

Output:

```
Running 6 audit categories in parallel...

[PASS] Security        — Score: 95/100 (0 CRITICAL, 0 HIGH)
[PASS] Dependencies    — Score: 98/100 (0 CRITICAL, 0 HIGH)
[PASS] Performance     — Score: 90/100 (0 CRITICAL, 0 HIGH)
[PASS] Code Quality    — Score: 88/100 (0 CRITICAL, 1 HIGH)
[PASS] Documentation   — Score: 85/100 (0 CRITICAL, 0 HIGH)
[PASS] Architecture    — Score: 92/100 (0 CRITICAL, 0 HIGH)

Overall: PASS (no CRITICAL findings)
1 HIGH finding:
  [CQ-001] Function `hashPassword` missing JSDoc. Severity: HIGH.

Ready to ratchet.
```

Fix the HIGH finding or proceed (HIGHs don't block, CRITICALs do):

```bash
spear ratchet --plan plan-001
```

---

## Step 6: Watch the Ratchet Tighten

```bash
spear ratchet status
```

```
Quality Floors (auto-tightened):
  security:        0 → 95  (+95)
  dependencies:    0 → 98  (+98)
  performance:     0 → 90  (+90)
  code_quality:    0 → 88  (+88)
  documentation:   0 → 85  (+85)
  architecture:    0 → 92  (+92)

Next audit must meet or exceed these scores.
```

Your quality can only go up from here. The next feature you build will be held to these standards — or higher.

---

## What's Next

- **Customize audits:** `docs/phases/04-audit.md`
- **Add fitness functions:** `docs/upgrades/fitness-functions.md`
- **Set up CI integration:** `docs/upgrades/ci-integration.md`
- **Configure your AI tool:** `docs/adapters/` (Claude Code, Cursor, Copilot, etc.)
- **Full config reference:** `docs/reference/config-schema.md`
