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

If prerequisites are not met, tell the user to complete `/execute` first.

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
2. **Category Reports**: One section per category with all findings
3. **Ratchet Compliance**: Did any threshold regress? Did any rule fire?
4. **Fitness Function Review**: Are all functions green?
5. **Verdict**: GO, CONDITIONAL GO, or NO-GO with reasoning

## After the Audit

Present the verdict to the user with:
1. Total findings count by severity
2. The verdict (GO / CONDITIONAL GO / NO-GO)
3. If NO-GO: list the blocking findings and what needs to be fixed
4. If GO: suggest running `/ratchet` to lock in improvements

If NO-GO, the user should fix findings and run `/audit` again.
If GO, suggest: "Audit passed. Ready to run /ratchet to lock in gains?"
