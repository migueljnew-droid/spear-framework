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

## Step 1: Read Inputs & Refresh Capability Registry

Read the following files:

1. `.spear/output/spec/prd.md` -- the approved PRD
2. `.spear/output/spec/architecture.md` -- architecture decisions
3. `.spear/output/spec/shards/` -- all epic shards
4. `.spear/ratchet/ratchet.json` -- current thresholds and rules
5. `.spear/memory/` -- lessons from previous phases (what worked, what failed)
6. `.spear/capability-registry.json` -- the Capability Registry (skills, agents, MCP tools, deps)
7. `.spear/output/spec/requirement-challenge.md` -- which requirements survived and why
8. `.spear/output/spec/deletion-proposal.md` -- what was marked for deletion

If the capability registry doesn't exist or is stale (>1 cycle old), refresh it:
- Re-scan all sources (skills, agents, MCP tools, dependencies)
- Update `.spear/capability-registry.json`

Summarize: how many shards, overall scope, current ratchet state, and how many
capabilities are available for this phase.

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
| # | Task | Effort | Dependencies | Success Criterion | Capability |
|---|------|--------|-------------|-------------------|------------|

Every task needs:
- Clear description (action verb + deliverable)
- Input: what files/state it reads
- Output: what files/state it changes
- Success criterion: how to verify it is done
- Effort estimate: S (< 1hr), M (1-4hr), L (4hr+)
- **Capability**: which registered skill/agent/MCP tool/dependency is used (or "manual" if none)

### Capabilities Used
Add a section to the phase plan listing all registered capabilities that will be used:

```markdown
## Capabilities Used
| Capability | Type | Phase Timing | Tasks |
|-----------|------|-------------|-------|
| [name] | skill/agent/mcp/dep | continuous/post-write/post-phase/at-commit | T1, T3 |
```

Follow the routing decision tree from `.spear/references/capability-registry.md`:
1. Registered SKILL → use Skill tool
2. SOVEREIGN AGENT → use mcp__council__invoke_agent
3. MCP TOOL → use directly
4. Claude Code AGENT → use Agent tool
5. Installed DEPENDENCY → write code using it
6. None → build it (flag as new capability)

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

## Step 5: Risk Assessment (6 Attack Vectors)

Before finalizing the plan, run Devil's Advocate against it. Attack the plan
across all 6 vectors. This is not optional -- every plan has cracks.

### The 6 Attack Vectors

1. **Logic** -- Does the reasoning hold? Are there logical fallacies? What
   evidence would disprove this approach?

2. **Audience** -- Would the target users actually respond this way? What if
   they hate it? Are we projecting our preferences onto them?

3. **Execution** -- What could go wrong during implementation? What dependencies
   could fail? What happens if the timeline slips?

4. **Competition** -- How would a competitor counter this? Is this already being
   done better by someone else? What is our actual edge?

5. **Worst Case** -- What is the absolute worst outcome? How likely is it?
   Can we survive it? What is the recovery plan?

6. **Scale** -- Does this work at 10x volume? Does this work with half the
   resources? What breaks first under pressure?

### Risk Matrix

After running all 6 vectors, document findings:

| # | Risk | Vector | Likelihood (1-5) | Impact (1-5) | Score (L x I) | Mitigation |
|---|------|--------|-----------------|-------------|---------------|------------|

**Any risk scoring 15+ (Likelihood x Impact) must have a mitigation plan
before execution begins. No exceptions.**

### Rollback Strategy

For each phase:
- What to roll back to (commit, state, checkpoint)
- How to roll back (exact steps)
- Irreversible changes (data migrations, etc.)

## Step 6: Self-Audit Checklist

### Capability Registry
- [ ] Capability registry loaded and current (refreshed if stale)
- [ ] Every task specifies which registered capability implements it (or "manual")
- [ ] "Capabilities Used" section included in phase plan
- [ ] Routing decision tree followed (skill → agent → MCP → dep → build)
- [ ] No task rebuilds functionality already available in a registered capability

### Plan Quality
- [ ] Every acceptance criterion from spec maps to at least one task
- [ ] Tasks ordered by dependency -- no task before its prerequisites
- [ ] Each task is atomic and has a measurable success criterion
- [ ] Fitness functions defined for all metrics
- [ ] Non-functional fitness functions included
- [ ] All 6 attack vectors evaluated (logic, audience, execution, competition, worst case, scale)
- [ ] Risk matrix produced with scores -- all risks scoring 15+ have mitigation plans
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
