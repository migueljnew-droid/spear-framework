# Reference: Template Format

SPEAR templates use Markdown files with YAML frontmatter. This document specifies the format for specs, plans, and audit reports.

---

## General Format

Every SPEAR document follows this structure:

```markdown
---
yaml: frontmatter
goes: here
---

# Document Title

Markdown body content.
```

The YAML frontmatter is parsed by SPEAR for indexing, validation, and status tracking. The Markdown body is human-readable content.

---

## Spec Template

### Required Frontmatter

```yaml
---
id: spec-001              # Unique identifier (auto-generated or manual)
title: User Authentication # Human-readable title
type: epic-shard          # prd | epic-shard | spike
status: draft             # draft | review | approved | implemented | archived
created: 2026-02-26       # ISO date
---
```

### Optional Frontmatter

```yaml
---
author: developer-name     # Who wrote the spec
priority: high             # high | medium | low
owner: "@sarah"            # Who owns this spec
reviewers:                 # List of reviewers
  - "@mike"
  - "@alex"
tags:                      # Searchable tags
  - authentication
  - security
depends_on:                # Other specs this depends on
  - spec-000              # Must be completed first
supersedes: spec-old-001   # If this replaces an older spec
deadline: 2026-03-15       # Target completion date
---
```

### Required Body Sections

```markdown
# [Title]

## Problem
[What problem does this solve? Why does it matter?]

## Acceptance Criteria
- [ ] [Testable criterion 1]
- [ ] [Testable criterion 2]
- [ ] [Testable criterion 3]

## Constraints
- [Technical constraint 1]
- [Technical constraint 2]
```

### Recommended Body Sections

```markdown
## Context
[References to past decisions, existing architecture, user research]

## Non-Functional Requirements
- [Performance requirement]
- [Security requirement]
- [Scalability requirement]

## Architecture Impact
[How this changes the system architecture, if at all]

## Out of Scope
- [Feature explicitly excluded 1]
- [Feature explicitly excluded 2]
```

### Full Example

```markdown
---
id: spec-001
title: User Authentication
type: epic-shard
status: approved
created: 2026-02-26
author: developer
priority: high
owner: "@sarah"
reviewers: ["@mike", "@alex"]
tags: [authentication, security, api]
---

# User Authentication

## Problem
The application has no authentication. All API endpoints are publicly
accessible, exposing user data to unauthorized access.

## Context
- Per DEC-005, the API uses Express.js with v2 router pattern
- Per DEC-008, PostgreSQL is the primary data store
- No existing user table (greenfield)

## Acceptance Criteria
- [ ] POST /api/register with valid email/password returns 201 + JWT
- [ ] POST /api/register with duplicate email returns 409
- [ ] Passwords are hashed with bcrypt (cost factor 12+)
- [ ] POST /api/login with valid credentials returns 200 + JWT
- [ ] POST /api/login with invalid credentials returns 401
- [ ] Protected routes without token return 401
- [ ] Protected routes with expired token return 401
- [ ] Rate limiter blocks after 5 failed login attempts per minute

## Constraints
- Must use existing Express.js server
- Must use PostgreSQL (Redis optional for rate limiting)
- Must pass OWASP Authentication Cheat Sheet guidelines

## Non-Functional Requirements
- Auth endpoint response time under 500ms
- Passwords must never appear in logs
- JWT secret from environment variable

## Out of Scope
- OAuth / social login (spec-002)
- Two-factor authentication (spec-003)
- Password reset flow (spec-004)
```

---

## Plan Template

### Required Frontmatter

```yaml
---
id: plan-001               # Unique identifier
spec: spec-001             # Which spec this implements
status: draft              # draft | approved | in_progress | completed | archived
created: 2026-02-26        # ISO date
phases: 3                  # Number of phases
---
```

### Optional Frontmatter

```yaml
---
plan_owner: "@mike"         # Who owns the plan
estimated_hours: 10         # Total estimated hours
executors:                  # Who executes each phase
  phase-1: "@alex"
  phase-2: "@jordan"
  phase-3: "@alex"
auditor: "@sarah"           # Who will audit
version: 1                  # Plan version (incremented on revision)
revised_from: plan-001-v0   # Previous version if revised
---
```

