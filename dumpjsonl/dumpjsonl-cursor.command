#!/bin/bash
set -uo pipefail
# dumpjsonl-cursor.command — thin orchestrator: verbatim Cursor IDE jsonl export.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DUMPCHAT_DIR="$SCRIPT_DIR/../dumpchat"

source "$DUMPCHAT_DIR/lib/shared/parse_uuid_args.sh" "$@"      # sets APPEND_SUFFIX, TARGET_DIR, SESSION_ID
source "$DUMPCHAT_DIR/lib/shared/setup_old_chats.sh"            # blocks scam dir, sets OLD_CHATS_DIR
source "$DUMPCHAT_DIR/cursor-session-find.sh"                   # provides cursor_resolve_session()
cursor_resolve_session "$SESSION_ID"

[[ -z "${SESSION_FILE:-}" || ! -r "$SESSION_FILE" ]] && {
  echo "Error: No Cursor main session jsonl found"; exit 1; }

source "$DUMPCHAT_DIR/lib/shared/next_number.sh"                # sets NEXT_NUM
EXPORT_EXT=jsonl source "$DUMPCHAT_DIR/lib/shared/export_path.sh"  # sets EXPORT_FILE

cp "$SESSION_FILE" "$EXPORT_FILE"                               # verbatim copy
echo "Exported raw Cursor jsonl to $EXPORT_FILE"
echo "Source: $SESSION_FILE"
echo "Resume: cursor agent --resume $SESSION_ID"
