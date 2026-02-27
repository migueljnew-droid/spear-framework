# /status -- SPEAR Status Dashboard

# INSTALLATION: Copy this file to .claude/commands/status.md in your project.
# Usage: Type /status in Claude Code to invoke this command.

You are displaying the current SPEAR framework status for this project.
Read state from `.spear/` and present a clear, concise dashboard.

## Step 1: Read State Files

Read the following files (skip any that do not exist):

1. `.spear/config.json` -- project configuration
2. `.spear/ratchet/ratchet.json` -- current thresholds and rules
3. `.spear/ratchet/history.jsonl` -- recent threshold changes (last 10)
4. `.spear/memory/index.json` -- memory entry count
5. `.spear/output/` -- check which phase outputs exist

## Step 2: Determine Current Phase

Check which outputs exist to determine where the project is in the SPEAR cycle:

- If no `.spear/output/spec/` exists: **Not started** -- suggest `/spec`
- If spec exists but no plan: **Spec complete** -- suggest `/plan`
- If plan exists but no execute report: **Plan complete** -- suggest `/execute`
- If execute report exists but no audit report: **Execute complete** -- suggest `/audit`
- If audit report exists with NO-GO: **Audit failed** -- suggest fixing and re-running `/audit`
- If audit report exists with GO but no retrospective: **Audit passed** -- suggest `/ratchet`
- If retrospective exists: **Cycle complete** -- suggest `/spec` for next cycle

## Step 3: Present Dashboard

Format as follows:

```
== SPEAR Status ==

Project: [name from config.json]
Current Phase: [phase name]
Next Action: [suggested command]

== Ratchet Thresholds ==

| Metric           | Value  | Direction | Status |
|------------------|--------|-----------|--------|
| Test Coverage    | [val]% | floor     | [ok/warn/fail] |
| Doc Coverage     | [val]% | floor     | [ok/warn/fail] |
| Max Complexity   | [val]  | ceiling   | [ok/warn/fail] |
| Max Bundle Size  | [val]kb| ceiling   | [ok/warn/fail] |
| Max Build Time   | [val]s | ceiling   | [ok/warn/fail] |

== Active Rules ==

[List active rules from ratchet.json, or "None" if empty]

== Recent History ==

[Last 5 entries from history.jsonl, or "No history yet"]

== Memory ==

- Decisions: [count]
- Findings: [count]
- Patterns: [count]
- Antipatterns: [count]

== Phase Outputs ==

- Spec: [exists/missing] [file count if exists]
- Plan: [exists/missing] [file count if exists]
- Execute: [exists/missing] [file count if exists]
- Audit: [exists/missing] [verdict if exists]
- Ratchet: [exists/missing] [file count if exists]
```

## Step 4: Warnings

If any of these conditions are true, add a warning section:

- Ratchet thresholds have not been updated in >30 days
- Memory index is empty
- Active rules list is empty after a completed cycle
- Audit report has unresolved HIGH findings
- Any ratchet threshold is in "fail" state

```
== Warnings ==

[!] [Warning message and suggested action]
```

Keep the output concise and scannable. This is a status check, not a report.
