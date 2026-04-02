# /productize -- SPEAR Productize Phase (Post-Ratchet)

# INSTALLATION: Copy this file to .claude/commands/productize.md in your project.
# Usage: Type /productize in Claude Code after /ratchet.

# Integrated into SPEAR from Project Ignition Pillar 8 concepts
# by Miguel Jiminez, April 2026

You are entering the **Productize phase** of the SPEAR framework. This is a
post-ratchet phase that scores every completed SPEAR cycle for packaging and
shipping as a standalone product. After every successful ratchet, pause and ask:
"Could this help someone else?" If yes, score it and decide whether to package it.

## Prerequisites

Before proceeding, verify:
1. Ratchet phase is complete (retrospective written, thresholds updated)
2. Audit verdict was GO or CONDITIONAL GO
3. The feature/product is functional and tested

## Step 1: The Productization Filter

Score the completed work on these 7 criteria (1-10 each, max 70):

| # | Criteria | Question | Score (1-10) |
|---|----------|----------|-------------|
| 1 | **Repeatable** | Would someone else face this same problem? | |
| 2 | **Transferable** | Can the solution work without your personal expertise? | |
| 3 | **Domain-Specific** | Niche enough to be valuable, broad enough for a market? | |
| 4 | **Data-Clean** | Can you strip client/personal data and keep the engine? | |
| 5 | **Better Than Free** | Does it outperform what's freely available? | |
| 6 | **Demonstrable** | Can you show results in under 60 seconds? | |
| 7 | **Stackable** | Can it bundle with other products or upsell? | |

### Scoring Thresholds

- **Score 50+**: GREEN. Build the product. Create a product brief.
- **Score 35-49**: YELLOW. Refine the concept first. What pushes it to 50+?
- **Below 35**: RED. Keep it internal. Not everything needs to be a product.

## Step 2: Product Form

If score is GREEN (50+), evaluate which form fits:

| Form | Best For | How It Makes Money |
|------|----------|--------------------|
| **SaaS Feature** | Workflow tools, dashboards | Subscription |
| **Template Pack** | Documents, scripts, checklists | One-time purchase |
| **Course or Training** | Teaching the methodology | Course platform |
| **White-Label Solution** | Licensing to other businesses | Licensing fee |
| **API / MCP Tool** | Developer integrations | Usage-based |
| **Plugin / Extension** | Extending existing platforms | Marketplace |
| **Open Source + Premium** | Community + enterprise upsell | Freemium |

## Step 3: Competitive Quick-Scan

Before committing to productize, run a rapid competitive check:

1. **Does this already exist?** Search for direct competitors.
2. **At what level?** (Funded startup? OSS project? Nobody?)
3. **What's our edge?** (Technology, domain expertise, integration, speed?)
4. **What's the whitespace?** (What gap does nobody fill?)

## Step 4: Pricing and Routing

For GREEN-scored products, map:

| Metric | Value |
|--------|-------|
| **Target addressable market** | [total / serviceable / obtainable] |
| **Pricing model** | [subscription / one-time / usage] |
| **Price point** | [$X/mo or $X one-time] |
| **Year 1 projection** | [$X] |
| **Effort to productize** | [S/M/L] |
| **Portfolio synergy** | [Which other products does this enhance?] |

Route the product to the correct entity:
- Justice/Grant products -> **FathersCAN**
- Music/SaaS/Tech products -> **GoldenMind Enterprize LLC**

## Output

Write to: `.spear/output/productize/PROD-[name].md`

Structure:
1. Product Name
2. Productization Score (7-criteria table + total)
3. Verdict (GREEN / YELLOW / RED)
4. Product Form (if GREEN)
5. Competitive Position
6. Pricing and Year 1 Projection (if GREEN)
7. Entity Routing
8. Next Steps (3-5 concrete actions)

## Present Summary

Show the user:
1. The score (X/70) with verdict color
2. If GREEN: form + pricing + next steps
3. If YELLOW: what needs to change to reach 50+
4. If RED: why it stays internal

Inform: "Productize complete. SPEAR cycle fully closed."
