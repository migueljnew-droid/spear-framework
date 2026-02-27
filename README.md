```
   ███████╗██████╗ ███████╗ █████╗ ██████╗
   ██╔════╝██╔══██╗██╔════╝██╔══██╗██╔══██╗
   ███████╗██████╔╝█████╗  ███████║██████╔╝
   ╚════██║██╔═══╝ ██╔══╝  ██╔══██║██╔══██╗
   ███████║██║     ███████╗██║  ██║██║  ██║
   ╚══════╝╚═╝     ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝
```

**Spec-driven. Audit-gated. Self-improving.**

[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-1.0.0-green.svg)]()
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

---

## The Problem

AI coding tools are powerful but chaotic. Without structure, they produce code that works today and breaks tomorrow. Teams get:

- **No specification** — jumping straight to code without defining what or why
- **No audit gate** — shipping whatever the AI generates without independent review
- **No learning** — making the same mistakes every cycle because nothing is remembered
- **Tool lock-in** — methodology tied to one AI tool, useless with another

## The Solution

SPEAR is a drop-in development methodology that adds structure, audit gates, and a learning ratchet to any AI-assisted workflow. Five phases, six audit categories, one direction: forward.

```
┌──────┐    ┌──────┐    ┌─────────┐    ┌───────┐    ┌─────────┐
│ SPEC │───>│ PLAN │───>│ EXECUTE │───>│ AUDIT │───>│ RATCHET │
└──────┘    └──────┘    └─────────┘    └───────┘    └─────────┘
```

**S**pec → Define what to build and why. PRDs, architecture docs, epic shards.
**P**lan → Break into phases with fitness functions and success criteria.
**E**xecute → Build with atomic commits, checkpoints, and deviation logging.
**A**udit → Independent review across 6 categories. GO/NO-GO verdict.
**R**atchet → Tighten thresholds, generate rules, remember decisions. Quality only goes up.

## 30-Second Install

```bash
curl -fsSL https://raw.githubusercontent.com/migueljnew-droid/spear-framework/main/install.sh | sh
```

This auto-detects your project language and AI tool, installs `.spear/`, configures hooks, and sets up your adapter.

Or manually:

```bash
git clone https://github.com/migueljnew-droid/spear-framework.git
cp -r spear-framework/.spear your-project/.spear
cp -r spear-framework/hooks your-project/hooks
cd your-project && ./hooks/install.sh
```

## The 6 Audit Categories

Every change is reviewed across six independent categories. They run in parallel. Each produces its own verdict.

| Category | What It Checks |
|----------|---------------|
| **Security** | Secrets, injection, auth, OWASP Top 10 |
| **Dependencies** | CVEs, licenses, outdated packages, supply chain |
| **Performance** | Complexity, bundle size, queries, memory |
| **Code Quality** | Duplication, dead code, naming, error handling |
| **Documentation** | API docs, README accuracy, changelog |
| **Architecture** | Layer violations, circular deps, pattern consistency |

Severity levels: **CRITICAL** (blocks deploy) → **HIGH** (fix or justify) → **MEDIUM** → **LOW** → **INFO**

## The Ratchet

The ratchet ensures quality only goes up. It tracks thresholds for metrics like test coverage, bundle size, and complexity:

- **Floor thresholds** (must stay above): test coverage ≥ 70%, doc coverage ≥ 60%
- **Ceiling thresholds** (must stay below): complexity ≤ 20, bundle ≤ 500kb
- **Auto-tighten**: When you exceed a threshold by 5%+, it ratchets to the new level (minus 2% buffer)
- **Never loosens silently**: Every threshold change is logged with justification

```json
{
  "test_coverage": { "value": 70, "direction": "floor" },
  "max_complexity": { "value": 20, "direction": "ceiling" }
}
```

## AI Tool Support

SPEAR is AI-agnostic at its core. Adapters translate the methodology into each tool's native format:

| Tool | Adapter | What You Get |
|------|---------|-------------|
| **Claude Code** | `adapters/claude-code/` | CLAUDE.md + slash commands + custom agents |
| **Cursor** | `adapters/cursor/` | .cursorrules with SPEAR directives |
| **GitHub Copilot** | `adapters/copilot/` | copilot-instructions.md |
| **Antigravity** | `adapters/antigravity/` | Project rules + agent workflows |
| **Kiro** | `adapters/kiro/` | Steering files + hooks + spec templates |
| **Any LLM** | `adapters/generic/` | Self-contained system prompt |

## Key Features

| Feature | Description |
|---------|-------------|
| **Phase State Machine** | Sequential phases with gates. No skipping. |
| **6-Category Audit** | Parallel, independent audits with severity classification |
| **Learning Ratchet** | Auto-tightening thresholds. Quality only goes up. |
| **Fitness Functions** | Automated metric checks against ratchet thresholds |
| **Project Memory** | Decisions, patterns, and findings persist across cycles |
| **Pre-commit Hooks** | Secrets scan, lint, tests, dependency audit — zero-dep bash |
| **AI-Agnostic Core** | One framework, six tool adapters, works with anything |

