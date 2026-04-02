# SPEAR Framework

> **Spec-driven. Audit-gated. Self-improving.**

SPEAR is a development methodology for AI-assisted software engineering. It structures work into five phases with mandatory audit gates and a learning ratchet that makes every project better than the last.

Read this file first. It is the single source of truth for the framework.

---

## The Full Cycle

```
┌─────────┐    ┌──────┐    ┌──────┐    ┌─────────┐    ┌───────┐    ┌─────────┐    ┌─────────────┐
│ IGNITE  │───>│ SPEC │───>│ PLAN │───>│ EXECUTE │───>│ AUDIT │───>│ RATCHET │───>│ PRODUCTIZE  │
└─────────┘    └──────┘    └──────┘    └─────────┘    └───────┘    └─────────┘    └─────────────┘
   │              │                                       │              │
   │              │            ◄── FAIL: return ──────────┘              │
   │              │                                                      │
   │              ◄──────────────── NEXT CYCLE ──────────────────────────┘
   │
   MANDATORY — No spec without Ignition outputs.
```

### Phase 0: IGNITE (Mandatory Pre-Spec)
Force precision of intent before any specification is written. Eliminates ambiguity, assumptions, and wasted cycles. **No spec is written until Ignition is complete.**

Inspired by Project Ignition (Rico Williams, UDIG Solutions). Integrated April 2026.

**Inputs:** User request, existing context
**Outputs:** Outcome Formula, answered key questions, expert role assignment, first principles challenge
**Gate:** Outcome Formula passes The Test (a stranger with expertise could deliver without questions). All 50%+ impact gaps resolved. Hard gate -- no spec without Ignition outputs.
**Method:** Outcome Formula → 7-category key questions → role assignment → first principles decomposition

### Phase 1: SPEC
Define what to build and why. No code. No implementation details. Challenge requirements before accepting them.

If IGNITE was run, the Spec phase loads Ignition outputs (Outcome Formula, key questions, role assignment, first principles) as primary input. The Spec phase also maps **constraints** (7 categories: budget, time, team, technology, legal, knowledge, client) classified as Hard vs Soft, and defines **format specifications** for non-code deliverables.

SPEAR's Spec phase integrates Elon Musk's first three manufacturing steps — applied to software:

1. **Challenge requirements** (Musk Step 1) — Every requirement is questioned: who needs it, what's the cost of skipping it, is it from domain expertise or assumption. Requirements are KEPT, KILLED, or SIMPLIFIED.
2. **Propose deletions** (Musk Step 2) — Before adding anything, identify dead code, redundant processes, over-engineering, and dependency bloat to remove.
3. **Simplify** (Musk Step 3) — Reduce surviving scope to its minimum useful form. Only then write the spec.

> Musk Steps 4 (accelerate) and 5 (automate) map to Execute and Ratchet respectively.

**Inputs:** User request, existing codebase context, memory/decisions, ratchet retrospective, capability registry
**Outputs:** Capability Registry (`.spear/capability-registry.json`), Requirement Challenge Log, Deletion Proposal, PRD, architecture doc, epic shards
**Gate:** Spec-document-reviewer validates. Human partner explicitly approves. Hard gate — no implementation without approval.
**Method:** Challenge → Delete → Simplify → Socratic questioning → 2-3 design approaches with trade-offs.
**Templates:** `templates/spec/prd.md`, `templates/spec/architecture.md`, `templates/spec/epic-shard.md`

### Phase 2: PLAN
Break the spec into executable phases with success criteria. Run Devil's Advocate against the plan using 6 attack vectors (Logic, Audience, Execution, Competition, Worst Case, Scale) with a risk matrix. Any risk scoring 15+ (Likelihood x Impact) must have a mitigation plan before execution begins.

**Inputs:** Approved spec outputs, codebase analysis, ratchet thresholds, capability registry
**Outputs:** Phase plan (with Capabilities Used section), fitness functions, research briefs (if needed)
**Gate:** Each phase has measurable success criteria. Fitness functions defined. Each task specifies its assigned capability.
**Templates:** `templates/plan/phase-plan.md`, `templates/plan/fitness-function.md`, `templates/plan/research-brief.md`

