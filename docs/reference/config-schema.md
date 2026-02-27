# Reference: config.json Schema

Complete documentation for every field in `.spear/config.json`.

---

## Default Configuration

```json
{
  "version": "1.0",
  "project": {
    "name": "",
    "type": "single"
  },
  "spec": {
    "required_fields": ["title", "acceptance_criteria", "constraints"],
    "types": ["prd", "epic-shard", "spike"],
    "default_type": "epic-shard",
    "require_out_of_scope": true
  },
  "plan": {
    "max_phase_hours": 8,
    "require_fitness_functions": true,
    "require_dependencies": true
  },
  "execute": {
    "checkpoints": [25, 50, 75, 100],
    "commit_convention": "conventional",
    "require_spec_reference": true,
    "deviation_logging": "required"
  },
  "audit": {
    "categories": [
      "architecture",
      "code_quality",
      "security",
      "performance",
      "testing",
      "spec_compliance"
    ],
    "block_on": ["CRITICAL"],
    "parallel": true,
    "timeout_seconds": 300,
    "custom_rules": ".spear/audit-rules/"
  },
  "ratchet": {
    "mode": "immediate",
    "increment": 0,
    "override_requires_expiry": true,
    "override_max_days": 90
  },
  "memory": {
    "backend": "file",
    "sync_to_files": true
  },
  "adapters": {
    "auto_update": true,
    "active": []
  }
}
```

---

## Field Reference

### `version`

- **Type:** string
- **Default:** `"1.0"`
- **Description:** Config schema version. Used for migration when SPEAR updates.

### `project`

#### `project.name`

- **Type:** string
- **Default:** `""` (inferred from git remote or directory name)
- **Description:** Human-readable project name. Used in audit reports and dashboards.

#### `project.type`

- **Type:** string
- **Values:** `"single"`, `"monorepo"`, `"multi-repo"`
- **Default:** `"single"`
- **Description:** Project structure type. Affects how audits and ratchets scope to packages.
  - `"single"` — Standard single-repo project
  - `"monorepo"` — Multiple packages in one repo (enables `--all-packages` flag)
  - `"multi-repo"` — Part of a multi-repo setup (enables shared config)

---

### `spec`

#### `spec.required_fields`

- **Type:** string[]
- **Default:** `["title", "acceptance_criteria", "constraints"]`
- **Description:** Fields that must be present for a spec to pass validation. `spear spec finalize` checks these.
- **Valid values:** `"title"`, `"acceptance_criteria"`, `"constraints"`, `"problem_statement"`, `"out_of_scope"`, `"non_functional_requirements"`, `"architecture_impact"`

#### `spec.types`

- **Type:** string[]
- **Default:** `["prd", "epic-shard", "spike"]`
- **Description:** Allowed spec types. Custom types can be added.

#### `spec.default_type`

- **Type:** string
- **Default:** `"epic-shard"`
- **Description:** Type used when `--type` is not specified in `spear spec create`.

#### `spec.require_out_of_scope`

- **Type:** boolean
- **Default:** `true`
- **Description:** Whether specs must include an "Out of Scope" section. Prevents scope creep.

---

### `plan`

#### `plan.max_phase_hours`

- **Type:** number
- **Default:** `8`
- **Description:** Maximum estimated hours per phase. `spear plan finalize` warns if a phase exceeds this. Set to `0` to disable the check.

#### `plan.require_fitness_functions`

- **Type:** boolean
- **Default:** `true`
- **Description:** Whether every phase must have at least one fitness function. Strongly recommended.

#### `plan.require_dependencies`

- **Type:** boolean
- **Default:** `true`
- **Description:** Whether phases must declare dependencies (or explicitly mark as independent). Prevents out-of-order execution.

---

### `execute`

#### `execute.checkpoints`

- **Type:** number[]
- **Default:** `[25, 50, 75, 100]`
- **Description:** Percentage milestones where checkpoints trigger. Each checkpoint prompts for status and runs available fitness functions.
- **Example:** `[50, 100]` for fewer checkpoints. `[100]` for completion-only check.

#### `execute.commit_convention`

- **Type:** string
- **Values:** `"conventional"`, `"none"`, `"custom"`
- **Default:** `"conventional"`
- **Description:** Commit message format enforcement.
  - `"conventional"` — `type(scope): description [spec-id/phase-n]`
  - `"none"` — No format enforcement
  - `"custom"` — Use `execute.commit_pattern` regex

#### `execute.commit_pattern`

- **Type:** string (regex)
- **Default:** (not set, uses conventional format)
- **Description:** Custom regex for commit message validation. Only used when `commit_convention` is `"custom"`.
- **Example:** `"^\\[PROJ-\\d+\\] .+"` for Jira-style messages.

#### `execute.require_spec_reference`

- **Type:** boolean
- **Default:** `true`
- **Description:** Whether commit messages must include the spec and phase reference (e.g., `[spec-001/phase-2]`).

#### `execute.deviation_logging`

- **Type:** string
- **Values:** `"required"`, `"optional"`, `"disabled"`
- **Default:** `"required"`
- **Description:** Whether deviations from the plan must be logged during execution.

---

### `audit`

#### `audit.categories`

