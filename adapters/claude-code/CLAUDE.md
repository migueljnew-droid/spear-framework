# SPEAR Framework -- Claude Code Adapter
#
# INSTALLATION: Copy this file to your project root as CLAUDE.md.
# Ensure .spear/ directory exists (run: spear init).
# Copy the commands/ and agents/ directories to .claude/ in your project.

## Governing Framework

This project follows the **SPEAR methodology** defined in `.spear/SPEAR.md`.
SPEAR is the single source of truth for development process. All work flows
through sequential phases: **Ignite (mandatory)** → Spec → Plan → Execute → Audit → Ratchet → Productize (optional).

## Phase Workflow Rules

1. **Phases are sequential.** Never skip a phase. Never start Execute before Plan is approved.
2. **Audit failure returns to Execute.** Fix findings, then re-audit.
3. **Ratchet never loosens silently.** Every threshold change requires justification logged in `.spear/ratchet/history.jsonl`.
4. **Memory persists.** Read `.spear/memory/` before every Spec and Plan phase.
5. **Deviations are logged, not hidden.** Use `.spear/templates/execute/deviation-log.md`.
6. **Use what you have.** Every phase consults `.spear/capability-registry.json`. Route: Skill → SOVEREIGN agent → MCP tool → Claude Code agent → dependency → build from scratch.
7. **Challenge before accepting.** Requirements are challenged (Musk Step 1), deletions proposed (Step 2), scope simplified (Step 3) before spec writing.

## Phase Commands

| Command | Phase | What It Does |
|---------|-------|--------------|
| `/ignite` | Ignite | Pre-spec intent clarification: Outcome Formula, key questions, role assignment, first principles |
| `/spec` | Spec | Build capability registry, challenge requirements, map constraints, produce PRD + architecture + shards |
| `/plan` | Plan | Break spec into phased tasks with fitness functions, 6-vector risk matrix |
| `/execute` | Execute | Implement one phase with atomic commits and checkpoints |
| `/audit` | Audit | Outcome verification + 7-category audit, produce GO/NO-GO verdict |
| `/ratchet` | Ratchet | Update thresholds, track cycle time, analyze capability utilization, record decisions |
| `/productize` | Productize | Score completed work for revenue potential (7-criteria filter, product form, pricing) |
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
| UI/Visual | CRITICAL | Console errors, failed requests, broken UI, accessibility |

**CRITICAL = blocks deployment, no override. HIGH = blocks unless explicitly justified.**
**UI/Visual auto-skips if no web UI detected. Requires `browser-cdp` MCP (`packages/browser-cdp-mcp/`).**

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

## Capability Registry

The **Unified Capability Registry** (`.spear/capability-registry.json`) maps all available
tools across the entire stack:

| Source | What It Contains |
|--------|-----------------|
| Claude Code Skills | 70+ skills (senior-fullstack, tdd, code-review, etc.) |
| Claude Code Agents | spear-executor, spear-planner, spear-auditor + custom |
| SOVEREIGN Agents | 441 agents across 5 tiers (SOPHIA, TECHNE, BASTION, etc.) |
| MCP Tools | perplexity, council, qmd, llm-gateway, n8n, content-creator |
| Dependencies | Cargo.toml / package.json / requirements.txt |

**Built during /spec (Step 1). Refreshed during /plan (Step 1). Consulted by ALL phases.**

Routing priority: Skill → SOVEREIGN agent → MCP tool → Claude Code agent → dependency → build new.

See `.spear/references/capability-registry.md` for full schema and routing rules.

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
  SPEAR.md                 -- Framework definition (read-only reference)
  config.json              -- Project configuration
  capability-registry.json -- Unified Capability Registry (skills, agents, MCPs, deps)
  references/              -- Schemas and routing rules
  templates/               -- Phase output templates
  agents/                  -- Agent role definitions
  ratchet/                 -- Thresholds, rules, history, cycle times
  memory/                  -- Decisions, findings, patterns
  fitness/                 -- Fitness function registry
```
