#!/usr/bin/env bash
# =============================================================================
# SPEAR Framework — lint-check checker
# =============================================================================
# Auto-detects project language and runs the appropriate linter on staged files.
# Gracefully skips if the linter is not installed.
# =============================================================================
set -euo pipefail

# ---------------------------------------------------------------------------
# Color helpers
# ---------------------------------------------------------------------------
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BOLD='\033[1m'
    RESET='\033[0m'
else
    RED='' GREEN='' YELLOW='' CYAN='' BOLD='' RESET=''
fi

CHECKER_NAME="lint-check"
PROJECT_ROOT="${1:-.}"

# ---------------------------------------------------------------------------
# Get staged files
# ---------------------------------------------------------------------------
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null) || STAGED_FILES=""

if [ -z "$STAGED_FILES" ]; then
    printf "${GREEN}[SPEAR] %-20s PASS %s (no staged files)${RESET}\n" "${CHECKER_NAME}:" "✓"
    exit 0
fi

# ---------------------------------------------------------------------------
# Detect languages present in the project
# ---------------------------------------------------------------------------
HAS_JS=0
HAS_RUST=0
HAS_PYTHON=0
HAS_GO=0

[ -f "${PROJECT_ROOT}/package.json" ] && HAS_JS=1
[ -f "${PROJECT_ROOT}/Cargo.toml" ] && HAS_RUST=1
[ -f "${PROJECT_ROOT}/requirements.txt" ] || [ -f "${PROJECT_ROOT}/pyproject.toml" ] || [ -f "${PROJECT_ROOT}/setup.py" ] || [ -f "${PROJECT_ROOT}/setup.cfg" ] && HAS_PYTHON=1
[ -f "${PROJECT_ROOT}/go.mod" ] && HAS_GO=1

# If no manifest found, try to detect from staged file extensions
if [ "$HAS_JS" -eq 0 ] && [ "$HAS_RUST" -eq 0 ] && [ "$HAS_PYTHON" -eq 0 ] && [ "$HAS_GO" -eq 0 ]; then
    echo "$STAGED_FILES" | grep -qE '\.(js|jsx|ts|tsx|mjs|cjs)$' && HAS_JS=1
    echo "$STAGED_FILES" | grep -qE '\.rs$' && HAS_RUST=1
    echo "$STAGED_FILES" | grep -qE '\.py$' && HAS_PYTHON=1
    echo "$STAGED_FILES" | grep -qE '\.go$' && HAS_GO=1
fi

if [ "$HAS_JS" -eq 0 ] && [ "$HAS_RUST" -eq 0 ] && [ "$HAS_PYTHON" -eq 0 ] && [ "$HAS_GO" -eq 0 ]; then
    printf "${YELLOW}[SPEAR] %-20s SKIP %s (no recognized language detected)${RESET}\n" "${CHECKER_NAME}:" "⊘"
    exit 0
fi

# ---------------------------------------------------------------------------
# Track results
# ---------------------------------------------------------------------------
RAN_ANY=0
FAILURES=0
MESSAGES=""

# ---------------------------------------------------------------------------
# JS/TS linting
# ---------------------------------------------------------------------------
if [ "$HAS_JS" -eq 1 ]; then
    JS_FILES=$(echo "$STAGED_FILES" | grep -E '\.(js|jsx|ts|tsx|mjs|cjs)$' || true)

    if [ -n "$JS_FILES" ]; then
        if command -v npx >/dev/null 2>&1 && [ -f "${PROJECT_ROOT}/node_modules/.bin/eslint" ]; then
            RAN_ANY=1
            # shellcheck disable=SC2086
            if (cd "$PROJECT_ROOT" && npx eslint --no-error-on-unmatched-pattern $JS_FILES) >/dev/null 2>&1; then
                MESSAGES="${MESSAGES}${GREEN}[SPEAR]     JS/TS (eslint): passed${RESET}\n"
            else
                FAILURES=$((FAILURES + 1))
                MESSAGES="${MESSAGES}${RED}[SPEAR]     JS/TS (eslint): failed${RESET}\n"
            fi
        elif command -v eslint >/dev/null 2>&1; then
            RAN_ANY=1
            # shellcheck disable=SC2086
            if (cd "$PROJECT_ROOT" && eslint --no-error-on-unmatched-pattern $JS_FILES) >/dev/null 2>&1; then
                MESSAGES="${MESSAGES}${GREEN}[SPEAR]     JS/TS (eslint): passed${RESET}\n"
            else
                FAILURES=$((FAILURES + 1))
                MESSAGES="${MESSAGES}${RED}[SPEAR]     JS/TS (eslint): failed${RESET}\n"
            fi
        else
            MESSAGES="${MESSAGES}${YELLOW}[SPEAR]     JS/TS: eslint not found — skipped${RESET}\n"
        fi
    fi
