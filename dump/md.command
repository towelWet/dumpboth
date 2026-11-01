#!/bin/bash
# md.command — write readable .md for one agent's session into Old Chats.
# Why: one flow for every agent; what differs lives in agents/<name>/.
# Usage: md.command <agent> [home|dir] [uuid] [-append suffix]
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/export/begin.sh" md "$@"   # sets AGENT_DIR, SESSION_ID, EXPORT_FILE, TARGET_DIR

if [[ -x "$AGENT_DIR/md.sh" ]]; then                        # agent whose session is not a plain file
  OUT="$("$AGENT_DIR/md.sh" "$SESSION_ID")" || exit 1       # hold output: failure must not leave empty dump
  printf '%s\n' "$OUT" > "$EXPORT_FILE"
else
  SESSION_FILE="$("$AGENT_DIR/session.sh" "$SESSION_ID")"
  if [[ -z "$SESSION_FILE" || ! -r "$SESSION_FILE" ]]; then
    echo "Error: no session found for ${AGENT_DIR##*/}" >&2; exit 1
  fi
  PYTHONDONTWRITEBYTECODE=1 python3 "$ROOT/dump/render.py" "$AGENT_DIR" "$SESSION_FILE" "$TARGET_DIR" > "$EXPORT_FILE"
fi
echo "Exported ${AGENT_DIR##*/} session to $EXPORT_FILE"
