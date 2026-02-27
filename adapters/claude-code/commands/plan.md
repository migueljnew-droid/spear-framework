# /plan -- SPEAR Plan Phase

# INSTALLATION: Copy this file to .claude/commands/plan.md in your project.
# Usage: Type /plan in Claude Code to invoke this command.

You are entering the **Plan phase** of the SPEAR framework. Your job is to
break the approved spec into executable phase plans with measurable success
criteria, fitness functions, and rollback strategies.

## Prerequisites

Before proceeding, verify:
1. Spec phase outputs exist in `.spear/output/spec/`
2. PRD, architecture doc, and at least one shard are present
3. All research briefs are resolved (status != "open")

If prerequisites are not met, tell the user what is missing and suggest
running `/spec` first.

## Step 1: Read Inputs

Read the following files:

1. `.spear/output/spec/prd.md` -- the approved PRD
2. `.spear/output/spec/architecture.md` -- architecture decisions
3. `.spear/output/spec/shards/` -- all epic shards
4. `.spear/ratchet/ratchet.json` -- current thresholds and rules
5. `.spear/memory/` -- lessons from previous phases (what worked, what failed)

Summarize: how many shards, what the overall scope is, current ratchet state.

## Step 2: Define Phases

For each shard (or group of related shards), create a phase:

- **One phase at a time.** Produce a detailed plan only for Phase 1.
  Future phases get a one-paragraph summary.
- **Order by dependency.** Foundational work first. No phase depends
  on a later phase.
- **Atomic tasks.** Each task within a phase must be completable in a
  single work session. If a task feels too large, split it.

## Step 3: Create Phase Plan

Use template: `.spear/templates/plan/phase-plan.md`
Write to: `.spear/output/plan/PHASE-001-[name].md`

Each phase plan must include:

### Tasks Table
| # | Task | Effort | Dependencies | Success Criterion |
|---|------|--------|-------------|-------------------|

Every task needs:
- Clear description (action verb + deliverable)
- Input: what files/state it reads
- Output: what files/state it changes
- Success criterion: how to verify it is done
- Effort estimate: S (< 1hr), M (1-4hr), L (4hr+)

### Task Ordering
Build a dependency graph. Tasks with no dependencies come first.
Tasks with the most dependents come before tasks with fewer.

## Step 4: Define Fitness Functions

Use template: `.spear/templates/plan/fitness-function.md`
Write to: `.spear/output/plan/fitness-functions.md`

For every metric that matters, define:
- **Name**: descriptive (e.g., `api-response-time-p95`)
- **What it measures**: precise definition
- **How to measure**: exact command, tool, or script
- **Current value**: from ratchet or baseline
- **Target value**: from spec acceptance criteria
- **Threshold**: minimum acceptable (ratchet floor/ceiling)
- **Direction**: higher-is-better or lower-is-better

Always include these non-functional fitness functions:
- Test pass rate (must be 100%)
- Test coverage delta (must not decrease)
- Build time (should not increase significantly)
- Lint/clippy clean (zero warnings)

## Step 5: Risk Assessment

For each phase, identify risks:

| Risk | Likelihood | Impact | Mitigation | Contingency |
|------|-----------|--------|------------|-------------|

And a rollback strategy:
- What to roll back to (commit, state, checkpoint)
- How to roll back (exact steps)
- Irreversible changes (data migrations, etc.)

## Step 6: Self-Audit Checklist

- [ ] Every acceptance criterion from spec maps to at least one task
- [ ] Tasks ordered by dependency -- no task before its prerequisites
- [ ] Each task is atomic and has a measurable success criterion
- [ ] Fitness functions defined for all metrics
- [ ] Non-functional fitness functions included
- [ ] Risks identified with mitigation and contingency
- [ ] Rollback strategy documented
- [ ] Only next phase planned in detail -- future phases are summaries
- [ ] No ratchet rules violated by the plan
- [ ] Memory consulted for lessons from previous work

## Step 7: Present Plan

Show the user:
1. Phase 1 task list with effort estimates
2. Total estimated effort for Phase 1
3. Fitness functions that will be tracked
4. Top risks and mitigations
5. Summary of future phases

Ask: "Ready to approve this plan and move to Execute phase?"

The Plan phase is complete only when the user approves the phase plan.
