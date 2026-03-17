---
cycle_id: "CYCLE-[NNN]"
date: "YYYY-MM-DD"
phases_completed:
  - "PHASE-[NNN]"
  - "PHASE-[NNN]"
duration: "[e.g., 3d, 1w, 2w]"
---

# Retrospective: CYCLE-[NNN]

**Phases:** [List of phases completed in this cycle]
**Duration:** [Actual time from start to audit pass]
**Planned duration:** [What was estimated]

## What Went Well

- [Specific thing that worked — be concrete, not generic]
- [Specific thing that worked]
- [Specific thing that worked]

## What Didn't

- [Specific problem — what happened and what was the impact]
- [Specific problem]
- [Specific problem]

## Surprises

- [Something unexpected — good or bad — that was not anticipated in planning]
- [Something unexpected]

## Musk Gate Results (Requirement Challenge)

| Metric | Value | Notes |
|--------|-------|-------|
| Requirements challenged | [e.g., 8] | [total from requirement-challenge.md] |
| Requirements KILLED | [e.g., 2] | [which ones and why] |
| Requirements SIMPLIFIED | [e.g., 1] | [what was reduced] |
| Deletions proposed | [e.g., 3] | [from deletion-proposal.md] |
| Deletions executed | [e.g., 2] | [what was actually removed] |
| Net scope reduction | [e.g., -25%] | [estimated reduction from original ask] |

> If all requirements survived unchallenged, explain why. "No deletions" requires justification.

## Cycle Time (Musk Step 4: Accelerate)

| Phase | Duration | Rolling Avg (last 3) | Flag |
|-------|----------|---------------------|------|
| Spec | [e.g., 45m] | [e.g., 40m] | [OK / SLOW / FAST] |
| Plan | [e.g., 30m] | [e.g., 35m] | [OK / SLOW / FAST] |
| Execute | [e.g., 180m] | [e.g., 120m] | [SLOW — investigate] |
| Audit | [e.g., 20m] | [e.g., 18m] | [OK] |
| Ratchet | [e.g., 10m] | [e.g., 12m] | [OK] |
| **Total** | [e.g., 285m] | [e.g., 225m] | [SLOW] |

> SLOW (>2x avg): investigate root cause. FAST (<0.5x avg): verify quality wasn't sacrificed.

## Metrics Delta

| Metric | Before Cycle | After Cycle | Delta | Ratchet Updated? |
|--------|-------------|------------|-------|-----------------|
| Test Coverage | [e.g., 72%] | [e.g., 85%] | [+13%] | [yes — RATCHET-NNN] |
| Build Time | [e.g., 38s] | [e.g., 42s] | [+4s] | [no — within threshold] |
| Lint Errors | [e.g., 3] | [e.g., 0] | [-3] | [yes — RATCHET-NNN] |
| Deviations | [n/a] | [e.g., 2] | [n/a] | [n/a] |
| Findings (critical) | [n/a] | [e.g., 0] | [n/a] | [n/a] |
| Findings (total) | [n/a] | [e.g., 7] | [n/a] | [n/a] |

## Capability Utilization

| Capability | Type | Assigned | Used? | Notes |
|-----------|------|----------|-------|-------|
| [name] | skill/agent/mcp/dep | T1, T3 | yes/no | [fallback reason if no] |

**Summary:**
- Capabilities available: [N]
- Capabilities used: [N]
- Utilization rate: [N%]
- Missed opportunities: [list capabilities that could have been used but weren't]
- Fallback incidents: [list capabilities that were unavailable at runtime]
- Registry freshness: [cycles since last refresh — WARN if >3]

## New Rules Proposed

| Rule ID | Statement | Status |
|---------|-----------|--------|
| [RULE-NNN] | [One-line rule statement] | [proposed/approved/rejected] |
| [RULE-NNN] | [One-line rule statement] | [proposed/approved/rejected] |

> If none: "No new rules proposed this cycle."

## Memory Updates

[What should be remembered for future cycles? These get saved to the project memory.]

- [Lesson or context to persist]
- [Lesson or context to persist]
- [Decision rationale to preserve]

## Action Items for Next Cycle

| # | Action | Owner | Priority |
|---|--------|-------|----------|
| 1 | [Concrete action to take in the next cycle] | [who] | [high/med/low] |
| 2 | [Concrete action] | [who] | [high/med/low] |
| 3 | [Concrete action] | [who] | [high/med/low] |
