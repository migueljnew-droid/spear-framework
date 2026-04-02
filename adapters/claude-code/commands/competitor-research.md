# /competitor-research — SPEAR Competitive Intelligence Phase

# INSTALLATION: Copy this file to .claude/commands/competitor-research.md in your project.
# Usage: Type /competitor-research in Claude Code to invoke this command.

You are entering the **Competitor Research phase** of the SPEAR framework. This is
a structured research phase that runs BEFORE or DURING the Plan phase to gather
competitive intelligence via binary analysis (App X-Ray) and web research.

## Prerequisites

Before proceeding, verify:
1. `.spear/` directory exists in the project
2. `~/app-xray/xray.sh` exists (App X-Ray framework)
3. Optionally: `.spear/output/spec/prd.md` exists (to know what WE are building)

If prerequisites are not met, tell the user what is missing and how to fix it.

## Step 1: Gather Competitor List

Ask the user to provide their competitors. For each, collect:

| Field | Required | Example |
|-------|----------|---------|
| Name | Yes | "Studio One" |
| Category | Yes | daw, ide, design, game-engine, video-editor, browser, generic |
| Local Path | If installed | "/Applications/Studio One 7.app" |
| Priority | Yes | primary, secondary, aspirational |

If the user isn't sure what's installed locally, run:
```bash
~/app-xray/xray.sh --list
```
to show all installed macOS apps.

If the user provides just names, auto-detect:
- Check if `/Applications/[Name].app` exists → offer binary analysis
- If not installed → default to web-only mode

## Step 2: Run the Research Runner

For each competitor, use the SPEAR × App X-Ray runner:

### If locally installed:
```bash
~/app-xray/spear-xray.sh --project <project-path> --app "<name>" --path "<app-path>" --category <cat>
```

### If web-only:
```bash
~/app-xray/spear-xray.sh --project <project-path> --app "<name>" --category <cat> --web-only
```

### Batch mode (multiple competitors):
Create a `competitors.json` file and run:
```bash
~/app-xray/spear-xray.sh --project <project-path> --competitors competitors.json
```

This generates:
- Per-competitor profiles (skeleton + xray data) in `.spear/output/research/competitors/`
- Research briefs in `.spear/output/research/briefs/`
- Research plan (search queries) from `research.py`
- Competitive matrix and gap analysis scaffolds

## Step 3: Execute Web Research

For EACH competitor, use the generated research queries to perform web searches.
The research plan at `.spear/output/research/competitors/[Name]_research.md` contains
pre-built search queries organized by topic.

### What to search for:
1. **White papers** — Technical architecture documents
2. **Engineering blogs** — How they solved specific problems
3. **Patent filings** — `site:patents.google.com "[Company]" [technology]`
4. **SDK documentation** — Public APIs, plugin development guides
5. **Conference talks** — GDC, AES Convention, WWDC, Strange Loop, etc.
6. **Open-source components** — Libraries they maintain or heavily use
7. **User reviews** — Technical depth from power users (Reddit, forums, Hacker News)
8. **Pricing & tiers** — Feature gates, what's free vs. paid

Use Perplexity (perplexity_search or perplexity_research) for web searches.
Use WebSearch/WebFetch for specific URLs.

### Record findings:
Update each competitor's profile with web research findings.
Update each research brief's "Findings" → "Web Research" section.

## Step 4: Cross-Reference Binary + Web

For competitors with binary analysis:
1. Compare xray framework detection with advertised features
2. Note discrepancies (marketing claims vs. actual implementation)
3. Identify architecture patterns from symbol analysis
4. Map class prefixes to internal modules/teams

Document cross-references in the research brief's "Cross-Reference" section.

## Step 5: Complete the Competitive Matrix

Fill in `.spear/output/research/competitive-matrix.md`:
- Every feature from our PRD should be a row
- Every competitor should be a column
- Use evidence-based status (not guesses)

## Step 6: Complete the Gap Analysis

Fill in `.spear/output/research/gap-analysis.md`:
- **Must-Have:** Features ALL competitors have (table stakes)
- **Differentiator:** Features only leaders have (opportunity)
- **Nice-to-Have:** Some competitors have (low priority)
- **Skip:** Competitors have but we intentionally exclude (with reasoning)

## Step 7: Generate Architecture Research Briefs

For any competitive finding that should influence our architecture:
1. Create a new research brief using `.spear/templates/plan/research-brief.md`
2. ID prefix: `RB-COMP-`
3. Reference the competitor evidence (xray report section + web URLs)
4. Set `blocking:` to the relevant SHARD or PHASE
5. Include a recommendation: adopt, adapt, or consciously avoid

## Step 8: Summary & Handoff

Present to the user:
1. Number of competitors analyzed (binary vs. web-only)
2. Key findings (top 3-5 insights)
3. Must-have gaps identified
4. Research briefs created (and which phases they block)
5. Recommended next action (typically: resolve briefs → continue Plan phase)

Mark the competitive analysis as complete. All research briefs remain "open" until
the user resolves them during the Plan phase.

## Self-Audit Checklist

- [ ] Every competitor has a profile (binary + web, or web-only)
- [ ] Binary analysis run on all locally-installed competitors
- [ ] Web research covers: white papers, blogs, patents, docs, pricing
- [ ] Cross-reference done (binary vs. web findings reconciled)
- [ ] Competitive matrix covers all PRD features
- [ ] Gap analysis categorized (must-have, differentiator, nice-to-have, skip)
- [ ] Research briefs created for architecture-impacting findings
- [ ] All sources documented in sources.md
- [ ] No marketing claims accepted without technical evidence
