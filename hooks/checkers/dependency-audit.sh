#!/usr/bin/env bash
# =============================================================================
# SPEAR Framework — dependency-audit checker
# =============================================================================
# Auto-detects project language and runs the appropriate dependency
# vulnerability scanner. Exits 1 on high/critical vulnerabilities.
# Gracefully skips if audit tool is not installed.
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

CHECKER_NAME="dependency-audit"
PROJECT_ROOT="${1:-.}"

# ---------------------------------------------------------------------------
# Detect project languages
# ---------------------------------------------------------------------------
HAS_RUST=0
HAS_NODE=0
HAS_PYTHON=0
HAS_GO=0

[ -f "${PROJECT_ROOT}/Cargo.toml" ] && HAS_RUST=1
[ -f "${PROJECT_ROOT}/package.json" ] && HAS_NODE=1
[ -f "${PROJECT_ROOT}/requirements.txt" ] || [ -f "${PROJECT_ROOT}/pyproject.toml" ] || [ -f "${PROJECT_ROOT}/setup.py" ] && HAS_PYTHON=1
[ -f "${PROJECT_ROOT}/go.mod" ] && HAS_GO=1

if [ "$HAS_RUST" -eq 0 ] && [ "$HAS_NODE" -eq 0 ] && [ "$HAS_PYTHON" -eq 0 ] && [ "$HAS_GO" -eq 0 ]; then
    printf "${YELLOW}[SPEAR] %-20s SKIP %s (no recognized project manifests)${RESET}\n" "${CHECKER_NAME}:" "⊘"
    exit 0
fi

# ---------------------------------------------------------------------------
# Track results
# ---------------------------------------------------------------------------
RAN_ANY=0
FAILURES=0
MESSAGES=""

# ---------------------------------------------------------------------------
# Rust: cargo audit
# ---------------------------------------------------------------------------
if [ "$HAS_RUST" -eq 1 ]; then
    if command -v cargo >/dev/null 2>&1; then
        # Check if cargo-audit subcommand is available
        if cargo audit --version >/dev/null 2>&1; then
            RAN_ANY=1
            AUDIT_OUT=""
            if AUDIT_OUT=$(cd "$PROJECT_ROOT" && cargo audit 2>&1); then
                MESSAGES="${MESSAGES}${GREEN}[SPEAR]     Rust (cargo audit): no vulnerabilities${RESET}\n"
            else
                # Check severity — cargo audit exits 1 on any vuln
                if echo "$AUDIT_OUT" | grep -qi "critical\|high"; then
                    FAILURES=$((FAILURES + 1))
                    MESSAGES="${MESSAGES}${RED}[SPEAR]     Rust (cargo audit): HIGH/CRITICAL vulnerabilities found${RESET}\n"
                    # Show first few lines of output
                    SUMMARY=$(echo "$AUDIT_OUT" | grep -i "vulnerability\|crate\|critical\|high" | head -5)
                    if [ -n "$SUMMARY" ]; then
                        while IFS= read -r line; do
                            MESSAGES="${MESSAGES}${RED}[SPEAR]       ${line}${RESET}\n"
                        done <<< "$SUMMARY"
                    fi
                else
                    # Only low/medium — warn but don't fail
                    MESSAGES="${MESSAGES}${YELLOW}[SPEAR]     Rust (cargo audit): low/medium vulnerabilities (non-blocking)${RESET}\n"
                fi
            fi
        else
            MESSAGES="${MESSAGES}${YELLOW}[SPEAR]     Rust: cargo-audit not installed — skipped (install: cargo install cargo-audit)${RESET}\n"
        fi
    else
        MESSAGES="${MESSAGES}${YELLOW}[SPEAR]     Rust: cargo not found — skipped${RESET}\n"
    fi
fi

# ---------------------------------------------------------------------------
# Node: npm audit
# ---------------------------------------------------------------------------
if [ "$HAS_NODE" -eq 1 ]; then
    if [ -f "${PROJECT_ROOT}/package-lock.json" ] || [ -f "${PROJECT_ROOT}/yarn.lock" ]; then
        if command -v npm >/dev/null 2>&1; then
            RAN_ANY=1
            AUDIT_OUT=""
            if AUDIT_OUT=$(cd "$PROJECT_ROOT" && npm audit --audit-level=high 2>&1); then
                MESSAGES="${MESSAGES}${GREEN}[SPEAR]     Node (npm audit): no high/critical vulnerabilities${RESET}\n"
            else
                EXIT_CODE=$?
                # npm audit exits non-zero when vulns found at/above specified level
                if [ "$EXIT_CODE" -ne 0 ]; then
                    FAILURES=$((FAILURES + 1))
                    VULN_COUNT=$(echo "$AUDIT_OUT" | grep -oE '[0-9]+ (high|critical)' | head -3 || echo "")
                    MESSAGES="${MESSAGES}${RED}[SPEAR]     Node (npm audit): HIGH/CRITICAL vulnerabilities found${RESET}\n"
                    if [ -n "$VULN_COUNT" ]; then
                        while IFS= read -r line; do
                            [ -n "$line" ] && MESSAGES="${MESSAGES}${RED}[SPEAR]       ${line}${RESET}\n"
                        done <<< "$VULN_COUNT"
                    fi
                fi
            fi
        else
            MESSAGES="${MESSAGES}${YELLOW}[SPEAR]     Node: npm not found — skipped${RESET}\n"
        fi
    else
        MESSAGES="${MESSAGES}${YELLOW}[SPEAR]     Node: no lockfile found — skipped (run npm install first)${RESET}\n"
    fi
