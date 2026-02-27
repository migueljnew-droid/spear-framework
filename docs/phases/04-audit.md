# Phase 4: Audit

The Audit phase verifies that what was built matches what was specified, meets quality standards, and doesn't introduce regressions. Six independent audit categories run in parallel, each producing findings with severity levels.

---

## Running an Audit

```bash
spear audit --plan plan-001
```

This runs all six categories against the code changes associated with the plan. Each category runs independently — a slow security scan doesn't block the architecture review.

### Targeted Audits

Run a single category:

```bash
spear audit --plan plan-001 --category security
```

Run multiple specific categories:

```bash
spear audit --plan plan-001 --category security,performance
```

Re-run after fixes:

```bash
spear audit --plan plan-001 --rerun
# => Only re-runs categories with CRITICAL or HIGH findings
```

---

## The Six Audit Categories

### 1. Architecture

Checks structural soundness:
- Does the implementation follow established patterns?
- Are module boundaries respected?
- Are dependencies flowing in the right direction?
- Is there unnecessary coupling between components?
- Does the change fit the existing architecture or fight it?

### 2. Code Quality

Checks implementation quality:
- Code readability and naming conventions
- Function length and complexity (cyclomatic)
- Duplication detection
- Documentation coverage (JSDoc, docstrings, comments)
- Linting compliance

### 3. Security

Checks for vulnerabilities:
- OWASP Top 10 issues
- Input validation and sanitization
- Authentication/authorization flaws
- Secrets in code or config
- Dependency vulnerabilities (npm audit, cargo audit, etc.)
- SQL injection, XSS, CSRF exposure

### 4. Performance

Checks for performance issues:
- N+1 query patterns
- Missing database indexes for queried fields
- Unbounded operations (no pagination, no limits)
- Memory leaks (event listeners, unclosed connections)
- Response time estimates for critical paths

### 5. Testing

Checks test coverage and quality:
- Line and branch coverage percentages
- Critical path test coverage
- Edge case coverage (nulls, empty, overflow, unicode)
- Test isolation (no shared state between tests)
- Test naming and organization

### 6. Spec Compliance

Checks implementation against the original spec:
- Every acceptance criterion has corresponding implementation
- Every acceptance criterion has a corresponding test
- Constraints are satisfied
- Out-of-scope items were not accidentally included
- Non-functional requirements are met

---

## Severity Classification Guide

### CRITICAL — Blocks ratchet, must fix

Definition: The finding represents a correctness, security, or data integrity issue that will cause harm in production.

Examples:
- SQL injection vulnerability in user input handling
- Passwords stored in plaintext
- Authentication bypass possible via parameter tampering
- Data loss possible under concurrent operations
- Acceptance criteria from spec not implemented at all

Response: Fix before ratcheting. No exceptions.

### HIGH — Should fix, doesn't block

Definition: The finding represents a significant quality issue that should be addressed but doesn't cause immediate harm.

Examples:
- Missing input validation on non-critical fields
- No rate limiting on expensive operations
- Test coverage below project threshold for new code
- Missing error handling on external service calls
- Performance regression of 2-5x on non-critical paths

Response: Fix now or create a tracked follow-up spec. The finding is logged regardless.

### MEDIUM — Improve when possible

Definition: The finding represents a code quality or maintainability issue.

Examples:
- Functions exceeding complexity thresholds
- Missing documentation on public interfaces
- Inconsistent naming conventions
- Suboptimal but functional query patterns
- Test names don't describe behavior

Response: Fix during this cycle if time permits, otherwise address in next related spec.

### LOW — Informational

Definition: Observations and suggestions for improvement.

Examples:
- Alternative approach would be more idiomatic
- Opportunity to extract shared utility
- Config value could be externalized
- Related TODO in adjacent code
- Style preference differences

Response: Note for future reference. No action required.

---

## Audit Output Format

```bash
spear audit --plan plan-001
```

