---
title: "[Product/Feature Name]"
version: "0.1.0"
status: draft # draft | review | approved | superseded
author: "[Your Name]"
date: "YYYY-MM-DD"
epic: "[EPIC-ID]"
---

# Product Requirements Document: [Product/Feature Name]

## Outcome Formula

> I need [SPECIFIC DELIVERABLE]
> that [MEASURABLE ACTION OR RESULT]
> for [TARGET AUDIENCE]
> in [CONTEXT OR TIMEFRAME]

*Source: `.spear/output/ignition/outcome.md` (if Ignition was run) or define here.*

## Overview

[1-2 paragraph high-level description of what this product/feature is and why it matters. Write for someone with zero context.]

## Problem Statement

[What specific problem does this solve? Who experiences it? What is the cost of not solving it?]

**Current State:** [How things work today]
**Desired State:** [How things should work after delivery]

## Goals & Non-Goals

### Goals
1. [Measurable goal with success criteria]
2. [Measurable goal with success criteria]
3. [Measurable goal with success criteria]

### Non-Goals
1. [Explicitly out of scope — prevents scope creep]
2. [Explicitly out of scope]

## User Stories

| ID | As a... | I want to... | So that... | Priority |
|----|---------|-------------|-----------|----------|
| US-001 | [role] | [action] | [benefit] | must-have |
| US-002 | [role] | [action] | [benefit] | should-have |
| US-003 | [role] | [action] | [benefit] | nice-to-have |

## Acceptance Criteria

### US-001: [Story Title]
- [ ] [Given/When/Then or concrete assertion]
- [ ] [Given/When/Then or concrete assertion]
- [ ] [Given/When/Then or concrete assertion]

### US-002: [Story Title]
- [ ] [Given/When/Then or concrete assertion]
- [ ] [Given/When/Then or concrete assertion]

## Constraints

### Hard Constraints (non-negotiable)
| Category | Constraint | Source |
|----------|-----------|--------|
| **Technology** | [e.g., Rust 1.75+, iOS 16+] | [who set this] |
| **Legal/Regulatory** | [e.g., GDPR, SOC2, HIPAA] | [regulation] |
| **Time** | [e.g., court deadline April 6, grant deadline April 15] | [source] |
| **Platform** | [e.g., Linux x86_64, App Store guidelines] | [requirement] |

### Soft Constraints (negotiable trade-offs)
| Category | Constraint | Flexibility |
|----------|-----------|-------------|
| **Budget** | [available resources] | [what can be adjusted] |
| **Team** | [bandwidth, skill gaps] | [what can be hired/learned] |
| **Knowledge** | [what we need to learn] | [research vs build] |
| **Timeline** | [soft deadlines, preferences] | [what can slip] |

### Technical Specifications
- **Language/Runtime:** [e.g., Rust 1.75+, Node 20 LTS]
- **Performance:** [e.g., p99 latency < 200ms]
- **Data:** [e.g., Must handle 10K concurrent users]
- **Other:** [Any additional technical requirements]

## Dependencies (Full Analysis)

### Dependency Summary
| Dependency | Type | Owner | Status | Risk |
|-----------|------|-------|--------|------|
| [Service/Library/Team] | blocks/soft | [who] | [ready/in-progress/unknown] | [low/med/high] |

### Dependency Audit Table
| Dependency | Version | License | CVE Status | Transitive Deps | Maintenance | Risk |
|-----------|---------|---------|------------|-----------------|-------------|------|
| [name]    | [ver]   | [MIT/Apache/etc] | [clean/CVE-XXXX] | [count] | [active/stale/abandoned] | [low/med/high] |

### License Compatibility
- **Project license:** [e.g., LicenseRef-Proprietary / MIT / Apache-2.0]
- **Conflicts found:** [none / list with resolution]

### System Dependencies
- [OS packages, native libraries, build tools, runtimes required]

## Compliance Requirements

### App Store Compliance
<!-- Mark N/A with reason if not a mobile/desktop app -->
- [ ] Apple App Store Review Guidelines adherence
- [ ] Google Play Store policies adherence
- [ ] Privacy nutrition labels / Data Safety accuracy
- [ ] Required entitlements and capabilities declared
- **Status:** [N/A — reason / PASS / NEEDS REVIEW: items]

### Regulatory Compliance
- [ ] GDPR / data privacy
- [ ] CCPA / state privacy laws
- [ ] COPPA (if minors may use)
- [ ] ADA / WCAG accessibility (AA minimum)
- [ ] Industry-specific (HIPAA, PCI-DSS, SOC2)
- **Applicable frameworks:** [list or N/A with reason]

### Security Compliance
- [ ] OWASP Top 10 addressed
- [ ] Authentication/authorization model defined
- [ ] Data encryption at rest and in transit
- [ ] Secret management (no hardcoded credentials)
- [ ] Input validation and output encoding

### License Compliance
- [ ] All dependency licenses compatible
- [ ] No copyleft contamination in proprietary code
- [ ] Attribution requirements documented
- [ ] Export control considerations

## Recommended Arsenal

### Skills
| Skill | Relevance | When to Use |
|-------|-----------|-------------|
| [skill-name] | [score/10] | [which phase/task] |

### Agents
| Agent | Specialization | When to Use |
|-------|---------------|-------------|
| [agent-name] | [what it does] | [which phase/task] |

### MCP Tools
| MCP | Tool | When to Use |
|-----|------|-------------|
| [mcp-name] | [tool] | [which phase/task] |

## Open Questions

| # | Question | Impact if Unresolved | Owner | Due Date |
|---|----------|---------------------|-------|----------|
| 1 | [Question that needs answering] | [What breaks if we guess wrong] | [who] | [date] |
| 2 | [Question that needs answering] | [What breaks if we guess wrong] | [who] | [date] |
