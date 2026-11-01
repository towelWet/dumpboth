#!/bin/bash
set -uo pipefail
# dumpjsonl-codex.command — verbatim Codex session rollout export to Old Chats/.
# Why: pairs with dumpchat-codex.command so /dumpboth codex gets .md + .jsonl on one name.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.
# Usage: dumpjsonl-codex.command [home] [-append -suffix] [target_dir]

APPEND_SUFFIX=""
TARGET_DIR="$HOME"                                          # never the shell cwd
while [[ $# -gt 0 ]]; do
  case "$1" in
    home)           TARGET_DIR="$HOME"; shift ;;
    -append|append) shift; APPEND_SUFFIX="${1:-}"; APPEND_SUFFIX="${APPEND_SUFFIX#-}"; shift ;;
    *)              TARGET_DIR="$1"; shift ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GUARD="$SCRIPT_DIR/../lib/block/refuse_blocked_dir.sh"           # release repo: lib/ beside dumpjsonl/
[[ -f "$GUARD" ]] || GUARD="$SCRIPT_DIR/../dumpboth/lib/block/refuse_blocked_dir.sh"   # installed skills/ layout
source "$GUARD"
refuse_blocked_dir "$TARGET_DIR"
OLD_CHATS_DIR="$TARGET_DIR/Old Chats"; mkdir -p "$OLD_CHATS_DIR"
source "$SCRIPT_DIR/../dumpchat/codex-session-find.sh"       # same finder as dumpchat-codex
SESSION_FILE="$(codex_session_file)" || true
if [[ -z "${SESSION_FILE:-}" || ! -r "$SESSION_FILE" ]]; then
  echo "Error: No Codex session file found in ~/.codex/sessions/"; exit 1
fi

if [[ -n "${DUMP_FORCE_NUM:-}" ]]; then
  NEXT_NUM="$DUMP_FORCE_NUM"                                 # /dumpboth forces shared number
else
  NEXT_NUM=0                                                 # shared counter across .md and .jsonl
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
cp "$SESSION_FILE" "$EXPORT_FILE"                            # verbatim: this IS the session
echo "Exported raw Codex jsonl to $EXPORT_FILE"
echo "Source: $SESSION_FILE"
