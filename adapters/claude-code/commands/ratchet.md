# /ratchet -- SPEAR Ratchet Phase

# INSTALLATION: Copy this file to .claude/commands/ratchet.md in your project.
# Usage: Type /ratchet in Claude Code to invoke this command.

You are entering the **Ratchet phase** of the SPEAR framework. Your job is
to learn from this cycle, tighten quality thresholds, generate new rules from
findings, and record decisions in memory. The ratchet is monotonic by default:
quality only goes up.

## Prerequisites

Before proceeding, verify:
1. Audit report exists with a GO or CONDITIONAL GO verdict
2. Fitness function measurements are available
3. Current ratchet state is in `.spear/ratchet/ratchet.json`

If audit verdict was NO-GO, do not proceed. Tell the user to fix findings
and re-run `/audit` first.

## Step 1: Read Current State

1. Read `.spear/ratchet/ratchet.json` -- current thresholds, rules, and cycle times
2. Read `.spear/output/audit/audit-report.md` -- findings, measurements, and capability utilization
3. Read `.spear/output/execute/execution-report.md` -- fitness results, phase duration, capability utilization
4. Read `.spear/ratchet/history.jsonl` -- past threshold changes
5. Read `.spear/capability-registry.json` -- registered capabilities
6. Read `.spear/output/spec/requirement-challenge.md` -- Musk gate results
7. Read `.spear/output/spec/deletion-proposal.md` -- deletion results

Report: current thresholds, measured values, cycle time for this phase,
and capability utilization rate.

## Step 2: Auto-Tighten Thresholds

For each threshold in `ratchet.json`, compare current value to threshold:

### Floor Metrics (higher is better: test coverage, doc coverage)
- If measured value > threshold + 5%: tighten threshold to (measured - 2% buffer)
- If measured value > threshold but < threshold + 5%: no change
- If measured value < threshold: THIS IS A REGRESSION -- flag it

### Ceiling Metrics (lower is better: bundle size, complexity, build time)
- If measured value < threshold - 5%: tighten threshold to (measured + 2% buffer)
- If measured value < threshold but > threshold - 5%: no change
- If measured value > threshold: THIS IS A REGRESSION -- flag it

Show the user a table:

| Metric | Old Threshold | Measured | New Threshold | Change |
|--------|--------------|----------|---------------|--------|

## Step 3: Generate Rules from Findings

For every audit finding with severity >= HIGH:

1. Extract the pattern that caused the finding
2. Create a ratchet rule that prevents recurrence
3. Write the rule in YAML format

Rule format:
```yaml
id: "RULE-NNN"
created_from: "[finding ID]"
category: "[audit category]"
description: "[What this rule prevents]"
check: "[How to verify compliance]"
severity: "[CRITICAL|HIGH]"
auto_generated: true
```

Write rules to: `.spear/ratchet/rules/RULE-NNN.yaml`
Add rule IDs to `active_rules` array in `ratchet.json`.

## Step 4: Record in Memory

### Decisions
For every significant architectural or technical decision made during this
cycle, create an ADR in `.spear/memory/decisions/`:

```markdown
# ADR-NNN: [Decision Title]
**Date:** [YYYY-MM-DD]
**Status:** accepted
**Context:** [Why this decision was needed]
**Decision:** [What was decided]
**Consequences:** [What follows from this decision]
```

### Findings Archive
Move resolved findings to `.spear/memory/findings/` for future reference.

### Patterns
If a new code pattern was established, document it in `.spear/memory/patterns/`.

### Antipatterns
If a mistake was made and corrected, document the antipattern in
`.spear/memory/antipatterns/` so it is not repeated.

### Update Memory Index
Add all new entries to `.spear/memory/index.json`.

## Step 5: Log Changes

Append every threshold change and rule creation to `.spear/ratchet/history.jsonl`:

```json
{"timestamp": "ISO-8601", "type": "threshold_tighten", "metric": "...", "old": ..., "new": ..., "reason": "auto-tighten: measured X exceeded threshold Y by >5%"}
{"timestamp": "ISO-8601", "type": "rule_created", "rule_id": "RULE-NNN", "from_finding": "...", "description": "..."}
```

## Step 5b: Record Cycle Time

Extract phase durations from the execution report and spec/plan timestamps:
- Spec phase duration (start → approval)
- Plan phase duration (start → plan approved)
- Execute phase duration (start → all fitness green)
- Audit phase duration (start → verdict)
- Ratchet phase duration (now)

Add to `cycle_times` section in `ratchet.json`. Compare to rolling average
of last 3 cycles. Flag SLOW (>2x avg) or FAST (<0.5x avg) phases.

## Step 5c: Record Capability Utilization

From the execution report and audit report, compile:
- Total registered capabilities available
- Total capabilities actually used
- Utilization rate (used / available)
- Missed opportunities (available but not used, no deviation logged)
- Fallback incidents (assigned but unavailable at runtime)

Add to retrospective. If utilization < 50%, flag as INFO: "Consider whether
the capability registry needs updating or whether tasks are under-leveraging
available tools."

## Step 6: Write Retrospective

Produce a retrospective for this cycle using the template at
`.spear/templates/ratchet/retrospective.md`. Must include ALL sections:

1. **What went well:** (bullets)
2. **What did not go well:** (bullets)
3. **Musk Gate Results:** requirements challenged/killed/simplified, deletions
4. **Cycle Time:** per-phase durations with SLOW/FAST flags
5. **Capability Utilization:** used vs. available, missed opportunities
6. **Metrics snapshot:** threshold table with before/after
7. **Rules created:** list with descriptions
8. **Memory entries added:** count by category

Write to: `.spear/output/ratchet/retrospective.md`

## Step 7: Update ratchet.json

Write the updated `ratchet.json` with:
- New threshold values
- New rules added to `active_rules`
- `cycle_times` entry for this cycle (per-phase durations + flags)
- Updated `last_updated` timestamp
- Incremented version

## Step 8: Present Summary

Show the user:
1. Thresholds that were tightened (table)
2. Rules that were generated (list)
3. Memory entries created (count)
4. Retrospective highlights
5. Updated ratchet state

Inform the user: "SPEAR cycle complete. Quality floor has been raised.
Next cycle starts with /spec when you are ready."
