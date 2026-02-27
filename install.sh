#!/usr/bin/env bash
# SPEAR Framework Installer
# Usage: curl -fsSL https://raw.githubusercontent.com/migueljnew-droid/spear-framework/main/install.sh | sh
# Or:    ./install.sh [--adapter=claude-code|cursor|copilot|antigravity|kiro|generic]
#
# Idempotent — safe to re-run.

set -euo pipefail

# ─── Colors ───────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()  { printf "${CYAN}[SPEAR]${NC} %s\n" "$1"; }
ok()    { printf "${GREEN}[SPEAR]${NC} %s\n" "$1"; }
warn()  { printf "${YELLOW}[SPEAR]${NC} %s\n" "$1"; }
fail()  { printf "${RED}[SPEAR]${NC} %s\n" "$1"; exit 1; }

# ─── Parse Args ───────────────────────────────────────────
ADAPTER="auto"
for arg in "$@"; do
  case "$arg" in
    --adapter=*) ADAPTER="${arg#*=}" ;;
    --help|-h)
      echo "SPEAR Framework Installer"
      echo ""
      echo "Usage: ./install.sh [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --adapter=NAME   Set AI tool adapter (claude-code, cursor, copilot, antigravity, kiro, generic)"
      echo "                   Default: auto-detect"
      echo "  --help, -h       Show this help"
      exit 0
      ;;
  esac
done

# Validate adapter value
case "$ADAPTER" in
  auto|claude-code|cursor|copilot|antigravity|kiro|generic) ;;
  *) fail "Invalid adapter: $ADAPTER. Valid: claude-code, cursor, copilot, antigravity, kiro, generic" ;;
esac

# ─── Preflight ────────────────────────────────────────────
info "SPEAR Framework Installer v1.0.0"
echo ""

# Check git root
GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || fail "Not a git repository. Run 'git init' first."
info "Git root: $GIT_ROOT"
cd "$GIT_ROOT"

# Check if .spear already exists
if [ -d ".spear" ]; then
  warn ".spear/ already exists — updating (idempotent)"
fi

# ─── Detect Language ──────────────────────────────────────
LANGUAGE="unknown"
if [ -f "Cargo.toml" ]; then
  LANGUAGE="rust"
elif [ -f "package.json" ]; then
  if grep -q '"typescript"' package.json 2>/dev/null || [ -f "tsconfig.json" ]; then
    LANGUAGE="typescript"
  else
    LANGUAGE="javascript"
  fi
elif [ -f "pyproject.toml" ] || [ -f "requirements.txt" ] || [ -f "setup.py" ]; then
  LANGUAGE="python"
elif [ -f "go.mod" ]; then
  LANGUAGE="go"
elif [ -f "Gemfile" ]; then
  LANGUAGE="ruby"
elif [ -f "pom.xml" ] || [ -f "build.gradle" ]; then
  LANGUAGE="java"
fi
info "Detected language: $LANGUAGE"

# ─── Detect AI Tool ───────────────────────────────────────
if [ "$ADAPTER" = "auto" ]; then
  if [ -f "CLAUDE.md" ] || [ -f ".claude/settings.json" ]; then
    ADAPTER="claude-code"
  elif [ -f ".cursorrules" ] || [ -f ".cursor/rules" ]; then
    ADAPTER="cursor"
  elif [ -f ".github/copilot-instructions.md" ]; then
    ADAPTER="copilot"
  elif [ -d ".antigravity" ]; then
    ADAPTER="antigravity"
  elif [ -d ".kiro" ]; then
    ADAPTER="kiro"
  else
    ADAPTER="generic"
  fi
fi
info "AI tool adapter: $ADAPTER"

# ─── Download or Copy Framework ──────────────────────────
SPEAR_SOURCE=""

# Check if we're running from the cloned repo
if [ -f ".spear/SPEAR.md" ] && [ -d "adapters" ]; then
  SPEAR_SOURCE="local"
  info "Running from SPEAR repo — using local files"
