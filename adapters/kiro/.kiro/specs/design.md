# SPEAR Design Template -- Kiro Spec Format
#
# INSTALLATION: Copy the .kiro/ directory to your project root.
#
# This template maps the SPEAR architecture doc to Kiro's design structure.
# Use this when defining system architecture in the Spec phase.

## System Design: [System/Feature Name]

### Overview
[High-level description: what this system does, its boundaries,
how it fits into the broader landscape.]

### System Context

**Actors:**
- [Actor 1]: [role, interaction pattern]
- [Actor 2]: [role, interaction pattern]

**External Systems:**
- [System A]: [provides/consumes what]
- [System B]: [provides/consumes what]

### Architecture

#### Component Diagram
```
[ASCII art showing components, their relationships, and data flow.
Use boxes, arrows, and labels. Keep it readable.]
```

#### Components

| Component | Responsibility | Technology | Interfaces |
|-----------|---------------|------------|------------|
| [name] | [what it does] | [tech choice] | [APIs/events] |
| [name] | [what it does] | [tech choice] | [APIs/events] |

### Data Flow

#### Primary Flow: [Name]
1. [Actor/System] sends [what] to [Component]
2. [Component] validates and processes
3. [Component] persists/emits to [destination]
4. [downstream] handles [result]

#### Error Flow: [Name]
1. [What triggers the error]
2. [How the error is detected]
3. [How the error is handled]
4. [What the user sees]

### API Contracts

#### [Endpoint 1]
- **Method:** GET | POST | PUT | DELETE
- **Path:** `/api/v1/[resource]`
- **Auth:** [required | optional | none]
- **Request:**
  ```json
  { "field": "type -- description" }
  ```
- **Response (2xx):**
  ```json
  { "field": "type -- description" }
  ```
- **Errors:** [status codes and when they occur]

### Technology Decisions

| Decision | Choice | Alternatives | Rationale |
|----------|--------|-------------|-----------|
| Language | [chosen] | [options] | [why] |
| Database | [chosen] | [options] | [why] |
| Framework | [chosen] | [options] | [why] |

### Security Design

- **Authentication:** [method and flow]
- **Authorization:** [model: RBAC, ABAC, etc.]
- **Data at Rest:** [encryption approach]
- **Data in Transit:** [TLS config]
- **Secrets:** [management approach]
- **Attack Surface:** [known risks and mitigations]

### Performance Targets

| Metric | Target | How to Measure | Fitness Function |
|--------|--------|---------------|-----------------|
| Latency (p50) | [value] | [tool/method] | [FF-NNN] |
| Latency (p99) | [value] | [tool/method] | [FF-NNN] |
| Throughput | [value] | [tool/method] | [FF-NNN] |
| Memory | [value] | [tool/method] | [FF-NNN] |

### SPEAR References

- **PRD:** Link to `.spear/output/spec/prd.md`
- **Ratchet:** Current thresholds from `.spear/ratchet/ratchet.json`
- **Memory:** Past architectural decisions from `.spear/memory/decisions/`
- **Patterns:** Established patterns from `.spear/memory/patterns/`

> If no prior architectural decisions exist, state:
> "Greenfield -- no prior decisions to reference."