## Comparison

| | SPEAR | BMAD | GSD | Bare Prompting |
|---|---|---|---|---|
| Structured spec phase | ✅ | ✅ | ❌ | ❌ |
| Execution engine | ✅ | ❌ | ✅ | ❌ |
| Independent audit gate | ✅ | ❌ | ❌ | ❌ |
| Learning ratchet | ✅ | ❌ | ❌ | ❌ |
| Fitness functions | ✅ | ❌ | ✅ | ❌ |
| Project memory | ✅ | ❌ | ❌ | ❌ |
| Multi-tool support | ✅ 6 tools | ❌ Claude only | ❌ Claude only | Tool-specific |
| Pre-commit hooks | ✅ | ❌ | ❌ | ❌ |
| Zero dependencies | ✅ | ✅ | ❌ | ✅ |

## Quick Start Example

```bash
# 1. Install SPEAR in your project
cd my-project
curl -fsSL https://raw.githubusercontent.com/.../install.sh | sh

# 2. Start a cycle — write a spec
# (Use your AI tool's SPEAR commands, or manually create from template)
cp .spear/templates/spec/prd.md docs/specs/auth-feature.md
# Fill in the PRD...

# 3. Plan the implementation
cp .spear/templates/plan/phase-plan.md docs/plans/auth-phase-1.md
# Define tasks, fitness functions, success criteria...

# 4. Execute with SPEAR discipline
# Atomic commits, checkpoints at 25/50/75%, deviation logging
git commit -m "feat(auth): add JWT token generation"

# 5. Audit passes automatically via pre-commit hooks
# For full audit, run the audit agent or use templates

# 6. Ratchet tightens automatically
# Check: cat .spear/ratchet/ratchet.json
```

## Project Structure

```
.spear/                    ← The distribution unit (copy this to any project)
├── SPEAR.md               ← Framework brain — read this first
├── config.json            ← Project configuration
├── templates/             ← Output templates for each phase
│   ├── spec/              ← PRD, architecture, epic shard
│   ├── plan/              ← Phase plan, fitness function, research brief
│   ├── execute/           ← Task commit, deviation log, checkpoint
│   ├── audit/             ← Audit report, summary, finding
│   └── ratchet/           ← Ratchet entry, rule proposal, retrospective
├── agents/                ← AI agent role definitions
├── ratchet/               ← Threshold state + history + rules
├── memory/                ← Project knowledge base
└── fitness/               ← Automated fitness functions

adapters/                  ← AI tool integrations
hooks/                     ← Git hooks + checker scripts
docs/                      ← Full documentation
install.sh                 ← One-command installer
```

## Documentation

- **[Philosophy](docs/philosophy.md)** — Design principles behind SPEAR
- **[Quick Start](docs/quickstart.md)** — Get running in 5 minutes
- **Phase Guides:** [Spec](docs/phases/01-spec.md) · [Plan](docs/phases/02-plan.md) · [Execute](docs/phases/03-execute.md) · [Audit](docs/phases/04-audit.md) · [Ratchet](docs/phases/05-ratchet.md)
- **Adapter Guides:** [Claude Code](docs/adapters/claude-code.md) · [Cursor](docs/adapters/cursor.md) · [Copilot](docs/adapters/copilot.md) · [Antigravity](docs/adapters/antigravity.md) · [Kiro](docs/adapters/kiro.md) · [Generic](docs/adapters/generic.md)
- **Upgrades:** [Fitness Functions](docs/upgrades/fitness-functions.md) · [Memory Backends](docs/upgrades/memory-backends.md) · [Custom Audits](docs/upgrades/custom-audit-categories.md) · [Monorepo](docs/upgrades/multi-project.md) · [CI/CD](docs/upgrades/ci-integration.md) · [Teams](docs/upgrades/team-workflows.md) · [Metrics](docs/upgrades/metrics-dashboard.md)
- **Reference:** [Config Schema](docs/reference/config-schema.md) · [Template Format](docs/reference/template-format.md) · [Audit Categories](docs/reference/audit-categories.md)

## Contributing

We welcome contributions! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

The most impactful contributions:
- **Audit rules** from real-world findings (use the [audit rule proposal](../../issues/new?template=audit_rule_proposal.md) template)
- **Fitness functions** for different ecosystems
- **Adapter improvements** for your favorite AI tool
- **Language-specific hook improvements**

## License

MIT — use it everywhere. See [LICENSE](LICENSE).

---

*Created by [Louis Gold](https://github.com/migueljnew-droid). Spec-driven. Audit-gated. Self-improving.*
