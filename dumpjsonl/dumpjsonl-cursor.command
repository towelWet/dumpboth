#!/bin/bash
set -uo pipefail
# dumpjsonl-cursor.command — verbatim Cursor IDE agent jsonl export to Old Chats/
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Usage mirrors dumpchat-cursor.command; pairs with /dumpboth cursor.

APPEND_SUFFIX=""
# Same rule as dumpchat-cursor.command: no pwd. Home unless a directory was named.
TARGET_DIR="$HOME"
SESSION_ID=""
UUID_RE='^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'

while [[ $# -gt 0 ]]; do
  case "$1" in
    home)           TARGET_DIR="$HOME"; shift ;;
    -append|append) shift; APPEND_SUFFIX="${1:-}"; APPEND_SUFFIX="${APPEND_SUFFIX#-}"; shift ;;
    *)
      if [[ "$1" =~ $UUID_RE ]]; then SESSION_ID="$1"; else TARGET_DIR="$1"; fi
      shift
      ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Same block as dumpboth: this project folder is not ~/Old Chats.
source "$SCRIPT_DIR/../lib/block/refuse_scam_dir.sh"
refuse_scam_old_chats "$TARGET_DIR"
OLD_CHATS_DIR="$TARGET_DIR/Old Chats"
mkdir -p "$OLD_CHATS_DIR"
# shellcheck source=../dumpchat/cursor-session-find.sh
source "$SCRIPT_DIR/../dumpchat/cursor-session-find.sh"
cursor_resolve_session "$SESSION_ID"

if [[ -z "${SESSION_FILE:-}" || ! -r "$SESSION_FILE" ]]; then
  echo "Error: No Cursor main session jsonl found under ~/.cursor/projects/*/agent-transcripts/"
  exit 1
fi

if [[ -n "${DUMP_FORCE_NUM:-}" ]]; then
  NEXT_NUM="$DUMP_FORCE_NUM"
else
  NEXT_NUM=0
  for file in "$OLD_CHATS_DIR"/oldchat*.md "$OLD_CHATS_DIR"/oldchat*.jsonl; do
    [[ -f "$file" ]] || continue
    NUM=$(basename "$file" | sed 's/oldchat\([0-9]*\).*/\1/')
    [[ "$NUM" -ge "$NEXT_NUM" ]] 2>/dev/null && NEXT_NUM=$NUM
  done
  NEXT_NUM=$((NEXT_NUM + 1))
fi

[[ -n "$APPEND_SUFFIX" ]] \
  && EXPORT_FILE="$OLD_CHATS_DIR/oldchat${NEXT_NUM}-${APPEND_SUFFIX}.jsonl" \
  || EXPORT_FILE="$OLD_CHATS_DIR/oldchat${NEXT_NUM}.jsonl"

cp "$SESSION_FILE" "$EXPORT_FILE"
echo "Exported raw Cursor jsonl to $EXPORT_FILE"
echo "Source: $SESSION_FILE"
echo "Resume: cursor agent --resume $SESSION_ID"
