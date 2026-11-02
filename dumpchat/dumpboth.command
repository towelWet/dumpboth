#!/bin/bash
set -uo pipefail
# dumpboth.command — dump both .md and .jsonl to Old Chats with the SAME number
# Usage: dumpboth.command [home] [append -suffix]
# NEVER DELETE COMMENTS — explain every non-obvious line.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$HOME"                                      # never the shell cwd; that counter minted oldchat1–3
APPEND_SUFFIX=""
SESSION_ID=""
UUID_RE='^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'

while [[ $# -gt 0 ]]; do
  case "$1" in
    home)           TARGET_DIR="$HOME"; shift ;;
    append|-append) shift; APPEND_SUFFIX="${1:-}"; APPEND_SUFFIX="${APPEND_SUFFIX#-}"; shift ;;
    *)              [[ "$1" =~ $UUID_RE ]] && SESSION_ID="$1" || TARGET_DIR="$1"; shift ;;
  esac
done

source "$SCRIPT_DIR/../lib/block/refuse_scam_dir.sh"
refuse_scam_old_chats "$TARGET_DIR"
OLD_CHATS_DIR="$TARGET_DIR/Old Chats"
mkdir -p "$OLD_CHATS_DIR"

# Find next number — scan BOTH .md and .jsonl so counter never collides
NEXT_NUM=0
for file in "$OLD_CHATS_DIR"/oldchat*.md "$OLD_CHATS_DIR"/oldchat*.jsonl; do
  [[ -f "$file" ]] || continue
  NUM=$(basename "$file" | sed 's/oldchat\([0-9]*\).*/\1/')
  [[ "$NUM" -ge "$NEXT_NUM" ]] 2>/dev/null && NEXT_NUM=$NUM
done
NEXT_NUM=$((NEXT_NUM + 1))

# --- 1. MD dump via dumpchat.command (force same number) ---
DUMP_ARGS=()
[[ "$TARGET_DIR" == "$HOME" ]] && DUMP_ARGS+=(home)
[[ -n "$APPEND_SUFFIX" ]] && DUMP_ARGS+=(-append "-$APPEND_SUFFIX")
[[ -n "$SESSION_ID" ]] && DUMP_ARGS+=("$SESSION_ID")

export DUMP_FORCE_NUM="$NEXT_NUM"                        # lock the number for MD
"$SCRIPT_DIR/dumpchat.command" ${DUMP_ARGS[@]+"${DUMP_ARGS[@]}"}
unset DUMP_FORCE_NUM

# --- 2. JSONL copy (same number, raw session file) ---
source "$SCRIPT_DIR/dumpchat-session-find.sh"

if [[ -n "$SESSION_ID" ]]; then
  SESSION_FILE="$(dumpchat_resolve_session_file "$SESSION_ID")" || true
else
  SESSION_FILE="$(dumpchat_resolve_session_file)" || true
fi

if [[ -n "${SESSION_FILE:-}" && -r "$SESSION_FILE" ]]; then
  [[ -n "$APPEND_SUFFIX" ]] \
    && JSONL_OUT="$OLD_CHATS_DIR/oldchat${NEXT_NUM}-${APPEND_SUFFIX}.jsonl" \
    || JSONL_OUT="$OLD_CHATS_DIR/oldchat${NEXT_NUM}.jsonl"
  cp "$SESSION_FILE" "$JSONL_OUT"
  echo "Copied JSONL to $JSONL_OUT"
else
  echo "Warning: could not find session JSONL to copy"
fi
