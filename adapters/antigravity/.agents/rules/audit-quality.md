# Code Quality Audit Rules -- Antigravity Format
#
# INSTALLATION: Copy .agents/ directory to your project root.
# These rules are referenced by the SPEAR audit workflow.
#
# Category: Code Quality
# Blocks on: HIGH

## Rule CQ-001: No Code Duplication
**Severity:** HIGH
**Check:** Identify blocks of code (>10 lines) that are duplicated across files
or within the same file. Look for:
- Copy-pasted functions with minor parameter differences
- Repeated patterns that should be extracted to a shared utility
- Duplicated validation logic, error handling, or data transformation
**Action:** Extract to shared function, trait, module, or utility.

## Rule CQ-002: No Dead Code
**Severity:** MEDIUM
**Check:** Identify:
- Unreachable branches (always-true/false conditions)
- Unused functions, variables, imports, or types
- Commented-out code blocks (>5 lines)
- Deprecated code without removal timeline
**Action:** Remove dead code. If needed later, it is in version control.

## Rule CQ-003: Clear Naming
**Severity:** MEDIUM
**Check:**
- Variable names describe what they hold (not `x`, `temp`, `data`)
- Function names describe what they do (verb + noun)
- Type/class names describe what they represent
- Boolean names read as assertions (`is_valid`, `has_permission`)
- No misleading names (e.g., `list` for something that is not a list)
- Abbreviations are consistent with codebase conventions
**Action:** Rename for clarity. Code is read more than it is written.

## Rule CQ-004: Error Handling Completeness
**Severity:** HIGH
**Check:**
- No empty catch/except blocks
- No errors swallowed silently (caught but not logged or propagated)
- Every error path has appropriate handling: log, propagate, or recover
- Error types are specific (not bare `Exception` or `Error`)
- Async error paths are handled (no unhandled promise rejections)
**Action:** Handle every error explicitly. Log at the boundary, propagate internally.

## Rule CQ-005: Test Coverage
**Severity:** HIGH
**Check:**
- All new public functions have unit tests
- All new API endpoints have integration tests
- Edge cases are tested (empty input, max values, error paths)
- Test coverage for changed files has not decreased
- Tests are meaningful (not just asserting true)
**Action:** Write tests alongside code. Coverage must not regress.

## Rule CQ-006: Consistent Style
**Severity:** LOW
**Check:**
- Code follows the same patterns as surrounding code
- Indentation, spacing, and formatting match project conventions
- Import ordering matches project convention
- File organization matches existing structure
**Action:** Match existing style. Run formatter if available.

## Rule CQ-007: Function Complexity
**Severity:** MEDIUM
**Check:**
- Functions longer than 50 lines
- Cyclomatic complexity > 15 per function
- Nesting depth > 4 levels
- Functions with >5 parameters
**Action:** Extract sub-functions. Reduce nesting with early returns.
Consider using builder/options pattern for many parameters.

## Rule CQ-008: Single Responsibility
**Severity:** MEDIUM
**Check:**
- Each function does one thing
- Each module/file has a clear, single purpose
- No "god objects" or "god functions" that do everything
- Changes to one concern do not require changes to unrelated code
**Action:** Split multi-purpose functions/modules into focused units.

## Rule CQ-009: Dependency Injection
**Severity:** LOW
**Check:**
- Hard dependencies on external services are injected, not constructed
- Tests can substitute mocks/stubs for external dependencies
- Configuration is passed in, not read globally
**Action:** Accept dependencies as parameters. Makes testing easier.

## Rule CQ-010: Resource Management
**Severity:** HIGH
**Check:**
- File handles, connections, locks are properly closed/released
- RAII patterns used in languages that support them
- Defer/finally blocks for cleanup in languages without RAII
- No resource leaks in error paths
- Timeouts on all external calls (HTTP, DB, file I/O)
**Action:** Ensure all resources are released in all code paths, including errors.
