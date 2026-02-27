---
name: Audit Rule Proposal
about: Propose a new audit rule for SPEAR
title: "[RULE] "
labels: audit-rule
assignees: ''
---

## Rule Statement
One sentence: what should SPEAR check for?

## Category
- [ ] Security
- [ ] Dependencies
- [ ] Performance
- [ ] Code Quality
- [ ] Documentation
- [ ] Architecture

## Severity
- [ ] CRITICAL — blocks deployment
- [ ] HIGH — significant issue
- [ ] MEDIUM — should fix
- [ ] LOW — nice to have

## Detection Method
How would a hook or agent detect this? (regex pattern, AST check, command output, etc.)

## Real-World Example
Show an example of code that would trigger this rule and why it matters.

## Enforcement
- [ ] Pre-commit hook (automated)
- [ ] Fitness function (automated)
- [ ] Agent audit (AI-reviewed)
- [ ] Manual review

## Languages
Which languages does this apply to? (all, Rust, TypeScript, Python, etc.)
