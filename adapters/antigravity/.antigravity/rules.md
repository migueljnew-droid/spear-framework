# SPEAR Framework -- Antigravity (Google) Project Rules
#
# INSTALLATION: Copy the .antigravity/ and .agents/ directories to your project root.
# Ensure .spear/ directory exists (run: spear init).
#
# This file defines SPEAR methodology rules for Google's Antigravity AI tool.
# Reference: .spear/SPEAR.md for the full framework definition.

## Framework Overview

This project follows SPEAR: a 5-phase, audit-gated, self-improving development
methodology.

Phases: **Spec** -> **Plan** -> **Execute** -> **Audit** -> **Ratchet**

Rules:
1. Phases are sequential. Never skip.
2. Audit failure returns to Execute.
3. Ratchet never loosens silently -- all changes logged.
4. Memory persists across cycles.
5. Deviations are logged, not hidden.

## Phase-Specific Rules

### Spec
- Read `.spear/memory/` before writing any specification
- Produce PRD, architecture doc, and epic shards using `.spear/templates/spec/`
- No implementation code during Spec phase
- Every goal must be testable, every acceptance criterion verifiable

### Plan
- Read approved spec and ratchet state before planning
- One phase at a time -- detailed plan for next phase only
- Every task must be atomic with measurable success criteria
- Define fitness functions for all tracked metrics
- Include rollback strategy for every phase

### Execute
- Follow the plan. Log deviations immediately.
- Atomic commits: `type(scope): description`
- Read files before modifying -- match existing patterns
- Tests alongside code, never deferred
- Checkpoints at 25%, 50%, 75%, 100% of tasks

### Audit
- Independent review across 6 categories
- CRITICAL findings block deployment (no override)
- HIGH findings require fix or written justification
- All findings must include file path, evidence, and recommendation

### Ratchet
- Auto-tighten thresholds on >5% improvement (2% buffer)
- Generate rules from HIGH+ audit findings
- Record decisions and patterns in `.spear/memory/`
- Update `.spear/ratchet/ratchet.json`

## Audit Categories

| Category | Blocks On | Focus Areas |
|----------|-----------|-------------|
| Security | CRITICAL | Secrets, injection, auth, OWASP Top 10 |
| Dependencies | CRITICAL | CVEs, licenses, pinned versions |
| Performance | HIGH | Complexity, N+1, bundle size, memory |
| Code Quality | HIGH | Duplication, dead code, error handling |
| Documentation | CRITICAL | API docs, README, changelog |
| Architecture | HIGH | Layer violations, circular deps, patterns |

## Code Standards

- Match existing codebase patterns
- Explicit error handling (no swallowed errors)
- No hardcoded config, secrets, or magic numbers
- Tests for all new code
- Functions under 50 lines
- Conventional commit messages

## Ratchet Thresholds

Read `.spear/ratchet/ratchet.json` for current values.
Floor metrics (test_coverage, doc_coverage): must stay above threshold.
Ceiling metrics (max_complexity, max_bundle_size, max_build_time): must stay below.

## Workflows

SPEAR phase workflows are available in `.agents/workflows/`:
- `spear-spec.md` -- Specification phase workflow
- `spear-execute.md` -- Execution phase workflow
- `spear-audit.md` -- Audit phase workflow

## Audit Rules

Detailed audit rules are in `.agents/rules/`:
- `audit-security.md` -- Security audit checks
- `audit-quality.md` -- Code quality audit checks
