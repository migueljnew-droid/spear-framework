# Phase 3: Execute

The Execute phase is where code gets written. SPEAR does not dictate how you write code — use your preferred AI tool, IDE, or plain text editor. What SPEAR does is track progress, enforce checkpoints, log deviations, and verify fitness functions.

---

## Starting Execution

```bash
spear execute --plan plan-001 --phase 1
```

This does three things:
1. Loads the plan context (what you're building, fitness functions, dependencies)
2. Creates a checkpoint tracker for the phase
3. Sets the phase status to `in_progress`

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

## Execution Tips

1. **Commit early, commit often.** Small commits are easier to audit and revert.
2. **Run fitness functions after every significant change.** Don't wait for checkpoints.
3. **Log deviations in real time.** Reconstructing them later is unreliable.
4. **Don't skip checkpoints.** They take 30 seconds and catch drift early.
5. **If a phase is going off-plan, stop and revise the plan** rather than improvising. Documented revisions are fine; undocumented drift is not.
