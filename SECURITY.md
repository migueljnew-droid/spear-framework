# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in SPEAR, please report it responsibly:

1. **Do NOT open a public issue.** Security vulnerabilities should not be disclosed publicly until a fix is available.
2. **Email:** Send details to [security contact - add your email here]
3. **Include:** Description, steps to reproduce, affected versions, potential impact.

We will acknowledge receipt within 48 hours and provide a fix timeline within 7 days.

## Scope

SPEAR installs git hooks and shell scripts into your project. Security issues include:
- Command injection in hook scripts
- Path traversal in file operations
- Secrets exposure through scanning gaps
- Supply chain risks in the installer

## Supported Versions

| Version | Supported |
|---------|-----------|
| 1.0.x   | Yes       |