- **Type:** string[]
- **Default:** `["architecture", "code_quality", "security", "performance", "testing", "spec_compliance"]`
- **Description:** Which audit categories to run. Add custom category IDs to include them. Remove built-in categories to skip them.

#### `audit.block_on`

- **Type:** string[]
- **Default:** `["CRITICAL"]`
- **Description:** Severity levels that prevent ratcheting. If any finding at these levels exists, the ratchet cannot proceed.
- **Example:** `["CRITICAL", "HIGH"]` to also block on HIGH findings.

#### `audit.parallel`

- **Type:** boolean
- **Default:** `true`
- **Description:** Run audit categories in parallel. Set to `false` for sequential execution (useful for debugging or resource-constrained environments).

#### `audit.timeout_seconds`

- **Type:** number
- **Default:** `300`
- **Description:** Maximum time in seconds for each audit category. Categories exceeding this timeout are marked as errors.

#### `audit.custom_rules`

- **Type:** string (path)
- **Default:** `".spear/audit-rules/"`
- **Description:** Directory containing custom audit rules (YAML files). Rules are loaded and applied during audits.

---

### `ratchet`

#### `ratchet.mode`

- **Type:** string
- **Values:** `"immediate"`, `"incremental"`
- **Default:** `"immediate"`
- **Description:** How floors are tightened.
  - `"immediate"` — Floor jumps to audit score: `new_floor = max(current, score)`
  - `"incremental"` — Floor increases by increment: `new_floor = min(current + increment, score)`

#### `ratchet.increment`

- **Type:** number
- **Default:** `0` (only used when mode is `"incremental"`)
- **Description:** Points to increase floor per cycle in incremental mode. Typical values: 2-5.

#### `ratchet.override_requires_expiry`

- **Type:** boolean
- **Default:** `true`
- **Description:** Whether ratchet overrides (lowering a floor) must have an expiration date. Prevents permanent quality regression.

#### `ratchet.override_max_days`

- **Type:** number
- **Default:** `90`
- **Description:** Maximum days a ratchet override can last before the original floor is restored.

---

### `memory`

#### `memory.backend`

- **Type:** string
- **Values:** `"file"`, `"sqlite-fts"`, `"qdrant"`, `"hybrid"`
- **Default:** `"file"`
- **Description:** Memory storage backend. See `docs/upgrades/memory-backends.md` for details.

#### `memory.db_path`

- **Type:** string (path)
- **Default:** `".spear/memory/spear.db"`
- **Description:** Path to SQLite database. Only used when backend is `"sqlite-fts"` or `"hybrid"`.

#### `memory.qdrant_url`

- **Type:** string (URL)
- **Default:** (not set)
- **Description:** Qdrant server URL. Only used when backend is `"qdrant"` or `"hybrid"`.

#### `memory.collection`

- **Type:** string
- **Default:** `"spear_memory"`
- **Description:** Qdrant collection name. Only used with Qdrant backend.

#### `memory.embedding_model`

- **Type:** string
- **Default:** `"all-MiniLM-L6-v2"`
- **Description:** Sentence transformer model for vector embeddings. Only used with Qdrant backend.

#### `memory.sync_to_files`

- **Type:** boolean
- **Default:** `true`
- **Description:** Keep Markdown files updated alongside database backends. Enables git tracking of memory changes.

---

### `adapters`

#### `adapters.auto_update`

- **Type:** boolean
- **Default:** `true`
- **Description:** Automatically regenerate adapter files when phase context changes (during `spear execute` and `spear execute complete`).

#### `adapters.active`

- **Type:** string[]
- **Default:** `[]`
- **Description:** Which adapters to auto-update. Empty array means manual-only.
- **Example:** `["claude-code", "cursor"]` — Both adapters update on phase changes.
- **Valid values:** `"claude-code"`, `"cursor"`, `"copilot"`, `"antigravity"`, `"kiro"`, `"generic"`

---

### `metrics` (optional)

#### `metrics.push`

- **Type:** object
- **Default:** (not set)
- **Description:** Push metrics to external monitoring. See `docs/upgrades/metrics-dashboard.md`.

```json
{
  "metrics": {
    "push": {
      "type": "prometheus",
      "endpoint": "http://prometheus:9091/metrics/job/spear",
      "interval": "on_audit"
    }
  }
}
```

#### `metrics.alerts`

- **Type:** object[]
- **Default:** (not set)
- **Description:** Alert conditions for quality regression. See `docs/upgrades/metrics-dashboard.md`.

---

### `notifications` (optional)

#### `notifications.webhook_url`

- **Type:** string (URL)
- **Default:** (not set)
- **Description:** Webhook URL for SPEAR event notifications.

#### `notifications.events`

- **Type:** string[]
- **Default:** `["critical_finding", "ratchet_failed"]`
- **Description:** Which events trigger notifications.
- **Valid values:** `"spec_submitted"`, `"spec_approved"`, `"plan_finalized"`, `"phase_complete"`, `"audit_complete"`, `"critical_finding"`, `"ratchet_updated"`, `"ratchet_failed"`, `"override_created"`

---

## Validation

Validate your config:

```bash
spear config validate
# => Config valid. 0 errors, 0 warnings.
```

View effective config (with defaults applied):

```bash
spear config show
# => Prints full config with all defaults filled in
```
