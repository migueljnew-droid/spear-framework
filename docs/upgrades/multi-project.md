# Upgrade: Multi-Project SPEAR

SPEAR works out of the box for single repositories. For monorepos or multi-repo setups, additional configuration enables shared standards, cross-project memory, and coordinated audits.

---

## Monorepo Setup

### Directory Structure

```
my-monorepo/
  .spear/                     # Root-level SPEAR (shared config)
    config.json               # Global settings
    ratchet.json              # Global floors (minimum for all packages)
    memory/                   # Shared memory
    audit-rules/              # Shared audit rules
  packages/
    api/
      .spear/                 # Package-level SPEAR
        config.json           # Package-specific overrides
        ratchet.json          # Package floors (can be stricter than global)
        specs/
        plans/
        audits/
    web/
      .spear/
        config.json
        ratchet.json
        specs/
        plans/
        audits/
    shared/
      .spear/
        config.json
        ratchet.json
        specs/
        plans/
        audits/
```

### Initialize Monorepo

```bash
# Initialize root
spear init --monorepo

# Initialize packages
spear init --package packages/api
spear init --package packages/web
spear init --package packages/shared
```

### Configuration Inheritance

Package configs inherit from root and can override:

```json
// .spear/config.json (root)
{
  "audit": {
    "categories": ["architecture", "code_quality", "security", "performance", "testing", "spec_compliance"],
    "block_on": ["CRITICAL"]
  },
  "ratchet": {
    "mode": "immediate"
  }
}
```

```json
// packages/api/.spear/config.json
{
  "extends": "../../.spear/config.json",
  "audit": {
    "categories": ["architecture", "code_quality", "security", "performance", "testing", "spec_compliance", "api_compatibility"]
  }
}
```

The `api` package inherits all root settings but adds the `api_compatibility` category.

### Ratchet Inheritance

Package floors must meet or exceed global floors:

```json
// .spear/ratchet.json (root — global minimums)
{
  "floors": {
    "security": 90,
    "testing": 80
  }
}
```

```json
// packages/api/.spear/ratchet.json (can be stricter)
{
  "floors": {
    "security": 95,
    "testing": 85
  }
}
```

The API package has stricter floors than the global minimum. A package cannot set floors below the global minimum.

---

## Multi-Repo Setup

### Shared Config Repository

Create a shared SPEAR config repo:

```bash
# In your shared config repo
spear init --shared-config
```

```
spear-config/
  config.json               # Org-wide defaults
  ratchet-minimums.json     # Org-wide minimum floors
  audit-rules/              # Org-wide audit rules
  templates/                # Shared spec/plan templates
```

### Consuming Shared Config

In each project:

```json
// .spear/config.json
{
  "extends": "@myorg/spear-config",
  "audit": {
    "categories": ["architecture", "code_quality", "security", "performance", "testing", "spec_compliance"]
  }
}
```

Install the shared config:

```bash
npm install --save-dev @myorg/spear-config
# or
spear config link --repo git@github.com:myorg/spear-config.git
```

### Cross-Repo Memory

Share decisions and learnings across repositories:

```json
{
  "memory": {
    "backend": "qdrant",
    "qdrant_url": "http://memory.internal:6333",
    "collection": "org_memory",
    "project_prefix": "api-service"
  }
}
```

Search across all projects:

```bash
spear memory search "authentication strategy" --scope org
# => [api-service] DEC-012: JWT with RS256 for service-to-service
# => [web-app] DEC-005: Session-based auth for browser clients
# => [mobile-api] DEC-018: Refresh token rotation pattern
```

---

## Running Audits Across Projects

### Monorepo: All Packages

```bash
# Audit all packages
spear audit --all-packages

# Audit specific packages
spear audit --packages api,web

# Audit only changed packages (CI-friendly)
spear audit --changed
```

Output:

```
SPEAR Monorepo Audit

packages/api:
  [PASS] architecture: 94  code_quality: 91  security: 96
         performance: 92   testing: 87       spec_compliance: 100

packages/web:
  [PASS] architecture: 90  code_quality: 88  security: 93
         performance: 85   testing: 82       spec_compliance: 100

packages/shared:
  [FAIL] architecture: 88  code_quality: 85  security: 91
         performance: 80   testing: 78*      spec_compliance: 95
         * testing (78) below floor (80)

Overall: 1 package failed audit
```

### Multi-Repo: Aggregated Dashboard

```bash
# From any repo with shared config
spear audit dashboard --scope org
```

```
Organization Audit Dashboard

Repository         Arch  CQ    Sec   Perf  Test  Spec  Status
api-service        94    91    96    92    87    100   PASS
web-app            90    88    93    85    82    100   PASS
mobile-api         92    89    95    88    84    100   PASS
shared-lib         88    85    91    80    78    95    FAIL
data-pipeline      86    82    90    75    70    90    FAIL

Org averages:      90    87    93    84    80    97
Org minimums:      85    80    90    75    75    90
```

---

## Coordinated Specs

When a feature spans multiple projects:

```markdown
---
id: spec-042
title: Real-time Notifications
type: prd
scope: multi-project
projects:
  - api-service (WebSocket server, notification model)
  - web-app (notification UI, WebSocket client)
  - mobile-api (push notification gateway)
---
```

SPEAR tracks which project handles which acceptance criteria:

```markdown
## Acceptance Criteria

### api-service
- [ ] WebSocket endpoint at /ws/notifications
- [ ] Notification model with user_id, type, payload, read_at
- [ ] REST endpoint for marking notifications as read

### web-app
- [ ] Notification bell icon with unread count
- [ ] WebSocket connection with auto-reconnect
- [ ] Notification dropdown with mark-as-read

### mobile-api
- [ ] Push notification delivery via FCM/APNs
- [ ] Notification preferences per user
```

Plan and execute per-project, audit across all:

```bash
spear audit --spec spec-042 --cross-project
# => Audits all three projects for spec-042 compliance
```

---

## CI Integration for Multi-Project

### GitHub Actions (Monorepo)

```yaml
name: SPEAR Audit
on: pull_request

jobs:
  audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: spear-framework/setup@v1

      - name: Detect changed packages
        id: changes
        run: |
          echo "packages=$(spear packages --changed --format csv)" >> $GITHUB_OUTPUT

      - name: Run SPEAR audit
        run: spear audit --packages ${{ steps.changes.outputs.packages }}

      - name: Check ratchet
        run: spear ratchet check --packages ${{ steps.changes.outputs.packages }}
```

### GitLab CI (Multi-Repo)

```yaml
spear-audit:
  stage: quality
  script:
    - spear audit --plan $PLAN_ID
    - spear ratchet check
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
```

---

## Best Practices

1. **Start with global minimums, let packages tighten.** Don't set aggressive global floors — let each package's ratchet find its level.
2. **Share audit rules, not audit results.** Rules are reusable; results are context-specific.
3. **Use cross-repo memory for architectural decisions.** "Why did we choose X?" should be findable from any repo.
4. **Audit changed packages only in CI.** Full-org audits are for dashboards, not pull requests.
5. **One spec per project boundary.** Multi-project specs should decompose into per-project acceptance criteria.
