# Adapter: Claude Code

Configure SPEAR to work with Claude Code via CLAUDE.md files, slash commands, and task agents.

---

## Installation

```bash
# Install SPEAR with Claude Code adapter
./install.sh --adapter=claude-code
```

> **Note:** The `spear adapt` CLI commands shown in this guide are planned for v2.0.
> For now, use `install.sh` or manually copy adapter files from `adapters/claude-code/`.

This creates or updates:
- `CLAUDE.md` — Project instructions with SPEAR context
- `.claude/commands/` — Slash commands for SPEAR phases

---

## How SPEAR Maps to Claude Code

| SPEAR Concept | Claude Code Equivalent |
|---------------|----------------------|
| Spec | Section in CLAUDE.md ("Current Spec") |
| Plan | Section in CLAUDE.md ("Current Plan") |
| Fitness functions | Bash commands in CLAUDE.md |
| Audit rules | Instructions in CLAUDE.md |
| Memory | `.claude/memories/` or CLAUDE.md context |
| Phase execution | Slash command `/spear-execute` |

---

## Generated CLAUDE.md Structure

```markdown
# Project Instructions

## SPEAR Framework Active

Current cycle: spec-015 / plan-015 / phase-2

### Current Spec
[Injected from .spear/specs/spec-015.md]

### Current Plan — Phase 2
[Injected from .spear/plans/plan-015.md, filtered to phase 2]

### Fitness Functions
Run these after making changes:
- `npm test -- --grep "payment endpoints"` (must pass, 6+ tests)
- `curl -s localhost:3000/api/health | jq .status` (must equal "ok")

### Audit Rules
- All exported functions must have JSDoc
- No secrets in source code
- All inputs must be validated before use
- Error responses must not contain stack traces

### Commit Convention
Format: `type(scope): description [spec-015/phase-2]`
Types: feat, fix, refactor, test, docs, chore

### Deviation Protocol
If you deviate from the plan, log the deviation:
`echo "DEVIATION: [type] [description]" >> .spear/deviations-active.log`
```

---

## Slash Commands

### `/spear-execute`

Starts or continues execution of the current phase:

```bash
# .claude/commands/spear-execute.md
Execute the current SPEAR phase. Check the plan section in CLAUDE.md for tasks.
After each significant change:
1. Run the fitness functions listed in CLAUDE.md
2. Commit with the conventional format
3. Report which tasks are complete
```

### `/spear-audit`

Runs the audit from within Claude Code:

```bash
# .claude/commands/spear-audit.md
Run the SPEAR audit. Execute: `spear audit --plan [current-plan] --ci`
Review each finding and suggest fixes for HIGH and CRITICAL items.
```

### `/spear-checkpoint`

Reports checkpoint status:

```bash
# .claude/commands/spear-checkpoint.md
Report current phase progress:
1. List completed tasks from the plan
2. Run all fitness functions and report results
3. Note any deviations from the plan
4. Estimate completion percentage
```

---

## Phase Transitions

When moving between phases, regenerate the adapter:

```bash
# Complete phase 1, prepare for phase 2
spear execute complete --plan plan-015 --phase 1
spear adapt claude-code --phase plan-015/phase-2
```

This updates CLAUDE.md with:
- Phase 2 tasks and fitness functions
- Handoff context from phase 1 (files changed, decisions made)
- Updated audit rules (including any new rules from phase 1)

---

## Using Claude Code Task Agents

For parallel phase execution, use Claude Code's sub-agent capability:

```markdown
### Phase 2a: Payment Model (parallel)
Task: Build the Payment model and migration.
Fitness: `npm test -- --grep "Payment model"` passes.

### Phase 2b: Webhook Handler (parallel)
Task: Build the Stripe webhook handler.
Fitness: `npm test -- --grep "webhook"` passes.
```

Each sub-task can be dispatched as a Claude Code Task agent, working in parallel while respecting the plan.

---

## Memory Integration

Claude Code's memory system maps to SPEAR's:

```bash
# SPEAR decisions appear in Claude Code context
spear memory sync claude-code
# => Synced 15 decisions to .claude/memories/spear-decisions.md
```

Key decisions are included in CLAUDE.md automatically:

```markdown
### Key Decisions
- DEC-012: Using bcrypt for password hashing (cost factor 12)
- DEC-018: JWT with 1-hour expiry, no refresh tokens for MVP
- DEC-025: Redis for rate limiting (express-rate-limit + rate-limit-redis)
```

---

## Troubleshooting

### CLAUDE.md is too long

SPEAR only injects the current phase, not the entire plan. If CLAUDE.md is still too long:

```bash
spear adapt claude-code --minimal
# => Only includes: current phase tasks, fitness functions, and top 5 audit rules
```

### Fitness functions require a running server

Add a server start instruction:

```markdown
### Before Running Fitness Functions
Start the dev server: `npm run dev &`
Wait for "Server ready on port 3000" before running HTTP-based checks.
```

### Claude Code doesn't follow the commit convention

Add explicit instructions in CLAUDE.md:

```markdown
### MANDATORY: Commit Format
Every commit MUST follow this format:
`type(scope): description [spec-015/phase-2]`

Do NOT use any other commit format. This is required for audit traceability.
```
