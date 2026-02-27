#!/usr/bin/env bash
# =============================================================================
# SPEAR Framework — doc-coverage checker
# =============================================================================
# Checks that public API items have documentation comments.
# Supports Rust (/// or //!), JS/TS (JSDoc), and Python (docstrings).
# Compares coverage percentage to ratchet threshold (default 80%).
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

NL=$'\n'
CHECKER_NAME="doc-coverage"
PROJECT_ROOT="${1:-.}"

RATCHET="${PROJECT_ROOT}/.spear/ratchet/ratchet.json"
DEFAULT_THRESHOLD=60

# ---------------------------------------------------------------------------
# Get staged files
# ---------------------------------------------------------------------------
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null) || STAGED_FILES=""

if [ -z "$STAGED_FILES" ]; then
    printf "${GREEN}[SPEAR] %-20s PASS %s (no staged files)${RESET}\n" "${CHECKER_NAME}:" "✓"
    exit 0
fi

# ---------------------------------------------------------------------------
# Read threshold from ratchet
# ---------------------------------------------------------------------------
THRESHOLD="$DEFAULT_THRESHOLD"

read_ratchet_threshold() {
    local name="doc_coverage"
    local rfile="$1"

    [ ! -f "$rfile" ] && return 1

    if command -v python3 >/dev/null 2>&1; then
        SPEAR_RATCHET_FILE="$rfile" SPEAR_THRESHOLD_NAME="$name" python3 -c "
import json, os
data = json.load(open(os.environ['SPEAR_RATCHET_FILE']))
entry = data.get(os.environ['SPEAR_THRESHOLD_NAME'], {})
if isinstance(entry, dict) and 'value' in entry:
    print(entry['value'])
" 2>/dev/null && return 0
    fi

    if command -v node >/dev/null 2>&1; then
        SPEAR_RATCHET_FILE="$rfile" SPEAR_THRESHOLD_NAME="$name" node -e "
const d = JSON.parse(require('fs').readFileSync(process.env.SPEAR_RATCHET_FILE,'utf8'));
const e = d[process.env.SPEAR_THRESHOLD_NAME];
if (e && typeof e === 'object' && 'value' in e) console.log(e.value);
" 2>/dev/null && return 0
    fi

    if command -v jq >/dev/null 2>&1; then
        jq -r ".[\"$name\"].value // empty" "$rfile" 2>/dev/null && return 0
    fi

    return 1
}

RATCHET_VAL=$(read_ratchet_threshold "$RATCHET" 2>/dev/null) || true
if [ -n "$RATCHET_VAL" ] && echo "$RATCHET_VAL" | grep -Eq '^[0-9]+\.?[0-9]*$'; then
    THRESHOLD="$RATCHET_VAL"
fi

# ---------------------------------------------------------------------------
# Counters
# ---------------------------------------------------------------------------
TOTAL_PUBLIC=0
TOTAL_DOCUMENTED=0
UNDOCUMENTED_ITEMS=""

# ---------------------------------------------------------------------------
# Rust doc coverage
# ---------------------------------------------------------------------------
check_rust_docs() {
    local file="$1"
    [ ! -f "$file" ] && return

    # Get staged content
    local content
    content=$(git show ":${file}" 2>/dev/null) || return

    local line_num=0
    local prev_line=""
    local prev_prev_line=""

    while IFS= read -r line; do
        line_num=$((line_num + 1))

        # Check for public items: pub fn, pub struct, pub enum, pub trait, pub type, pub const, pub static
        if echo "$line" | grep -Eq '^[[:space:]]*(pub\s+(fn|struct|enum|trait|type|const|static|mod))'; then
            TOTAL_PUBLIC=$((TOTAL_PUBLIC + 1))

            # Check if preceding line(s) have doc comments (/// or //! or #[doc)
            if echo "$prev_line" | grep -Eq '^\s*(///|//!|#\[doc)'; then
                TOTAL_DOCUMENTED=$((TOTAL_DOCUMENTED + 1))
            elif echo "$prev_prev_line" | grep -Eq '^\s*(///|//!|#\[doc)'; then
                # Could have an attribute between doc and item
                TOTAL_DOCUMENTED=$((TOTAL_DOCUMENTED + 1))
            else
                ITEM_NAME=$(echo "$line" | sed -n 's/.*pub\s\+\(fn\|struct\|enum\|trait\|type\|const\|static\|mod\)\s\+\([a-zA-Z_][a-zA-Z0-9_]*\).*/\2/p')
                UNDOCUMENTED_ITEMS="${UNDOCUMENTED_ITEMS}  ${file}:${line_num} — pub ${ITEM_NAME:-item}${NL}"
            fi
        fi

        prev_prev_line="$prev_line"
        prev_line="$line"
    done <<< "$content"
}

