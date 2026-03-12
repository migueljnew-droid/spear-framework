# SPEAR Philosophy: Design Principles

## Why SPEAR Exists

Software development with AI assistants is powerful but chaotic. Without structure, you get:
- Code that drifts from requirements mid-implementation
- Quality that fluctuates wildly between sessions
- Knowledge that evaporates when context resets
- Audits that happen too late to catch architectural mistakes

SPEAR solves this by enforcing a disciplined cycle: **Spec, Plan, Execute, Audit, Ratchet**. Each phase has clear inputs, outputs, and gates. Quality only goes up.

---

## The Ten Principles

### 1. Spec-First, Not Code-First

**The problem:** Developers (and AI agents) jump to code before understanding the problem. This produces technically impressive solutions to the wrong requirements.

**SPEAR's answer:** Nothing gets built until a spec exists. The spec defines acceptance criteria, constraints, and scope. The plan references the spec. Execution references the plan. Every line of code traces back to a written requirement.

**In practice:** Before `spear execute`, you must have a spec file in `.spear/specs/`. The CLI enforces this. No spec, no execution.

**Comparison:** BMAD gets this right with its PRD-first workflow. GSD skips it entirely, relying on the developer to "just know" what to build. Traditional agile puts stories in Jira but rarely enforces that code traces back to them. SPEAR takes BMAD's spec rigor and makes it machine-enforceable.

### 2. Audit-Gated, Not Trust-Gated

**The problem:** Code reviews catch surface issues. CI/CD catches build failures. Neither catches architectural drift, security gaps in business logic, or performance regressions in algorithms — not until production.

**SPEAR's answer:** Six independent audit categories run after every execution phase. Each produces findings with severity levels. CRITICAL findings block progression. The audit is automated, repeatable, and opinionated.

**In practice:** `spear audit` runs all six categories in parallel. If any returns a CRITICAL finding, you cannot ratchet. You fix or you justify (and justifications are logged permanently).

**Comparison:** Traditional CI/CD gates check "does it compile" and "do tests pass." SPEAR gates check "is the architecture sound," "are there security holes," "will this perform at scale," and "does this match the spec." GSD has no audit phase. BMAD has review steps but they're manual and subjective.

### 3. Self-Improving, Not Static

**The problem:** Quality standards are set once and decay. Teams lower the bar when deadlines hit. New patterns emerge but old rules stay.

**SPEAR's answer:** The Ratchet phase automatically tightens thresholds. If your test coverage hits 85%, the new floor is 85%. If your audit scores improve, the new minimum is the improved score. Quality only moves in one direction: up.

**In practice:** `.spear/ratchet.json` stores current floors. After each successful audit, floors auto-update. You can override with justification, but overrides are logged and visible in retrospectives.

**Comparison:** No existing framework does this. CI/CD coverage gates are static numbers someone picked once. BMAD has no ratchet concept. GSD has no quality tracking at all. The ratchet is SPEAR's most distinctive feature.

### 4. AI-Agnostic, Not AI-Locked

**The problem:** Every AI coding tool has its own configuration format, its own way of defining rules, and its own limitations. A workflow built for Cursor doesn't work in Claude Code. Knowledge encoded in `.cursorrules` is invisible to Copilot.

**SPEAR's answer:** The core framework is tool-independent. Adapters translate SPEAR's universal format into tool-specific configurations. Switch tools without losing your specs, plans, audits, or ratchet history.

**In practice:** `.spear/` is the source of truth. `spear adapt claude-code` generates a CLAUDE.md. `spear adapt cursor` generates .cursorrules. The adapter reads the same specs and rules — the output format changes, not the content.

**Comparison:** BMAD is tightly coupled to its own agent system. GSD assumes a specific LLM interaction pattern. Kiro only works within its IDE. SPEAR works with all of them through adapters, and also works with plain copy-paste into any LLM chat.

### 5. File-Native, Not Service-Dependent

**The problem:** SaaS tools create vendor lock-in. Databases require infrastructure. APIs go down. Pricing changes.

**SPEAR's answer:** Everything is Markdown and JSON, committed to git. No database required (though you can upgrade to SQLite or Qdrant for memory). No API calls needed for core functionality. Your entire SPEAR state is version-controlled and diffable.

**In practice:** `ls .spear/` shows you everything — specs, plans, audits, ratchet history, memory, decisions. It's all text files. `git log .spear/` shows you the full history of quality changes. `git diff .spear/ratchet.json` shows exactly what tightened.

**Comparison:** Most quality tools require dashboards, servers, or cloud accounts. SPEAR requires `git` and a text editor. Everything else is optional enhancement.

### 6. Convention Over Configuration

**The problem:** Highly configurable systems are never configured. Developers use defaults anyway, and the configuration complexity adds cognitive load.

**SPEAR's answer:** Sensible defaults work out of the box. `spear init` creates a working setup with no configuration needed. When you need to customize, `config.json` has clear, documented fields. But you don't need to touch it for 80% of use cases.

**In practice:** Default audit categories cover the six most important dimensions. Default severity thresholds match industry standards. Default ratchet increments are conservative (2%). Override any of these in `config.json` when your project demands it.

