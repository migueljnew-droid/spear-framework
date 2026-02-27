#!/usr/bin/env bash
# =============================================================================
# SPEAR Framework — fitness-check checker
# =============================================================================
# Runs fitness functions registered in .spear/fitness/registry.json and
# compares their output to thresholds from .spear/ratchet/ratchet.json.
#
# Registry format:
# {
#   "functions": [
#     {
#       "name": "test-coverage",
#       "script": ".spear/fitness/scripts/test-coverage.sh",
#       "metric": "coverage_pct",
#       "enabled": true
#     }
#   ]
# }
#
# Ratchet format:
# {
#   "test-coverage": { "value": 80, "direction": "floor" },
#   "bundle-size":   { "value": 500, "direction": "ceiling" }
# }
#
# Each fitness script must print a single numeric value to stdout.
# Direction "floor"   => measured value must be >= threshold
# Direction "ceiling"  => measured value must be <= threshold
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
CHECKER_NAME="fitness-check"
PROJECT_ROOT="${1:-.}"

REGISTRY="${PROJECT_ROOT}/.spear/fitness/registry.json"
RATCHET="${PROJECT_ROOT}/.spear/ratchet/ratchet.json"

# ---------------------------------------------------------------------------
# Check for registry
# ---------------------------------------------------------------------------
if [ ! -f "$REGISTRY" ]; then
    printf "${YELLOW}[SPEAR] %-20s SKIP %s (no fitness registry found)${RESET}${NL}" "${CHECKER_NAME}:" "⊘"
    exit 0
fi

# ---------------------------------------------------------------------------
# JSON parser helper — extract fitness functions from registry
# Returns lines of: name|script|active
# ---------------------------------------------------------------------------
parse_registry() {
    local file="$1"

    if command -v python3 >/dev/null 2>&1; then
        SPEAR_PARSE_FILE="$file" python3 -c "
import json, sys, os
try:
    data = json.load(open(os.environ['SPEAR_PARSE_FILE']))
    for fn in data.get('functions', []):
        name = fn.get('name', '')
        script = fn.get('script', '')
        active = 'true' if fn.get('enabled', True) else 'false'
        if name and script:
            print(f'{name}|{script}|{active}')
except Exception as e:
    print(f'ERROR|{e}|false', file=sys.stderr)
    sys.exit(1)
" 2>/dev/null && return 0
    fi

    if command -v node >/dev/null 2>&1; then
        SPEAR_PARSE_FILE="$file" node -e "
try {
    const d = JSON.parse(require('fs').readFileSync(process.env.SPEAR_PARSE_FILE,'utf8'));
    for (const fn of (d.functions || [])) {
        const name = fn.name || '';
        const script = fn.script || '';
        const active = fn.enabled !== false ? 'true' : 'false';
        if (name && script) console.log(name + '|' + script + '|' + active);
    }
} catch(e) { process.exit(1); }
" 2>/dev/null && return 0
    fi

    if command -v jq >/dev/null 2>&1; then
        jq -r '.functions[]? | [.name // "", .script // "", if .enabled == false then "false" else "true" end] | join("|")' "$file" 2>/dev/null && return 0
    fi

    printf "${YELLOW}[SPEAR] %-20s SKIP %s (no JSON parser: need python3, node, or jq)${RESET}${NL}" "${CHECKER_NAME}:" "⊘"
    exit 0
}

# ---------------------------------------------------------------------------
# Ratchet threshold reader — get threshold for a fitness function name
# Returns: value|direction
# ---------------------------------------------------------------------------
get_threshold() {
    local name="$1"
    local rfile="$2"

    if [ ! -f "$rfile" ]; then
        echo ""
        return 0
    fi

    if command -v python3 >/dev/null 2>&1; then
        SPEAR_RATCHET_FILE="$rfile" SPEAR_THRESHOLD_NAME="$name" python3 -c "
import json, os
data = json.load(open(os.environ['SPEAR_RATCHET_FILE']))
entry = data.get(os.environ['SPEAR_THRESHOLD_NAME'], {})
if isinstance(entry, dict) and 'value' in entry:
    print(str(entry['value']) + '|' + entry.get('direction', 'floor'))
" 2>/dev/null && return 0
    fi

    if command -v node >/dev/null 2>&1; then
        SPEAR_RATCHET_FILE="$rfile" SPEAR_THRESHOLD_NAME="$name" node -e "
const d = JSON.parse(require('fs').readFileSync(process.env.SPEAR_RATCHET_FILE,'utf8'));
const e = d[process.env.SPEAR_THRESHOLD_NAME];
if (e && typeof e === 'object' && 'value' in e) {
    console.log(e.value + '|' + (e.direction || 'floor'));
}
" 2>/dev/null && return 0
    fi

    if command -v jq >/dev/null 2>&1; then
        jq -r ".[\"$name\"] // empty | [.value, .direction // \"floor\"] | join(\"|\")" "$rfile" 2>/dev/null && return 0
    fi

    echo ""
}

