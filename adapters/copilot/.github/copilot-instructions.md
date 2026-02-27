# SPEAR Framework -- GitHub Copilot Instructions
#
# INSTALLATION: Copy this file to .github/copilot-instructions.md in your project.
# Ensure .spear/ directory exists (run: spear init).
#
# This file provides SPEAR methodology context to GitHub Copilot.
# Reference: .spear/SPEAR.md for the full framework definition.

## Development Methodology

This project follows the SPEAR framework: a 5-phase development methodology
with mandatory audit gates and a learning ratchet.

**Phases:** Spec -> Plan -> Execute -> Audit -> Ratchet

Phases are sequential. Never skip a phase. Audit failure returns to Execute.

## Phase Rules

### Spec Phase
- Gather requirements and produce: PRD, architecture doc, epic shards
- Read `.spear/memory/` for past decisions before writing specs
- Use templates from `.spear/templates/spec/`
- No implementation code during Spec

### Plan Phase
- Break spec into atomic tasks with measurable success criteria
- Define fitness functions for every tracked metric
- Order tasks by dependency graph
- Plan only the next phase in detail
- Use templates from `.spear/templates/plan/`

### Execute Phase
- Follow the phase plan task by task
- Atomic commits with conventional messages: `type(scope): description`
- Types: feat, fix, refactor, test, docs, chore, perf
- Read files before modifying -- match existing patterns
- Write tests alongside code, never defer
- Log deviations from the plan immediately
- Run fitness functions at 25/50/75/100% checkpoints
- Stop on any fitness function regression

### Audit Phase
- Review all changes across 6 categories (see below)
- Produce findings with severity levels
- Verdict: GO (zero CRITICAL, zero unresolved HIGH), CONDITIONAL GO, or NO-GO

### Ratchet Phase
- Tighten thresholds when metrics improve by >5%
- Generate rules from HIGH+ findings
- Record decisions, patterns, and antipatterns in memory
- Quality only goes up -- ratchet is monotonic

## Audit Categories

1. **Security** (blocks: CRITICAL) -- secrets, injection, auth, OWASP Top 10
2. **Dependencies** (blocks: CRITICAL) -- CVEs, licenses, pinned versions
3. **Performance** (blocks: HIGH) -- complexity, N+1 queries, bundle size
4. **Code Quality** (blocks: HIGH) -- duplication, dead code, error handling, tests
5. **Documentation** (blocks: CRITICAL) -- API docs, README, changelog
6. **Architecture** (blocks: HIGH) -- layer violations, circular deps, patterns

## Severity Levels

- **CRITICAL**: Must fix. No override. Security vulnerability or data loss risk.
- **HIGH**: Fix or provide written justification.
- **MEDIUM**: Fix in current or next cycle.
- **LOW**: Track and fix opportunistically.
- **INFO**: Observation only.

## Code Standards

When generating or suggesting code, follow these rules:

1. **Match existing patterns.** Read surrounding code and match its style,
   error handling, logging, and naming conventions.
2. **Explicit error handling.** No empty catch blocks or swallowed errors.
3. **No hardcoded values.** Config in files or env vars. Named constants.
4. **Tests alongside code.** Generate tests with implementation.
5. **Function size.** Keep under 50 lines. Split larger functions.
6. **Conventional commits.** Format: `type(scope): imperative description`

## Ratchet Thresholds

Current thresholds are in `.spear/ratchet/ratchet.json`.
- Floor metrics (must stay above): test_coverage, doc_coverage
- Ceiling metrics (must stay below): max_complexity, max_bundle_size, max_build_time
- Never regress a threshold without written justification

## Memory System

Check `.spear/memory/` before architectural suggestions:
- `decisions/` -- Architecture Decision Records
- `patterns/` -- Established code patterns
- `antipatterns/` -- Known failures to avoid
- `findings/` -- Archived audit findings

## Templates

Structured outputs use `.spear/templates/`:
- `spec/`: prd.md, architecture.md, epic-shard.md
- `plan/`: phase-plan.md, fitness-function.md, research-brief.md
- `execute/`: task-commit.md, deviation-log.md, checkpoint.md
