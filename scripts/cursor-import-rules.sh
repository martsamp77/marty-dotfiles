#!/bin/bash
# ══════════════════════════════════════════════════════════════════════════════
#  cursor-import-rules.sh
#
#  Writes Cursor User Rules from cursor/user-rules.md back into the
#  state.vscdb SQLite database.
#
#  WARNING: Close Cursor before running this script. The database is
#  locked while Cursor is running and writes will fail or corrupt data.
#
#  Usage:
#    ./scripts/cursor-import-rules.sh
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
            WIN_APPDATA=$(wslpath "$(cmd.exe /c "echo %APPDATA%" 2>/dev/null | tr -d '\r')")
            DB_PATH="${WIN_APPDATA}/Cursor/User/globalStorage/state.vscdb"
        else
            DB_PATH="$HOME/.config/Cursor/User/globalStorage/state.vscdb"
        fi
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

# ── Locate the rules file ──────────────────────────────────────────────────
if command -v chezmoi &>/dev/null; then
    SOURCE_DIR="$(chezmoi source-path 2>/dev/null || echo "")"
fi
if [[ -z "${SOURCE_DIR:-}" ]]; then
    SOURCE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
fi

RULES_FILE="${SOURCE_DIR}/cursor/user-rules.md"
if [[ ! -f "$RULES_FILE" ]]; then
    echo "Rules file not found: $RULES_FILE" >&2
    echo "Run cursor-export-rules.sh first on a machine that has your rules." >&2
    exit 1
fi

RULES=$(cat "$RULES_FILE")
if [[ -z "$RULES" ]]; then
    echo "Rules file is empty — nothing to import."
    exit 0
fi

# ── Back up the database ────────────────────────────────────────────────────
BACKUP="${DB_PATH}.pre-import-$(date +%Y%m%d%H%M%S)"
cp "$DB_PATH" "$BACKUP"
echo "Database backed up to: $BACKUP"

# ── Write rules into the database ──────────────────────────────────────────
sqlite3 "$DB_PATH" <<SQL
INSERT OR REPLACE INTO ItemTable (key, value)
VALUES ('aicontext.personalContext', '$(echo "$RULES" | sed "s/'/''/g")');
SQL

echo "User Rules imported successfully."
echo "Restart Cursor to see the changes."
