# SPEAR Framework -- Claude Code Adapter
#
# INSTALLATION: Copy this file to your project root as CLAUDE.md.
# Ensure .spear/ directory exists (run: spear init).
# Copy the commands/ and agents/ directories to .claude/ in your project.

## Governing Framework

This project follows the **SPEAR methodology** defined in `.spear/SPEAR.md`.
SPEAR is the single source of truth for development process. All work flows
through five sequential phases: Spec, Plan, Execute, Audit, Ratchet.

## Phase Workflow Rules

1. **Phases are sequential.** Never skip a phase. Never start Execute before Plan is approved.
2. **Audit failure returns to Execute.** Fix findings, then re-audit.
3. **Ratchet never loosens silently.** Every threshold change requires justification logged in `.spear/ratchet/history.jsonl`.
4. **Memory persists.** Read `.spear/memory/` before every Spec and Plan phase.
5. **Deviations are logged, not hidden.** Use `.spear/templates/execute/deviation-log.md`.

## Phase Commands

| Command | Phase | What It Does |
|---------|-------|--------------|
| `/spec` | Spec | Gather requirements, produce PRD + architecture + shards |
| `/plan` | Plan | Break spec into phased tasks with fitness functions |
| `/execute` | Execute | Implement one phase with atomic commits and checkpoints |
| `/audit` | Audit | Run 6-category audit, produce GO/NO-GO verdict |
| `/ratchet` | Ratchet | Update thresholds, generate rules, record decisions |
| `/status` | Any | Show current SPEAR state and ratchet thresholds |

## Audit Categories and Blocking Rules

| Category | Blocks On | Focus |
|----------|-----------|-------|
| Security | CRITICAL | Secrets, injection, auth, OWASP Top 10 |
| Dependencies | CRITICAL | Versions, CVEs, license compatibility |
| Performance | HIGH | Complexity, bundle size, query efficiency |
| Code Quality | HIGH | Duplication, dead code, naming, error handling |
| Documentation | CRITICAL | Public API docs, README accuracy, changelog |
| Architecture | HIGH | Layer violations, circular deps, pattern consistency |

**CRITICAL = blocks deployment, no override. HIGH = blocks unless explicitly justified.**

## Severity Levels

- **CRITICAL**: Must fix. No override allowed. Security vulnerabilities, data loss risk.
- **HIGH**: Fix or provide written justification in audit report.
- **MEDIUM**: Fix in current or next cycle.
- **LOW**: Track. Fix opportunistically.
- **INFO**: Observation only. No action required.

## Ratchet Thresholds

Read current thresholds from `.spear/ratchet/ratchet.json`. Key rules:
- **Floor metrics** (test coverage, doc coverage): must stay at or above threshold.
- **Ceiling metrics** (bundle size, complexity, build time): must stay at or below threshold.
- **Auto-tighten**: When a metric improves by >5% over threshold, the threshold ratchets to (new value - 2% buffer).
- **Loosening**: Requires written justification in `ratchet/history.jsonl`.

## Memory System

- **Decisions**: `.spear/memory/decisions/` -- Architecture Decision Records
- **Findings**: `.spear/memory/findings/` -- Archived audit findings
- **Patterns**: `.spear/memory/patterns/` -- Established code patterns
- **Antipatterns**: `.spear/memory/antipatterns/` -- Known failures with context
- **Index**: `.spear/memory/index.json` -- Searchable memory index

Always read memory before Spec and Plan phases. Always write memory after Ratchet phase.

## Templates

All outputs must use templates from `.spear/templates/`:
- Spec: `prd.md`, `architecture.md`, `epic-shard.md`
- Plan: `phase-plan.md`, `fitness-function.md`, `research-brief.md`
- Execute: `task-commit.md`, `deviation-log.md`, `checkpoint.md`

## Agents

Custom agent definitions in `.claude/agents/`:
- `spear-executor.md` -- Implementation work (Edit, Write, Bash, test)
- `spear-auditor.md` -- Audit work (Read-only analysis, report generation)
- `spear-planner.md` -- Planning work (Read, research, plan generation)

## Commit Convention

```
type(scope): imperative description (<72 chars)

[body: explain WHY, not WHAT]

Refs: SHARD-NNN, PHASE-NNN
```

Types: feat, fix, refactor, test, docs, chore, perf

## File Structure Reference

```
.spear/
  SPEAR.md            -- Framework definition (read-only reference)
  config.json         -- Project configuration
  templates/          -- Phase output templates
  agents/             -- Agent role definitions
  ratchet/            -- Thresholds, rules, history
  memory/             -- Decisions, findings, patterns
  fitness/            -- Fitness function registry
```
