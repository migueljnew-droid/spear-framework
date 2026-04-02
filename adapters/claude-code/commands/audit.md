# /audit -- SPEAR Audit Phase

# INSTALLATION: Copy this file to .claude/commands/audit.md in your project.
# Usage: Type /audit in Claude Code to invoke this command.

You are entering the **Audit phase** of the SPEAR framework. Your job is to
independently review all changes across 6 categories and produce a GO/NO-GO
verdict. You are an auditor -- thorough, objective, evidence-based.

## Prerequisites

Before proceeding, verify:
1. Execute phase output exists (execution report, commits, checkpoints)
2. All fitness functions have been measured
3. Ratchet state is available
4. Capability registry exists (`.spear/capability-registry.json`)

If prerequisites are not met, tell the user to complete `/execute` first.

## Step 0: Load Capability Registry for Audit Enhancement

Read `.spear/capability-registry.json` and identify registered capabilities
that strengthen each audit category:

| Category | Registry Enhancement |
|----------|---------------------|
| Security | Registered security scanners, SAST tools, silent-failure-hunter |
| Dependencies | Registered dep audit tools, license checkers |
| Performance | Registered profilers, benchmark tools |
| Code Quality | Registered linters, code reviewers, code simplifiers |
| Documentation | Registered doc generators, comment analyzers |
| Architecture | Registered type analyzers, architecture reviewers |

For each category, invoke the relevant registered capability IN ADDITION to
your own analysis. Tag findings from registered capabilities with their source:
`[source: capability-name]`

Also check the execution report for **capability utilization**:
- Which registered capabilities were assigned but NOT used? Flag as INFO.
- Which tasks were "manual" that had a registered capability available? Flag as MEDIUM.

## Audit Scope

Review ALL changes from the most recent Execute phase. This includes:
- All committed code changes (read every diff)
- All new and modified test files
- All documentation changes
- Configuration changes
- Dependency additions or updates

## The 6 Audit Categories

Run each category independently. Each produces its own findings and verdict.

---

### Category 1: SECURITY
**Blocks on: CRITICAL**

Check for:
- [ ] Hardcoded secrets, API keys, tokens, passwords
- [ ] SQL injection, XSS, CSRF vulnerabilities
- [ ] Authentication and authorization gaps
- [ ] Input validation and sanitization
- [ ] Dependency vulnerabilities (known CVEs)
- [ ] Insecure cryptographic practices
- [ ] OWASP Top 10 violations
- [ ] Error messages that leak internal details
- [ ] Overly permissive CORS, file permissions, or access controls

---

### Category 2: DEPENDENCIES
**Blocks on: CRITICAL**

Check for:
- [ ] New dependencies justified and necessary
- [ ] No known vulnerabilities in added/updated packages
- [ ] License compatibility with project license
- [ ] Pinned versions (no floating ranges in production)
- [ ] No unnecessary transitive dependency bloat
- [ ] Deprecated packages identified

---

### Category 3: PERFORMANCE
**Blocks on: HIGH**

Check for:
- [ ] O(n^2) or worse algorithms where O(n) or O(n log n) is feasible
- [ ] Unnecessary allocations in hot paths
- [ ] Missing pagination on list endpoints
- [ ] N+1 query patterns
- [ ] Bundle/binary size increases justified
- [ ] Memory leaks (unclosed resources, growing collections)
- [ ] Build time not significantly increased

---

### Category 4: CODE QUALITY
**Blocks on: HIGH**

Check for:
- [ ] Code duplication (DRY violations)
- [ ] Dead code or unreachable branches
- [ ] Naming clarity (variables, functions, types)
- [ ] Error handling completeness (no swallowed errors)
- [ ] Test coverage for new code
- [ ] Consistent style with existing codebase
- [ ] Functions/methods not excessively long (>50 lines is suspect)
- [ ] Single Responsibility Principle adherence

---

### Category 5: DOCUMENTATION
**Blocks on: CRITICAL**

Check for:
- [ ] Public API documentation present for new endpoints/types
- [ ] README updated if behavior or setup changed
- [ ] Changelog entry for user-facing changes
- [ ] Inline comments for non-obvious logic
- [ ] Outdated documentation corrected
- [ ] Configuration options documented

---

### Category 6: ARCHITECTURE
**Blocks on: HIGH**

Check for:
- [ ] Layer violations (e.g., UI calling database directly)
- [ ] Circular dependencies between modules
- [ ] Pattern consistency with existing codebase
- [ ] Proper separation of concerns
- [ ] Interface contracts respected
- [ ] New patterns justified when existing patterns exist

---

## Outcome Verification Gate

Before running the technical audit categories, verify that the built thing
actually delivers what was promised. Code quality is necessary but not sufficient
-- fitness for purpose is the real test.

### Step A: Load the Outcome

Read the Outcome Formula from `.spear/output/ignition/outcome.md` (if it exists)
or the PRD problem statement from `.spear/output/spec/prd.md`.

### Step B: Verify Against Outcome

For each part of the Outcome Formula, verify:

