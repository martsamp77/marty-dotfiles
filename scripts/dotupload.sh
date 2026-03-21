#!/bin/bash
# ══════════════════════════════════════════════════════════════════════════════
#  dotupload.sh — copy local Cursor/VS Code state into the chezmoi source tree,
#  then git commit (descriptive message required) and push.
#
#  Reverse of run_after_apply-cursor.sh.tmpl (repo → IDE).  This script pulls
#  IDE files → cursor/ in the chezmoi source so you can commit and push.
#
#  Platforms: macOS, Linux, WSL (Windows-side AppData), Git Bash on Windows
#  (uses $APPDATA).  Native Windows PowerShell: use scripts/dotupload.ps1 via
#  the dotupload function in your profile.
#
#  Does NOT upload: keybindings.json (regenerated on every chezmoi apply),
#  template sources from a raw ~/.zshrc edit (use chezmoi edit / merge).
#
#  Usage:
#    dotupload "Describe what you changed (12+ characters, not a vague word)"
#    dotupload --rules "Export Cursor user rules and sync editor settings"
#    dotupload --extensions "Refresh extension manifest from Cursor CLI"
#    dotupload --snippets "Copy snippet files from Cursor User/snippets"
#
#  Flags:
#    --rules       Run scripts/cursor-export-rules.sh (needs sqlite3; Unix DB paths)
#    --extensions  Overwrite cursor/extensions.txt from: cursor --list-extensions
#    --snippets    Copy *.code-snippets from Cursor User/snippets → cursor/snippets/
#
#  Pre-commit hook may require CHANGELOG.md when cursor/ or scripts/ change;
#  use SKIP_CHANGELOG=1 git commit … only when appropriate (see README).
# ══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

usage() {
    cat <<'EOF'
dotupload.sh — sync Cursor/VS Code → chezmoi source, git commit, push

  dotupload "Descriptive commit message (12+ characters)"
  dotupload --rules "Export Cursor user rules and sync editor settings"
  dotupload --extensions "Refresh extension manifest from Cursor CLI"
  dotupload --snippets "Copy snippet files from Cursor User/snippets"

Flags: --rules --extensions --snippets (combine as needed)
EOF
}

DO_RULES=false
DO_EXTENSIONS=false
DO_SNIPPETS=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --rules)       DO_RULES=true; shift ;;
        --extensions)  DO_EXTENSIONS=true; shift ;;
        --snippets)    DO_SNIPPETS=true; shift ;;
        -h|--help)     usage; exit 0 ;;
        *)
            COMMIT_MSG="$*"
            break
            ;;
    esac
done

trim() {
    local s="$1"
    s="${s#"${s%%[![:space:]]*}"}"
    s="${s%"${s##*[![:space:]]}"}"
    printf '%s' "$s"
}

COMMIT_MSG="$(trim "${COMMIT_MSG:-}")"

if [[ -z "$COMMIT_MSG" ]]; then
    echo "dotupload: missing commit message." >&2
    echo "  Example: dotupload \"Sync Cursor theme, tab size, and format on save\"" >&2
    exit 1
fi

if [[ ${#COMMIT_MSG} -lt 12 ]]; then
    echo "dotupload: commit message must be at least 12 characters — say what changed." >&2
    exit 1
fi

shopt -s nocasematch
if [[ "$COMMIT_MSG" =~ ^(wip|update|changes|fix|test|sync|stuff|asdf|commit|msg)$ ]]; then
    echo "dotupload: commit message is too vague; use a specific sentence." >&2
    exit 1
fi
shopt -u nocasematch

if ! command -v chezmoi &>/dev/null; then
    echo "dotupload: chezmoi not found in PATH." >&2
    exit 1
fi

SOURCE_DIR="$(chezmoi source-path 2>/dev/null || true)"
if [[ -z "$SOURCE_DIR" || ! -d "$SOURCE_DIR" ]]; then
    echo "dotupload: chezmoi source-path failed — is this machine initialized?" >&2
    exit 1
fi

# ── Resolve Cursor / VS Code User directories (match run_after_apply-cursor) ─
OS="$(uname -s)"
CURSOR_DIR=""
CODE_DIR=""

case "$OS" in
    Darwin)
        CURSOR_DIR="$HOME/Library/Application Support/Cursor/User"
        CODE_DIR="$HOME/Library/Application Support/Code/User"
        ;;
    Linux)
        if [[ -f /proc/version ]] && grep -qi microsoft /proc/version 2>/dev/null; then
            WIN_APPDATA="$(wslpath "$(cmd.exe /c "echo %APPDATA%" 2>/dev/null | tr -d '\r')" 2>/dev/null || true)"
            if [[ -n "$WIN_APPDATA" ]]; then
                CURSOR_DIR="${WIN_APPDATA}/Cursor/User"
                CODE_DIR="${WIN_APPDATA}/Code/User"
            fi
        else
            CURSOR_DIR="$HOME/.config/Cursor/User"
            CODE_DIR="$HOME/.config/Code/User"
        fi
        ;;
    MINGW*|MSYS*)
        if [[ -n "${APPDATA:-}" ]]; then
            CURSOR_DIR="$APPDATA/Cursor/User"
            CODE_DIR="$APPDATA/Code/User"
        fi
        ;;
    *)
        echo "dotupload.sh: unsupported OS \"$OS\". Use PowerShell dotupload.ps1 on native Windows." >&2
        exit 1
        ;;
