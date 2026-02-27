#!/usr/bin/env bash
# =============================================================================
# SPEAR Framework — secrets-scan checker
# =============================================================================
# Regex-based credential detection on git-staged files.
# Exits 1 if any potential secrets are found.
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

CHECKER_NAME="secrets-scan"
PROJECT_ROOT="${1:-.}"

# ---------------------------------------------------------------------------
# Get staged files
# ---------------------------------------------------------------------------
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null) || {
    printf "${YELLOW}[SPEAR] %-20s SKIP %s (not in a git repo or no staged files)${RESET}\n" "${CHECKER_NAME}:" "⊘"
    exit 0
}

if [ -z "$STAGED_FILES" ]; then
    printf "${GREEN}[SPEAR] %-20s PASS %s (no staged files)${RESET}\n" "${CHECKER_NAME}:" "✓"
    exit 0
fi

# ---------------------------------------------------------------------------
# Filter out ignored paths
# ---------------------------------------------------------------------------
FILTERED_FILES=""
while IFS= read -r file; do
    [ -z "$file" ] && continue

    # Skip .spear/ templates and config
    case "$file" in
        .spear/*) continue ;;
    esac

    # Skip test fixtures
    case "$file" in
        */test/fixtures/*|*/tests/fixtures/*|*/__fixtures__/*|*/testdata/*) continue ;;
    esac

    # Skip markdown files
    case "$file" in
        *.md|*.MD|*.markdown) continue ;;
    esac

    # Skip binary files (images, fonts, etc.)
    case "$file" in
        *.png|*.jpg|*.jpeg|*.gif|*.ico|*.woff|*.woff2|*.ttf|*.eot|*.svg|*.pdf|*.zip|*.tar|*.gz) continue ;;
    esac

    # Skip lock files
    case "$file" in
        *.lock|package-lock.json|yarn.lock|Cargo.lock|Gemfile.lock|poetry.lock) continue ;;
    esac

    FILTERED_FILES="${FILTERED_FILES}${file}
"
done <<< "$STAGED_FILES"

if [ -z "$(echo "$FILTERED_FILES" | tr -d '[:space:]')" ]; then
    printf "${GREEN}[SPEAR] %-20s PASS %s (no scannable files staged)${RESET}\n" "${CHECKER_NAME}:" "✓"
    exit 0
fi

# ---------------------------------------------------------------------------
# Secret patterns
# ---------------------------------------------------------------------------
# Each pattern is: label|regex
# We use grep -nEi on staged file contents.
# ---------------------------------------------------------------------------
PATTERNS=(
    "AWS Access Key|AKIA[0-9A-Z]{16}"
    "AWS Secret Key|aws_secret_access_key[[:space:]]*[=:][[:space:]]*['\"]?[A-Za-z0-9/+=]{40}"
    "Generic API Key|['\"]?api[_-]?key['\"]?[[:space:]]*[=:][[:space:]]*['\"][a-zA-Z0-9]"
    "Private Key Block|BEGIN[[:space:]]+(RSA|DSA|EC|OPENSSH|PGP)[[:space:]]+PRIVATE[[:space:]]+KEY"
    "Password in Config|['\"]?password['\"]?[[:space:]]*[=:][[:space:]]*['\"][^'\"]{4,}"
    "Token Assignment|['\"]?token['\"]?[[:space:]]*[=:][[:space:]]*['\"][a-zA-Z0-9_.-]{10,}"
    "Generic Secret|['\"]?secret['\"]?[[:space:]]*[=:][[:space:]]*['\"][a-zA-Z0-9_.-]{8,}"
    "JWT Token|eyJ[a-zA-Z0-9_-]{10,}\\.eyJ[a-zA-Z0-9_-]{10,}\\.[a-zA-Z0-9_-]{10,}"
    "Connection String Password|://[^:]+:[^@]{4,}@[a-zA-Z0-9]"
    "GitHub Token|gh[pousr]_[A-Za-z0-9_]{36,}"
    "Slack Token|xox[bpras]-[0-9a-zA-Z-]{10,}"
    "Stripe Key|sk_live_[0-9a-zA-Z]{24,}"
    "Env File Contents|^[A-Z_]{3,}=['\"]?[a-zA-Z0-9_/+=.-]{20,}"
    "Heroku API Key|[hH][eE][rR][oO][kK][uU].*[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}"
)

# ---------------------------------------------------------------------------
# Scan staged files
# ---------------------------------------------------------------------------
FOUND_SECRETS=0
FINDINGS=""

while IFS= read -r file; do
    [ -z "$file" ] && continue
    [ ! -f "$file" ] && continue

    # Get the staged content (what will actually be committed)
    CONTENT=$(git show ":${file}" 2>/dev/null) || continue

    for pattern_entry in "${PATTERNS[@]}"; do
        LABEL="${pattern_entry%%|*}"
        REGEX="${pattern_entry#*|}"

        # Search for pattern, collect matches
        MATCHES=$(echo "$CONTENT" | grep -nEi "$REGEX" 2>/dev/null) || continue

        while IFS= read -r match_line; do
            [ -z "$match_line" ] && continue
            LINE_NUM="${match_line%%:*}"
            FOUND_SECRETS=$((FOUND_SECRETS + 1))
            FINDINGS="${FINDINGS}${RED}[SPEAR]   ${file}:${LINE_NUM} — ${LABEL}${RESET}\n"
        done <<< "$MATCHES"
    done
done <<< "$FILTERED_FILES"

# ---------------------------------------------------------------------------
# Also flag any .env files being committed
# ---------------------------------------------------------------------------
while IFS= read -r file; do
    [ -z "$file" ] && continue
    case "$file" in
        .env|.env.*|*.env)
            FOUND_SECRETS=$((FOUND_SECRETS + 1))
            FINDINGS="${FINDINGS}${RED}[SPEAR]   ${file} — .env file should not be committed${RESET}\n"
            ;;
    esac
done <<< "$STAGED_FILES"

# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------
if [ "$FOUND_SECRETS" -gt 0 ]; then
    printf "${RED}${BOLD}[SPEAR] %-20s FAIL %s (%d potential secret(s) found)${RESET}\n" "${CHECKER_NAME}:" "✗" "$FOUND_SECRETS"
    printf "$FINDINGS"
    printf "\n${YELLOW}[SPEAR]   Add false positives to .spear/secrets-allowlist or use .gitignore.${RESET}\n"
    exit 1
else
    printf "${GREEN}[SPEAR] %-20s PASS %s${RESET}\n" "${CHECKER_NAME}:" "✓"
    exit 0
fi
