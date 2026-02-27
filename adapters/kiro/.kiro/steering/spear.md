# SPEAR Framework -- Kiro Steering File
#
# INSTALLATION: Copy the .kiro/ directory to your project root.
# Ensure .spear/ directory exists (run: spear init).
#
# This steering file provides SPEAR methodology context to Kiro (AWS).
# Reference: .spear/SPEAR.md for the full framework definition.

## Framework

SPEAR is a 5-phase, audit-gated, self-improving development methodology:

1. **Spec** -- Define what to build. PRD, architecture, epic shards. No code.
2. **Plan** -- Break spec into phased tasks with fitness functions. One phase at a time.
3. **Execute** -- Implement the plan. Atomic commits. Checkpoints. Log deviations.
4. **Audit** -- Independent 6-category review. GO/NO-GO verdict.
5. **Ratchet** -- Tighten thresholds. Generate rules. Record decisions in memory.

## Rules

- Phases are sequential. Never skip.
- Audit failure returns to Execute for fixes, then re-audit.
- Ratchet never loosens silently. All changes logged.
- Memory persists across cycles. Read before Spec and Plan.
- Deviations during Execute are logged, not hidden.
- Each phase has one owner at a time.

## Audit Categories

| Category | Blocks | Focus |
|----------|--------|-------|
| Security | CRITICAL | Secrets, injection, auth, OWASP Top 10 |
| Dependencies | CRITICAL | CVEs, licenses, pinned versions |
| Performance | HIGH | Complexity, N+1 queries, bundle size |
| Code Quality | HIGH | Duplication, dead code, error handling |
| Documentation | CRITICAL | API docs, README, changelog |
| Architecture | HIGH | Layer violations, circular deps |

## Severity

- CRITICAL: Must fix. No override.
- HIGH: Fix or justify in writing.
- MEDIUM: Fix now or next cycle.
- LOW: Track and fix opportunistically.
- INFO: Observation only.

## Ratchet

Thresholds in `.spear/ratchet/ratchet.json`:
- Floor (stay above): test_coverage, doc_coverage
- Ceiling (stay below): max_complexity, max_bundle_size, max_build_time
- Auto-tighten on >5% improvement (2% buffer)
- Loosening requires written justification

## Code Standards

- Match existing codebase patterns
- Explicit error handling (no swallowed errors)
- No hardcoded secrets, config, or magic numbers
- Tests alongside code, never deferred
- Functions under 50 lines
- Conventional commits: `type(scope): description`

## Memory

Read `.spear/memory/` before Spec and Plan:
- `decisions/` -- ADRs
- `patterns/` -- Established patterns
- `antipatterns/` -- Known failures
- `findings/` -- Archived findings

## Templates

Use `.spear/templates/` for all phase outputs:
- `spec/`: prd.md, architecture.md, epic-shard.md
- `plan/`: phase-plan.md, fitness-function.md, research-brief.md
- `execute/`: task-commit.md, deviation-log.md, checkpoint.md

## Hooks

SPEAR hooks in `.kiro/hooks/`:
- `spear-audit.kiro.hook` -- triggers audit checks on file save

## Specs

SPEAR spec templates in `.kiro/specs/`:
- `requirements.md` -- requirements template
- `design.md` -- architecture/design template
