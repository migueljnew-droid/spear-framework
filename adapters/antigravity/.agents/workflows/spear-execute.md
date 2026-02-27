# SPEAR Execute Workflow -- Antigravity Format
#
# INSTALLATION: Copy .agents/ directory to your project root.
# Trigger: User has approved a phase plan and is ready to implement.

name: SPEAR Execution
description: Implement one phase plan with atomic commits and checkpoints
trigger: Phase plan approved, user invokes execution

## Prerequisites
- Phase plan exists in `.spear/output/plan/`
- Fitness functions defined
- Ratchet state is current in `.spear/ratchet/ratchet.json`

## Steps

### Step 1: Pre-Execution Setup
- Read the entire phase plan (all tasks, dependencies, success criteria)
- Read ratchet state and know the thresholds
- Verify prerequisite phases are complete
- Read relevant code files to understand existing patterns

Output: Report which phase, task count, ratchet constraints.

### Step 2: Task Execution Loop
For each task in the phase plan (in order):

1. **Announce** which task is starting
2. **Read** any files that will be modified
3. **Implement** the task according to its description
4. **Test** -- run tests for the task's success criterion
5. **Commit** with conventional format: `type(scope): description`
   - One logical change per commit
   - Body explains WHY, refs SHARD-NNN and PHASE-NNN
6. **Deviation check** -- if anything differs from the plan:
   - Log using `.spear/templates/execute/deviation-log.md`
   - Include: planned vs actual, reason, impact

### Step 3: Checkpoint (at 25%, 50%, 75%, 100%)
At each milestone:
1. Run all fitness functions
2. Record results using `.spear/templates/execute/checkpoint.md`
3. Compare to ratchet thresholds
4. If any function regresses: STOP and report to user
5. Write checkpoint to `.spear/output/execute/checkpoints/`

### Step 4: Code Standards Enforcement
Throughout execution, enforce:
- Match existing codebase patterns and conventions
- Tests alongside code (never deferred)
- Explicit error handling (no swallowed errors)
- No hardcoded secrets, magic numbers, or config in code
- Functions under 50 lines where possible

### Step 5: Post-Execution
After all tasks complete:
1. Run the FULL test suite (not just new tests)
2. Run ALL fitness functions and record final values
3. Produce execution report at `.spear/output/execute/execution-report.md`:
   - Task summary with statuses
   - Deviations logged
   - All checkpoint results
   - Final fitness function values
   - List of all commits

### Step 6: Transition
Inform user: "Phase [N] execution complete. [N] tasks, [N] deviations,
fitness functions [status]. Ready for audit?"

Do not proceed to audit without user confirmation.
