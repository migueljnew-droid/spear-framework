# Upgrade: Custom Fitness Functions

Fitness functions are automated checks that verify whether a phase meets its goals. SPEAR includes built-in fitness functions, but real projects need custom ones tailored to their domain.

---

## Anatomy of a Fitness Function

```yaml
# .spear/fitness/auth-token-expiry.yaml
id: ff-auth-token-expiry
name: JWT Token Expiry Check
phase: plan-001/phase-2
type: script
command: "node scripts/fitness/check-token-expiry.js"
expected_exit_code: 0
timeout_seconds: 30
description: "Verify JWT tokens expire within 1 hour"
```

The check script:

```javascript
// scripts/fitness/check-token-expiry.js
const jwt = require('jsonwebtoken');
const { generateToken } = require('../src/utils/token');

const token = generateToken({ id: 1, email: 'test@example.com' });
const decoded = jwt.decode(token, { complete: true });

const expiry = decoded.payload.exp - decoded.payload.iat;
if (expiry > 3600) {
  console.error(`FAIL: Token expiry is ${expiry}s, must be <= 3600s`);
  process.exit(1);
}

console.log(`PASS: Token expiry is ${expiry}s`);
process.exit(0);
```

---

## Fitness Function Types

### Script-Based

Run any command and check the exit code.

```yaml
type: script
command: "python3 scripts/check_schema.py"
expected_exit_code: 0
```

Best for: custom validation logic, data integrity checks, integration tests.

### Test-Based

Run a test suite and check results.

```yaml
type: test
command: "npm test -- --grep 'auth endpoints'"
min_tests: 8
max_failures: 0
```

Best for: unit tests, integration tests, end-to-end tests.

### HTTP-Based

Make an HTTP request and check the response.

```yaml
type: http
url: "http://localhost:3000/api/health"
method: GET
expected_status: 200
expected_body_contains: '"status":"ok"'
timeout_seconds: 10
```

Best for: API endpoint validation, health checks, smoke tests.

### Performance-Based

Run a benchmark and check against thresholds.

```yaml
type: performance
command: "autocannon -d 10 -c 10 http://localhost:3000/api/login"
metric: "requests.average"
min_value: 100
unit: "req/sec"
```

Best for: throughput, latency, resource usage checks.

### Static Analysis

Run a linter or analyzer and check for zero violations.

```yaml
type: static
command: "eslint src/auth/ --format json"
max_errors: 0
max_warnings: 5
```

Best for: code style, complexity, documentation coverage.

---

## Writing Effective Fitness Functions

### Good Fitness Functions

1. **Deterministic.** Same code produces same result every time.
2. **Fast.** Under 30 seconds. If it takes longer, it's a test suite, not a fitness function.
3. **Self-contained.** No manual setup or teardown required.
4. **Clear output.** PASS/FAIL with a reason, not a wall of text.
5. **Specific.** Tests one thing, not everything.

### Bad Fitness Functions

- "Code compiles" — too broad, your build tool already checks this
- "Looks correct" — not automatable
- "Runs without errors" — too vague, which errors?
- Takes 5 minutes — too slow for checkpoint runs

### Pattern: Compose Small Functions

Instead of one large fitness function, compose several small ones:

```yaml
# .spear/fitness/auth-suite.yaml
id: ff-auth-suite
name: Auth Fitness Suite
type: composite
functions:
  - ff-user-model-schema
  - ff-password-hashing
  - ff-token-expiry
  - ff-rate-limit-threshold
pass_condition: all  # all must pass (vs "majority" or "any")
```

---

## Registering Fitness Functions

### Per-Plan Registration

Fitness functions defined inline in plan files are automatically registered:

```markdown
## Phase 2: Auth Endpoints
**Fitness function:** `npm test -- --grep "auth"` passes with 8+ tests
```

SPEAR extracts this into a fitness function automatically.

### Global Registration

For fitness functions that apply to every plan:

```bash
spear fitness register --global \
  --name "No secrets in code" \
  --command "gitleaks detect --source . --no-git" \
  --type script
```

Global fitness functions run on every phase of every plan.

### Project-Level Registration

```bash
spear fitness register \
  --name "Database migrations reversible" \
  --command "npm run migrate:test-rollback" \
  --type script \
  --category "data_integrity"
```

---

## Running Fitness Functions

### During Execution

```bash
# Run all fitness functions for current phase
spear fitness run

# Run a specific function
spear fitness run --id ff-auth-token-expiry

# Run all global functions
spear fitness run --global
```

### Standalone (Outside Execution)

```bash
# Run all registered fitness functions
spear fitness run --all

# Run by category
spear fitness run --category data_integrity
```

### Output

```
Fitness Functions — Phase 2: Auth Endpoints

  [PASS] ff-user-model-schema      (0.3s) User model has required fields
  [PASS] ff-password-hashing       (0.8s) Bcrypt hash is 60 chars
  [PASS] ff-token-expiry           (0.2s) Token expires in 3600s
  [FAIL] ff-rate-limit-threshold   (1.2s) Rate limiter not configured
         Expected: 429 on 6th request
         Actual: 200 on 6th request

3/4 passing, 1 failure
```

---

## Examples by Domain

### Web API

```yaml
- name: "Response time under 200ms"
  command: "curl -o /dev/null -s -w '%{time_total}' http://localhost:3000/api/users | awk '{if ($1 > 0.2) exit 1}'"

- name: "No N+1 queries"
  command: "node scripts/check-query-count.js --endpoint /api/users --max-queries 3"

- name: "CORS headers present"
  command: "curl -sI http://localhost:3000/api/users | grep -i 'access-control-allow-origin'"
```

### Database

```yaml
- name: "Migration is reversible"
  command: "npm run migrate && npm run migrate:rollback && npm run migrate"

- name: "No raw SQL (use ORM)"
  command: "grep -r 'query(' src/ --include='*.js' | grep -v 'node_modules' | wc -l | awk '{if ($1 > 0) exit 1}'"

- name: "Foreign keys have indexes"
  command: "node scripts/check-fk-indexes.js"
```

### Frontend

```yaml
- name: "Bundle size under 250KB"
  command: "npm run build && du -k dist/main.js | awk '{if ($1 > 250) exit 1}'"

- name: "No accessibility violations"
  command: "npx pa11y http://localhost:3000 --threshold 0"

- name: "Core Web Vitals pass"
  command: "npx lighthouse http://localhost:3000 --output json | node scripts/check-cwv.js"
```

---

## Fitness Function Lifecycle

```
registered -> active -> retired
```

Functions can be retired when they're no longer relevant:

```bash
spear fitness retire ff-old-schema-check \
  --reason "Schema migrated to v2, old check no longer applies"
```

Retired functions are kept in history but no longer run.
