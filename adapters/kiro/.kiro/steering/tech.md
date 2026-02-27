# Technical Audit Standards -- Kiro Steering File
#
# INSTALLATION: Copy the .kiro/ directory to your project root.
#
# This file defines the technical audit standards that Kiro should enforce
# as part of the SPEAR framework. These standards apply during the Execute
# and Audit phases.

## Security Standards

### Secrets Management
- No hardcoded API keys, tokens, passwords, or connection strings
- Secrets stored in environment variables or a dedicated secret manager
- Scan patterns: `AKIA`, `-----BEGIN.*KEY-----`, `password\s*=`, `token\s*=`
- .env files must be in .gitignore

### Input Validation
- All external inputs validated at the boundary (type, length, range)
- Parameterized queries for all database operations (no string concatenation)
- HTML output escaped or auto-escaped by framework
- File paths normalized and validated (no directory traversal)
- URL parameters encoded

### Authentication and Authorization
- Every protected endpoint requires authentication
- Authorization checked for every data access (not just authentication)
- No IDOR (Insecure Direct Object Reference) vulnerabilities
- Session tokens have appropriate expiry and rotation

### Cryptography
- No MD5 or SHA1 for security purposes
- No ECB mode, no hardcoded IVs/salts
- TLS 1.2+ for all external communication
- Passwords hashed with bcrypt, argon2, or scrypt

## Performance Standards

### Algorithm Complexity
- No O(n^2) algorithms where O(n log n) or O(n) is feasible
- Document complexity of critical algorithms in comments
- No unbounded loops or recursion without depth limits

### Database Patterns
- No N+1 query patterns (use joins or batch loading)
- Pagination on all list endpoints
- Indexes on frequently queried columns
- Connection pooling for database access

### Resource Efficiency
- No memory leaks (unclosed handles, growing collections, circular references)
- Timeouts on all external calls (HTTP, database, file I/O)
- Streaming for large data (not loading entire datasets into memory)
- Bundle/binary size changes justified

## Code Quality Standards

### Structure
- Functions under 50 lines (extract helpers for longer functions)
- Cyclomatic complexity under 15 per function
- Nesting depth under 4 levels (use early returns)
- Single Responsibility Principle for functions and modules

### Error Handling
- No empty catch/except blocks
- No silently swallowed errors
- Specific error types (not bare Exception/Error)
- Resources released in error paths (RAII, defer, finally)
- Async errors handled (no unhandled rejections)

### Testing
- Unit tests for all public functions
- Integration tests for API endpoints
- Edge cases tested (empty, null, max, error paths)
- Test coverage must not decrease
- Tests are meaningful (assert behavior, not implementation)

### Style
- Match existing codebase patterns and conventions
- Clear naming: variables describe contents, functions describe actions
- No magic numbers (use named constants)
- No commented-out code (it is in version control)
- Imports organized per project convention

## Documentation Standards

### Public API
- All public functions, types, and endpoints documented
- Parameters, return types, and error conditions described
- Examples provided for non-obvious usage

### Project
- README updated when setup or behavior changes
- Changelog entry for user-facing changes
- Configuration options documented with defaults

### Code
- Non-obvious logic commented (WHY, not WHAT)
- Complex algorithms explained with approach and complexity
- TODO comments include context and owner

## Architecture Standards

### Boundaries
- No layer violations (UI must not call database directly)
- No circular dependencies between modules
- Clear separation of concerns (business logic, data access, presentation)
- Interface contracts respected across module boundaries

### Patterns
- New patterns justified when existing patterns exist
- Consistent use of chosen patterns throughout codebase
- Dependencies injected, not constructed (for testability)
- Configuration passed in, not read globally
