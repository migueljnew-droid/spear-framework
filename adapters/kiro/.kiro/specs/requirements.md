# SPEAR Requirements Template -- Kiro Spec Format
#
# INSTALLATION: Copy the .kiro/ directory to your project root.
#
# This template maps the SPEAR PRD format to Kiro's requirements structure.
# Use this when creating specifications in the Spec phase.

## Feature: [Feature Name]

### Description
[1-2 paragraph description of the feature. What it is, why it matters,
who benefits. Write for someone with zero context.]

### Problem Statement
**Current State:** [How things work today without this feature]
**Desired State:** [How things should work after delivery]
**Impact of Inaction:** [What happens if we do not build this]

### Requirements

#### Functional Requirements

##### FR-1: [Requirement Name]
- **Description:** [What the system must do]
- **User Story:** As a [role], I want to [action], so that [benefit]
- **Priority:** must-have | should-have | nice-to-have
- **Acceptance Criteria:**
  - Given [context], when [action], then [expected result]
  - Given [context], when [action], then [expected result]
  - Given [context], when [action], then [expected result]

##### FR-2: [Requirement Name]
- **Description:** [What the system must do]
- **User Story:** As a [role], I want to [action], so that [benefit]
- **Priority:** must-have | should-have | nice-to-have
- **Acceptance Criteria:**
  - Given [context], when [action], then [expected result]

#### Non-Functional Requirements

##### NFR-1: Performance
- Response time: [e.g., p95 < 200ms]
- Throughput: [e.g., 1000 req/s]
- Concurrent users: [e.g., 10K]

##### NFR-2: Security
- Authentication: [method]
- Authorization: [model]
- Data protection: [encryption, compliance]

##### NFR-3: Reliability
- Uptime target: [e.g., 99.9%]
- Error rate: [e.g., < 0.1%]
- Recovery time: [e.g., < 5 min]

### Technical Constraints
- **Language/Runtime:** [e.g., Rust 1.75+, Node 20 LTS]
- **Platform:** [e.g., Linux x86_64, iOS 16+]
- **Compliance:** [e.g., GDPR, SOC2, HIPAA]
- **Integration:** [e.g., must work with existing auth system]

### Dependencies

| Dependency | Type | Owner | Status | Risk Level |
|-----------|------|-------|--------|------------|
| [name] | blocks / soft | [who] | ready / in-progress / unknown | low / med / high |

### Open Questions

| # | Question | Impact if Unresolved | Owner | Target Date |
|---|----------|---------------------|-------|-------------|
| 1 | [question] | [what breaks if we guess] | [who] | [date] |

### SPEAR References

- **Epic Shards:** List shards derived from these requirements
- **Fitness Functions:** Metrics to track (reference `.spear/output/plan/fitness-functions.md`)
- **Ratchet Thresholds:** Current constraints from `.spear/ratchet/ratchet.json`
- **Memory:** Past decisions from `.spear/memory/decisions/` that inform this spec
