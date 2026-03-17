# /execute -- SPEAR Execute Phase

# INSTALLATION: Copy this file to .claude/commands/execute.md in your project.
# Usage: Type /execute in Claude Code to invoke this command.

You are entering the **Execute phase** of the SPEAR framework. Your job is
to implement the approved phase plan. One phase at a time. Atomic commits.
Follow the plan or log deviations.

## Prerequisites

Before proceeding, verify:
1. Phase plan exists in `.spear/output/plan/`
2. Fitness functions are defined
3. Ratchet state is current

If prerequisites are not met, tell the user what is missing and suggest
running `/plan` first.

## Step 1: Pre-Execution Setup

1. **Read the phase plan.** Read the entire plan -- all tasks, dependencies,
   and success criteria. Understand the full picture before writing code.
2. **Check ratchet rules.** Read `.spear/ratchet/ratchet.json`. Know the
   thresholds you must not violate. If unclear, stop and ask.
3. **Verify prerequisites.** Confirm prior phases are complete and their
   fitness functions are green.
4. **Read relevant code.** Before modifying any file, read it first.
   Match existing patterns, conventions, and style.
5. **Load the Capability Registry.** Read `.spear/capability-registry.json`.
   For each task in the phase plan, note which registered capability is assigned.
   Load the "Capabilities Used" section from the phase plan. Categorize by timing:
   - **continuous**: use throughout execution (skills like senior-fullstack)
   - **post-write**: invoke after writing code (code-review, testing)
   - **at-commit**: invoke at commit time (commit-commands, lint)
   - **post-phase**: invoke after all tasks (audit prep, PR review)
   - **on-demand**: invoke when specific domain knowledge is needed (SOVEREIGN agents)
6. **Record start timestamp.** Note the time execution begins (for cycle time tracking).

Report: which phase you are executing, how many tasks, current ratchet state,
and which capabilities are loaded for this phase.

## Step 2: Execute Tasks in Order

Follow the task order from the phase plan. For each task:

1. **Announce the task.** State which task you are working on and which
   registered capability (if any) is assigned to it.
2. **Use the assigned capability.** If the task has a registered capability:
   - **Skill** → invoke via Skill tool
   - **SOVEREIGN agent** → invoke via `mcp__council__invoke_agent`
   - **MCP tool** → call directly
   - **Claude Code agent** → dispatch via Agent tool
   - **Dependency** → write code using the dependency
   - **"manual"** → implement from scratch
   If the assigned capability is unavailable, fall back to manual and log a deviation.
3. **Implement.** Write code, tests, and docs as specified.
4. **Atomic commits.** Each commit must:
   - Contain exactly one logical change
   - Use conventional commit format: `type(scope): description`
   - Leave the codebase buildable and testable
   - Reference the shard and phase: `Refs: SHARD-NNN, PHASE-NNN`
5. **Verify.** Run tests and fitness functions for the task's success criterion.
6. **Post-write capabilities.** After writing code, invoke any capabilities
   with `post-write` timing (e.g., code-review skills, testing agents).
7. **Log deviations.** If you deviate from the plan, immediately log it using
   `.spear/templates/execute/deviation-log.md`. Include: what was planned,
   what you did instead, why, and impact on subsequent tasks.

### Commit Types
- `feat` -- new feature or capability
- `fix` -- bug fix
- `refactor` -- restructuring, no behavior change
- `test` -- adding or updating tests only
- `docs` -- documentation changes only
- `chore` -- build, tooling, dependency updates
- `perf` -- performance improvement

## Step 3: Checkpoints

At 25%, 50%, 75%, and 100% of tasks completed:

1. Run all fitness functions
2. Record results using `.spear/templates/execute/checkpoint.md`
3. Compare to thresholds
4. If any fitness function regresses, STOP and assess before continuing
5. Report checkpoint status to the user

Write checkpoints to: `.spear/output/execute/checkpoints/CP-[NNN].md`

## Step 4: Code Quality Standards

Follow these non-negotiable standards during execution:

- **Match existing patterns.** Consistency beats personal preference.
- **Write tests alongside code.** Never defer tests. Every task that produces
  code must include tests verifying its success criterion.
- **Handle errors explicitly.** No swallowed errors. No empty catch blocks.
  Every error path handled with logging, propagation, or recovery.
- **No hardcoded values.** Config in config files or env vars. Magic numbers
  get named constants. Secrets never in code.

## Step 5: Post-Execution

After all tasks are complete:

1. **Run the full test suite.** Not just new tests -- everything.
2. **Run all fitness functions.** Record final values.
3. **Invoke post-phase capabilities.** Run any capabilities with `post-phase`
   timing (e.g., code-reviewer agent, PR test analyzer, type design analyzer).
   These run in parallel if independent. Log their findings.
4. **Record end timestamp.** Note the time execution completes (for cycle time tracking).
5. **Produce the execution report.** Write to `.spear/output/execute/execution-report.md`:
   - Summary of what was done
   - Any deviations from the plan
   - All checkpoint results
   - Final fitness function values
   - List of all commits
   - **Capability utilization**: which registered capabilities were used vs. available
   - **Phase duration**: start → end timestamp (feeds ratchet cycle time tracking)

## Step 6: Self-Audit Checklist

### Capability Registry
- [ ] Registry loaded at pre-execution (Step 1.5)
- [ ] Each task used its assigned capability (or deviation logged)
- [ ] Post-write capabilities invoked after code changes
- [ ] Post-phase capabilities invoked after all tasks
- [ ] Capability utilization recorded in execution report
- [ ] No task rebuilt functionality available in a registered capability

### Execution Quality
- [ ] Phase plan followed completely (or all deviations logged)
- [ ] All commits are atomic with conventional messages
- [ ] All tests pass -- both new and existing
- [ ] All fitness functions green -- no ratchet regressions
- [ ] Checkpoints recorded at 25%, 50%, 75%, 100%
- [ ] No hardcoded secrets, magic numbers, or config in code
- [ ] Error handling is explicit everywhere
- [ ] Existing codebase patterns matched, not replaced
- [ ] Execution report is complete (including capability utilization + phase duration)
- [ ] Every file was read before being modified
- [ ] Start and end timestamps recorded for cycle time tracking

## Transition

When execution is complete, inform the user:
"Phase [N] execution complete. [N] tasks done, [N] deviations logged,
all fitness functions [green/yellow/red]. Ready to run /audit?"

Do NOT proceed to audit automatically. Wait for user confirmation.
