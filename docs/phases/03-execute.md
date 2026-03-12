# Phase 3: Execute

The Execute phase is where code gets written — under strict discipline. SPEAR enforces TDD (RED-GREEN-REFACTOR per task), verification gates (evidence before claims), worktree isolation (clean baseline), and systematic debugging (no random fixes). Use your preferred AI tool, IDE, or plain text editor — SPEAR controls the process, not the tools.

---

## Starting Execution

```bash
spear execute --plan plan-001 --phase 1
```

This does five things:
1. Creates a **git worktree** on branch `spear/phase-1-[slug]` for isolation
2. Runs the **full test suite** to verify a clean baseline (all tests must pass before any changes)
3. Loads the plan context (what you're building, fitness functions, dependencies)
4. Creates a checkpoint tracker for the phase
5. Sets the phase status to `in_progress`

If you're using an adapter, this also updates your tool's configuration:

```bash
# Claude Code: updates CLAUDE.md with current phase context
# Cursor: updates .cursorrules with current phase context
# Copilot: updates copilot-instructions.md
```

---

## Atomic Commits and Conventional Messages

### Commit Convention

Every commit during execution should follow conventional commit format with the spec and phase reference:

```
feat(auth): add User model with bcrypt hashing [spec-001/phase-1]

- Created users table migration
- User model with create, findByEmail, verifyPassword
- Bcrypt utility with cost factor 12
- 4 unit tests passing
```

Format: `type(scope): description [spec-id/phase-n]`

Types:
- `feat` — New functionality
- `fix` — Bug fix
- `refactor` — Code restructuring without behavior change
- `test` — Adding or updating tests
- `docs` — Documentation changes
- `chore` — Build, config, dependency updates

### Why Atomic Commits Matter

1. **Audit traceability.** Each commit maps to a specific phase and spec.
2. **Rollback granularity.** If phase 3 fails audit, you can revert to end of phase 2.
3. **Review clarity.** Reviewers (human or AI) see focused, understandable diffs.

### Commit Tracking

SPEAR tracks commits associated with each phase:

```bash
spear execute commits --phase 1
# => 4 commits in phase 1:
# =>   abc1234 feat(auth): add users table migration [spec-001/phase-1]
# =>   def5678 feat(auth): add User model [spec-001/phase-1]
# =>   ghi9012 feat(auth): add bcrypt utility [spec-001/phase-1]
# =>   jkl3456 test(auth): add User model tests [spec-001/phase-1]
```

---

## Checkpoint Protocol

SPEAR prompts for status at 25%, 50%, 75%, and 100% of each phase. Checkpoints are based on task completion, not time.

### 25% Checkpoint — Foundation

```
Checkpoint: Phase 1 at 25%
  Completed: users table migration
  Remaining: User model, bcrypt utility, tests
  Fitness: (not yet runnable)
  Deviations: None

Continue? [y/n]
```

At 25%, SPEAR checks:
- Is the phase on track?
- Have any deviations from the plan occurred?

### 50% Checkpoint — Midpoint

```
Checkpoint: Phase 1 at 50%
  Completed: users table migration, User model
  Remaining: bcrypt utility, tests
  Fitness: User.create() returns object [PASS], User.findByEmail() [PASS]
  Deviations: None

Continue? [y/n]
```

At 50%, SPEAR checks:
- Are available fitness functions passing?
- Is the implementation matching the plan?

### 75% Checkpoint — Integration

```
Checkpoint: Phase 1 at 75%
  Completed: migration, User model, bcrypt utility
  Remaining: unit tests
  Fitness: All 3 model functions pass, hash is 60 chars [PASS]
  Deviations: Added index on email column (not in plan)

Continue? [y/n]
```

At 75%, SPEAR checks:
- Are all fitness functions that can run passing?
- Are deviations logged?

### 100% Checkpoint — Completion

```
Checkpoint: Phase 1 at 100%
  Completed: All tasks
  Fitness: 4/4 passing
  Deviations: 1 (email index — improvement, not regression)

Phase 1 complete. Run 'spear execute --plan plan-001 --phase 2' to continue.
```

At 100%, all fitness functions must pass. If any fail, the phase cannot be marked complete.

---

## Deviation Logging

Deviations are differences between the plan and what actually happened. They are not failures — they are documentation.

### Types of Deviations

**Addition:** Something was added that wasn't in the plan.
```bash
spear execute deviate --type addition \
  --description "Added unique index on users.email for query performance"
```

**Change:** A planned approach was modified.
```bash
spear execute deviate --type change \
  --description "Used argon2 instead of bcrypt — better resistance to GPU attacks" \
  --reason "Research during phase showed argon2id is now OWASP preferred"
```

**Removal:** A planned task was dropped.
```bash
spear execute deviate --type removal \
  --description "Dropped separate hashing utility — integrated into User model" \
  --reason "Single function, not worth a separate module"
```

**Blocker:** Something prevented progress.
```bash
spear execute deviate --type blocker \
  --description "Redis not available in dev environment" \
  --impact "Phase 3 rate limiting will need in-memory fallback"
```

### Why Log Deviations

1. **Audit uses them.** The auditor compares plan vs actual. Deviations explain gaps.
2. **Memory captures them.** Future specs reference what was learned.
3. **Ratchet adjusts.** Recurring deviations of the same type trigger process improvements.

---

## Running Fitness Functions During Execution

Don't wait until 100% to check fitness functions. Run them continuously:

```bash
spear fitness --plan plan-001 --phase 1
```

```
Fitness Functions for Phase 1:
  [PASS] npm test -- --grep "User model" (4 tests, 0 failures)
  [PASS] npm run migrate (exit code 0)
  [PASS] User.create stores 60-char hash
  [PASS] User.findByEmail returns user or null
  [PASS] User.verifyPassword returns boolean

All fitness functions passing.
```

If a fitness function fails mid-phase:

```
Fitness Functions for Phase 1:
  [PASS] npm test -- --grep "User model" (3 tests, 0 failures)
  [PASS] npm run migrate (exit code 0)
  [FAIL] User.create stores 60-char hash
         Expected: 60 characters
         Actual: 128 characters (sha512 hash detected — wrong algorithm)
  [SKIP] User.findByEmail (depends on create)
  [SKIP] User.verifyPassword (depends on create)

1 failure. Fix before proceeding.
```

Fix the issue immediately. Fitness function failures that persist to a checkpoint are flagged in the audit.

---

## Example: Executing the Auth Feature

### Phase 1 Execution

```bash
spear execute --plan plan-001 --phase 1
# => Phase 1 started: Data Layer
# => 4 tasks, 5 fitness functions
# => Checkpoint schedule: 25% (1 task), 50% (2 tasks), 75% (3 tasks), 100% (4 tasks)
```

Build the migration:

```bash
git commit -m "feat(auth): add users table migration [spec-001/phase-1]"
spear execute progress --tasks-done 1
# => Phase 1: 25% — checkpoint triggered
```

Build the model:

```bash
git commit -m "feat(auth): add User model with CRUD operations [spec-001/phase-1]"
spear execute progress --tasks-done 2
# => Phase 1: 50% — checkpoint triggered
# => Running available fitness functions...
# => [PASS] User.create returns object
# => [PASS] User.findByEmail works
```

Build the hashing:

```bash
git commit -m "feat(auth): add bcrypt hashing utility [spec-001/phase-1]"
spear execute progress --tasks-done 3
# => Phase 1: 75% — checkpoint triggered
```

Write tests:

```bash
git commit -m "test(auth): add User model unit tests [spec-001/phase-1]"
spear execute progress --tasks-done 4
# => Phase 1: 100% — final checkpoint
# => All 5 fitness functions passing
# => Phase 1 complete. 1 deviation logged (email index addition).
```

### Moving to Phase 2

```bash
spear execute --plan plan-001 --phase 2
# => Dependency check: Phase 1 [COMPLETE] — OK
# => Phase 2 started: Auth Endpoints
```

Repeat the same cycle: build, commit, checkpoint, fitness check.

---

## TDD Enforcement — The Iron Law

> **No production code without a failing test first.** Code written before a test exists gets deleted. No exceptions.

Every task that produces code must follow the RED-GREEN-REFACTOR cycle:

### RED — Write a Failing Test
- Write one minimal test demonstrating desired behavior
- Run it and confirm it **fails for the right reason** (missing feature, not syntax error)
- If the test passes immediately, you're testing existing functionality — rewrite it

### GREEN — Write Minimal Implementation
- Write the simplest code that makes the test pass
- No feature additions beyond what the test requires
- No refactoring yet

### REFACTOR — Clean Up (only after green)
- Remove duplication, improve naming, extract helpers if warranted
- All tests must stay green throughout

### Record the Cycle
Fill out `.spear/templates/execute/tdd-cycle.md` for each task. This is proof the cycle was followed, not optional documentation.

### Invalid Excuses (all of these are wrong)

| Excuse | Reality |
|--------|---------|
| "Too simple to test" | Simple code still breaks. 30 seconds. |
| "I'll test after" | Tests-after verify existing code. Tests-first specify requirements. |
| "Need exploration first" | Explore, discard, restart with TDD. |
| "TDD slows me down" | TDD is faster than debugging. Always. |

### Red Flags — Delete and Restart

If any of these are true, delete the code and begin with a failing test:
- Code was written before a test exists
- Test passes on first run without investigation
- Cannot articulate why the test initially failed

---

## Verification-Before-Completion Gate

> **Evidence before claims, always.**

Before ANY success claim (task done, test passing, build clean, bug fixed), follow the **5-step gate**:

1. **Identify** the verification command that proves the assertion
2. **Run** the complete command fresh (not from memory, not from cache)
3. **Read** the full output — every line, every warning, every exit code
4. **Verify** the output actually confirms the claim
5. **Only then** state the claim, with evidence

### Banned Language

These words in execution reports indicate unverified claims:
- "should work" → Run it and confirm
- "probably passes" → Run the tests
- "seems to be fixed" → Reproduce the original bug and verify
- "looks good" → What specific output proves this?

---

## Systematic Debugging

When a task fails due to a bug, invoke the debugging protocol (`.spear/agents/debugger.md`):

1. **Root Cause Investigation** — Read errors fully, reproduce consistently, check recent changes, trace data flow
2. **Pattern Analysis** — Compare broken code against working examples
3. **Hypothesis Testing** — State "I think X because Y", change one variable at a time
4. **Implementation** — Write failing test, implement single fix, verify

**The 3-Strike Rule:** If 3+ fix attempts fail, STOP. This is architectural. Escalate to human partner.

---

## Subagent Execution (for complex phases)

For phases with 5+ tasks, consider subagent execution (`.spear/agents/subagent-executor.md`):

- **Fresh agent per task** — prevents context pollution
- **Two-stage review** — spec compliance first, then code quality
- **Model routing** — mechanical tasks → cheap model, architecture → best model
- **Parallel dispatch** — independent tasks (no shared files) run concurrently
- **Merge protocol** — review summaries → conflict detection → full suite test → spot check

---

## Execution Tips

1. **TDD first, always.** Write the test, watch it fail, then implement. No exceptions.
2. **Verify before claiming.** Run the command, read the output, then state the result.
3. **Commit early, commit often.** Small atomic commits are easier to audit and revert.
4. **Run fitness functions after every significant change.** Don't wait for checkpoints.
5. **Log deviations in real time.** Reconstructing them later is unreliable.
6. **Don't skip checkpoints.** They take 30 seconds and catch drift early.
7. **If a bug appears, follow the protocol.** Root cause first. No random fixes.
8. **If a phase is going off-plan, stop and revise the plan** rather than improvising.