### Required Body Structure

Each phase must include:

```markdown
## Phase N: [Name] ([Estimated Hours])

**Goal:** [One sentence describing what this phase achieves]

**Tasks:**
1. [Specific task 1]
2. [Specific task 2]
3. [Specific task 3]

**Fitness Functions:**
- [Automatable check 1]
- [Automatable check 2]

**Depends on:** [Phase N-1 or "Nothing"]
```

### Optional Phase Fields

```markdown
**Parallel with:** [Phase N if independent]
**Executor:** [@name]
**Research required:** [Brief description if unknowns exist]
```

---

## Audit Report Template

### Frontmatter

```yaml
---
id: audit-001              # Auto-generated
plan: plan-001             # Which plan was audited
spec: spec-001             # Which spec was targeted
date: 2026-02-26T14:30:00Z # ISO timestamp
status: complete           # complete | partial | failed
---
```

### Body Structure

```markdown
# Audit Report — [Plan ID]

## Summary
- Total findings: [N] ([N] CRITICAL, [N] HIGH, [N] MEDIUM, [N] LOW)
- Overall: [PASS | FAIL]
- Blocking findings: [N]

## Architecture (Score: [N]/100)

[SEVERITY] [ID]: [Description]
  File: [path]:[line]
  Recommendation: [What to do]

## Code Quality (Score: [N]/100)

[Findings...]

## Security (Score: [N]/100)

[Findings...]

## Performance (Score: [N]/100)

[Findings...]

## Testing (Score: [N]/100)

[Findings...]

## Spec Compliance (Score: [N]/100)

[Findings or "All acceptance criteria verified."]

## Deviations Reviewed
- [DEV-ID]: [Description] — [Assessment]
```

---

## Decision Log Template

### Frontmatter

```yaml
---
id: DEC-001                # Auto-generated
date: 2026-02-26           # When the decision was made
type: technical            # technical | process | architecture | tool
spec: spec-001             # Related spec (optional)
plan: plan-001             # Related plan (optional)
status: active             # active | superseded | deprecated
superseded_by: DEC-015     # If replaced (optional)
---
```

### Body

```markdown
# [Decision Title]

## Context
[Why this decision was needed]

## Options Considered
1. [Option A] — [Pros/Cons]
2. [Option B] — [Pros/Cons]
3. [Option C] — [Pros/Cons]

## Decision
[Which option was chosen and why]

## Consequences
- [Positive consequence]
- [Negative consequence / tradeoff]
- [Follow-up action needed]
```

---

## Deviation Log Template

### Frontmatter

```yaml
---
id: DEV-001                # Auto-generated
type: addition             # addition | change | removal | blocker
plan: plan-001             # Which plan
phase: 2                   # Which phase
date: 2026-02-26           # When it occurred
---
```

### Body

```markdown
# [Deviation Description]

## What Changed
[Description of the deviation]

## Reason
[Why the deviation was necessary]

## Impact
[How this affects the plan, timeline, or quality]
```

---

## Validation Rules

SPEAR validates templates on `finalize` commands:

| Check | Applies To | Rule |
|-------|-----------|------|
| Required frontmatter | All | Fields listed in config must be present |
| Unique ID | All | No duplicate IDs within a type |
| Valid status | All | Must be one of the allowed values |
| ISO date format | All | Dates must be YYYY-MM-DD or ISO 8601 |
| Acceptance criteria format | Specs | Must use `- [ ]` checkbox format |
| At least one criterion | Specs | Cannot have empty acceptance criteria |
| Fitness functions present | Plans | Each phase must have at least one (if configured) |
| Dependency acyclic | Plans | Phase dependencies cannot form cycles |
| Spec reference valid | Plans | Referenced spec must exist |
| Finding severity valid | Audits | Must be CRITICAL, HIGH, MEDIUM, or LOW |

Run validation manually:

```bash
spear validate .spear/specs/spec-001.md
# => Valid. 8 acceptance criteria, all testable.

spear validate .spear/plans/plan-001.md
# => Valid. 3 phases, all have fitness functions, dependencies acyclic.
```
