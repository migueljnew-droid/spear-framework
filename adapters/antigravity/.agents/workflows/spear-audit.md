# SPEAR Audit Workflow -- Antigravity Format
#
# INSTALLATION: Copy .agents/ directory to your project root.
# Trigger: Execute phase is complete, user requests audit.

name: SPEAR Audit
description: Independent 6-category audit with GO/NO-GO verdict
trigger: Execution complete, user invokes audit

## Prerequisites
- Execution report exists at `.spear/output/execute/execution-report.md`
- All fitness functions measured
- Ratchet state available

## Steps

### Step 1: Scope Identification
- Identify all changes from the Execute phase
- Read every diff, new file, modified test, config change
- Read ratchet state for threshold comparison

### Step 2: Category Audits (run all 6)

#### 2a: Security Audit (blocks: CRITICAL)
Apply rules from `.agents/rules/audit-security.md`:
- Hardcoded secrets, keys, tokens
- Injection vulnerabilities (SQL, XSS, CSRF)
- Authentication and authorization gaps
- Input validation completeness
- Known CVEs in dependencies
- Error messages leaking internals

#### 2b: Dependencies Audit (blocks: CRITICAL)
- New deps justified and necessary
- No known vulnerabilities
- License compatibility
- Versions pinned (no floating ranges)
- No unnecessary transitive bloat

#### 2c: Performance Audit (blocks: HIGH)
- Algorithm complexity appropriate
- No N+1 query patterns
- Pagination on list operations
- Bundle/binary size changes justified
- No memory leaks

#### 2d: Code Quality Audit (blocks: HIGH)
Apply rules from `.agents/rules/audit-quality.md`:
- No code duplication
- No dead code
- Clear naming conventions
- Complete error handling
- Test coverage for new code
- Functions under 50 lines

#### 2e: Documentation Audit (blocks: CRITICAL)
- Public API docs for new endpoints/types
- README updated if behavior changed
- Changelog for user-facing changes
- Non-obvious logic commented

#### 2f: Architecture Audit (blocks: HIGH)
- No layer violations
- No circular dependencies
- Pattern consistency with codebase
- Separation of concerns maintained
- New patterns justified

### Step 3: Finding Documentation
For each finding, record:
- Severity: CRITICAL / HIGH / MEDIUM / LOW / INFO
- Category: which of the 6
- File path and line number
- Evidence (code snippet)
- Recommendation to fix
- Estimated fix effort (S/M/L)

### Step 4: Ratchet Compliance Check
- Compare all measured metrics to ratchet thresholds
- Any regression is a finding (severity based on degree)
- Check all active rules from `ratchet.json`

### Step 5: Verdict
- **GO**: Zero CRITICAL, zero unresolved HIGH
- **CONDITIONAL GO**: Zero CRITICAL, HIGH findings have justifications
- **NO-GO**: Any CRITICAL, or HIGH without justification

### Step 6: Report
Write to `.spear/output/audit/audit-report.md`:
1. Summary: finding counts by severity, verdict
2. Category reports (6 sections)
3. Ratchet compliance
4. Fitness function review
5. Final verdict with reasoning

Present to user with next step recommendation.