# ---------------------------------------------------------------------------
# JS/TS doc coverage
# ---------------------------------------------------------------------------
check_js_docs() {
    local file="$1"
    [ ! -f "$file" ] && return

    local content
    content=$(git show ":${file}" 2>/dev/null) || return

    local line_num=0
    local prev_line=""
    local prev_prev_line=""
    local in_jsdoc=0

    while IFS= read -r line; do
        line_num=$((line_num + 1))

        # Track JSDoc blocks
        if echo "$line" | grep -q '/\*\*'; then
            in_jsdoc=1
        fi
        if echo "$line" | grep -q '\*/'; then
            in_jsdoc=0
        fi

        # Check for exported items: export function, export class, export interface, export type, export const, export default
        if echo "$line" | grep -Eq '^[[:space:]]*(export\s+(function|class|interface|type|const|default|async\s+function))'; then
            TOTAL_PUBLIC=$((TOTAL_PUBLIC + 1))

            # Check if preceding lines have JSDoc (/** ... */)
            if echo "$prev_line" | grep -Eq '^\s*\*/'; then
                TOTAL_DOCUMENTED=$((TOTAL_DOCUMENTED + 1))
            elif echo "$prev_line" | grep -Eq '^\s*/\*\*'; then
                TOTAL_DOCUMENTED=$((TOTAL_DOCUMENTED + 1))
            elif echo "$prev_prev_line" | grep -Eq '^\s*\*/'; then
                TOTAL_DOCUMENTED=$((TOTAL_DOCUMENTED + 1))
            else
                ITEM_NAME=$(echo "$line" | sed -n 's/.*export\s\+\(default\s\+\)\?\(async\s\+\)\?\(function\|class\|interface\|type\|const\)\s\+\([a-zA-Z_][a-zA-Z0-9_]*\).*/\4/p')
                UNDOCUMENTED_ITEMS="${UNDOCUMENTED_ITEMS}  ${file}:${line_num} — export ${ITEM_NAME:-item}${NL}"
            fi
        fi

        prev_prev_line="$prev_line"
        prev_line="$line"
    done <<< "$content"
}

