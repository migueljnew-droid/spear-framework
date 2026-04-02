# /ignite -- SPEAR Ignition Phase (Pre-Spec Intent Clarification)

# INSTALLATION: Copy this file to .claude/commands/ignite.md in your project.
# Usage: Type /ignite in Claude Code before /spec to clarify intent.

# Inspired by Project Ignition (Rico Williams, UDIG Solutions Inc.)
# Integrated into SPEAR by Miguel Jiminez, April 2026

You are entering the **Ignition phase** of the SPEAR framework. This is a
pre-spec phase that forces precision of intent before any specification is
written. Your job is to eliminate ambiguity, assumptions, and wasted cycles
by defining exactly what success looks like BEFORE the spec phase begins.

**Rule:** No spec is written until the Outcome Formula is complete, all key
questions are answered, and the expert role is assigned.

## Step 0: Outcome First

Every project begins with a single statement that defines the desired outcome.
Not the task. The RESULT.

### The Outcome Formula

Guide the user to fill in all four parts:

```
I need [SPECIFIC DELIVERABLE]
that [MEASURABLE ACTION OR RESULT]
for [TARGET AUDIENCE]
in [CONTEXT OR TIMEFRAME]
```

### How to Use It

1. Ask: "What is the result you need?" (not "what do you want to build")
2. Write the outcome using the formula
3. If any of the four parts are vague, dig deeper before proceeding
4. Apply **The Test**: "If I handed this to a stranger with the right expertise,
   could they deliver exactly what you need without asking a single question?"
   If the answer is no, the outcome is not specific enough.

### Examples

**Bad (task-focused):** "Build me a reentry app."
**Good (outcome-focused):** "I need a mobile application that connects
returning citizens with housing, jobs, and legal aid within 48 hours of release,
for formerly incarcerated individuals in Georgia, launching by Q3 2026."

**Bad:** "Make a mastering plugin."
**Good:** "I need a Rust audio plugin that produces mastering quality matching
FabFilter Pro-L 2, for independent artists who can't afford $200 plugins,
shipping as VST3/AU within Mercury Studio by end of April."

Write the approved Outcome Formula to: `.spear/output/ignition/outcome.md`

## Step 0.5: Key Questions

The AI asks before it assumes. Always.

### The Smart Threshold

Not every missing detail requires a hard stop:

| What's Missing | Impact on Output | Action |
|----------------|-----------------|--------|
| Would change output by 50%+ (target audience, core outcome, jurisdiction) | **Hard stop.** Do not proceed. | Ask and wait. |
| Would change output by 20-50% (tone, budget, timeline) | **Stop and ask.** | Ask before proceeding. |
| Would change output by less than 20% (font, exact word count) | **State assumption and continue.** | Note it, move on. |

### The 7 Question Categories

For every project, ensure answers exist for these categories. Generate 8-15
targeted questions specific to THIS project. Ask them in batches of 3-4
(grouped by category), not all at once.

1. **AUDIENCE** — Who exactly is this for? What do they already know? What is
   their primary pain point? What language do they use?

2. **VOICE AND TONE** — Formal, conversational, authoritative, or adaptive?
   Any existing brand voice to match? Examples of what they like? What they hate?

3. **SCOPE** — How deep should this go? What is explicitly out of scope?
   What is the minimum viable deliverable?

4. **CONTEXT** — What has already been tried? What failed? What worked?
   What does this connect to before and after in the workflow?

5. **SUCCESS METRICS** — How will we know if this worked? What does "good"
   look like? What would a home run look like?

6. **EXISTING ASSETS** — What content, data, code, or materials already exist?
   What can be reused? What must be created?

7. **DEPENDENCIES** — Who else needs to approve? What systems does this plug
   into? What are the hard deadlines?

### How to Use It

1. Start with the Outcome Formula (Step 0)
2. Scan for gaps using the 7 categories
3. Generate 8-15 targeted questions specific to this project
4. Group questions by category, ask 3-4 at a time
5. Acknowledge answers before asking the next batch
6. If answers are incomplete, dig deeper — do not fill in blanks yourself

