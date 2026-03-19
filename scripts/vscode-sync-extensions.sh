#!/bin/bash
# ══════════════════════════════════════════════════════════════════════════════
#  vscode-sync-extensions.sh
#
#  Compares installed VS Code extensions to cursor/extensions.txt (the manifest).
#  Skips anysphere.* extensions (Cursor-only). For extensions installed but not
#  in the manifest: lets you choose to remove them or add them to the list.
#  For extensions in the manifest but not installed: lets you install them.
#
#  Usage:
#    ./scripts/vscode-sync-extensions.sh
#
#  Run from repo root or anywhere; uses chezmoi source-path or script location.
# ══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

# ── Resolve CODE_CMD ────────────────────────────────────────────────────────
OS="$(uname -s)"
if [[ "$OS" == "Darwin" ]]; then
    CODE_CMD="code"
elif [[ "$OS" == "Linux" ]]; then
    if [[ -f /proc/version ]] && grep -qi microsoft /proc/version 2>/dev/null; then
        CODE_CMD="code.exe"
        if ! command -v "$CODE_CMD" &>/dev/null; then
            CODE_FALLBACK="/mnt/c/Program Files/Microsoft VS Code/bin/code"
            [[ -x "$CODE_FALLBACK" ]] && CODE_CMD="$CODE_FALLBACK"
        fi
    else
        CODE_CMD="code"
    fi
else
    echo "Unsupported OS: $OS" >&2
    exit 1
fi

if ! (command -v "$CODE_CMD" &>/dev/null || [[ -x "$CODE_CMD" ]]); then
    echo "VS Code CLI not found. Install VS Code and ensure '$CODE_CMD' is in PATH." >&2
    exit 1
fi

# ── Locate manifest ─────────────────────────────────────────────────────────
if command -v chezmoi &>/dev/null; then
    SOURCE_DIR="$(chezmoi source-path 2>/dev/null || echo "")"
fi
if [[ -z "${SOURCE_DIR:-}" ]]; then
    SOURCE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
fi

MANIFEST="${SOURCE_DIR}/cursor/extensions.txt"
if [[ ! -f "$MANIFEST" ]]; then
    echo "Manifest not found: $MANIFEST" >&2
    exit 1
fi

# ── Get extension lists ──────────────────────────────────────────────────────
INSTALLED=$(mktemp)
MANIFEST_LIST=$(mktemp)
trap 'rm -f "$INSTALLED" "$MANIFEST_LIST"' EXIT

"$CODE_CMD" --list-extensions 2>/dev/null | sort -u > "$INSTALLED"
grep -v '^#' "$MANIFEST" | grep -v '^[[:space:]]*$' | grep -v '^anysphere\.' | while read -r line; do
    echo "${line%%[[:space:]]*}"
done | sort -u > "$MANIFEST_LIST"

# ── Compute diffs ───────────────────────────────────────────────────────────
ORPHANS=$(comm -23 "$INSTALLED" "$MANIFEST_LIST")
MISSING=$(comm -13 "$INSTALLED" "$MANIFEST_LIST")

echo ""
echo "════════════════════════════════════════════════════"
echo "  VS Code Extension Sync"
echo "════════════════════════════════════════════════════"
echo "  Manifest: $MANIFEST (anysphere.* excluded)"
echo ""

# ── Orphans: installed but not in manifest ───────────────────────────────────
if [[ -n "$ORPHANS" ]]; then
    echo "  Installed but NOT in manifest (choose one per extension):"
    echo "  ─────────────────────────────────────────────────────────"
    while IFS= read -r ext; do
        [[ -z "$ext" ]] && continue
        echo -n "    $ext — [R]emove / [A]dd to list / [S]kip? "
        read -r choice
        case "${choice,,}" in
            r|remove)
                echo "      Uninstalling $ext..."
                "$CODE_CMD" --uninstall-extension "$ext" 2>/dev/null || true
                ;;
            a|add)
                echo "      Adding $ext to manifest..."
                echo "$ext" >> "$MANIFEST"
                ;;
            s|skip|"")
                echo "      Skipped."
                ;;
            *)
                echo "      Skipped (unknown choice)."
                ;;
        esac
    done <<< "$ORPHANS"
    echo ""
else
    echo "  No orphan extensions (all installed extensions are in the manifest)."
    echo ""
fi

# ── Missing: in manifest but not installed ────────────────────────────────────
if [[ -n "$MISSING" ]]; then
    echo "  In manifest but NOT installed:"
    echo "$MISSING" | sed 's/^/    /'
    echo ""
    echo -n "  Install these? [y/N] "
    read -r choice
    if [[ "${choice,,}" == "y" || "${choice,,}" == "yes" ]]; then
        while IFS= read -r ext; do
            [[ -z "$ext" ]] && continue
            echo "    Installing $ext..."
            "$CODE_CMD" --install-extension "$ext" 2>/dev/null || true
        done <<< "$MISSING"
    fi
else
    echo "  No missing extensions (all manifest extensions are installed)."
fi

echo ""
echo "  Done."
echo ""
