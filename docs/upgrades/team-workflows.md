# Upgrade: Team Workflows

SPEAR works for solo developers by default. With multiple developers (or multiple AI agents), you need clear ownership of phases and coordination protocols.

---

## Role Definitions

### Spec Owner

Writes and maintains specs. Responsible for:
- Defining acceptance criteria
- Reviewing specs for completeness
- Approving spec changes during execution
- Verifying spec compliance in audits

Typically: Product manager, tech lead, or senior developer.

### Plan Owner

Creates implementation plans from specs. Responsible for:
- Breaking specs into phases
- Defining fitness functions
- Identifying research needs
- Adjusting plans based on execution feedback

Typically: Tech lead or architect.

### Executor

Implements the plan. Responsible for:
- Writing code per the plan
- Running fitness functions at checkpoints
- Logging deviations in real time
- Committing with conventional message format

Typically: Developer or AI agent. Multiple executors can work on different phases in parallel.

### Auditor

Runs and interprets audits. Responsible for:
- Running audit categories
- Classifying findings
- Approving or rejecting overrides
- Signing off on ratchet updates

Typically: Senior developer, security engineer, or a dedicated review role. Must NOT be the executor (independent verification).

---

## Ownership Assignment

### In Spec Files

```markdown
---
id: spec-015
title: Payment Processing
owner: @sarah
reviewers: [@mike, @alex]
---
```

### In Plan Files

```markdown
---
id: plan-015
spec: spec-015
plan_owner: @mike
executors:
  phase-1: @alex
  phase-2: @jordan
  phase-3: @alex
auditor: @sarah
---
```

### Tracking Ownership

```bash
spear status --plan plan-015
```

```
Plan: plan-015 (Payment Processing)
Spec owner:  @sarah
Plan owner:  @mike
Auditor:     @sarah

Phase 1 (Data Layer)     @alex     [COMPLETE]
Phase 2 (API Endpoints)  @jordan   [IN PROGRESS - 50%]
Phase 3 (Webhooks)       @alex     [BLOCKED - waiting on Phase 2]
```

---

## Team Coordination Patterns

### Pattern 1: Sequential Handoff

One person per phase, sequential execution.

```
@sarah writes spec -> @mike creates plan -> @alex executes phase 1
-> @jordan executes phase 2 -> @alex executes phase 3
-> @sarah audits -> @mike ratchets
```

Best for: Small teams, features with tight phase dependencies.

### Pattern 2: Parallel Execution

Multiple executors work on independent phases simultaneously.

```
@sarah writes spec -> @mike creates plan
  -> @alex executes phase 1 (data layer)    [parallel]
  -> @jordan executes phase 2 (frontend)    [parallel]
  -> @kim executes phase 3 (API)            [parallel]
-> @sarah audits all phases -> @mike ratchets
```

Best for: Larger teams, features with independent components.

Mark parallel phases in the plan:

```markdown
## Phase 1: Data Layer
**Executor:** @alex
**Parallel with:** Phase 2

## Phase 2: Frontend Components
**Executor:** @jordan
**Parallel with:** Phase 1
**Depends on:** Nothing

## Phase 3: API Integration
**Executor:** @kim
**Depends on:** Phase 1, Phase 2
```

### Pattern 3: Spec Review Board

Multiple reviewers must approve specs before planning begins.

```bash
spear spec submit spec-015 --reviewers @sarah,@mike,@alex
```

```
Spec spec-015 submitted for review.
  @sarah: pending
  @mike: pending
  @alex: pending

Requires: 2/3 approvals to proceed.
```

```bash
spear spec approve spec-015 --reviewer @sarah
spear spec approve spec-015 --reviewer @mike
# => 2/3 approvals received. Spec approved.
```

### Pattern 4: Rotating Auditor

No one audits their own code. Rotate the auditor role:

```bash
spear config set audit.rotation true
spear config set audit.team '["@sarah", "@mike", "@alex", "@jordan"]'
```

SPEAR automatically assigns an auditor who was NOT an executor:

```
Plan plan-015:
  Executors: @alex, @jordan
  Eligible auditors: @sarah, @mike
  Assigned auditor: @sarah (least recent audit)
```

---

## Conflict Resolution

### Spec Disagreements

When reviewers disagree on a spec:

```bash
spear spec comment spec-015 --reviewer @alex \
  --comment "Acceptance criteria 5 is too strict for MVP. Suggest moving to spec-016."
```

The spec owner resolves conflicts and logs the decision:

```bash
spear memory log-decision \
  --description "Relaxed rate limiting for MVP (5 -> 10 per minute). Strict limit in spec-016." \
  --spec spec-015
```

### Plan Disagreements

When the plan owner and executor disagree on approach:

```bash
spear plan comment plan-015 --phase 2 \
  --author @jordan \
  --comment "REST endpoints won't support real-time. Propose WebSocket for Phase 2."
```

Plan revisions require plan owner approval:

```bash
spear plan revise plan-015 --phase 2 \
  --author @jordan \
  --approved-by @mike \
  --reason "Switched to WebSocket for real-time payment status updates"
```

### Audit Disagreements

When the executor disagrees with an audit finding:

```bash
spear audit challenge --finding SEC-005 \
  --challenger @alex \
  --argument "This is a false positive. The input is validated by the gateway."
```

The auditor reviews and decides:

```bash
# Accept the challenge
spear audit override --finding SEC-005 \
  --justification "Confirmed: gateway validates this input. See nginx.conf:45." \
  --approved-by @sarah

# Reject the challenge
spear audit reject-challenge --finding SEC-005 \
  --reason "Gateway config doesn't cover this specific input vector."
```

---

## Notifications

### Git-Based (Default)

SPEAR creates conventional commits that trigger existing notification systems:

```
chore(spear): spec-015 submitted for review [reviewers: @sarah, @mike, @alex]
chore(spear): plan-015 phase 2 completed by @jordan [fitness: 6/6 pass]
chore(spear): audit plan-015 - 1 CRITICAL finding [assigned: @sarah]
```

### Webhook Integration

```json
{
  "notifications": {
    "webhook_url": "https://hooks.slack.com/services/T.../B.../xxx",
    "events": ["spec_submitted", "audit_complete", "ratchet_failed", "critical_finding"]
  }
}
```

---

## AI Agent Teams

When using multiple AI agents as executors:

### Assignment

```markdown
---
executors:
  phase-1: claude-code    # Claude Code for backend
  phase-2: cursor         # Cursor for frontend
  phase-3: claude-code    # Claude Code for integration
auditor: copilot          # Copilot for independent review
---
```

### Context Passing

Each agent gets phase-specific context through its adapter:

```bash
# Before Phase 1 execution
spear adapt claude-code --phase plan-015/phase-1
# => Updates CLAUDE.md with Phase 1 context, fitness functions, constraints

# Before Phase 2 execution
spear adapt cursor --phase plan-015/phase-2
# => Updates .cursorrules with Phase 2 context
```

### Handoff Protocol

When one agent's phase completes and another's begins:

```bash
spear execute complete --plan plan-015 --phase 1
# => Phase 1 marked complete. 6/6 fitness functions pass.
# => Generating handoff context for Phase 2...
# => Handoff includes: files changed, key decisions, deviation log
```

The handoff context is automatically included in the next agent's adapter output.
