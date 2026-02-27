# SPEAR Spec Workflow -- Antigravity Format
#
# INSTALLATION: Copy .agents/ directory to your project root.
# Trigger: User requests a new feature, product, or specification.

name: SPEAR Specification
description: Gather requirements and produce structured specifications
trigger: User requests feature development, product spec, or architecture design

## Steps

### Step 1: Context Gathering
Read existing context before writing anything:
- Read `.spear/memory/index.json` for past decisions and patterns
- Read `.spear/memory/decisions/` for relevant ADRs
- Read `.spear/ratchet/ratchet.json` for current quality thresholds
- Scan existing codebase for relevant modules and patterns

Output: Brief context summary (3-5 bullets)

### Step 2: Requirements Clarification
Ask the user clarifying questions grouped by category:
- **Scope**: What is included? What is excluded?
- **Behavior**: How should it work? Edge cases?
- **Constraints**: Performance, security, compliance requirements?
- **Dependencies**: What does this depend on? What depends on this?

Wait for user responses before continuing.

### Step 3: Unknown Identification
For any technical unknowns (library capabilities, API limits, performance):
- Create a research brief using `.spear/templates/plan/research-brief.md`
- Do NOT assume -- flag and document the unknown

### Step 4: PRD Creation
Using template `.spear/templates/spec/prd.md`, produce:
- Problem statement with concrete impact
- Testable goals and explicit non-goals
- User stories with priorities
- Acceptance criteria (measurable, verifiable)
- Technical constraints and dependencies
- Open questions with owners

Output to: `.spear/output/spec/prd.md`

### Step 5: Architecture Document
Using template `.spear/templates/spec/architecture.md`, produce:
- System context and boundaries
- Component diagram with responsibilities
- Data flow for primary and secondary paths
- API contracts with request/response schemas
- Technology choices with alternatives considered
- Security and performance considerations

Must reference existing codebase patterns from memory.
Output to: `.spear/output/spec/architecture.md`

### Step 6: Epic Shards
Using template `.spear/templates/spec/epic-shard.md`:
- Break work into bite-sized deliverables
- Each shard: objective, scope, acceptance criteria, fitness functions
- Order by dependency (no shard depends on a later shard)
- Name: `SHARD-001-[name].md`, `SHARD-002-[name].md`, etc.

Output to: `.spear/output/spec/shards/`

### Step 7: Review
Present summary to user:
1. Problem being solved
2. Number and names of shards
3. Key architectural decisions
4. Open questions needing resolution
5. Research briefs (if any)

Ask for approval before proceeding to Plan phase.
