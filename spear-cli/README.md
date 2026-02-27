# SPEAR CLI (Future)

The SPEAR CLI will provide command-line access to framework operations:

```bash
spear init          # Initialize SPEAR in current project
spear status        # Show current phase, ratchet state, pending findings
spear spec          # Start the Spec phase
spear plan          # Start the Plan phase
spear execute       # Start the Execute phase
spear audit         # Run all 6 audit categories
spear ratchet       # Update ratchet and generate retrospective
spear memory search # Search project memory
spear fitness run   # Run all active fitness functions
```

**Status:** Planned for v2.0. Currently, SPEAR operates through AI tool adapters, git hooks, and templates.

For now, use the AI tool adapters (Claude Code commands, Cursor rules, etc.) or work directly with the templates and hooks.