### Phase 3: EXECUTE
Build what was planned. One phase at a time. Atomic commits. TDD-enforced. Evidence-verified.

**Inputs:** Phase plan, fitness functions, ratchet rules, capability registry
**Outputs:** Code changes, task commits, TDD cycle records, deviation log, capability utilization report, debug reports (if bugs hit)
**Gate:** All fitness functions pass. No ratchet regressions. Tests green. Every claim verified via 5-step gate. Assigned capabilities used (or deviation logged).
**Method:** Git worktree isolation. Use assigned capabilities (Skill → SOVEREIGN → MCP → Agent → Dep → manual). RED-GREEN-REFACTOR per task. Subagent dispatch for 5+ task phases. Systematic debugging on failures.
**Templates:** `templates/execute/task-commit.md`, `templates/execute/deviation-log.md`, `templates/execute/checkpoint.md`, `templates/execute/tdd-cycle.md`
**Agents:** `agents/executor.md` (standard), `agents/subagent-executor.md` (parallel), `agents/debugger.md` (on failure)

### Phase 4: AUDIT
Independent review across 6 categories. Parallel-runnable. Each category produces an independent verdict. Includes an **Outcome Verification Gate** that checks whether the built thing actually delivers what the Outcome Formula (or PRD) defined — code quality alone is not sufficient.

**Inputs:** All changes from Execute phase, ratchet state, fitness results, capability registry, capability utilization report
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
Learn from the cycle. Tighten thresholds. Track velocity. Record decisions.

**Inputs:** Audit results, fitness function measurements, execution history, phase timestamps, capability utilization
**Outputs:** Updated thresholds, new rules, cycle time analysis, capability utilization analysis, retrospective, memory entries
**Gate:** Ratchet state updated. No threshold loosened without justification.

#### Ratchet Mechanics

- **Floor thresholds** (must stay above): test coverage, doc coverage
- **Ceiling thresholds** (must stay below): bundle size, complexity, build time
- **Auto-tighten policy:** When a metric improves by >5% over threshold, the threshold ratchets up/down to the new level minus a 2% buffer
- **Override:** Requires written justification logged in `ratchet/history.jsonl`
- **Rules:** Audit findings with severity >= HIGH auto-generate ratchet rules

#### Cycle Time Tracking (Musk Step 4: Accelerate)

- **Phase durations** recorded per cycle: Spec, Plan, Execute, Audit, Ratchet (in minutes)
- **Rolling average** computed from last 3 cycles
- **SLOW flag**: phase took >2x rolling average → root cause investigation required
- **FAST flag**: phase took <0.5x rolling average → verify quality wasn't sacrificed
- **Stored in** `ratchet/ratchet.json` under `cycle_times` key
- Cycle time is tracked but NOT auto-tightened — it's a diagnostic signal, not a quality gate

**Templates:** `templates/ratchet/ratchet-entry.md`, `templates/ratchet/rule-proposal.md`, `templates/ratchet/retrospective.md`

### Phase 6: PRODUCTIZE (Optional Post-Ratchet)
Evaluate every completed SPEAR cycle for revenue potential. Score the work on 7 criteria (Repeatable, Transferable, Domain-Specific, Data-Clean, Better Than Free, Demonstrable, Stackable). GREEN (50+/70) = build the product. YELLOW (35-49) = refine first. RED (<35) = keep internal.

Inspired by Project Ignition Pillar 8 (Rico Williams, UDIG Solutions). Integrated April 2026.

**Inputs:** Completed ratchet, audit results, the built product/feature
**Outputs:** Productization score, product form recommendation, competitive quick-scan, pricing estimate
**Gate:** Score threshold (50+ for GREEN). Competitive quick-scan must not reveal dominant competitor with identical approach.
**Method:** 7-criteria filter → product form selection → competitive scan → pricing → entity routing

---

## State Machine Rules

