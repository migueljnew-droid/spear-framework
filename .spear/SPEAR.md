# SPEAR Framework

> **Spec-driven. Audit-gated. Self-improving.**

SPEAR is a development methodology for AI-assisted software engineering. It structures work into five phases with mandatory audit gates and a learning ratchet that makes every project better than the last.

Read this file first. It is the single source of truth for the framework.

---

## The Five Phases

```
┌──────┐    ┌──────┐    ┌─────────┐    ┌───────┐    ┌─────────┐
│ SPEC │───>│ PLAN │───>│ EXECUTE │───>│ AUDIT │───>│ RATCHET │
└──────┘    └──────┘    └─────────┘    └───────┘    └─────────┘
   │                                       │              │
   │            ◄── FAIL: return ──────────┘              │
   │                                                      │
   ◄──────────────── NEXT CYCLE ──────────────────────────┘
```

### Phase 1: SPEC
Define what to build and why. No code. No implementation details.

**Inputs:** User request, existing codebase context, memory/decisions
**Outputs:** PRD, architecture doc, epic shards (bite-sized deliverables)
**Gate:** All outputs reviewed. Architecture doc references existing patterns from memory.
**Templates:** `templates/spec/prd.md`, `templates/spec/architecture.md`, `templates/spec/epic-shard.md`

### Phase 2: PLAN
Break the spec into executable phases with success criteria.

**Inputs:** Approved spec outputs, codebase analysis, ratchet thresholds
**Outputs:** Phase plan, fitness functions, research briefs (if needed)
**Gate:** Each phase has measurable success criteria. Fitness functions defined.
**Templates:** `templates/plan/phase-plan.md`, `templates/plan/fitness-function.md`, `templates/plan/research-brief.md`

### Phase 3: EXECUTE
Build what was planned. One phase at a time. Atomic commits.

**Inputs:** Phase plan, fitness functions, ratchet rules
**Outputs:** Code changes, task commits, deviation log (if plan was modified)
**Gate:** All fitness functions pass. No ratchet regressions. Tests green.
**Templates:** `templates/execute/task-commit.md`, `templates/execute/deviation-log.md`, `templates/execute/checkpoint.md`

### Phase 4: AUDIT
Independent review across 6 categories. Parallel-runnable. Each category produces an independent verdict.

**Inputs:** All changes from Execute phase, ratchet state, fitness results
**Outputs:** Audit report per category, summary with GO/NO-GO verdict
**Gate:** Zero CRITICAL findings. HIGH findings require explicit override with justification.

#### The 6 Audit Categories

| # | Category | Focus |
|---|----------|-------|
| 1 | **Security** | Secrets, injection, auth, OWASP Top 10 |
| 2 | **Dependencies** | Versions, vulnerabilities, license compatibility |
| 3 | **Performance** | Complexity, bundle size, query efficiency, memory |
| 4 | **Code Quality** | Duplication, dead code, naming, error handling |
| 5 | **Documentation** | Public API docs, README accuracy, changelog |
| 6 | **Architecture** | Layer violations, circular deps, pattern consistency |

#### Severity Levels

| Level | Meaning | Action |
|-------|---------|--------|
| **CRITICAL** | Blocks deployment. Security vulnerability, data loss risk. | Must fix. No override. |
| **HIGH** | Significant issue. Performance regression, missing tests. | Fix or justify override. |
| **MEDIUM** | Should fix. Code smell, minor doc gap. | Fix in current or next cycle. |
| **LOW** | Nice to have. Style preference, optional optimization. | Track. Fix opportunistically. |
| **INFO** | Observation. No action required. | Log for context. |

**Templates:** `templates/audit/audit-report.md`, `templates/audit/audit-summary.md`, `templates/audit/finding.md`

### Phase 5: RATCHET
Learn from the cycle. Tighten thresholds. Record decisions.

**Inputs:** Audit results, fitness function measurements, execution history
**Outputs:** Updated thresholds, new rules, retrospective, memory entries
**Gate:** Ratchet state updated. No threshold loosened without justification.

#### Ratchet Mechanics

- **Floor thresholds** (must stay above): test coverage, doc coverage
- **Ceiling thresholds** (must stay below): bundle size, complexity, build time
- **Auto-tighten policy:** When a metric improves by >5% over threshold, the threshold ratchets up/down to the new level minus a 2% buffer
- **Override:** Requires written justification logged in `ratchet/history.jsonl`
- **Rules:** Audit findings with severity >= HIGH auto-generate ratchet rules

**Templates:** `templates/ratchet/ratchet-entry.md`, `templates/ratchet/rule-proposal.md`, `templates/ratchet/retrospective.md`

---

## State Machine Rules

1. **Phases are sequential.** You cannot skip phases.
2. **Audit failure returns to Execute.** Fix findings, then re-audit.
3. **Ratchet never loosens silently.** Every threshold change is logged.
4. **Memory persists across cycles.** Decisions, patterns, and findings carry forward.
5. **Deviation is allowed, not hidden.** If the plan changes during Execute, log it.
6. **Each phase has a single owner.** One agent/human per phase at a time.
7. **Audit categories are independent.** Run them in parallel. Each produces its own verdict.
8. **The ratchet is monotonic by default.** Quality only goes up.

---

## File Structure

```
.spear/
├── SPEAR.md              ← You are here
├── config.json           ← Project configuration
├── templates/            ← Phase output templates
│   ├── spec/
│   ├── plan/
│   ├── execute/
│   ├── audit/
│   └── ratchet/
├── agents/               ← Agent role prompts
├── ratchet/
│   ├── ratchet.json      ← Current thresholds + rules
│   ├── history.jsonl     ← Append-only change log
│   ├── thresholds/       ← Per-metric config
│   └── rules/            ← Auto-generated rules (YAML)
├── memory/
│   ├── index.json        ← Searchable memory index
│   ├── decisions/        ← Architecture Decision Records
│   ├── findings/         ← Archived audit findings
│   ├── patterns/         ← Established code patterns
│   └── antipatterns/     ← Known failures with context
└── fitness/
    ├── registry.json     ← Active fitness functions
    └── examples/         ← Starter fitness functions
```

---

## Integration

SPEAR is AI-tool-agnostic at its core. Adapters translate SPEAR concepts into tool-specific formats:

| Tool | Adapter Location | How It Works |
|------|-----------------|--------------|
| Claude Code | `adapters/claude-code/` | CLAUDE.md + slash commands + custom agents |
| Cursor | `adapters/cursor/` | .cursorrules file with SPEAR directives |
| GitHub Copilot | `adapters/copilot/` | copilot-instructions.md |
| Antigravity | `adapters/antigravity/` | Project rules + agent workflows |
| Kiro | `adapters/kiro/` | Steering files + hooks + spec templates |
| Generic | `adapters/generic/` | System prompt for any LLM |

---

## Quick Reference

**Start a cycle:** Create a PRD using `templates/spec/prd.md`
**Check status:** Read `ratchet/ratchet.json` for current thresholds
**Review memory:** Search `memory/index.json` for past decisions
**Run audit:** Execute all 6 category agents against current changes
**Install:** `curl -fsSL https://raw.githubusercontent.com/migueljnew-droid/spear-framework/main/install.sh | sh`

---

*SPEAR v1.0.0 — Created by Louis Gold*
