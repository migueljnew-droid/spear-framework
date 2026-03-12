# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [2.0.0] - 2026-03-12

### Added
- **TDD Iron Law** — No production code without a failing test first. RED-GREEN-REFACTOR cycle mandatory per task. Code before test = delete and restart. Anti-rationalization table blocks AI from skipping TDD.
- **5-Step Verification Gate** — Identify → Run → Read → Verify → Claim. Banned language list ("should work", "probably passes"). Every success claim requires command output proof.
- **Socratic Spec Phase** — One question at a time (not lists). Multiple choice preferred over open-ended. Spec-document-reviewer validation before human approval. Hard gate: no implementation without sign-off.
- **Systematic Debugging Agent** — 4-phase protocol: Root Cause Investigation → Pattern Analysis → Hypothesis Testing → Implementation. 3-strike rule: 3+ failed fixes = escalate (architectural issue). Red flags trigger immediate stop.
- **Subagent Executor Agent** — Fresh agent per task (prevents context pollution). Two-stage review: spec compliance then code quality. Model routing by task complexity (Haiku → Sonnet → Opus). Parallel dispatch with file/state overlap safety checks.
- **Parallel Execution Dispatch** — Independence detection for concurrent tasks. 4-step merge protocol: review summaries → conflict detection → full suite test → spot check.
- **Git Worktree Isolation** — Execute phase starts in fresh worktree branch. Clean baseline verified before any changes. Worktree cleanup on branch completion.
- **TDD Cycle Template** — `templates/execute/tdd-cycle.md` — RED-GREEN-REFACTOR record with mandatory verification checkboxes
- 5 new state machine rules (13 total): explicit spec approval, TDD iron law, evidence before claims, 3-strike debugging escalation, worktree isolation default

### Changed
- Executor agent expanded from 133 to 220 lines — TDD enforcement, verification gate, debugging protocol, worktree lifecycle, parallel dispatch classification
- Spec-writer agent expanded from 108 to 149 lines — Socratic questioning protocol, design validation, spec-document-reviewer gate
- SPEAR.md updated to v2.0 — Phase 1 and 3 descriptions rewritten, file structure expanded, state machine rules expanded from 8 to 13
- Agent count: 11 → 14 (added debugger, subagent-executor, spec-document-reviewer role)

## [1.0.0] - 2026-02-26

### Added
- Complete SPEAR methodology: Spec, Plan, Execute, Audit, Ratchet
- 15 templates across all 5 phases
- 11 agent role prompts
- 6 AI tool adapters: Claude Code, Cursor, Copilot, Antigravity, Kiro, Generic
- Git hooks: pre-commit with 6 checker scripts, commit-msg validator
- 5 fitness function examples
- Ratchet system with auto-tightening thresholds
- Project memory system with searchable index
- JSON Schema for config validation
- Comprehensive documentation: philosophy, quickstart, phase guides, adapter guides, upgrade paths, reference docs
- One-command installer with auto-detection
