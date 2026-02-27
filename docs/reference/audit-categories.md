# Reference: Audit Categories

Detailed reference for all six built-in audit categories. Each section includes: what the category checks, how it scores, severity classification, and example findings.

---

## 1. Architecture

### What It Checks

- **Module boundaries:** Are concerns properly separated? Does the route handler contain business logic that should be in a service?
- **Dependency direction:** Do dependencies flow inward (infrastructure depends on domain, not the other way)?
- **Pattern consistency:** Are established patterns followed? If the project uses repository pattern, does the new code use it too?
- **Coupling:** Are modules tightly coupled when they shouldn't be? Can you change one module without breaking others?
- **Naming conventions:** Do files, directories, and exports follow the project's naming patterns?

### Scoring

Starts at 100, deductions per finding:
- CRITICAL: -25 (circular dependency, wrong layer access)
- HIGH: -10 (pattern violation, misplaced logic)
- MEDIUM: -3 (naming inconsistency, minor coupling)
- LOW: -1 (style preference, alternative approach)

### Example Findings

```
[CRITICAL] ARCH-001: Circular dependency between userService and orderService
  File: src/services/userService.js:3
  Import: const orderService = require('./orderService')
  Impact: Circular dependencies cause unpredictable initialization order
  Fix: Extract shared logic to a new service or use events

[HIGH] ARCH-002: Database query in route handler (bypasses service layer)
  File: src/routes/v2/users.js:45
  Code: const user = await db.query('SELECT * FROM users WHERE id = $1', [id])
  Fix: Move to userService.findById() — routes should only call services

[HIGH] ARCH-003: Business logic in middleware
  File: src/middleware/calculateDiscount.js:12
  Impact: Middleware should handle cross-cutting concerns, not business rules
  Fix: Move discount calculation to pricingService

[MEDIUM] ARCH-004: Controller in services/ directory
  File: src/services/userController.js
  Fix: Move to src/controllers/ or src/routes/ per project convention

[LOW] ARCH-005: Utility function could be extracted to shared module
  File: src/routes/v2/payments.js:89
  Note: formatCurrency() is duplicated in 3 route files
```

---

## 2. Code Quality

### What It Checks

- **Readability:** Can a new developer understand this code without extensive context?
- **Documentation:** Are public functions documented with parameter and return types?
- **Complexity:** Are functions within reasonable cyclomatic complexity (typically under 10)?
- **Duplication:** Is there copy-pasted code that should be extracted?
- **Naming:** Do variable and function names accurately describe their purpose?
- **Error handling:** Are errors caught, logged, and handled appropriately?
- **Linting:** Does the code pass the project's linter without warnings?

### Scoring

Starts at 100, deductions per finding:
- CRITICAL: -25 (no error handling on critical path)
- HIGH: -10 (missing docs on public API, high complexity)
- MEDIUM: -3 (minor duplication, naming issues)
- LOW: -1 (style suggestions, optional improvements)

### Example Findings

```
[CRITICAL] CQ-001: Unhandled promise rejection in payment processing
  File: src/services/paymentService.js:34
  Code: stripe.paymentIntents.create(params)  // no .catch() or try/catch
  Impact: Unhandled rejection will crash the process in Node 18+
  Fix: Wrap in try/catch, handle Stripe API errors explicitly

[HIGH] CQ-002: Function processOrder has cyclomatic complexity of 15
  File: src/services/orderService.js:78
  Impact: High complexity correlates with bugs and makes testing difficult
  Fix: Extract validation, discount calculation, and inventory check into separate functions

[HIGH] CQ-003: Public function missing JSDoc documentation
  File: src/utils/token.js:12
  Code: function generateToken(payload, options) { ... }
  Fix: Add JSDoc with @param {object} payload, @param {object} options, @returns {string}

[MEDIUM] CQ-004: Variable name 'd' is not descriptive
  File: src/services/analyticsService.js:56
  Code: const d = new Date()
  Fix: Use 'currentDate' or 'timestamp'

[MEDIUM] CQ-005: Duplicated validation logic
  File: src/routes/v2/users.js:23 and src/routes/v2/payments.js:31
  Note: Email validation regex appears in both files
  Fix: Extract to src/utils/validators.js

[LOW] CQ-006: Console.log used instead of logger
  File: src/services/emailService.js:45
  Fix: Replace with logger.info() for structured logging
```

---

## 3. Security

### What It Checks

- **OWASP Top 10:** Injection, broken auth, sensitive data exposure, XXE, broken access control, misconfiguration, XSS, insecure deserialization, known vulnerable components, insufficient logging
- **Input validation:** Is all user input validated and sanitized before use?
- **Authentication:** Are auth mechanisms properly implemented? Token validation, session management?
- **Authorization:** Are access controls enforced? Can user A access user B's data?
- **Secrets:** Are any secrets, API keys, or passwords hardcoded?
- **Dependencies:** Are there known vulnerabilities in third-party packages?
- **Error information:** Do error responses leak internal details?

