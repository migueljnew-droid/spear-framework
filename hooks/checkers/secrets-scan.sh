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

NL=$'\n'
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
    "Anthropic API Key|sk-ant-[a-zA-Z0-9_-]{20,}"
    "OpenAI Project Key|sk-proj-[a-zA-Z0-9_-]{20,}"
    "HuggingFace Token|hf_[a-zA-Z0-9]{20,}"
    "npm Token|npm_[a-zA-Z0-9]{20,}"
)

# ---------------------------------------------------------------------------
# Load secrets allowlist (fix #8)
# ---------------------------------------------------------------------------
ALLOWLIST_FILE="${PROJECT_ROOT}/.spear/secrets-allowlist"
ALLOWLIST=()
if [ -f "$ALLOWLIST_FILE" ]; then
    while IFS= read -r line; do
        [[ -z "$line" || "$line" == \#* ]] && continue
        ALLOWLIST+=("$line")
    done < "$ALLOWLIST_FILE"
fi

# Helper: check if a matched line is in the allowlist
is_allowlisted() {
    local match_text="$1"
    for allowed in "${ALLOWLIST[@]+"${ALLOWLIST[@]}"}"; do
        if [[ "$match_text" == *"$allowed"* ]]; then
            return 0
        fi
    done
    return 1
}

# ---------------------------------------------------------------------------
# Build combined regex + label lookup (fix #9: single grep per file)
# ---------------------------------------------------------------------------
# Combine all regex patterns into one alternation for a single grep call,
# then look up which label matched for reporting.
COMBINED_REGEX=""
declare -a REGEX_LIST=()
declare -a LABEL_LIST=()
for pattern_entry in "${PATTERNS[@]}"; do
    LABEL_LIST+=("${pattern_entry%%|*}")
    REGEX_LIST+=("${pattern_entry#*|}")
    if [ -z "$COMBINED_REGEX" ]; then
        COMBINED_REGEX="${pattern_entry#*|}"
    else
        COMBINED_REGEX="${COMBINED_REGEX}|${pattern_entry#*|}"
    fi
done

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

    # Single combined grep per file (fix #9: performance)
    MATCHES=$(echo "$CONTENT" | grep -nEi "$COMBINED_REGEX" 2>/dev/null) || continue

    while IFS= read -r match_line; do
        [ -z "$match_line" ] && continue
        LINE_NUM="${match_line%%:*}"
        MATCH_TEXT="${match_line#*:}"

        # Check allowlist (fix #8)
        if is_allowlisted "$MATCH_TEXT"; then
            continue
        fi

        # Determine which pattern matched for the label
        MATCHED_LABEL="Unknown Secret"
        for i in "${!REGEX_LIST[@]}"; do
            if echo "$MATCH_TEXT" | grep -Eiq "${REGEX_LIST[$i]}" 2>/dev/null; then
                MATCHED_LABEL="${LABEL_LIST[$i]}"
                break
            fi
        done

        FOUND_SECRETS=$((FOUND_SECRETS + 1))
        FINDINGS="${FINDINGS}${RED}[SPEAR]   ${file}:${LINE_NUM} — ${MATCHED_LABEL}${RESET}${NL}"
    done <<< "$MATCHES"
done <<< "$FILTERED_FILES"

# ---------------------------------------------------------------------------
# Also flag .env files being committed (fix #10: distinguish .env from
# .env.example/.env.template — only block actual secret files)
# ---------------------------------------------------------------------------
while IFS= read -r file; do
    [ -z "$file" ] && continue
    case "$file" in
        .env.example|.env.template|.env.sample|.env.*.example|.env.*.template|.env.*.sample)
            # These are safe template files — scan for patterns (already done above)
            # but do not block on filename alone
            ;;
        .env|.env.*|*.env)
            FOUND_SECRETS=$((FOUND_SECRETS + 1))
            FINDINGS="${FINDINGS}${RED}[SPEAR]   ${file} — .env file should not be committed${RESET}${NL}"
            ;;
    esac
done <<< "$STAGED_FILES"

# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------
if [ "$FOUND_SECRETS" -gt 0 ]; then
    printf "${RED}${BOLD}[SPEAR] %-20s FAIL %s (%d potential secret(s) found)${RESET}\n" "${CHECKER_NAME}:" "✗" "$FOUND_SECRETS"
    printf '%s' "$FINDINGS"
    printf "\n${YELLOW}[SPEAR]   Add false positives to .spear/secrets-allowlist or use .gitignore.${RESET}\n"
    exit 1
else
    printf "${GREEN}[SPEAR] %-20s PASS %s${RESET}\n" "${CHECKER_NAME}:" "✓"
    exit 0
fi
