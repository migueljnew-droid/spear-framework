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

## 5. Dependencies

### What It Checks

- **Known vulnerabilities:** Are there CVEs in third-party packages (npm audit, cargo audit, pip-audit)?
- **License compatibility:** Do dependency licenses conflict with the project license?
- **Outdated packages:** Are there major version updates available with security fixes?
- **Supply chain risks:** Are dependencies well-maintained? Any typosquatting risks?
- **Tree depth:** Is the dependency tree excessively deep or duplicated?
- **Lock file integrity:** Is the lock file in sync with the manifest?

### Scoring

Starts at 100, deductions per finding:
- CRITICAL: -30 (known exploited CVE, license violation)
- HIGH: -15 (high-severity CVE, unmaintained critical dependency)
- MEDIUM: -5 (outdated major version, moderate CVE)
- LOW: -1 (minor version behind, optimization opportunity)

### Example Findings

```
[CRITICAL] DEP-001: Critical CVE in dependency
  Package: lodash@4.17.15
  CVE: CVE-2021-23337 (prototype pollution)
  Impact: Remote code execution via crafted input
  Fix: Upgrade to lodash@4.17.21: npm install lodash@4.17.21

[HIGH] DEP-002: Unmaintained critical dependency
  Package: request@2.88.2
  Issue: Deprecated, no security patches since 2020
  Impact: Known vulnerabilities will never be patched
  Fix: Replace with node-fetch or axios

[HIGH] DEP-003: License incompatibility
  Package: gpl-module@1.0.0
  License: GPL-3.0
  Project license: MIT
  Impact: GPL requires derivative works to also be GPL
  Fix: Replace with MIT/Apache-2.0 licensed alternative

[MEDIUM] DEP-004: Major version behind
  Package: express@4.18.2
  Latest: express@5.0.1
  Note: Express 5 includes security improvements and breaking changes
  Fix: Review migration guide and upgrade

[MEDIUM] DEP-005: Lock file out of sync
  File: package-lock.json
  Issue: package.json specifies "^3.0.0" but lock has 2.8.1
  Fix: Run npm install to regenerate lock file

[LOW] DEP-006: Duplicate dependency in tree
  Package: debug (appears 4 times at different versions)
  Impact: Increases bundle size by ~12KB
  Fix: Run npm dedupe
```

---

## 6. Documentation

### What It Checks

- **API documentation:** Are public functions and endpoints documented with parameters and return types?
- **README accuracy:** Does the README match the current implementation?
- **Changelog:** Are notable changes recorded with dates and versions?
- **Architecture decisions:** Are significant decisions documented (ADRs)?
- **Inline comments:** Is complex logic explained with comments?
- **Setup instructions:** Can a new developer follow the docs to get running?

### Scoring

Starts at 100, deductions per finding:
- CRITICAL: -25 (public API completely undocumented, README describes nonexistent features)
- HIGH: -10 (missing JSDoc on public functions, outdated setup instructions)
- MEDIUM: -3 (missing inline comments on complex logic, minor README gaps)
- LOW: -1 (style improvements, optional documentation enhancements)

### Example Findings

```
[CRITICAL] DOC-001: Public API endpoint undocumented
  File: src/routes/v2/payments.js
  Issue: 4 endpoints with no JSDoc, no OpenAPI spec, no README mention
  Impact: Consumers cannot discover or use the API correctly
  Fix: Add JSDoc to each route handler, update API section in README

[HIGH] DOC-002: Public function missing JSDoc documentation
  File: src/utils/hash.js:12
  Code: function hashPassword(password, rounds) { ... }
  Fix: Add JSDoc with @param {string} password, @param {number} rounds, @returns {Promise<string>}

[HIGH] DOC-003: README setup instructions outdated
  File: README.md:45
  Issue: References .env.example but file was renamed to .env.template
  Impact: New developers cannot complete setup
  Fix: Update README to reference .env.template

[MEDIUM] DOC-004: Complex algorithm without explanation
  File: src/services/pricingService.js:67
  Code: 45 lines of discount calculation with no comments
  Fix: Add block comment explaining the discount tier logic

[MEDIUM] DOC-005: CHANGELOG not updated for recent release
  File: CHANGELOG.md
  Issue: Last entry is v1.2.0 but current version is v1.3.1
  Fix: Add entries for v1.2.1, v1.3.0, and v1.3.1

[LOW] DOC-006: Consider adding architecture diagram
  File: docs/
  Suggestion: A system diagram would help new contributors understand component relationships
```

---

## Category Summary

| Category | Focus | Most Common CRITICAL | Most Common HIGH |
|----------|-------|---------------------|-----------------|
| Security | Safety | Injection, secrets, auth bypass | Missing validation |
| Dependencies | Supply chain | Exploited CVEs, license violations | Unmaintained packages |
| Performance | Speed | Unbounded queries, memory leaks | N+1 patterns |
| Code Quality | Maintainability | Unhandled errors on critical paths | High complexity |
| Documentation | Clarity | Undocumented public APIs | Missing JSDoc |
| Architecture | Structure | Circular dependencies | Pattern violations |
