# Security Audit Rules -- Antigravity Format
#
# INSTALLATION: Copy .agents/ directory to your project root.
# These rules are referenced by the SPEAR audit workflow.
#
# Category: Security
# Blocks on: CRITICAL
# Reference: OWASP Top 10, CWE Top 25

## Rule SEC-001: No Hardcoded Secrets
**Severity:** CRITICAL
**Check:** Search all changed files for patterns matching:
- API keys: `[A-Za-z0-9_-]{20,}` near keywords like `key`, `token`, `secret`, `password`
- AWS keys: `AKIA[0-9A-Z]{16}`
- Private keys: `-----BEGIN (RSA |EC )?PRIVATE KEY-----`
- Connection strings with embedded credentials
- Base64-encoded secrets in config files
**Action:** Secrets must use environment variables or a secret manager. Never in code.

## Rule SEC-002: Injection Prevention
**Severity:** CRITICAL
**Check:** Review all places where external input reaches:
- SQL queries (use parameterized queries, never string concatenation)
- Shell commands (use safe APIs, never pass raw input to shell)
- HTML output (escape or use framework auto-escaping)
- URL construction (validate and encode parameters)
- File paths (validate, normalize, prevent traversal)
**Action:** All external input must be validated and sanitized before use.

## Rule SEC-003: Authentication Checks
**Severity:** CRITICAL
**Check:** For every endpoint or operation that accesses user data:
- Authentication middleware is present
- Session/token validation occurs before data access
- No authentication bypass paths exist
**Action:** Every protected resource must verify identity.

## Rule SEC-004: Authorization Enforcement
**Severity:** CRITICAL
**Check:** For every data access:
- User can only access their own data (or data they are authorized for)
- Role/permission checks are present for admin operations
- No IDOR (Insecure Direct Object Reference) vulnerabilities
**Action:** Check authorization, not just authentication.

## Rule SEC-005: Input Validation
**Severity:** HIGH
**Check:** All external inputs (API parameters, form fields, headers, cookies):
- Have type validation (string, number, enum)
- Have length/range limits
- Are validated before processing
- Reject unexpected fields (allowlist, not denylist)
**Action:** Validate all inputs at the boundary.

## Rule SEC-006: Cryptographic Practices
**Severity:** CRITICAL
**Check:**
- No use of MD5 or SHA1 for security purposes
- No use of ECB mode for encryption
- No hardcoded initialization vectors or salts
- HTTPS enforced for all external communication
- TLS 1.2+ required
**Action:** Use modern cryptographic primitives with proper configuration.

## Rule SEC-007: Error Handling Security
**Severity:** HIGH
**Check:**
- Error responses do not include stack traces in production
- Error messages do not reveal database schema, file paths, or internal structure
- Errors are logged internally with detail, returned to users generically
**Action:** Internal errors return generic messages. Details go to logs only.

## Rule SEC-008: Dependency Vulnerabilities
**Severity:** CRITICAL
**Check:** Run dependency audit tool for the project's ecosystem:
- `npm audit` / `yarn audit` for Node.js
- `cargo audit` for Rust
- `pip-audit` for Python
- `bundle audit` for Ruby
- Check NVD/CVE databases for any flagged packages
**Action:** No known CRITICAL or HIGH CVEs in production dependencies.

## Rule SEC-009: Access Control Configuration
**Severity:** HIGH
**Check:**
- CORS configuration is restrictive (not `*` in production)
- File permissions are appropriate (no world-readable secrets)
- Rate limiting is present on authentication endpoints
- Account lockout or throttling after failed attempts
**Action:** Apply principle of least privilege to all access controls.

## Rule SEC-010: Data Protection
**Severity:** HIGH
**Check:**
- Sensitive data is encrypted at rest
- PII is not logged in plaintext
- Passwords are hashed with bcrypt/argon2/scrypt (not plain hash)
- Session tokens have appropriate expiry
- Secure cookie flags set (HttpOnly, Secure, SameSite)
**Action:** Protect sensitive data in storage, transit, and logs.