1. **Phases are sequential.** You cannot skip phases.
2. **Spec requires explicit human approval.** Hard gate — no planning without sign-off.
3. **Audit failure returns to Execute.** Fix findings, then re-audit.
4. **Ratchet never loosens silently.** Every threshold change is logged.
5. **Memory persists across cycles.** Decisions, patterns, and findings carry forward.
6. **Deviation is allowed, not hidden.** If the plan changes during Execute, log it.
7. **Each phase has a single owner.** One agent/human per phase at a time.
8. **Audit categories are independent.** Run them in parallel. Each produces its own verdict.
9. **The ratchet is monotonic by default.** Quality only goes up.
10. **No production code without a failing test first.** The Iron Law of TDD. No exceptions.
11. **Evidence before claims.** Every "done" assertion requires command output proof (5-step gate).
12. **3 failed fixes = escalate.** Do not attempt fix #4. This is architectural. Discuss with human.
13. **Worktree isolation is default.** Execute phase starts in a fresh worktree branch.
14. **Use what you have before building new.** Every phase consults the Capability Registry. The routing priority is: registered Skill → SOVEREIGN agent → MCP tool → Claude Code agent → installed dependency → build from scratch. Rebuilding available functionality is a deviation that must be logged and justified.
15. **Challenge before accepting.** Requirements are challenged (Musk Step 1), deletions are proposed (Step 2), and scope is simplified (Step 3) before any spec is written.

---

## Capability Routing

When a task needs functionality, follow this decision tree:

```
1. Registered SKILL?      → Use Skill tool (fastest, most integrated)
2. SOVEREIGN AGENT?        → Use mcp__council__invoke_agent (domain expertise)
3. MCP TOOL?               → Use the MCP tool directly
4. Claude Code AGENT?      → Use Agent tool with subagent_type
5. Installed DEPENDENCY?   → Write code using the dependency
6. None of the above?      → Build from scratch (flag as new capability)
```

Registry lookup failures are INFO-level, never blocking. If a capability is
unavailable at runtime, fall back to manual, log a deviation, and flag in audit.

---

## File Structure

```
.spear/
├── SPEAR.md              ← You are here
├── config.json           ← Project configuration
├── capability-registry.json ← Unified Capability Registry (skills, agents, MCPs, deps)
├── templates/            ← Phase output templates
│   ├── spec/
│   ├── plan/
│   ├── execute/          ← Includes tdd-cycle.md
│   ├── audit/
│   └── ratchet/
├── agents/               ← Agent role prompts
│   ├── spec-writer.md    ← Socratic questioning + design validation
│   ├── planner.md
│   ├── executor.md       ← TDD-enforced + verification gate + worktree isolation
│   ├── subagent-executor.md  ← Parallel task dispatch + two-stage review
│   ├── debugger.md       ← Systematic 4-phase debugging protocol
│   ├── verifier.md
│   ├── ratchet-engine.md
│   ├── audit-*.md        ← 6 audit category agents
│   └── competitor-researcher.md
├── references/
│   └── capability-registry.md ← Registry schema, discovery sources, routing rules
├── ratchet/
│   ├── ratchet.json      ← Current thresholds + rules
│   ├── history.jsonl     ← Append-only change log
│   ├── thresholds/       ← Per-metric config
│   └── rules/            ← Auto-generated rules (YAML)
├── output/               ← Phase output artifacts
│   ├── spec/
│   ├── plan/
│   ├── execute/
│   ├── audit/
│   └── ratchet/
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

*SPEAR v2.3.0 — Created by Miguel Jiminez*
*v2.3: Ignition Integration — pre-spec intent clarification (Outcome Formula, key questions, role assignment, first principles), constraints-first design, format specification, 6 attack vector risk matrix, outcome verification audit gate, productize phase. Inspired by Project Ignition (Rico Williams, UDIG Solutions).*
*v2.2: Unified Capability Registry — all phases discover and route through skills, agents, MCP tools, and dependencies*
*v2.1: Musk 5-Step Integration — requirement challenge gate, deletion audit, simplification pass, cycle time tracking*
*v2.0: TDD enforcement, verification gates, Socratic specs, systematic debugging, subagent execution, parallel dispatch, worktree isolation*