```
SPEAR Audit Report — plan-001 (spec-001: User Authentication)
Generated: 2026-02-26T14:30:00Z

=== Architecture (Score: 92/100) ===
[MEDIUM] ARCH-001: Auth middleware in routes/ directory; consider middleware/ directory
  File: src/routes/auth.js:15
  Suggestion: Move verifyToken to src/middleware/auth.js for consistency

=== Code Quality (Score: 88/100) ===
[HIGH] CQ-001: hashPassword function missing JSDoc documentation
  File: src/utils/hash.js:12
  Required: Public functions must have JSDoc with @param and @returns
[MEDIUM] CQ-002: loginHandler function has cyclomatic complexity of 8
  File: src/routes/auth.js:45
  Suggestion: Extract validation logic into separate function

=== Security (Score: 95/100) ===
[MEDIUM] SEC-001: JWT expiry of 1 hour may be long for sensitive operations
  File: src/utils/token.js:8
  Suggestion: Consider 15-minute access token + refresh token pattern

=== Performance (Score: 90/100) ===
[MEDIUM] PERF-001: User.findByEmail does full table scan without index
  File: src/models/user.js:28
  Note: Deviation DEV-001 added this index — verify migration ran

=== Testing (Score: 85/100) ===
[HIGH] TEST-001: No test for concurrent registration with same email
  File: tests/auth.test.js
  Missing: Race condition test for duplicate email handling
[MEDIUM] TEST-002: Login failure test doesn't verify response body shape
  File: tests/auth.test.js:67
  Suggestion: Assert that error response has { error: string } shape

=== Spec Compliance (Score: 100/100) ===
All 9 acceptance criteria verified.

=== Summary ===
Total findings: 6 (0 CRITICAL, 2 HIGH, 4 MEDIUM, 0 LOW)
Overall: PASS — no CRITICAL findings
Recommendation: Fix HIGH findings before ratcheting

Deviations reviewed: 1
  DEV-001 (email index addition) — Reviewed: improvement, no concerns
```

---

## Handling CRITICAL vs HIGH Findings

### CRITICAL Finding Flow

```
CRITICAL found
    |
    v
Must fix? ──yes──> Fix code
    |                  |
    no                 v
    |              Re-run audit
    v                  |
Override? ──no──> Cannot ratchet (blocked)
    |
    yes
    v
Justify override ──> Logged permanently
    |
    v
Override approved ──> Ratchet allowed (with flag)
```

### Override Justification

In rare cases, a CRITICAL finding may be a false positive or acceptable risk:

```bash
spear audit override --finding SEC-001 \
  --justification "False positive: input is pre-validated by API gateway. \
  Gateway config in infrastructure/nginx.conf line 45 handles this." \
  --approved-by "senior-dev"
```

Overrides are:
- Logged permanently in `.spear/audits/overrides/`
- Visible in all future audits
- Included in ratchet reports
- Flagged if the overridden code changes (re-audit triggered)

### HIGH Finding Flow

HIGH findings don't block the ratchet but are tracked:

```bash
# Option 1: Fix now
# (make the fix, commit, re-run audit)

# Option 2: Track for later
spear audit defer --finding CQ-001 \
  --reason "Will address in spec-006 (documentation pass)" \
  --deadline 2026-03-15
```

Deferred HIGH findings appear in the next audit as reminders.

---

## Example: Auth Feature Audit Findings

After executing all three phases of the auth feature:

```bash
spear audit --plan plan-001
```

Findings:

| ID | Category | Severity | Description |
|----|----------|----------|-------------|
| CQ-001 | Code Quality | HIGH | hashPassword missing JSDoc |
| TEST-001 | Testing | HIGH | No concurrent registration test |
| ARCH-001 | Architecture | MEDIUM | Auth middleware in wrong directory |
| CQ-002 | Code Quality | MEDIUM | loginHandler complexity 8 |
| SEC-001 | Security | MEDIUM | JWT 1h expiry may be long |
| PERF-001 | Performance | MEDIUM | Verify email index migration |

Action taken:

```bash
# Fix the two HIGH findings
vim src/utils/hash.js          # Add JSDoc
vim tests/auth.test.js         # Add concurrency test
git commit -m "fix(auth): add JSDoc and concurrent registration test [spec-001/audit]"

# Re-run audit
spear audit --plan plan-001 --rerun
# => 0 CRITICAL, 0 HIGH, 4 MEDIUM
# => Ready to ratchet
```

---

## Audit Configuration

Customize audit behavior in `.spear/config.json`:

```json
{
  "audit": {
    "categories": ["architecture", "code_quality", "security", "performance", "testing", "spec_compliance"],
    "block_on": ["CRITICAL"],
    "parallel": true,
    "timeout_seconds": 300,
    "custom_rules": ".spear/audit-rules/"
  }
}
```

- `block_on`: Which severities prevent ratcheting. Default: `["CRITICAL"]`.
- `parallel`: Run categories simultaneously. Default: `true`.
- `timeout_seconds`: Max time per category. Default: `300`.
- `custom_rules`: Directory for project-specific audit rules.
