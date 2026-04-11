# /spec -- SPEAR Spec Phase

# INSTALLATION: Copy this file to .claude/commands/spec.md in your project.
# Usage: Type /spec in Claude Code to invoke this command.

You are entering the **Spec phase** of the SPEAR framework. Your job is to
translate the user's request into structured, unambiguous specifications that
any executor can implement without guesswork.

## Step 0: Load Ignition Outputs (MANDATORY)

Ignition is a **hard gate** for the Spec phase. Check for outputs in
`.spear/output/ignition/`:

1. `outcome.md` -- The Outcome Formula (deliverable + result + audience + context)
2. `key-questions.md` -- All answered questions from the 7 categories
3. `role-assignment.md` -- Expert role(s) assigned for this project
4. `first-principles.md` -- Assumptions challenged, fundamentals identified

**If ANY of these files are missing, STOP.** Tell the user:
"Ignition phase is required before Spec. Run /spear:ignite first."
Do NOT proceed with the Spec phase without Ignition outputs.

The Outcome Formula defines what "done" looks like. The Key Questions eliminate
assumptions. The First Principles challenge validates the approach. These are
your primary inputs for everything that follows.

## Step 1: Read Context & Build Capability Registry

Before writing anything, read the following (skip if file does not exist):

1. `.spear/memory/index.json` -- past decisions, patterns, constraints
2. `.spear/memory/decisions/` -- relevant Architecture Decision Records
3. `.spear/ratchet/ratchet.json` -- current thresholds and active rules
4. Any existing specs in the project that overlap with or depend on this work
5. The relevant parts of the existing codebase to understand current state

Then **build/refresh the Capability Registry** (`.spear/capability-registry.json`):

6. **Scan Claude Code skills** -- list all available skills from the system
7. **Scan Claude Code agents** -- read `.claude/agents/` (project + global)
8. **Scan SOVEREIGN agents** -- call `mcp__council__list_agents` or `mcp__council__council_status` (if available)
9. **Scan MCP tools** -- list all connected MCP servers and their tools
10. **Scan project dependencies** -- read `Cargo.toml`, `package.json`, `requirements.txt`, or `go.mod`
11. **Map capabilities to phases** -- assign each capability to spec/plan/execute/audit/ratchet using the routing rules in `.spear/references/capability-registry.md`

Write the registry to: `.spear/capability-registry.json`

Summarize what you learned in 3-5 bullets, including:
- How many capabilities were discovered (skills + agents + MCP tools + deps)
- Any capabilities particularly relevant to the current request

## Step 2: Challenge Requirements (Musk Step 1)

