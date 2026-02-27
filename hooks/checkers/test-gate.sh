#!/usr/bin/env bash
# =============================================================================
# SPEAR Framework — test-gate checker
# =============================================================================
# Detects the test framework and runs tests. Exits 1 if tests fail.
# Supports Rust (cargo test), Node (npm test / jest / vitest),
# Python (pytest / unittest), and Go (go test).
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

CHECKER_NAME="test-gate"
PROJECT_ROOT="${1:-.}"

# ---------------------------------------------------------------------------
# Detect project language/framework
# ---------------------------------------------------------------------------
HAS_RUST=0
HAS_NODE=0
HAS_PYTHON=0
HAS_GO=0

[ -f "${PROJECT_ROOT}/Cargo.toml" ] && HAS_RUST=1
[ -f "${PROJECT_ROOT}/package.json" ] && HAS_NODE=1
[ -f "${PROJECT_ROOT}/requirements.txt" ] || [ -f "${PROJECT_ROOT}/pyproject.toml" ] || [ -f "${PROJECT_ROOT}/setup.py" ] || [ -f "${PROJECT_ROOT}/setup.cfg" ] && HAS_PYTHON=1
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
# Helper: extract test counts from output (best-effort)
# ---------------------------------------------------------------------------
extract_test_summary() {
    local output="$1"
    local framework="$2"

    case "$framework" in
        cargo)
            # "test result: ok. 42 passed; 0 failed; 0 ignored"
            echo "$output" | grep -oE 'test result: [a-z]+\. [0-9]+ passed; [0-9]+ failed' | tail -1
            ;;
        jest|vitest)
            # "Tests: 2 failed, 42 passed, 44 total"
            echo "$output" | grep -oEi '(Tests?|test suites?):.*' | tail -2
            ;;
        pytest)
            # "42 passed, 2 failed in 1.23s" or "===== 42 passed ====="
            echo "$output" | grep -oE '[0-9]+ passed' | tail -1
            ;;
        go)
            # "ok  ./... 1.234s"
            local pass_count
            pass_count=$(echo "$output" | grep -c '^ok' || true)
            local fail_count
            fail_count=$(echo "$output" | grep -c '^FAIL' || true)
            echo "${pass_count} passed, ${fail_count} failed"
            ;;
        npm)
            # npm test output varies widely
            echo "$output" | tail -3 | head -1
            ;;
        *)
            echo ""
            ;;
    esac
}

# ---------------------------------------------------------------------------
# Rust: cargo test
# ---------------------------------------------------------------------------
if [ "$HAS_RUST" -eq 1 ]; then
    if command -v cargo >/dev/null 2>&1; then
        RAN_ANY=1
        TEST_OUT=""
        if TEST_OUT=$(cd "$PROJECT_ROOT" && cargo test 2>&1); then
            SUMMARY=$(extract_test_summary "$TEST_OUT" "cargo")
            MESSAGES="${MESSAGES}${GREEN}[SPEAR]     Rust (cargo test): passed${RESET}\n"
            [ -n "$SUMMARY" ] && MESSAGES="${MESSAGES}${GREEN}[SPEAR]       ${SUMMARY}${RESET}\n"
        else
            FAILURES=$((FAILURES + 1))
            SUMMARY=$(extract_test_summary "$TEST_OUT" "cargo")
            MESSAGES="${MESSAGES}${RED}[SPEAR]     Rust (cargo test): FAILED${RESET}\n"
            [ -n "$SUMMARY" ] && MESSAGES="${MESSAGES}${RED}[SPEAR]       ${SUMMARY}${RESET}\n"
            # Show failing test names
            FAILING=$(echo "$TEST_OUT" | grep -E '^\s*---\s+.*FAILED' | head -5)
            if [ -n "$FAILING" ]; then
                while IFS= read -r line; do
                    [ -n "$line" ] && MESSAGES="${MESSAGES}${RED}[SPEAR]       ${line}${RESET}\n"
                done <<< "$FAILING"
            fi
        fi
    else
        MESSAGES="${MESSAGES}${YELLOW}[SPEAR]     Rust: cargo not found — skipped${RESET}\n"
    fi
fi