# ---------------------------------------------------------------------------
# Run fitness functions
# ---------------------------------------------------------------------------
FUNCTIONS=$(parse_registry "$REGISTRY")

if [ -z "$FUNCTIONS" ]; then
    printf "${YELLOW}[SPEAR] %-20s SKIP %s (no fitness functions defined)${RESET}${NL}" "${CHECKER_NAME}:" "⊘"
    exit 0
fi

TOTAL=0
PASSED=0
FAILED=0
SKIPPED=0
MESSAGES=""

while IFS='|' read -r fname fscript factive; do
    [ -z "$fname" ] && continue

    # Skip inactive functions
    if [ "$factive" = "false" ]; then
        SKIPPED=$((SKIPPED + 1))
        MESSAGES="${MESSAGES}${YELLOW}[SPEAR]     ${fname}: skipped (inactive)${RESET}${NL}"
        continue
    fi

    TOTAL=$((TOTAL + 1))
    SCRIPT_PATH="${PROJECT_ROOT}/${fscript}"

    # Check script exists
    if [ ! -f "$SCRIPT_PATH" ]; then
        FAILED=$((FAILED + 1))
        MESSAGES="${MESSAGES}${RED}[SPEAR]     ${fname}: FAIL — script not found (${fscript})${RESET}${NL}"
        continue
    fi

    # Run the fitness function, capture numeric output
    MEASURED=""
    if [ -x "$SCRIPT_PATH" ]; then
        MEASURED=$("$SCRIPT_PATH" 2>/dev/null | tail -1 | tr -d '[:space:]') || true
    else
        MEASURED=$(bash "$SCRIPT_PATH" 2>/dev/null | tail -1 | tr -d '[:space:]') || true
    fi

    # Validate numeric output
    if [ -z "$MEASURED" ] || ! echo "$MEASURED" | grep -Eq '^-?[0-9]+\.?[0-9]*$'; then
        FAILED=$((FAILED + 1))
        MESSAGES="${MESSAGES}${RED}[SPEAR]     ${fname}: FAIL — non-numeric output '${MEASURED}'${RESET}${NL}"
        continue
    fi

    # Get threshold from ratchet
    THRESHOLD_RAW=$(get_threshold "$fname" "$RATCHET")

    if [ -z "$THRESHOLD_RAW" ]; then
        # No threshold defined — just report the value as passed
        PASSED=$((PASSED + 1))
        MESSAGES="${MESSAGES}${GREEN}[SPEAR]     ${fname}: ${MEASURED} (no threshold — pass)${RESET}${NL}"
        continue
    fi

    THRESHOLD_VALUE="${THRESHOLD_RAW%%|*}"
    DIRECTION="${THRESHOLD_RAW#*|}"

    # Compare using awk for floating point (use -v to avoid code injection)
    case "$DIRECTION" in
        floor)
            # measured >= threshold
            PASS=$(awk -v m="$MEASURED" -v t="$THRESHOLD_VALUE" 'BEGIN { print (m >= t) ? 1 : 0 }')
            OP=">="
            ;;
        ceiling)
            # measured <= threshold
            PASS=$(awk -v m="$MEASURED" -v t="$THRESHOLD_VALUE" 'BEGIN { print (m <= t) ? 1 : 0 }')
            OP="<="
            ;;
        *)
            # Default to floor
            PASS=$(awk -v m="$MEASURED" -v t="$THRESHOLD_VALUE" 'BEGIN { print (m >= t) ? 1 : 0 }')
            OP=">="
            ;;
    esac

    if [ "$PASS" -eq 1 ]; then
        PASSED=$((PASSED + 1))
        MESSAGES="${MESSAGES}${GREEN}[SPEAR]     ${fname}: ${MEASURED} ${OP} ${THRESHOLD_VALUE} (${DIRECTION}) — pass${RESET}${NL}"
    else
        FAILED=$((FAILED + 1))
        MESSAGES="${MESSAGES}${RED}[SPEAR]     ${fname}: ${MEASURED} ${OP} ${THRESHOLD_VALUE} (${DIRECTION}) — FAIL${RESET}${NL}"
    fi

done <<< "$FUNCTIONS"

# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------
if [ "$TOTAL" -eq 0 ]; then
    printf "${YELLOW}[SPEAR] %-20s SKIP %s (all fitness functions inactive)${RESET}${NL}" "${CHECKER_NAME}:" "⊘"
    exit 0
fi

if [ "$FAILED" -gt 0 ]; then
    printf "${RED}${BOLD}[SPEAR] %-20s FAIL %s (%d/%d passed, %d failed)${RESET}${NL}" "${CHECKER_NAME}:" "✗" "$PASSED" "$TOTAL" "$FAILED"
    printf '%s' "$MESSAGES"
    exit 1
else
    printf "${GREEN}[SPEAR] %-20s PASS %s (%d/%d passed)${RESET}${NL}" "${CHECKER_NAME}:" "✓" "$PASSED" "$TOTAL"
    printf '%s' "$MESSAGES"
    exit 0
fi
