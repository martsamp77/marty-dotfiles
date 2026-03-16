#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════════════════
#  install.sh — Bootstrap Marty's dotfiles on a new machine
#
#  One-liner install:
#    bash <(curl -fsLS https://raw.githubusercontent.com/martsamp77/marty-dotfiles/main/install.sh)
#
#  Works on:
#    macOS  — Apple Silicon (/opt/homebrew) and Intel (/usr/local)
#    Ubuntu — desktop, server, AWS EC2
#    WSL    — Ubuntu on Windows 10/11 (WSL 2)
#
#  Safe to re-run: every step checks before acting.
# ══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

# ── Colors ──────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

step() { echo -e "\n${CYAN}▸ $*${NC}"; }
ok()   { echo -e "${GREEN}  ✓ $*${NC}"; }
warn() { echo -e "${YELLOW}  ! $*${NC}"; }
die()  { echo -e "${RED}  ✗ $*${NC}"; exit 1; }

# ── Detect environment ───────────────────────────────────────────────────────
OS="$(uname -s)"
ARCH="$(uname -m)"
IS_WSL=false
[[ -f /proc/version ]] && grep -qi microsoft /proc/version && IS_WSL=true

echo ""
echo "════════════════════════════════════════════════════"
echo "  Marty's Dotfiles — Bootstrap Installer"
echo "════════════════════════════════════════════════════"
echo "  OS:   $OS ($ARCH)"
$IS_WSL && echo "  WSL:  yes"
echo ""

# ── Homebrew (macOS only) ────────────────────────────────────────────────────
if [[ "$OS" == "Darwin" ]]; then
    if ! command -v brew &>/dev/null; then
        step "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        # Add brew to PATH for the rest of this script
        if [[ "$ARCH" == "arm64" ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        else
            eval "$(/usr/local/bin/brew shellenv)"
        fi
        ok "Homebrew installed"
    else
        ok "Homebrew already installed"
    fi
fi

# ── apt prerequisites (Ubuntu / WSL) ────────────────────────────────────────
if [[ "$OS" == "Linux" ]]; then
    step "Updating apt and installing prerequisites..."
    sudo apt-get update -qq
    sudo apt-get install -y --no-install-recommends \
        curl git zsh fzf locales
    # Ensure UTF-8 locale is available (fixes ❯ rendering as a square)
    sudo locale-gen en_US.UTF-8 2>/dev/null || true
    sudo update-locale LANG=en_US.UTF-8 2>/dev/null || true
    ok "Prerequisites installed"
fi

# ── git ──────────────────────────────────────────────────────────────────────
step "Checking git..."
if ! command -v git &>/dev/null; then
    [[ "$OS" == "Darwin" ]] && brew install git || die "git not found and could not install"
fi
ok "git $(git --version | awk '{print $3}')"

# ── zsh ──────────────────────────────────────────────────────────────────────
step "Checking zsh..."
if ! command -v zsh &>/dev/null; then
    [[ "$OS" == "Darwin" ]] && brew install zsh || die "zsh not found and could not install"
fi
ok "zsh $(zsh --version | awk '{print $2}')"

# ── Set zsh as default shell ─────────────────────────────────────────────────
step "Setting zsh as default shell..."
ZSH_PATH="$(command -v zsh)"

# Register zsh in /etc/shells if not already listed
if ! grep -qxF "$ZSH_PATH" /etc/shells; then
    echo "$ZSH_PATH" | sudo tee -a /etc/shells >/dev/null
fi

if [[ "$SHELL" != "$ZSH_PATH" ]]; then
    chsh -s "$ZSH_PATH"
    ok "Default shell set to $ZSH_PATH"
else
    ok "zsh is already the default shell"
fi

# ── chezmoi ──────────────────────────────────────────────────────────────────
step "Checking chezmoi..."
if ! command -v chezmoi &>/dev/null; then
    if [[ "$OS" == "Darwin" ]]; then
        brew install chezmoi
    else
        sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
        export PATH="$HOME/.local/bin:$PATH"
    fi
    ok "chezmoi installed"
else
    ok "chezmoi $(chezmoi --version | awk '{print $3}')"
fi

# ── fzf (macOS — already handled via apt on Linux above) ────────────────────
if [[ "$OS" == "Darwin" ]] && ! command -v fzf &>/dev/null; then
    step "Installing fzf..."
    brew install fzf
    ok "fzf installed"
fi

# ── Apply dotfiles ───────────────────────────────────────────────────────────
step "Applying dotfiles from GitHub..."

# Try SSH first (works if a key is already registered with GitHub).
# Fall back to HTTPS for brand-new machines with no SSH key set up yet.
REPO_SSH="git@github.com:martsamp77/marty-dotfiles.git"
REPO_HTTPS="https://github.com/martsamp77/marty-dotfiles.git"

if ssh -o ConnectTimeout=5 -T git@github.com 2>&1 | grep -q "Hi martsamp77"; then
    REPO="$REPO_SSH"
    ok "GitHub SSH key found — using SSH"
else
    REPO="$REPO_HTTPS"
    warn "No GitHub SSH key found — using HTTPS (you can add a key later)"
fi

chezmoi init --apply "$REPO"
ok "Dotfiles applied"

# ── Done ─────────────────────────────────────────────────────────────────────
echo ""
echo "════════════════════════════════════════════════════"
echo -e "${GREEN}  All done!${NC}"
echo "════════════════════════════════════════════════════"
echo ""
echo "  Reload your shell:"
echo ""
echo "      exec zsh"
echo ""

if $IS_WSL; then
    warn "WSL: if the prompt doesn't appear correctly, open Windows Terminal"
    warn "     → Settings → your Ubuntu profile → Command line"
    warn "     → set to: /usr/bin/zsh"
    echo ""
fi

echo "  To verify everything is working:"
echo ""
echo "      echo \$DOTFILES_VERSION   # current dotfiles version"
echo "      echo \$SHELL              # should be /usr/bin/zsh or /bin/zsh"
echo "      dotup                    # pull latest dotfiles from GitHub"
echo ""