fi

# ---------------------------------------------------------------------------
# Python: pip-audit or safety
# ---------------------------------------------------------------------------
if [ "$HAS_PYTHON" -eq 1 ]; then
    if command -v pip-audit >/dev/null 2>&1; then
        RAN_ANY=1
        AUDIT_OUT=""
        if AUDIT_OUT=$(cd "$PROJECT_ROOT" && pip-audit 2>&1); then
            MESSAGES="${MESSAGES}${GREEN}[SPEAR]     Python (pip-audit): no vulnerabilities${RESET}\n"
        else
            FAILURES=$((FAILURES + 1))
            MESSAGES="${MESSAGES}${RED}[SPEAR]     Python (pip-audit): vulnerabilities found${RESET}\n"
            SUMMARY=$(echo "$AUDIT_OUT" | head -5)
            if [ -n "$SUMMARY" ]; then
                while IFS= read -r line; do
                    [ -n "$line" ] && MESSAGES="${MESSAGES}${RED}[SPEAR]       ${line}${RESET}\n"
                done <<< "$SUMMARY"
            fi
        fi
    elif command -v safety >/dev/null 2>&1; then
        RAN_ANY=1
        AUDIT_OUT=""
        if AUDIT_OUT=$(cd "$PROJECT_ROOT" && safety check 2>&1); then
            MESSAGES="${MESSAGES}${GREEN}[SPEAR]     Python (safety): no vulnerabilities${RESET}\n"
        else
            FAILURES=$((FAILURES + 1))
            MESSAGES="${MESSAGES}${RED}[SPEAR]     Python (safety): vulnerabilities found${RESET}\n"
        fi
    else
        MESSAGES="${MESSAGES}${YELLOW}[SPEAR]     Python: pip-audit/safety not found — skipped (install: pip install pip-audit)${RESET}\n"
    fi
fi

# ---------------------------------------------------------------------------
# Go: govulncheck
# ---------------------------------------------------------------------------
if [ "$HAS_GO" -eq 1 ]; then
    if command -v govulncheck >/dev/null 2>&1; then
        RAN_ANY=1
        AUDIT_OUT=""
        if AUDIT_OUT=$(cd "$PROJECT_ROOT" && govulncheck ./... 2>&1); then
            MESSAGES="${MESSAGES}${GREEN}[SPEAR]     Go (govulncheck): no vulnerabilities${RESET}\n"
        else
            FAILURES=$((FAILURES + 1))
            MESSAGES="${MESSAGES}${RED}[SPEAR]     Go (govulncheck): vulnerabilities found${RESET}\n"
            SUMMARY=$(echo "$AUDIT_OUT" | grep -i "vuln\|GO-" | head -5)
            if [ -n "$SUMMARY" ]; then
                while IFS= read -r line; do
                    [ -n "$line" ] && MESSAGES="${MESSAGES}${RED}[SPEAR]       ${line}${RESET}\n"
                done <<< "$SUMMARY"
            fi
        fi
    else
        MESSAGES="${MESSAGES}${YELLOW}[SPEAR]     Go: govulncheck not found — skipped (install: go install golang.org/x/vuln/cmd/govulncheck@latest)${RESET}\n"
    fi
fi

# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------
if [ "$FAILURES" -gt 0 ]; then
    printf "${RED}${BOLD}[SPEAR] %-20s FAIL %s (high/critical vulnerabilities)${RESET}\n" "${CHECKER_NAME}:" "✗"
    printf "$MESSAGES"
    exit 1
elif [ "$RAN_ANY" -eq 0 ]; then
    printf "${YELLOW}[SPEAR] %-20s SKIP %s (no audit tools available)${RESET}\n" "${CHECKER_NAME}:" "⊘"
    printf "$MESSAGES"
    exit 0
else
    printf "${GREEN}[SPEAR] %-20s PASS %s${RESET}\n" "${CHECKER_NAME}:" "✓"
    printf "$MESSAGES"
    exit 0
fi