fi

# ---------------------------------------------------------------------------
# Rust linting
# ---------------------------------------------------------------------------
if [ "$HAS_RUST" -eq 1 ]; then
    RS_FILES=$(echo "$STAGED_FILES" | grep -E '\.rs$' || true)

    if [ -n "$RS_FILES" ]; then
        if command -v cargo >/dev/null 2>&1; then
            RAN_ANY=1
            if (cd "$PROJECT_ROOT" && cargo clippy --all-targets --all-features -- -D warnings) >/dev/null 2>&1; then
                MESSAGES="${MESSAGES}${GREEN}[SPEAR]     Rust (clippy): passed${RESET}\n"
            else
                FAILURES=$((FAILURES + 1))
                MESSAGES="${MESSAGES}${RED}[SPEAR]     Rust (clippy): failed${RESET}\n"
            fi
        else
            MESSAGES="${MESSAGES}${YELLOW}[SPEAR]     Rust: cargo not found — skipped${RESET}\n"
        fi
    fi
fi

# ---------------------------------------------------------------------------
# Python linting
# ---------------------------------------------------------------------------
if [ "$HAS_PYTHON" -eq 1 ]; then
    PY_FILES=$(echo "$STAGED_FILES" | grep -E '\.py$' || true)

    if [ -n "$PY_FILES" ]; then
        if command -v ruff >/dev/null 2>&1; then
            RAN_ANY=1
            # shellcheck disable=SC2086
            if (cd "$PROJECT_ROOT" && ruff check $PY_FILES) >/dev/null 2>&1; then
                MESSAGES="${MESSAGES}${GREEN}[SPEAR]     Python (ruff): passed${RESET}\n"
            else
                FAILURES=$((FAILURES + 1))
                MESSAGES="${MESSAGES}${RED}[SPEAR]     Python (ruff): failed${RESET}\n"
            fi
        elif command -v flake8 >/dev/null 2>&1; then
            RAN_ANY=1
            # shellcheck disable=SC2086
            if (cd "$PROJECT_ROOT" && flake8 $PY_FILES) >/dev/null 2>&1; then
                MESSAGES="${MESSAGES}${GREEN}[SPEAR]     Python (flake8): passed${RESET}\n"
            else
                FAILURES=$((FAILURES + 1))
                MESSAGES="${MESSAGES}${RED}[SPEAR]     Python (flake8): failed${RESET}\n"
            fi
        else
            MESSAGES="${MESSAGES}${YELLOW}[SPEAR]     Python: ruff/flake8 not found — skipped${RESET}\n"
        fi
    fi
fi

# ---------------------------------------------------------------------------
# Go linting
# ---------------------------------------------------------------------------
if [ "$HAS_GO" -eq 1 ]; then
    GO_FILES=$(echo "$STAGED_FILES" | grep -E '\.go$' || true)

    if [ -n "$GO_FILES" ]; then
        if command -v golangci-lint >/dev/null 2>&1; then
            RAN_ANY=1
            if (cd "$PROJECT_ROOT" && golangci-lint run ./...) >/dev/null 2>&1; then
                MESSAGES="${MESSAGES}${GREEN}[SPEAR]     Go (golangci-lint): passed${RESET}\n"
            else
                FAILURES=$((FAILURES + 1))
                MESSAGES="${MESSAGES}${RED}[SPEAR]     Go (golangci-lint): failed${RESET}\n"
            fi
        else
            MESSAGES="${MESSAGES}${YELLOW}[SPEAR]     Go: golangci-lint not found — skipped${RESET}\n"
        fi
    fi
fi

# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------
if [ "$FAILURES" -gt 0 ]; then
    printf "${RED}${BOLD}[SPEAR] %-20s FAIL %s${RESET}\n" "${CHECKER_NAME}:" "✗"
    printf "$MESSAGES"
    exit 1
elif [ "$RAN_ANY" -eq 0 ]; then
    printf "${YELLOW}[SPEAR] %-20s SKIP %s (no linters available)${RESET}\n" "${CHECKER_NAME}:" "⊘"
    printf "$MESSAGES"
    exit 0
else
    printf "${GREEN}[SPEAR] %-20s PASS %s${RESET}\n" "${CHECKER_NAME}:" "✓"
    printf "$MESSAGES"
    exit 0
fi