**Comparison:** Traditional linting tools (ESLint, RuboCop) require extensive configuration before they're useful. SPEAR's defaults are production-ready. Customize when you have a reason, not because you have to.

### 7. Parallel Audits, Not Serial Bottlenecks

**The problem:** Sequential review processes are slow. One reviewer blocks the entire pipeline. Categories blur together when one person reviews everything.

**SPEAR's answer:** Six audit categories run independently and in parallel. Security doesn't wait for performance. Architecture doesn't wait for code quality. Each category has its own criteria, its own findings, and its own severity levels.

**In practice:** `spear audit` dispatches all six categories simultaneously. Results stream in as they complete. A CRITICAL in security doesn't block the performance audit from finishing — you see all findings at once and prioritize accordingly.

**Comparison:** Traditional code review is one person, one pass, serial. BMAD has review stages but they're sequential. SPEAR's parallel model gives you comprehensive feedback in the time it takes to run the slowest single category.

### 8. Test-First, Not Test-After

**The problem:** AI agents write code, then bolt on tests that verify what they already built. These tests prove nothing — they pass immediately because they test existing behavior, not intended behavior.

**SPEAR's answer:** The Iron Law of TDD. No production code exists without a prior failing test. RED-GREEN-REFACTOR is mandatory for every task. Code written before a test gets deleted — no exceptions, no rationalizations.

**In practice:** Each task produces a TDD cycle record documenting the failing test, the minimal fix, and the refactor. If the record is empty, the task is rejected.

### 9. Evidence Before Claims

**The problem:** AI agents declare "all tests pass" and "bug is fixed" without running verification. Humans trust these claims. Bugs ship.

**SPEAR's answer:** The 5-step verification gate. Before any success claim: (1) identify the verification command, (2) run it fresh, (3) read the full output, (4) verify it confirms the claim, (5) only then state the claim with evidence. Words like "should work" and "probably passes" are banned.

**In practice:** Execution reports must contain command output, not assertions. The audit checks for banned language in reports.

### 10. Root Cause First, Not Fix First

**The problem:** When bugs appear, the instinct is to try a fix immediately. This leads to random changes, symptom-level patches, and "fix the fix" chains that make code worse.

**SPEAR's answer:** Systematic debugging protocol. Root cause investigation before any fix attempt. One variable changed at a time. If 3+ fix attempts fail, stop — it's architectural. Every bug fix requires a failing test committed before the fix.

**In practice:** The debugger agent enforces the 4-phase protocol. Red flags (like "quick fix for now") trigger immediate halt and restart from Phase 1.

---

## How SPEAR Combines Existing Strengths

| Capability | BMAD | GSD | CI/CD | SPEAR |
|-----------|------|-----|-------|-------|
| Spec rigor | Strong | Weak | None | Strong (enforced) |
| Execution speed | Moderate | Strong | N/A | Strong (with gates) |
| Quality gates | Manual review | None | Build/test only | 6-category parallel audit |
| Self-improvement | None | None | Static thresholds | Auto-ratchet |
| Tool independence | Coupled | Coupled | Tool-specific | Adapter layer |
| Persistence | Session-based | Session-based | Pipeline logs | Git-native files |
| Memory | None | None | None | Decision log + memory backend |

SPEAR does not replace these approaches. It takes the best ideas from each:
- **From BMAD:** Spec-first discipline, structured phases, role clarity
- **From GSD:** Execution velocity, minimal ceremony, practical focus
- **From CI/CD:** Automated gates, repeatable checks, pipeline integration
- **Original to SPEAR:** The ratchet, parallel audits, adapter layer, file-native persistence

---

## The Non-Negotiables

These are hard constraints, not suggestions:

1. **A spec must exist before execution begins.** Even a one-paragraph spec counts. No spec, no code.
2. **The spec requires explicit human approval.** Hard gate. No planning without sign-off.
3. **No production code without a failing test first.** The Iron Law of TDD. No exceptions.
4. **Evidence before claims.** Every "done" assertion requires command output proof (5-step gate).
5. **3 failed fixes = escalate.** Do not attempt fix #4. This is architectural. Discuss with human.
6. **Execution starts in a fresh worktree.** Clean baseline verified before any changes.
7. **CRITICAL audit findings block the ratchet.** Fix them or justify the override. Justifications are permanent.
8. **Ratchet floors never decrease without explicit override.** Auto-tightening is the default.
9. **All state lives in `.spear/` and is git-tracked.** If it's not committed, it didn't happen.
10. **Adapters are read-only translators.** They never modify `.spear/` state — they only read it and output tool-specific files.

---

## When NOT to Use SPEAR

SPEAR adds overhead. It's worth it for:
- Projects lasting more than a few days
- Codebases with multiple contributors (human or AI)
- Systems where quality regression is costly
- Teams switching between AI tools

It's overkill for:
- One-off scripts
- Quick prototypes you'll throw away
- Solo experiments where speed matters more than quality

Start simple. Use the defaults. Let the ratchet teach you where your quality boundaries are.