### Scoring

Starts at 100, deductions per finding:
- CRITICAL: -30 (injection vulnerability, auth bypass, secret exposure)
- HIGH: -15 (missing input validation, weak crypto, info leakage)
- MEDIUM: -5 (suboptimal security practice, minor misconfiguration)
- LOW: -1 (security improvement suggestion)

### Example Findings

```
[CRITICAL] SEC-001: SQL injection vulnerability
  File: src/models/user.js:34
  Code: db.query(`SELECT * FROM users WHERE email = '${email}'`)
  Impact: Attacker can extract or modify any database data
  Fix: Use parameterized query: db.query('SELECT * FROM users WHERE email = $1', [email])

[CRITICAL] SEC-002: JWT secret hardcoded in source
  File: src/config/auth.js:5
  Code: const JWT_SECRET = 'my-super-secret-key-12345'
  Impact: Anyone with source access can forge authentication tokens
  Fix: Use environment variable: process.env.JWT_SECRET

[HIGH] SEC-003: Password logged in debug output
  File: src/routes/v2/auth.js:28
  Code: logger.debug('Login attempt', { email, password })
  Impact: Passwords visible in log files
  Fix: Remove password from log: logger.debug('Login attempt', { email })

[HIGH] SEC-004: No rate limiting on authentication endpoint
  File: src/routes/v2/auth.js
  Impact: Brute force attacks possible without restriction
  Fix: Add express-rate-limit middleware (5 attempts per minute per IP)

[MEDIUM] SEC-005: Error response contains stack trace
  File: src/middleware/errorHandler.js:12
  Code: res.status(500).json({ error: err.message, stack: err.stack })
  Fix: Only include stack trace in development mode

[MEDIUM] SEC-006: CORS allows all origins
  File: src/app.js:15
  Code: app.use(cors({ origin: '*' }))
  Fix: Restrict to specific domains: cors({ origin: ['https://app.example.com'] })

[LOW] SEC-007: Consider adding Helmet.js for security headers
  File: src/app.js
  Suggestion: app.use(helmet()) adds CSP, HSTS, X-Frame-Options, etc.
```

---

## 4. Performance

### What It Checks

- **N+1 queries:** Is the code making N database queries when 1 would suffice?
- **Missing indexes:** Are frequently queried fields indexed?
- **Unbounded operations:** Are there queries or operations without limits or pagination?
- **Memory leaks:** Are event listeners cleaned up? Are connections closed?
- **Blocking operations:** Is synchronous I/O used where async is appropriate?
- **Caching opportunities:** Is expensive computation repeated without caching?
- **Response payload size:** Are API responses returning more data than needed?

### Scoring

Starts at 100, deductions per finding:
- CRITICAL: -25 (unbounded operation in production path, memory leak)
- HIGH: -10 (N+1 query, missing index on high-traffic query)
- MEDIUM: -3 (missing pagination, suboptimal query)
- LOW: -1 (caching opportunity, minor optimization)

### Example Findings

```
[CRITICAL] PERF-001: Unbounded database query returns all rows
  File: src/models/payment.js:45
  Code: Payment.findAll()  // no limit or pagination
  Impact: With 1M+ rows, this will exhaust memory and timeout
  Fix: Add pagination: Payment.findAll({ limit: 50, offset: page * 50 })

[HIGH] PERF-002: N+1 query pattern in order listing
  File: src/services/orderService.js:23
  Code: orders.map(o => User.findById(o.userId))  // 1 query per order
  Impact: 100 orders = 101 queries instead of 2
  Fix: Use eager loading: Order.findAll({ include: User })

[HIGH] PERF-003: Missing index on payments.user_id
  File: src/models/payment.js
  Query: SELECT * FROM payments WHERE user_id = $1 (used in /api/users/:id/payments)
  Impact: Full table scan on every request
  Fix: Add migration: CREATE INDEX idx_payments_user_id ON payments(user_id)

[MEDIUM] PERF-004: Large response payload — returning all user fields
  File: src/routes/v2/users.js:15
  Code: res.json(user)  // includes password_hash, internal flags
  Fix: Select specific fields or use a serializer

[LOW] PERF-005: Date parsing in hot path could be cached
  File: src/utils/dateFormatter.js:8
  Note: new Intl.DateTimeFormat() created on every call
  Fix: Create formatter once at module level
```

---

## 5. Testing

### What It Checks