Before accepting any requirement, force-answer for EACH one:
1. **Who specifically needs this?** Name the person/role — not "users."
2. **What happens if we don't build it?** If "nothing much," kill it.
3. **Is this from domain expertise or assumption?** Question smart-people requirements hardest.
4. **When was this last validated?** Requirements rot.
5. **Can we solve this with what already exists?** — **Consult the Capability Registry.** Check if any registered skill, agent, MCP tool, or dependency already provides this functionality. If so, the requirement may be KILL (already solved) or SIMPLIFY (integrate existing, don't rebuild).

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

## Step 5: Constraints First

Map the walls before designing the room. Every project operates within limits.
Identifying them now prevents scope creep, over-engineering, and broken promises.

### The 7 Constraint Categories

For the surviving scope, map constraints in each category:

1. **Budget** -- What's available? Cost per phase? Cost of doing nothing?
2. **Time** -- Hard deadlines (court dates, launches, grant deadlines) vs soft deadlines.
   Dependencies that affect timing.
3. **Team** -- Who's available? Skill levels? Bandwidth?
4. **Technology** -- Platform limitations. Integration requirements. Legacy systems.
5. **Legal and Regulatory** -- Compliance requirements. Jurisdictional rules. Licensing.
6. **Knowledge** -- What do we know vs need to learn? What expertise is available?
7. **Client/User** -- Technical sophistication. Decision-making process. Risk tolerance.

### Hard vs Soft

Categorize every constraint as:
- **Hard** (cannot be changed): court deadlines, legal requirements, platform limits
- **Soft** (can be negotiated): timelines, budgets, feature scope

Hard constraints become non-negotiable design requirements.
Soft constraints become trade-off decisions.

**If constraints make the Outcome (Pillar 0) impossible, surface that NOW -- not
after building.** Write constraints to the PRD's Technical Constraints section.

## Step 5b: Clarify Requirements

Ask the user clarifying questions about the SURVIVING (post-challenge) scope.
Group them by category:

- **Scope**: What is included? What is explicitly excluded?
- **Behavior**: How should it work? What are the edge cases?
- **Constraints**: Performance, compatibility, security, compliance?
- **Dependencies**: What does this depend on? What depends on this?

Number every question. Wait for answers before proceeding.
If the request is already fully specified, confirm your understanding and proceed.

## Step 5c: Deep Dependency Analysis (MANDATORY)

Scan the project for ALL dependency manifests (Cargo.toml, package.json, Podfile,
requirements.txt, pyproject.toml, go.mod, etc.).

For EVERY new dependency the feature requires:
- Pin exact version or acceptable range
- Check license compatibility (MIT/Apache=safe, GPL/LGPL/AGPL=FLAG for proprietary)
- Run CVE scan (`cargo audit` / `npm audit` / `pip-audit` / equivalent)
- Count transitive dependencies and assess risk
- Check maintenance status (last release, bus factor)

For system dependencies: list OS packages, build tools, runtimes needed.
Produce a **Dependency Audit Table** in the PRD.

## Step 5d: Compliance Analysis (MANDATORY)

Evaluate ALL compliance categories — mark N/A with reason if not applicable:
- **App Store**: Apple/Google review guidelines, IAP rules, privacy labels, entitlements
- **Regulatory**: GDPR, CCPA, COPPA, ADA/WCAG (AA minimum), HIPAA, PCI-DSS, SOC2
- **Security**: OWASP Top 10, auth model, encryption, secret management, input validation
- **License**: All deps compatible, no copyleft contamination, attribution, export controls

Produce a **Compliance Requirements** section in the PRD.

## Step 5e: Full Arsenal Discovery (MANDATORY)

The Capability Registry (Step 1) already scanned available tools. Now **score and assign**
them to the spec:
- For each registered capability, score relevance (0-10) against this spec's domain
- Include anything scoring 5+
- Map to specific phases/tasks where they should be used
- Produce a **Recommended Arsenal** section with Skills, Agents, and MCP tables

This feeds directly into the Planner's capability assignment step.

## Step 6: Identify Unknowns

If anything requires technical investigation (library capabilities, API limits,
performance characteristics), create a research brief using the template at
`.spear/templates/plan/research-brief.md`. Do NOT guess -- flag it.

## Step 7: Format Specification (Non-Code Deliverables)

If this SPEAR cycle produces non-code deliverables (documents, reports, proposals,
grant applications, presentations, marketing materials), define the exact format
BEFORE building. Ambiguity in format creates revision loops.

### The Format Checklist

For each non-code deliverable, specify:

- **Document Type**: Report, memo, email, proposal, script, code, presentation?
- **File Formats**: PDF, Word, Markdown, HTML? What does the recipient need?
- **Structure**: Table of contents? Section headings? Appendices?
- **Length**: Word count range. Page count target. Character limits if applicable.
- **Visual Elements**: Tables? Charts? Images? What types?
- **Tone**: Formal or conversational? Technical level? Brand voice?
- **Naming Convention**: File naming pattern. Version numbering.

Write the format spec to the relevant shard or PRD deliverable section.
If no non-code deliverables exist, skip this step.

## Step 8: Produce Outputs

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

## Step 9: Self-Audit Checklist

Before presenting outputs, verify:

### Ignition Gate (Step 0)
- [ ] Ignition outputs loaded (if `/ignite` was run) or user notified to consider it
- [ ] Outcome Formula referenced in PRD problem statement (if available)
- [ ] Key Questions answers incorporated (no re-asking what was already answered)

### Constraints Gate (Step 5)
- [ ] All 7 constraint categories evaluated (budget, time, team, tech, legal, knowledge, client)
- [ ] Each constraint classified as Hard or Soft
- [ ] No Hard constraint conflicts with the Outcome -- or conflict surfaced to user

### Format Gate (Step 7)
- [ ] Non-code deliverables have format specs (or "no non-code deliverables" noted)

### Musk Gate (Steps 2-4)
- [ ] Requirement Challenge Log produced with verdicts for every requirement
- [ ] At least one requirement KILLED or SIMPLIFIED (or justified why all survived)
- [ ] Deletion Proposal produced (or "no deletions" with review count)
- [ ] Simplification pass applied to surviving scope
- [ ] Order enforced: challenge → delete → simplify → specify

### Dependency & Compliance Gate (Steps 5c-5e)
- [ ] Dependency Audit Table complete — every dep has version, license, CVE status, risk
- [ ] License compatibility verified — no copyleft contamination in proprietary code
- [ ] CVE scan run — cargo audit / npm audit / pip-audit executed, results documented
- [ ] System dependencies listed — OS packages, native libs, runtimes
- [ ] Compliance section fully evaluated — App Store, Regulatory, Security, License (each PASS/N/A/NEEDS REVIEW)
- [ ] Recommended Arsenal populated — best skills, agents, MCPs identified with relevance scores

### Spec Quality
- [ ] Problem is clearly stated with concrete impact
- [ ] Goals are testable -- each has a yes/no verification method
- [ ] Non-goals explicitly exclude adjacent scope
- [ ] Acceptance criteria are measurable and independently verifiable
- [ ] Architecture references existing codebase patterns (or justifies new ones)
- [ ] All dependencies identified with full audit table
- [ ] Open questions have owners and indicate what they block
- [ ] Research briefs created for unresolved unknowns
- [ ] Specs are written so someone without context can implement them
- [ ] Past decisions from memory are referenced where relevant

## Step 10: Present and Review

Present a summary of all outputs with:
1. The problem being solved (1-2 sentences)
2. Number of shards created and their names
3. Number of research briefs (if any)
4. Key architectural decisions made
5. Open questions that need resolution before Plan phase

Ask: "Ready to approve this spec and move to Plan phase?"

The Spec phase is complete only when the user approves all outputs.
