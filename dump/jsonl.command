#!/bin/bash
# jsonl.command — write raw session for one agent into Old Chats, untouched.
# Why: this copy IS the chat: no header, no footer, no reformatting.
# Usage: jsonl.command <agent> [home|dir] [uuid] [-append suffix]
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/export/begin.sh" jsonl "$@"   # sets AGENT_DIR, SESSION_ID, EXPORT_FILE, TARGET_DIR

if [[ -x "$AGENT_DIR/raw.sh" ]]; then                       # agent whose session is not a plain file
  "$AGENT_DIR/raw.sh" "$SESSION_ID" "$EXPORT_FILE" >/dev/null || exit 1
else
  SESSION_FILE="$("$AGENT_DIR/session.sh" "$SESSION_ID")"
  if [[ -z "$SESSION_FILE" || ! -r "$SESSION_FILE" ]]; then
    echo "Error: no session found for ${AGENT_DIR##*/}" >&2; exit 1
  fi
  cp "$SESSION_FILE" "$EXPORT_FILE"
  echo "Source: $SESSION_FILE"
fi
echo "Exported raw ${AGENT_DIR##*/} jsonl to $EXPORT_FILE"