else
  # Download from GitHub
  SPEAR_SOURCE="remote"
  SPEAR_TMPDIR=$(mktemp -d)
  trap 'rm -rf "$SPEAR_TMPDIR"' EXIT

  info "Downloading SPEAR framework..."
  if command -v curl &>/dev/null; then
    curl --proto '=https' --tlsv1.2 -fsSL "https://github.com/migueljnew-droid/spear-framework/archive/refs/heads/main.tar.gz" -o "$SPEAR_TMPDIR/spear.tar.gz"
  elif command -v wget &>/dev/null; then
    wget -q "https://github.com/migueljnew-droid/spear-framework/archive/refs/heads/main.tar.gz" -O "$SPEAR_TMPDIR/spear.tar.gz"
  else
    fail "Neither curl nor wget found. Install one and retry."
  fi

  tar -xzf "$SPEAR_TMPDIR/spear.tar.gz" -C "$SPEAR_TMPDIR"
  SPEAR_REPO="$SPEAR_TMPDIR/spear-framework-main"

  if [ ! -d "$SPEAR_REPO/.spear" ]; then
    fail "Download failed — .spear/ not found in archive"
  fi
fi

# ─── Install .spear/ Directory ────────────────────────────
info "Installing .spear/ directory..."

if [ "$SPEAR_SOURCE" = "local" ]; then
  # Already in place
  ok ".spear/ already present"
else
  # Copy .spear/ to project root
  cp -r "$SPEAR_REPO/.spear/." .spear/
  ok ".spear/ installed"
fi

# Update config with detected language (use env vars to avoid shell injection)
if command -v python3 &>/dev/null; then
  SPEAR_LANGUAGE="$LANGUAGE" SPEAR_ADAPTER="$ADAPTER" python3 -c "
import json, os
with open('.spear/config.json', 'r') as f:
    config = json.load(f)
config['project']['language'] = os.environ['SPEAR_LANGUAGE']
config['adapter'] = os.environ['SPEAR_ADAPTER']
with open('.spear/config.json', 'w') as f:
    json.dump(config, f, indent=2)
" 2>/dev/null && ok "Config updated (language=$LANGUAGE, adapter=$ADAPTER)"
elif command -v node &>/dev/null; then
  SPEAR_LANGUAGE="$LANGUAGE" SPEAR_ADAPTER="$ADAPTER" node -e "
const fs = require('fs');
const config = JSON.parse(fs.readFileSync('.spear/config.json', 'utf8'));
config.project.language = process.env.SPEAR_LANGUAGE;
config.adapter = process.env.SPEAR_ADAPTER;
fs.writeFileSync('.spear/config.json', JSON.stringify(config, null, 2));
" 2>/dev/null && ok "Config updated (language=$LANGUAGE, adapter=$ADAPTER)"
else
  warn "No python3 or node found — config.json not auto-configured. Edit manually."
fi

# ─── Install Git Hooks ────────────────────────────────────
info "Installing git hooks..."

HOOKS_DIR="$GIT_ROOT/.git/hooks"
mkdir -p "$HOOKS_DIR"

# Source hooks directory
if [ "$SPEAR_SOURCE" = "local" ]; then
  HOOKS_SRC="$GIT_ROOT/hooks"
else
  HOOKS_SRC="$SPEAR_REPO/hooks"
fi

if [ -d "$HOOKS_SRC" ]; then
  # Install pre-commit
  if [ -f "$HOOKS_SRC/pre-commit" ]; then
    cp "$HOOKS_SRC/pre-commit" "$HOOKS_DIR/pre-commit"
    chmod +x "$HOOKS_DIR/pre-commit"
    ok "pre-commit hook installed"
  fi

  # Install commit-msg
  if [ -f "$HOOKS_SRC/commit-msg" ]; then
    cp "$HOOKS_SRC/commit-msg" "$HOOKS_DIR/commit-msg"
    chmod +x "$HOOKS_DIR/commit-msg"
    ok "commit-msg hook installed"
  fi

  # Copy checkers
  if [ -d "$HOOKS_SRC/checkers" ]; then
    mkdir -p "$HOOKS_DIR/checkers"
    cp "$HOOKS_SRC/checkers/"*.sh "$HOOKS_DIR/checkers/" 2>/dev/null
    chmod +x "$HOOKS_DIR/checkers/"*.sh 2>/dev/null
    ok "checker scripts installed"
  fi
else
  warn "Hooks directory not found — skipping hook installation"
fi

# ─── Install Adapter ─────────────────────────────────────
info "Configuring $ADAPTER adapter..."

if [ "$SPEAR_SOURCE" = "local" ]; then
  ADAPTER_SRC="$GIT_ROOT/adapters/$ADAPTER"
else
  ADAPTER_SRC="$SPEAR_REPO/adapters/$ADAPTER"
