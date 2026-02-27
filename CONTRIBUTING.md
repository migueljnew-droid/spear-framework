# Contributing to SPEAR

Thank you for your interest in contributing to SPEAR! This framework thrives on community input.

## How to Contribute

### Reporting Issues
- Use GitHub Issues with the appropriate template (bug, feature, audit rule proposal)
- Include your SPEAR version, AI tool, and project language

### Submitting Changes

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Make your changes following the conventions below
4. Test your changes (see Testing section)
5. Commit with conventional commits: `feat:`, `fix:`, `docs:`, `chore:`
6. Push and open a Pull Request

### Conventions

**Templates:** All templates use Markdown with YAML frontmatter. Follow the existing format in `.spear/templates/`.

**Agent Prompts:** Keep prompts AI-agnostic. No tool-specific syntax in core agent files. Use the adapter layer for tool-specific integration.

**Hooks:** All hooks are POSIX-compatible bash. No external dependencies beyond standard unix tools + language-specific tooling (cargo, npm, etc.).

**Fitness Functions:** Each function reads its threshold from `.spear/ratchet/ratchet.json` and outputs pass/fail to stdout.

### What We're Looking For

- New audit rules derived from real-world findings
- Fitness function examples for different ecosystems
- AI tool adapter improvements
- Documentation fixes and improvements
- Language-specific hook improvements

### Testing

Before submitting a PR:

```bash
# Run the pre-commit hook manually
bash hooks/pre-commit

# Verify SPEAR.md is under 300 lines
wc -l .spear/SPEAR.md
```

## Code of Conduct

This project follows the [Contributor Covenant](CODE_OF_CONDUCT.md). By participating, you agree to abide by its terms.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
