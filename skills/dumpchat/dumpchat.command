#!/bin/bash
set -uo pipefail
# dumpchat.command — export current CLI session to Old Chats/oldchatN.md
# NEVER DELETE COMMENTS — parsing logic lives in lib/; see lib/parse_session.py
# Usage: dumpchat.command [home] [-append -suffix] [uuid] [target_dir]

APPEND_SUFFIX=""
TARGET_DIR="$HOME"                                          # never the shell cwd; that counter is how a project minted oldchat3
SESSION_ID=""
UUID_RE='^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'

while [[ $# -gt 0 ]]; do
  case "$1" in
    home)         TARGET_DIR="$HOME"; shift ;;
    append|-append) shift; APPEND_SUFFIX="${1:-}"; APPEND_SUFFIX="${APPEND_SUFFIX#-}"; shift ;;
    *)            [[ "$1" =~ $UUID_RE ]] && SESSION_ID="$1" || TARGET_DIR="$1"; shift ;;
  esac
done

# Block the Oct 20 project tree before any Old Chats directory is created.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../dumpboth/lib/block/refuse_scam_dir.sh"
refuse_scam_old_chats "$TARGET_DIR"
OLD_CHATS_DIR="$TARGET_DIR/Old Chats"
mkdir -p "$OLD_CHATS_DIR"
CLI_TYPE="unknown"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/dumpchat-session-find.sh"

if [[ -n "$SESSION_ID" ]]; then
  SESSION_FILE="$(dumpchat_resolve_session_file "$SESSION_ID")" || true
else
  SESSION_FILE="$(dumpchat_resolve_session_file)" || true
fi

if [[ -z "${SESSION_FILE:-}" || ! -r "$SESSION_FILE" ]]; then
  echo "Error: No session file found in any known CLI directory"; exit 1
fi

case "$SESSION_FILE" in
  *"/.claude/"*)   CLI_TYPE="claude" ;;
  *"/.codex/"*)    CLI_TYPE="codex" ;;
  *"/.gemini/"*)   CLI_TYPE="gemini" ;;
  *"/.kilocode/"*) CLI_TYPE="kilo" ;;
  *"/.kilo/"*)     CLI_TYPE="kilo" ;;
  *"/.opencode/"*) CLI_TYPE="opencode" ;;
  *"/.god/"*)      CLI_TYPE="god" ;;
esac

if [[ -n "${DUMP_FORCE_NUM:-}" ]]; then
  # /dumpboth sets this so md+jsonl land on the IDENTICAL number in one dump — no
  # race between the two auto-increment scans below.
  NEXT_NUM="$DUMP_FORCE_NUM"
else
  # SHARED counter with dumpjsonl's oldchatN.jsonl — scans both extensions so /dumpchat
  # and /dumpjsonl advance the same sequence (2026-08-18: dumpjsonl is now primary).
  NEXT_NUM=0
  for file in "$OLD_CHATS_DIR"/oldchat*.md "$OLD_CHATS_DIR"/oldchat*.jsonl; do
    [[ -f "$file" ]] || continue
    NUM=$(basename "$file" | sed 's/oldchat\([0-9]*\).*/\1/')
    [[ "$NUM" -ge "$NEXT_NUM" ]] 2>/dev/null && NEXT_NUM=$NUM
  done
  NEXT_NUM=$((NEXT_NUM + 1))
fi

[[ -n "$APPEND_SUFFIX" ]] \
  && EXPORT_FILE="$OLD_CHATS_DIR/oldchat${NEXT_NUM}-${APPEND_SUFFIX}.md" \
  || EXPORT_FILE="$OLD_CHATS_DIR/oldchat${NEXT_NUM}.md"

python3 "$SCRIPT_DIR/lib/parse_session.py" "$SESSION_FILE" "$CLI_TYPE" "$TARGET_DIR" > "$EXPORT_FILE"
echo "Exported session to $EXPORT_FILE"