esac

SETTINGS_SRC="$SOURCE_DIR/cursor/settings.json"
mkdir -p "$(dirname "$SETTINGS_SRC")"

COPIED_SETTINGS=false
if [[ -n "$CURSOR_DIR" && -f "$CURSOR_DIR/settings.json" ]]; then
    cp "$CURSOR_DIR/settings.json" "$SETTINGS_SRC"
    echo "dotupload: copied Cursor → cursor/settings.json"
    COPIED_SETTINGS=true
elif [[ -n "$CODE_DIR" && -f "$CODE_DIR/settings.json" ]]; then
    cp "$CODE_DIR/settings.json" "$SETTINGS_SRC"
    echo "dotupload: copied VS Code → cursor/settings.json (Cursor User dir missing or empty)"
    COPIED_SETTINGS=true
else
    echo "dotupload: warning — no settings.json found under Cursor or VS Code User (skipped)"
fi

if $DO_SNIPPETS; then
    if [[ -z "$CURSOR_DIR" || ! -d "$CURSOR_DIR/snippets" ]]; then
        echo "dotupload: --snippets: Cursor snippets directory not found — skipping" >&2
    else
        shopt -s nullglob
        _snip=("$CURSOR_DIR/snippets"/*.code-snippets)
        shopt -u nullglob
        if [[ ${#_snip[@]} -eq 0 ]]; then
            echo "dotupload: --snippets: no *.code-snippets in $CURSOR_DIR/snippets"
        else
            mkdir -p "$SOURCE_DIR/cursor/snippets"
            cp "${_snip[@]}" "$SOURCE_DIR/cursor/snippets/"
            echo "dotupload: copied ${#_snip[@]} snippet file(s) → cursor/snippets/"
        fi
    fi
fi

if $DO_RULES; then
    RULES_SCRIPT="$SOURCE_DIR/scripts/cursor-export-rules.sh"
    if [[ ! -f "$RULES_SCRIPT" ]]; then
        echo "dotupload: cursor-export-rules.sh not found" >&2
        exit 1
    fi
    bash "$RULES_SCRIPT" || {
        echo "dotupload: cursor-export-rules.sh failed (sqlite3 / OS / DB path?)" >&2
        exit 1
    }
fi

if $DO_EXTENSIONS; then
    CURSOR_CMD="cursor"
    if [[ "$OS" == Linux ]] && [[ -f /proc/version ]] && grep -qi microsoft /proc/version 2>/dev/null; then
        CURSOR_CMD="cursor.exe"
        if ! command -v "$CURSOR_CMD" &>/dev/null; then
            CURSOR_FALLBACK="/mnt/c/Program Files/cursor/resources/app/bin/cursor"
            [[ -x "$CURSOR_FALLBACK" ]] && CURSOR_CMD="$CURSOR_FALLBACK"
        fi
    fi
    if ! command -v "$CURSOR_CMD" &>/dev/null; then
        echo "dotupload: --extensions: '$CURSOR_CMD' not in PATH" >&2
        exit 1
    fi
    "$CURSOR_CMD" --list-extensions >"$SOURCE_DIR/cursor/extensions.txt"
    echo "dotupload: wrote cursor/extensions.txt from cursor --list-extensions"
fi

# ── Warn if home directory drift from source (no auto-merge) ────────────────
if chezmoi diff 2>/dev/null | grep -q .; then
    echo ""
    echo "dotupload: note — chezmoi diff shows differences between source and your home files."
    echo "          This script does not merge them; use dotedit, chezmoi merge, or fix templates."
    echo ""
fi

cd "$SOURCE_DIR"

if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "dotupload: not a git repository: $SOURCE_DIR" >&2
    exit 1
fi

git add -A

if git diff --cached --quiet; then
    echo "dotupload: nothing to commit (working tree clean after sync)."
    exit 0
fi

STAGED="$(git diff --cached --name-only)"
if echo "$STAGED" | grep -qE '^(cursor/|scripts/|\.chezmoi/|dot_|run_after_apply|Documents/|install|VERSION)(/|$)'; then
    if ! echo "$STAGED" | grep -q '^CHANGELOG\.md$'; then
        echo "dotupload: reminder — .githooks/pre-commit may require CHANGELOG.md staged for these paths."
        echo "          Add a bullet under [Unreleased] or use SKIP_CHANGELOG=1 git commit … if appropriate."
        echo ""
    fi
fi

set +e
git commit -m "$COMMIT_MSG"
COMMIT_STATUS=$?
set -e

if [[ $COMMIT_STATUS -ne 0 ]]; then
    echo "dotupload: git commit failed (hook? conflicts?). Fix and retry, or commit manually from: $SOURCE_DIR" >&2
    exit "$COMMIT_STATUS"
fi

git push
echo "dotupload: pushed to remote."