fi

case "$ADAPTER" in
  claude-code)
    if [ -d "$ADAPTER_SRC" ]; then
      # Install CLAUDE.md (append if exists, create if not)
      if [ -f "CLAUDE.md" ]; then
        if ! grep -q "SPEAR Framework" CLAUDE.md 2>/dev/null; then
          echo "" >> CLAUDE.md
          cat "$ADAPTER_SRC/CLAUDE.md" >> CLAUDE.md
          ok "SPEAR rules appended to existing CLAUDE.md"
        else
          ok "CLAUDE.md already contains SPEAR rules"
        fi
      else
        cp "$ADAPTER_SRC/CLAUDE.md" CLAUDE.md
        ok "CLAUDE.md created with SPEAR rules"
      fi
      # Install commands and agents
      mkdir -p .claude/commands .claude/agents
      cp "$ADAPTER_SRC/commands/"*.md .claude/commands/ 2>/dev/null && ok "Claude Code commands installed"
      cp "$ADAPTER_SRC/agents/"*.md .claude/agents/ 2>/dev/null && ok "Claude Code agents installed"
    fi
    ;;
  cursor)
    if [ -f "$ADAPTER_SRC/.cursorrules" ]; then
      if [ -f ".cursorrules" ]; then
        warn ".cursorrules exists — SPEAR rules saved to .cursorrules.spear (merge manually)"
        cp "$ADAPTER_SRC/.cursorrules" .cursorrules.spear
      else
        cp "$ADAPTER_SRC/.cursorrules" .cursorrules
        ok ".cursorrules installed"
      fi
    fi
    ;;
  copilot)
    mkdir -p .github
    if [ -f "$ADAPTER_SRC/.github/copilot-instructions.md" ]; then
      if [ -f ".github/copilot-instructions.md" ]; then
        warn "copilot-instructions.md exists — SPEAR rules saved to .github/copilot-instructions.spear.md"
        cp "$ADAPTER_SRC/.github/copilot-instructions.md" .github/copilot-instructions.spear.md
      else
        cp "$ADAPTER_SRC/.github/copilot-instructions.md" .github/copilot-instructions.md
        ok "copilot-instructions.md installed"
      fi
    fi
    ;;
  antigravity)
    mkdir -p .antigravity .agents/workflows .agents/rules
    [ -d "$ADAPTER_SRC" ] && cp -r "$ADAPTER_SRC/.antigravity/"* .antigravity/ 2>/dev/null
    [ -d "$ADAPTER_SRC/.agents" ] && cp -r "$ADAPTER_SRC/.agents/"* .agents/ 2>/dev/null
    ok "Antigravity adapter installed"
    ;;
  kiro)
    mkdir -p .kiro/steering .kiro/hooks .kiro/specs
    [ -d "$ADAPTER_SRC" ] && cp -r "$ADAPTER_SRC/.kiro/"* .kiro/ 2>/dev/null
    ok "Kiro adapter installed"
    ;;
  generic)
    if [ -f "$ADAPTER_SRC/system-prompt.md" ]; then
      cp "$ADAPTER_SRC/system-prompt.md" .spear/system-prompt.md
      ok "Generic system prompt installed to .spear/system-prompt.md"
    fi
    ;;
esac

# ─── Make Fitness Functions Executable ────────────────────
if [ -d ".spear/fitness/examples" ]; then
  chmod +x .spear/fitness/examples/*.sh 2>/dev/null
  ok "Fitness functions made executable"
fi

# ─── Summary ──────────────────────────────────────────────
echo ""
printf "${BOLD}${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
printf "${BOLD}${GREEN}  SPEAR Framework installed successfully!${NC}\n"
printf "${BOLD}${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
echo ""
info "Language:  $LANGUAGE"
info "Adapter:   $ADAPTER"
info "Framework: .spear/SPEAR.md"
info "Config:    .spear/config.json"
echo ""
info "Next steps:"
echo "  1. Review .spear/config.json and adjust settings"
echo "  2. Start your first cycle: create a spec using .spear/templates/spec/prd.md"
echo "  3. Read .spear/SPEAR.md for the full methodology"
echo ""
info "Documentation: https://github.com/migueljnew-droid/spear-framework"
echo ""

# Verify installation
if [ ! -f ".spear/SPEAR.md" ]; then
    fail "Installation verification failed — .spear/SPEAR.md not found"
fi