# ---------------------------------------------------------------------------
# Node: npm test / jest / vitest
# ---------------------------------------------------------------------------
if [ "$HAS_NODE" -eq 1 ]; then
    NODE_TEST_RAN=0

    # Check for vitest
    if [ -f "${PROJECT_ROOT}/node_modules/.bin/vitest" ]; then
        RAN_ANY=1
        NODE_TEST_RAN=1
        TEST_OUT=""
        if TEST_OUT=$(cd "$PROJECT_ROOT" && npx vitest run 2>&1); then
            SUMMARY=$(extract_test_summary "$TEST_OUT" "vitest")
            MESSAGES="${MESSAGES}${GREEN}[SPEAR]     Node (vitest): passed${RESET}\n"
            [ -n "$SUMMARY" ] && MESSAGES="${MESSAGES}${GREEN}[SPEAR]       ${SUMMARY}${RESET}\n"
        else
            FAILURES=$((FAILURES + 1))
            SUMMARY=$(extract_test_summary "$TEST_OUT" "vitest")
            MESSAGES="${MESSAGES}${RED}[SPEAR]     Node (vitest): FAILED${RESET}\n"
            [ -n "$SUMMARY" ] && MESSAGES="${MESSAGES}${RED}[SPEAR]       ${SUMMARY}${RESET}\n"
        fi
    fi

    # Check for jest (only if vitest didn't run)
    if [ "$NODE_TEST_RAN" -eq 0 ] && [ -f "${PROJECT_ROOT}/node_modules/.bin/jest" ]; then
        RAN_ANY=1
        NODE_TEST_RAN=1
        TEST_OUT=""
        if TEST_OUT=$(cd "$PROJECT_ROOT" && npx jest --passWithNoTests 2>&1); then
            SUMMARY=$(extract_test_summary "$TEST_OUT" "jest")
            MESSAGES="${MESSAGES}${GREEN}[SPEAR]     Node (jest): passed${RESET}\n"
            [ -n "$SUMMARY" ] && MESSAGES="${MESSAGES}${GREEN}[SPEAR]       ${SUMMARY}${RESET}\n"
        else
            FAILURES=$((FAILURES + 1))
            SUMMARY=$(extract_test_summary "$TEST_OUT" "jest")
            MESSAGES="${MESSAGES}${RED}[SPEAR]     Node (jest): FAILED${RESET}\n"
            [ -n "$SUMMARY" ] && MESSAGES="${MESSAGES}${RED}[SPEAR]       ${SUMMARY}${RESET}\n"
        fi
    fi

    # Fallback to npm test (only if nothing else ran)
    if [ "$NODE_TEST_RAN" -eq 0 ]; then
        # Check if package.json has a test script
        HAS_TEST_SCRIPT=0
        if command -v python3 >/dev/null 2>&1; then
            HAS_TEST_SCRIPT=$(python3 -c "
import json
d = json.load(open('${PROJECT_ROOT}/package.json'))
scripts = d.get('scripts', {})
t = scripts.get('test', '')
# Ignore default 'echo Error: no test specified' npm init boilerplate
if t and 'no test specified' not in t:
    print(1)
else:
    print(0)
" 2>/dev/null) || HAS_TEST_SCRIPT=0
        elif command -v node >/dev/null 2>&1; then
            HAS_TEST_SCRIPT=$(node -e "
const d = JSON.parse(require('fs').readFileSync('${PROJECT_ROOT}/package.json','utf8'));
const t = (d.scripts || {}).test || '';
console.log(t && !t.includes('no test specified') ? 1 : 0);
" 2>/dev/null) || HAS_TEST_SCRIPT=0
        elif grep -q '"test"' "${PROJECT_ROOT}/package.json" 2>/dev/null; then
            if ! grep -q 'no test specified' "${PROJECT_ROOT}/package.json" 2>/dev/null; then
                HAS_TEST_SCRIPT=1
            fi
        fi

        if [ "$HAS_TEST_SCRIPT" = "1" ]; then
            RAN_ANY=1
            TEST_OUT=""
            if TEST_OUT=$(cd "$PROJECT_ROOT" && npm test 2>&1); then
                MESSAGES="${MESSAGES}${GREEN}[SPEAR]     Node (npm test): passed${RESET}\n"
            else
                FAILURES=$((FAILURES + 1))
                MESSAGES="${MESSAGES}${RED}[SPEAR]     Node (npm test): FAILED${RESET}\n"
            fi
        else
            MESSAGES="${MESSAGES}${YELLOW}[SPEAR]     Node: no test script configured — skipped${RESET}\n"
        fi
    fi
fi

# ---------------------------------------------------------------------------
# Python: pytest / unittest
# ---------------------------------------------------------------------------
if [ "$HAS_PYTHON" -eq 1 ]; then
    PYTHON_TEST_RAN=0

    # Check for pytest
    if command -v pytest >/dev/null 2>&1; then
        RAN_ANY=1
        PYTHON_TEST_RAN=1
        TEST_OUT=""
        if TEST_OUT=$(cd "$PROJECT_ROOT" && pytest --tb=short -q 2>&1); then
            SUMMARY=$(extract_test_summary "$TEST_OUT" "pytest")
            MESSAGES="${MESSAGES}${GREEN}[SPEAR]     Python (pytest): passed${RESET}\n"
            [ -n "$SUMMARY" ] && MESSAGES="${MESSAGES}${GREEN}[SPEAR]       ${SUMMARY}${RESET}\n"
        else
            EXIT_CODE=$?
            # pytest exit code 5 = no tests collected (not a failure)
            if [ "$EXIT_CODE" -eq 5 ]; then
                MESSAGES="${MESSAGES}${YELLOW}[SPEAR]     Python (pytest): no tests found — skipped${RESET}\n"
            else
                FAILURES=$((FAILURES + 1))
                SUMMARY=$(extract_test_summary "$TEST_OUT" "pytest")
                MESSAGES="${MESSAGES}${RED}[SPEAR]     Python (pytest): FAILED${RESET}\n"
                [ -n "$SUMMARY" ] && MESSAGES="${MESSAGES}${RED}[SPEAR]       ${SUMMARY}${RESET}\n"
                # Show failing test lines
                FAILING=$(echo "$TEST_OUT" | grep -E '^FAILED' | head -5)
                if [ -n "$FAILING" ]; then
                    while IFS= read -r line; do
                        [ -n "$line" ] && MESSAGES="${MESSAGES}${RED}[SPEAR]       ${line}${RESET}\n"
                    done <<< "$FAILING"
                fi
            fi
        fi
    fi

    # Fallback to unittest discover
    if [ "$PYTHON_TEST_RAN" -eq 0 ]; then
        if command -v python3 >/dev/null 2>&1; then
            # Check if there are test files
            if find "$PROJECT_ROOT" -name "test_*.py" -o -name "*_test.py" 2>/dev/null | head -1 | grep -q .; then
                RAN_ANY=1
                TEST_OUT=""
                if TEST_OUT=$(cd "$PROJECT_ROOT" && python3 -m unittest discover -s . -p "test_*.py" 2>&1); then
                    MESSAGES="${MESSAGES}${GREEN}[SPEAR]     Python (unittest): passed${RESET}\n"
                else
                    FAILURES=$((FAILURES + 1))
                    MESSAGES="${MESSAGES}${RED}[SPEAR]     Python (unittest): FAILED${RESET}\n"
                fi
            else
                MESSAGES="${MESSAGES}${YELLOW}[SPEAR]     Python: no test files found — skipped${RESET}\n"
            fi
        else
            MESSAGES="${MESSAGES}${YELLOW}[SPEAR]     Python: python3 not found — skipped${RESET}\n"
        fi
    fi
fi

# ---------------------------------------------------------------------------
# Go: go test
# ---------------------------------------------------------------------------
if [ "$HAS_GO" -eq 1 ]; then
    if command -v go >/dev/null 2>&1; then
        RAN_ANY=1
        TEST_OUT=""
        if TEST_OUT=$(cd "$PROJECT_ROOT" && go test ./... 2>&1); then
            SUMMARY=$(extract_test_summary "$TEST_OUT" "go")
            MESSAGES="${MESSAGES}${GREEN}[SPEAR]     Go (go test): passed${RESET}\n"
            [ -n "$SUMMARY" ] && MESSAGES="${MESSAGES}${GREEN}[SPEAR]       ${SUMMARY}${RESET}\n"
        else
            # go test exits 1 on failure
            # Check if it's "no test files" (not a failure)
            if echo "$TEST_OUT" | grep -q 'no test files'; then
                NO_TEST_COUNT=$(echo "$TEST_OUT" | grep -c 'no test files' || true)
                TOTAL_COUNT=$(echo "$TEST_OUT" | wc -l | tr -d ' ')
                if [ "$NO_TEST_COUNT" -eq "$TOTAL_COUNT" ]; then
                    MESSAGES="${MESSAGES}${YELLOW}[SPEAR]     Go: no test files found — skipped${RESET}\n"
                else
                    FAILURES=$((FAILURES + 1))
                    SUMMARY=$(extract_test_summary "$TEST_OUT" "go")
                    MESSAGES="${MESSAGES}${RED}[SPEAR]     Go (go test): FAILED${RESET}\n"
                    [ -n "$SUMMARY" ] && MESSAGES="${MESSAGES}${RED}[SPEAR]       ${SUMMARY}${RESET}\n"
                fi
            else
                FAILURES=$((FAILURES + 1))
                SUMMARY=$(extract_test_summary "$TEST_OUT" "go")
                MESSAGES="${MESSAGES}${RED}[SPEAR]     Go (go test): FAILED${RESET}\n"
                [ -n "$SUMMARY" ] && MESSAGES="${MESSAGES}${RED}[SPEAR]       ${SUMMARY}${RESET}\n"
                # Show first few FAIL lines
                FAILING=$(echo "$TEST_OUT" | grep -E '^---\s+FAIL' | head -5)
                if [ -n "$FAILING" ]; then
                    while IFS= read -r line; do
                        [ -n "$line" ] && MESSAGES="${MESSAGES}${RED}[SPEAR]       ${line}${RESET}\n"
                    done <<< "$FAILING"
                fi
            fi
        fi
    else
        MESSAGES="${MESSAGES}${YELLOW}[SPEAR]     Go: go not found — skipped${RESET}\n"
    fi
fi

# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------
if [ "$FAILURES" -gt 0 ]; then
    printf "${RED}${BOLD}[SPEAR] %-20s FAIL %s (test failures detected)${RESET}\n" "${CHECKER_NAME}:" "✗"
    printf "$MESSAGES"
    exit 1
elif [ "$RAN_ANY" -eq 0 ]; then
    printf "${YELLOW}[SPEAR] %-20s SKIP %s (no test frameworks available)${RESET}\n" "${CHECKER_NAME}:" "⊘"
    printf "$MESSAGES"
    exit 0
else
    printf "${GREEN}[SPEAR] %-20s PASS %s${RESET}\n" "${CHECKER_NAME}:" "✓"
    printf "$MESSAGES"
    exit 0
fi