| Check | Question | Pass? |
|-------|----------|-------|
| Outcome | Does this achieve what the Outcome Formula defined? | |
| Assumptions | Were all key questions answered? No gaps? | |
| Expertise | Does the depth match the assigned role? | |
| Research | Was the topic properly researched? | |
| Challenged | Were assumptions tested and risks identified? | |
| Constraints | Does it operate within all hard constraints? | |
| Format | Does it match the format specification exactly? (non-code only) | |
| Verified | Are all factual claims sourced? | |
| Confidence | Overall confidence rating (0-100%) | |

### Step C: Minimum Passing Criteria

- **Minimum QA score**: 80% of checks must pass
- **Minimum confidence**: 75%

If the output fails the Outcome Verification Gate, it is a NO-GO regardless of
what the 6 technical categories say. A perfectly coded feature that doesn't
deliver the outcome is a perfectly coded failure.

Record the Outcome Verification in the audit report under a new section
between Summary and Category Reports.

---

## Ensemble Auditing (Multi-LLM Cross-Validation)

If `.spear/config.json` has `audit.ensemble.enabled: true`, run ensemble
cross-validation after your own analysis of each category.

### How Ensemble Works

For each category you audit:

1. **You audit first.** Use Read/Grep/Glob to analyze the code and produce your findings.
2. **Prepare a review packet.** Collect the relevant code diffs and your findings into a prompt.
3. **Send to external LLMs via `llm_compare`.** Call the `mcp__llm-gateway__llm_compare` tool with:
   - `providers`: from `config.json` `audit.ensemble.providers`
   - `prompt`: the review packet (code context + your findings + "what did I miss?")
   - `system`: a system prompt defining the audit category checklist
4. **Merge findings.** Parse each external LLM's response for new findings you missed.
   - `merge_strategy: "union"` — add all unique findings from any model
   - `merge_strategy: "consensus"` — only add findings that `min_agreement` models agree on
5. **Tag ensemble findings.** Any finding surfaced by an external LLM gets tagged `[ENSEMBLE]`
   and includes which provider(s) flagged it.

### Review Packet Format

Build the prompt like this:
```
I am auditing a codebase for [CATEGORY] issues. Below is the code diff
and my initial findings. Please review and identify any issues I missed.
Return findings in this exact format:

### [SEVERITY] [Category]-[NNN]: [Title]
**File:** [path:line]
**Severity:** CRITICAL | HIGH | MEDIUM | LOW | INFO
**Description:** [issue]
**Evidence:** [code reference]
**Recommendation:** [fix]

---
CODE DIFF:
[truncated to max_context_lines from config]

---
MY FINDINGS:
[your findings for this category]

---
What security/performance/quality issues did I miss?
```

### When Ensemble is Disabled

If `audit.ensemble.enabled` is `false` (the default), skip this section entirely
and audit using only your own analysis. Do not call llm-gateway tools.

### Ensemble Reporting

In the audit report, add an **Ensemble Results** section after the main categories:
- Which providers were consulted
- How many additional findings each provider surfaced
- Agreement rate between Claude and external models
- Any findings where external models disagreed with your severity assessment

---

## Finding Format

For each finding, record:

```markdown
### [SEVERITY] [Category]-[NNN]: [Short Title]

**File:** [path/to/file.ext:line]
**Category:** [Security|Dependencies|Performance|Code Quality|Documentation|Architecture]
**Severity:** [CRITICAL|HIGH|MEDIUM|LOW|INFO]

**Description:** [What the issue is]
**Evidence:** [Code snippet or reference]
**Recommendation:** [How to fix]
**Effort:** [S|M|L]
```

## Verdict Rules

- **GO**: Zero CRITICAL findings. Zero unresolved HIGH findings.
- **CONDITIONAL GO**: Zero CRITICAL. HIGH findings have approved justifications.
- **NO-GO**: Any CRITICAL finding, OR HIGH findings without justification.

## Output

Write the full audit report to: `.spear/output/audit/audit-report.md`

Structure:
1. **Summary**: Total findings by severity, GO/NO-GO verdict
2. **Outcome Verification**: QA score, confidence rating, pass/fail (from Outcome Gate)
3. **Category Reports**: One section per category with all findings
4. **Capability Utilization**: Which registered capabilities were used, missed, or failed
5. **Ensemble Results** (if enabled): Providers consulted, additional findings, agreement rates
6. **Ratchet Compliance**: Did any threshold regress? Did any rule fire?
7. **Fitness Function Review**: Are all functions green?
8. **Verdict**: GO, CONDITIONAL GO, or NO-GO with reasoning

## After the Audit

Present the verdict to the user with:
1. Total findings count by severity
2. The verdict (GO / CONDITIONAL GO / NO-GO)
3. If NO-GO: list the blocking findings and what needs to be fixed
4. If GO: suggest running `/ratchet` to lock in improvements

If NO-GO, the user should fix findings and run `/audit` again.
If GO, suggest: "Audit passed. Ready to run /ratchet to lock in gains?"