- **Coverage:** What percentage of lines and branches are covered by tests?
- **Critical path coverage:** Are the most important code paths tested?
- **Edge cases:** Are boundary conditions, null inputs, and error paths tested?
- **Test isolation:** Do tests share state? Can they run in any order?
- **Test quality:** Do tests actually assert meaningful behavior (not just "it doesn't crash")?
- **Test naming:** Do test names describe the expected behavior?

### Scoring

Starts at 100, deductions per finding:
- CRITICAL: -25 (zero tests for critical business logic)
- HIGH: -10 (missing edge case tests, shared test state)
- MEDIUM: -3 (poor test names, low branch coverage)
- LOW: -1 (test organization suggestions)

### Example Findings

```
[CRITICAL] TEST-001: No tests for payment processing service
  File: src/services/paymentService.js
  Impact: 0% coverage on business-critical code that handles money
  Fix: Write tests for createPayment, confirmPayment, handleWebhook

[HIGH] TEST-002: Missing test for concurrent duplicate registration
  File: tests/auth.test.js
  Gap: What happens when two requests register the same email simultaneously?
  Fix: Add test with Promise.all([register(email), register(email)])

[HIGH] TEST-003: Tests share database state
  File: tests/payments.test.js
  Issue: Tests insert data but don't clean up — test order affects results
  Fix: Add beforeEach() to reset test database or use transactions

[MEDIUM] TEST-004: Test name doesn't describe behavior
  File: tests/auth.test.js:45
  Current: it('test login')
  Better: it('should return 401 when password is incorrect')

[MEDIUM] TEST-005: Branch coverage at 62% for auth middleware
  File: src/middleware/auth.js
  Missing branches: expired token path, malformed token path
  Fix: Add tests for jwt.verify() failure modes

[LOW] TEST-006: Consider extracting test helpers
  File: tests/payments.test.js
  Note: createTestUser() and createTestPayment() duplicated across 4 test files
  Fix: Extract to tests/helpers.js
```

---

## 6. Spec Compliance

### What It Checks

- **Acceptance criteria coverage:** Does every criterion from the spec have corresponding code?
- **Test coverage of criteria:** Does every criterion have a corresponding test?
- **Constraint satisfaction:** Are all technical constraints met?
- **Scope adherence:** Was anything built that's listed as "out of scope"?
- **Non-functional requirements:** Are performance, security, and other NFRs met?

### Scoring

Starts at 100, deductions per finding:
- CRITICAL: -25 (acceptance criterion not implemented)
- HIGH: -10 (criterion implemented but not tested, constraint violated)
- MEDIUM: -3 (NFR partially met, minor scope concern)
- LOW: -1 (implementation differs from spec description but meets intent)

### Example Findings

```
[CRITICAL] SPEC-001: Acceptance criterion not implemented
  Spec: spec-001, Criterion 8
  Expected: "Rate limiter blocks after 5 failed login attempts per minute"
  Actual: No rate limiting code found
  Fix: Implement rate limiting per the spec

[HIGH] SPEC-002: Acceptance criterion implemented but no test
  Spec: spec-001, Criterion 3
  Expected: "Passwords are hashed with bcrypt (cost factor 12+)"
  Implementation: Found in src/utils/hash.js
  Missing: No test verifying cost factor >= 12
  Fix: Add test asserting bcrypt.getRounds(hash) >= 12

[HIGH] SPEC-003: Constraint violated
  Spec: spec-001, Constraint: "Must use PostgreSQL"
  Actual: Redis used for session storage (not listed in constraints)
  Fix: Add Redis to constraints or switch to PostgreSQL-based sessions

[MEDIUM] SPEC-004: Non-functional requirement partially met
  Spec: spec-001, NFR: "Auth endpoint response time under 500ms"
  Actual: Register endpoint averages 450ms, login averages 380ms
  Note: Close to limit — monitor in production
  Suggestion: Consider caching bcrypt rounds or reducing cost factor to 11

[LOW] SPEC-005: Implementation approach differs from spec implication
  Spec: spec-001 implies separate /api/register and /api/login endpoints
  Actual: Combined under /api/auth/register and /api/auth/login
  Assessment: Functionally equivalent, better organized. Not a violation.
```

---

## Category Summary

| Category | Focus | Most Common CRITICAL | Most Common HIGH |
|----------|-------|---------------------|-----------------|
| Architecture | Structure | Circular dependencies | Pattern violations |
| Code Quality | Maintainability | Unhandled errors | Missing documentation |
| Security | Safety | Injection, secrets | Missing validation |
| Performance | Speed | Unbounded queries | N+1 patterns |
| Testing | Confidence | Zero coverage on critical code | Missing edge cases |
| Spec Compliance | Correctness | Unimplemented criteria | Untested criteria |