# ---------------------------------------------------------------------------
# Python doc coverage
# ---------------------------------------------------------------------------
check_python_docs() {
    local file="$1"
    [ ! -f "$file" ] && return

    # Skip test files
    case "$file" in
        test_*|*_test.py|*/test_*|*/tests/*) return ;;
    esac

    local content
    content=$(git show ":${file}" 2>/dev/null) || return

    local line_num=0
    local check_next_for_docstring=0
    local item_info=""

    while IFS= read -r line; do
        line_num=$((line_num + 1))

        if [ "$check_next_for_docstring" -eq 1 ]; then
            check_next_for_docstring=0
            # Check if this line starts a docstring
            if echo "$line" | grep -Eq '^\s*("""|'"'"''"'"''"'"'|r"""|r'"'"''"'"''"'"')'; then
                TOTAL_DOCUMENTED=$((TOTAL_DOCUMENTED + 1))
            else
                UNDOCUMENTED_ITEMS="${UNDOCUMENTED_ITEMS}  ${item_info}${NL}"
            fi
        fi

        # Check for function/class definitions (not private: no leading _)
        # Match: def name(  or  class Name(  or  class Name:
        if echo "$line" | grep -Eq '^[[:space:]]*(def\s+[a-zA-Z][a-zA-Z0-9_]*|class\s+[A-Z][a-zA-Z0-9_]*)'; then
            # Skip private methods (single underscore is ok, double underscore is private)
            if echo "$line" | grep -Eq '(def\s+__[^_]|def\s+_[a-z])'; then
                continue
            fi
            TOTAL_PUBLIC=$((TOTAL_PUBLIC + 1))
            check_next_for_docstring=1
            ITEM_NAME=$(echo "$line" | sed -n 's/.*\(def\|class\)\s\+\([a-zA-Z_][a-zA-Z0-9_]*\).*/\2/p')
            item_info="${file}:${line_num} — ${ITEM_NAME:-item}"
        fi
    done <<< "$content"
}

# ---------------------------------------------------------------------------
# Process staged files
# ---------------------------------------------------------------------------
while IFS= read -r file; do
    [ -z "$file" ] && continue
    case "$file" in
        *.rs)
            check_rust_docs "$file"
            ;;
        *.js|*.jsx|*.ts|*.tsx|*.mjs)
            check_js_docs "$file"
            ;;
        *.py)
            check_python_docs "$file"
            ;;
    esac
done <<< "$STAGED_FILES"

# ---------------------------------------------------------------------------
# Calculate coverage
# ---------------------------------------------------------------------------
if [ "$TOTAL_PUBLIC" -eq 0 ]; then
    printf "${GREEN}[SPEAR] %-20s PASS %s (no public API items in staged files)${RESET}\n" "${CHECKER_NAME}:" "✓"
    exit 0
fi

# Calculate percentage using awk for floating point
COVERAGE=$(awk -v d="$TOTAL_DOCUMENTED" -v t="$TOTAL_PUBLIC" 'BEGIN { printf "%.1f", (d / t) * 100 }')
COVERAGE_INT=$(awk -v d="$TOTAL_DOCUMENTED" -v t="$TOTAL_PUBLIC" 'BEGIN { printf "%d", (d / t) * 100 }')

# ---------------------------------------------------------------------------
# Compare to threshold
# ---------------------------------------------------------------------------
PASS=$(awk -v c="$COVERAGE_INT" -v t="$THRESHOLD" 'BEGIN { print (c >= t) ? 1 : 0 }')

if [ "$PASS" -eq 1 ]; then
    printf "${GREEN}[SPEAR] %-20s PASS %s (${COVERAGE}%% documented, threshold ${THRESHOLD}%%)${RESET}\n" "${CHECKER_NAME}:" "✓"
    printf "${GREEN}[SPEAR]     ${TOTAL_DOCUMENTED}/${TOTAL_PUBLIC} public items documented${RESET}\n"
    if [ -n "$UNDOCUMENTED_ITEMS" ]; then
        printf "${YELLOW}[SPEAR]     Undocumented (non-blocking):${RESET}\n"
        printf '%s\n' "${YELLOW}[SPEAR]     ${UNDOCUMENTED_ITEMS}${RESET}"
    fi
    exit 0
else
    printf "${RED}${BOLD}[SPEAR] %-20s FAIL %s (${COVERAGE}%% documented, threshold ${THRESHOLD}%%)${RESET}\n" "${CHECKER_NAME}:" "✗"
    printf "${RED}[SPEAR]     ${TOTAL_DOCUMENTED}/${TOTAL_PUBLIC} public items documented${RESET}\n"
    if [ -n "$UNDOCUMENTED_ITEMS" ]; then
        printf "${RED}[SPEAR]     Undocumented items:${RESET}\n"
        printf '%s\n' "${RED}${UNDOCUMENTED_ITEMS}${RESET}"
    fi
    exit 1
fi
