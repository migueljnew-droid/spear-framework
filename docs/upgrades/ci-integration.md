# Upgrade: CI/CD Integration

Running SPEAR audits in CI/CD ensures that quality gates are enforced on every pull request, not just when a developer remembers to run them locally.

---

## GitHub Actions

### Basic Setup

```yaml
# .github/workflows/spear-audit.yml
name: SPEAR Audit
on:
  pull_request:
    branches: [main, develop]

jobs:
  spear-audit:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0  # Full history for diff analysis

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Install SPEAR
        run: npm install -g @spear-framework/cli

      - name: Install dependencies
        run: npm ci

      - name: Run SPEAR audit
        run: spear audit --ci --output json > audit-results.json

      - name: Check ratchet floors
        run: spear ratchet check --ci

      - name: Post audit summary
        if: always()
        uses: spear-framework/pr-comment@v1
        with:
          results: audit-results.json
          github-token: ${{ secrets.GITHUB_TOKEN }}
```

### PR Comment Output

The `pr-comment` action posts a summary on the pull request:

```
## SPEAR Audit Results

| Category | Score | Floor | Status |
|----------|-------|-------|--------|
| Architecture | 94 | 92 | PASS |
| Code Quality | 91 | 88 | PASS |
| Security | 96 | 95 | PASS |
| Performance | 90 | 90 | PASS |
| Testing | 87 | 85 | PASS |
| Spec Compliance | 100 | 100 | PASS |

**0 CRITICAL, 1 HIGH, 3 MEDIUM findings**

<details>
<summary>HIGH Findings (1)</summary>

- **[TEST-004]** Missing error boundary test for PaymentForm component
  `src/components/PaymentForm.tsx:45`

</details>
```

### Advanced: Separate Jobs per Category

Run audit categories in parallel CI jobs for faster feedback:

```yaml
jobs:
  audit-security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm ci
      - run: spear audit --category security --ci

  audit-performance:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm ci
      - run: spear audit --category performance --ci

  audit-testing:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm ci
      - run: spear audit --category testing --ci

  ratchet-check:
    needs: [audit-security, audit-performance, audit-testing]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: spear ratchet check --ci
```

---

## GitLab CI

```yaml
# .gitlab-ci.yml
stages:
  - test
  - audit
  - ratchet

spear-audit:
  stage: audit
  image: node:20
  before_script:
    - npm install -g @spear-framework/cli
    - npm ci
  script:
    - spear audit --ci --output junit > audit-results.xml
  artifacts:
    reports:
      junit: audit-results.xml
    when: always
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"

spear-ratchet:
  stage: ratchet
  image: node:20
  needs: [spear-audit]
  before_script:
    - npm install -g @spear-framework/cli
  script:
    - spear ratchet check --ci
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
```

---

## Jenkins

```groovy
// Jenkinsfile
pipeline {
    agent any
    stages {
        stage('Install') {
            steps {
                sh 'npm ci'
                sh 'npm install -g @spear-framework/cli'
            }
        }
        stage('SPEAR Audit') {
            steps {
                sh 'spear audit --ci --output json > audit-results.json'
                archiveArtifacts artifacts: 'audit-results.json'
            }
        }
        stage('Ratchet Check') {
            steps {
                sh 'spear ratchet check --ci'
            }
        }
    }
    post {
        always {
            sh 'spear audit summary --format markdown > audit-summary.md'
        }
    }
}
```

---

## CI-Specific Options

### The `--ci` Flag

`--ci` modifies SPEAR's behavior for CI environments:

- Non-interactive (no prompts)
- Exit code 1 on CRITICAL findings or ratchet failures
- Machine-readable output formats
- Skips checks that require a running server (unless `--with-server` is used)

### Output Formats

```bash
# JSON (for programmatic use)
spear audit --ci --output json

# JUnit XML (for CI test report integration)
spear audit --ci --output junit

# Markdown (for PR comments)
spear audit --ci --output markdown

# SARIF (for GitHub Code Scanning)
spear audit --ci --output sarif
```

### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | All audits pass, ratchet check passes |
| 1 | CRITICAL finding or ratchet floor violation |
| 2 | Configuration error (missing .spear/, invalid config) |
| 3 | Runtime error (check failed to execute) |

### Ratchet in CI

The ratchet check compares audit scores against floors without updating them:

```bash
# Check only (CI) — fail if below floors
spear ratchet check --ci

# Update floors (local/CD) — only after merge to main
spear ratchet update
```

Typical flow:
1. PR triggers audit + ratchet check (read-only)
2. Merge to main triggers ratchet update (tighten floors)
3. Updated `ratchet.json` is committed automatically

### Auto-Commit Ratchet Updates

```yaml
# On merge to main
on:
  push:
    branches: [main]

jobs:
  ratchet-update:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm install -g @spear-framework/cli
      - run: spear ratchet update --ci
      - name: Commit ratchet update
        run: |
          git config user.name "SPEAR Bot"
          git config user.email "spear@noreply.github.com"
          git add .spear/ratchet.json
          git diff --cached --quiet || git commit -m "chore: ratchet update [skip ci]"
          git push
```

---

## SARIF Integration (GitHub Code Scanning)

```yaml
- name: Run SPEAR audit
  run: spear audit --ci --output sarif > results.sarif

- name: Upload SARIF
  uses: github/codeql-action/upload-sarif@v3
  with:
    sarif_file: results.sarif
```

This puts SPEAR findings directly in the GitHub Security tab and inline on PR diffs.

---

## Caching

Speed up CI by caching SPEAR's analysis:

```yaml
- name: Cache SPEAR analysis
  uses: actions/cache@v4
  with:
    path: |
      .spear/.cache
      node_modules
    key: spear-${{ hashFiles('.spear/config.json', 'package-lock.json') }}
```

---

## Troubleshooting

### "No .spear/ directory found"

Ensure `.spear/` is committed to your repository. Run `spear init` locally and commit the result.

### "Ratchet check failed but audit passed"

The audit found no CRITICAL issues, but scores are below floors. This means quality regressed compared to previous cycles. Check which category is below its floor:

```bash
spear ratchet check --verbose
```

### "Audit timeout"

Some audit checks need a running server. Either:
1. Start the server in CI before running the audit
2. Skip server-dependent checks with `--skip-server-checks`
3. Increase timeout: `spear audit --timeout 600`

### "Flaky audit results"

If audit scores vary between runs, the checks may depend on external services or timing. Make checks deterministic:
- Mock external APIs
- Use fixed test data
- Set deterministic seeds for any randomized tests
