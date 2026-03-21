#!/bin/bash
# ══════════════════════════════════════════════════════════════════════════════
#  cursor-export-rules.sh
#
#  Extracts Cursor User Rules from the state.vscdb SQLite database and
#  saves them to cursor/user-rules.md in the chezmoi source directory.
#
#  User Rules are stored as a JSON string under the key
#  'aicontext.personalContext' in the ItemTable of state.vscdb.
#
#  Usage:
#    ./scripts/cursor-export-rules.sh
#
#  Requires: sqlite3
# ══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

# ── Detect OS and locate state.vscdb ────────────────────────────────────────
OS="$(uname -s)"
case "$OS" in
    Darwin)
        DB_PATH="$HOME/Library/Application Support/Cursor/User/globalStorage/state.vscdb"
        ;;
    Linux)
        if [[ -f /proc/version ]] && grep -qi microsoft /proc/version 2>/dev/null; then
            # WSL — database is on the Windows side
            WIN_APPDATA=$(wslpath "$(cmd.exe /c "echo %APPDATA%" 2>/dev/null | tr -d '\r')")
            DB_PATH="${WIN_APPDATA}/Cursor/User/globalStorage/state.vscdb"
        else
            DB_PATH="$HOME/.config/Cursor/User/globalStorage/state.vscdb"
        fi
        ;;
    MINGW*|MSYS*)
        # Git Bash on Windows — %APPDATA% as a Unix path
        if [[ -z "${APPDATA:-}" ]]; then
            echo "cursor-export-rules: APPDATA is not set (expected under Git Bash)" >&2
            exit 1
        fi
        DB_PATH="$APPDATA/Cursor/User/globalStorage/state.vscdb"
        ;;
    *)
        echo "Unsupported OS: $OS" >&2
        exit 1
        ;;
esac

if [[ ! -f "$DB_PATH" ]]; then
    echo "Database not found: $DB_PATH" >&2
    exit 1
fi

if ! command -v sqlite3 &>/dev/null; then
    echo "sqlite3 is required but not installed." >&2
    exit 1
fi

# ── Extract User Rules ──────────────────────────────────────────────────────
RULES=$(sqlite3 "$DB_PATH" \
    "SELECT value FROM ItemTable WHERE key = 'aicontext.personalContext';" 2>/dev/null)

if [[ -z "$RULES" ]]; then
    echo "No User Rules found in database."
    exit 0
fi

# ── Determine output path ───────────────────────────────────────────────────
# Try chezmoi source dir first, fall back to script's own directory
if command -v chezmoi &>/dev/null; then
    SOURCE_DIR="$(chezmoi source-path 2>/dev/null || echo "")"
fi
if [[ -z "${SOURCE_DIR:-}" ]]; then
    SOURCE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
fi

OUTPUT_FILE="${SOURCE_DIR}/cursor/user-rules.md"
mkdir -p "$(dirname "$OUTPUT_FILE")"

echo "$RULES" > "$OUTPUT_FILE"
echo "User Rules exported to: $OUTPUT_FILE"
echo "$(echo "$RULES" | wc -l | tr -d ' ') lines written."
