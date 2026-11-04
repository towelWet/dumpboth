#!/bin/bash
set -uo pipefail
# dumpchat-cursor.command — thin orchestrator: dump Cursor IDE agent session.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/lib/shared/parse_uuid_args.sh" "$@"        # sets APPEND_SUFFIX, TARGET_DIR, SESSION_ID
source "$SCRIPT_DIR/lib/shared/setup_old_chats.sh"              # blocks scam dir, sets OLD_CHATS_DIR
source "$SCRIPT_DIR/cursor-session-find.sh"                     # provides cursor_resolve_session()
cursor_resolve_session "$SESSION_ID"

if [[ -z "${SESSION_FILE:-}" || ! -f "$SESSION_FILE" ]]; then
  echo "Error: No Cursor main session jsonl found under ~/.cursor/projects/*/agent-transcripts/"
  exit 1
fi

source "$SCRIPT_DIR/lib/shared/next_number.sh"                  # sets NEXT_NUM
EXPORT_EXT=md source "$SCRIPT_DIR/lib/shared/export_path.sh"    # sets EXPORT_FILE

python3 "$SCRIPT_DIR/lib/parse_session.py" "$SESSION_FILE" cursor "$TARGET_DIR" > "$EXPORT_FILE"
echo "Exported Cursor session to $EXPORT_FILE"
