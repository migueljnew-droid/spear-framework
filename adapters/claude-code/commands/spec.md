# /spec -- SPEAR Spec Phase

# INSTALLATION: Copy this file to .claude/commands/spec.md in your project.
# Usage: Type /spec in Claude Code to invoke this command.

You are entering the **Spec phase** of the SPEAR framework. Your job is to
translate the user's request into structured, unambiguous specifications that
any executor can implement without guesswork.

## Step 1: Read Context

Before writing anything, read the following (skip if file does not exist):

1. `.spear/memory/index.json` -- past decisions, patterns, constraints
2. `.spear/memory/decisions/` -- relevant Architecture Decision Records
3. `.spear/ratchet/ratchet.json` -- current thresholds and active rules
4. Any existing specs in the project that overlap with or depend on this work
5. The relevant parts of the existing codebase to understand current state

Summarize what you learned in 3-5 bullets before proceeding.

## Step 2: Challenge Requirements (Musk Step 1)

Before accepting any requirement, force-answer for EACH one:
1. **Who specifically needs this?** Name the person/role — not "users."
2. **What happens if we don't build it?** If "nothing much," kill it.
3. **Is this from domain expertise or assumption?** Question smart-people requirements hardest.
4. **When was this last validated?** Requirements rot.
5. **Can we solve this with what already exists?**

Produce a Requirement Challenge Log:
- Write to: `.spear/output/spec/requirement-challenge.md`
- Table: `| # | Requirement | Who Needs It | Cost of Skipping | Source | Verdict |`
- Verdicts: **KEEP** / **KILL** / **SIMPLIFY**
- Requirements marked KILL are removed. SIMPLIFY means reduce to minimum useful form.

## Step 3: Propose Deletions (Musk Step 2)

Before adding anything new, identify what to REMOVE from the existing system:
- Dead code (unused modules, functions, endpoints)
- Redundant process (steps that exist "because we've always done it")
- Over-engineering (abstractions nobody uses)
- Dependency bloat (libraries replaceable by 20 lines of code)

Produce a Deletion Proposal:
- Write to: `.spear/output/spec/deletion-proposal.md`
- Table: `| # | Target | Type | Why It Should Go | Risk | Verdict |`
- Verdicts: **DELETE** / **KEEP** / **DEFER**
- If nothing to delete: "No deletions identified — reviewed [N] modules/processes."

## Step 4: Simplify Surviving Scope (Musk Step 3)

After challenging and deleting, simplify what remains:
- Can two features merge into one?
- Can a 5-step flow become 3 steps?
- Can a complex abstraction become a concrete implementation?

Document simplifications applied in the PRD's Background section.

## Step 5: Clarify Requirements

Ask the user clarifying questions about the SURVIVING (post-challenge) scope.
Group them by category:

- **Scope**: What is included? What is explicitly excluded?
- **Behavior**: How should it work? What are the edge cases?
- **Constraints**: Performance, compatibility, security, compliance?
- **Dependencies**: What does this depend on? What depends on this?

Number every question. Wait for answers before proceeding.
If the request is already fully specified, confirm your understanding and proceed.

## Step 6: Identify Unknowns

If anything requires technical investigation (library capabilities, API limits,
performance characteristics), create a research brief using the template at
`.spear/templates/plan/research-brief.md`. Do NOT guess -- flag it.

## Step 7: Produce Outputs

Create the following files using the SPEAR templates:

### 7a. PRD (Product Requirements Document)
- Template: `.spear/templates/spec/prd.md`
- Write to: `.spear/output/spec/prd.md`
- Must include: problem statement, goals, non-goals, user stories,
  acceptance criteria, technical constraints, dependencies, open questions

### 7b. Architecture Document
- Template: `.spear/templates/spec/architecture.md`
- Write to: `.spear/output/spec/architecture.md`
- Must include: system context, component diagram, data flow, API contracts,
  technology choices, security considerations, performance requirements
- MUST reference existing codebase patterns from memory

### 7c. Epic Shards
- Template: `.spear/templates/spec/epic-shard.md`
- Write to: `.spear/output/spec/shards/SHARD-001-[name].md`, etc.
- Break the work into bite-sized deliverables
- Each shard must have: objective, scope, acceptance criteria, fitness functions
- Order shards by dependency (no shard depends on a later shard)

### 7d. Research Briefs (if any unknowns)
- Template: `.spear/templates/plan/research-brief.md`
- Write to: `.spear/output/spec/research/RB-001-[name].md`, etc.

## Step 8: Self-Audit Checklist

Before presenting outputs, verify:

### Musk Gate (Steps 2-4)
- [ ] Requirement Challenge Log produced with verdicts for every requirement
- [ ] At least one requirement KILLED or SIMPLIFIED (or justified why all survived)
- [ ] Deletion Proposal produced (or "no deletions" with review count)
- [ ] Simplification pass applied to surviving scope
- [ ] Order enforced: challenge → delete → simplify → specify

### Spec Quality
- [ ] Problem is clearly stated with concrete impact
- [ ] Goals are testable -- each has a yes/no verification method
- [ ] Non-goals explicitly exclude adjacent scope
- [ ] Acceptance criteria are measurable and independently verifiable
- [ ] Architecture references existing codebase patterns (or justifies new ones)
- [ ] All dependencies identified (internal and external)
- [ ] Open questions have owners and indicate what they block
- [ ] Research briefs created for unresolved unknowns
- [ ] Specs are written so someone without context can implement them
- [ ] Past decisions from memory are referenced where relevant

## Step 9: Present and Review

Present a summary of all outputs with:
1. The problem being solved (1-2 sentences)
2. Number of shards created and their names
3. Number of research briefs (if any)
4. Key architectural decisions made
5. Open questions that need resolution before Plan phase

Ask: "Ready to approve this spec and move to Plan phase?"

The Spec phase is complete only when the user approves all outputs.
