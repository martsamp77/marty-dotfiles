#!/bin/bash
# ══════════════════════════════════════════════════════════════════════════════
#  dottools — upgrade git, chezmoi, zsh, fzf
#
#  Run: dottools
#  Skips each tool if not installed. Per-platform: Homebrew (macOS), apt
#  (Linux/WSL).
# ══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

OS="$(uname -s)"
IS_WSL=false
[[ -f /proc/version ]] && grep -qi microsoft /proc/version 2>/dev/null && IS_WSL=true

# ── macOS (Homebrew) ────────────────────────────────────────────────────────
if [[ "$OS" == "Darwin" ]]; then
    if command -v brew &>/dev/null; then
        echo "dottools: running brew upgrade..."
        TO_UPGRADE=""
        brew list --formula git &>/dev/null && TO_UPGRADE="$TO_UPGRADE git"
        brew list --formula chezmoi &>/dev/null && TO_UPGRADE="$TO_UPGRADE chezmoi"
        brew list --formula zsh &>/dev/null && TO_UPGRADE="$TO_UPGRADE zsh"
        brew list --formula fzf &>/dev/null && TO_UPGRADE="$TO_UPGRADE fzf"
        [[ -n "$TO_UPGRADE" ]] && brew upgrade $TO_UPGRADE 2>/dev/null || true
        echo "dottools: done"
    fi
    exit 0
fi

# ── Linux (apt) ──────────────────────────────────────────────────────────────
if [[ "$OS" == "Linux" ]] && ! $IS_WSL; then
    echo "dottools: running apt upgrade..."
    sudo apt-get update -qq 2>/dev/null || true
    sudo apt-get install -y --only-upgrade git zsh 2>/dev/null || true
    command -v chezmoi &>/dev/null && chezmoi upgrade 2>/dev/null || true
    dpkg -l fzf &>/dev/null && sudo apt-get install -y --only-upgrade fzf 2>/dev/null || true
    echo "dottools: done"
    exit 0
fi

# ── WSL (apt) ─────────────────────────────────────────────────────────────────
if [[ "$OS" == "Linux" ]] && $IS_WSL; then
    echo "dottools: running apt..."
    sudo apt-get update -qq 2>/dev/null || true
    sudo apt-get install -y --only-upgrade git zsh 2>/dev/null || true
    command -v chezmoi &>/dev/null && chezmoi upgrade 2>/dev/null || true
    dpkg -l fzf &>/dev/null && sudo apt-get install -y --only-upgrade fzf 2>/dev/null || true
    echo "dottools: done"
fi