Write answered questions to: `.spear/output/ignition/key-questions.md`

## Step 1: Role Assignment

Set the expertise level before generating anything. The role defines the ceiling
of output quality.

### The Role Formula

For the AI agents that will execute this project, define the expert identity:

```
Act as a [WORLD-CLASS / TOP 1%] [SPECIFIC ROLE]
who has [SPECIFIC CREDENTIAL OR TRACK RECORD]
specializing in [SPECIFIC DOMAIN]
with deep expertise in [SPECIFIC SUB-DOMAIN]
```

### How to Map Roles

1. Identify the domain of the project from the Outcome Formula
2. Write the role using the formula above
3. The role should match the OUTCOME, not just the task
4. If multiple domains are involved, assign a primary role and supporting roles
5. Map roles to SOVEREIGN agents or Claude Code agent types from the
   Capability Registry (if it exists from a prior cycle)

### Examples

| Domain | Weak Role | Strong Role |
|--------|-----------|-------------|
| Legal | "Act as a lawyer" | "Top federal civil rights litigator with 20 years of 42 USC 1983 experience, specializing in due process violations in family court" |
| Music Tech | "Act as a developer" | "World-class audio DSP engineer who has built commercial mastering plugins, specializing in LUFS loudness control and Rust real-time audio" |
| Grant Writing | "Act as a writer" | "Top 1% federal grant writer who has secured $50M+ in DOJ/DOL grants, specializing in reentry program funding with OJJDP experience" |

Write role assignment to: `.spear/output/ignition/role-assignment.md`

## Step 2: First Principles Gate

After defining outcome, answering questions, and assigning roles — challenge
whether the conventional approach is actually correct.

### The Process

1. **State the problem.** Restate the Outcome Formula.
2. **List all current assumptions.** Everything everyone believes about how this
   should work. Industry conventions. "Best practices." Defaults.
3. **Challenge each one.** For every assumption, ask:
   - Is this actually true, or is it just convention?
   - What if the opposite were true?
   - Why does everyone do it this way?
4. **Identify fundamental truths.** What is definitely true regardless of
   assumptions? What are the physics, economics, or psychology of this problem?
5. **Rebuild from the fundamentals.** Using only the truths, sketch a solution.
   Ignore how it's "normally done."

The rebuilt solution may look similar to conventional. That's fine — as long as
each element earned its place through reasoning instead of copying.

Write first principles analysis to: `.spear/output/ignition/first-principles.md`

## Self-Audit Checklist

Before declaring Ignition complete, verify:

### Outcome (Pillar 0)
- [ ] Outcome Formula has all 4 parts filled (deliverable, result, audience, context)
- [ ] Passes The Test (stranger with expertise could deliver without questions)
- [ ] Written to `.spear/output/ignition/outcome.md`

### Key Questions (Pillar 0.5)
- [ ] All 7 question categories covered
- [ ] 8-15 targeted questions asked and answered
- [ ] No Hard Stop gaps remaining (50%+ impact items all resolved)
- [ ] Written to `.spear/output/ignition/key-questions.md`

### Role Assignment (Pillar 1)
- [ ] Role uses the Role Formula (world-class + credential + domain + sub-domain)
- [ ] Role matches the OUTCOME, not just the task
- [ ] Mapped to SOVEREIGN agents or Claude Code agent types where possible
- [ ] Written to `.spear/output/ignition/role-assignment.md`

### First Principles (Pillar 3)
- [ ] Assumptions listed and challenged
- [ ] Fundamental truths identified
- [ ] Solution rebuilt from fundamentals (even if similar to conventional)
- [ ] Written to `.spear/output/ignition/first-principles.md`

## Present and Handoff

Present a summary:
1. The Outcome Formula (1 statement)
2. Key questions answered (count) and any remaining assumptions
3. Expert role(s) assigned
4. First principles insights (any surprising departures from convention?)
5. Recommended approach for the Spec phase

Ask: "Ignition complete. Ready to move to /spec?"

The Ignition phase is complete when the user confirms. The spec-writer should
reference all Ignition outputs in `.spear/output/ignition/` during the Spec phase.
