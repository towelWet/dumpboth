#!/bin/bash
set -uo pipefail
# dumpjsonl.command — thin orchestrator: export current CLI session as raw jsonl.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.
# WHY: /find-claude-chat and training pipelines read live jsonl; this dumps that exact file untouched.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DUMPCHAT_DIR="$SCRIPT_DIR/../dumpchat"

source "$DUMPCHAT_DIR/lib/shared/parse_uuid_args.sh" "$@"      # sets APPEND_SUFFIX, TARGET_DIR, SESSION_ID
source "$DUMPCHAT_DIR/lib/shared/setup_old_chats.sh"            # blocks scam dir, sets OLD_CHATS_DIR
source "$DUMPCHAT_DIR/dumpchat-session-find.sh"                 # provides dumpchat_resolve_session_file()

if [[ -n "$SESSION_ID" ]]; then
  SESSION_FILE="$(dumpchat_resolve_session_file "$SESSION_ID")" || true
else
  SESSION_FILE="$(dumpchat_resolve_session_file)" || true
fi
[[ -z "${SESSION_FILE:-}" || ! -r "$SESSION_FILE" ]] && { echo "Error: No session file found"; exit 1; }

source "$DUMPCHAT_DIR/lib/shared/next_number.sh"                # sets NEXT_NUM
EXPORT_EXT=jsonl source "$DUMPCHAT_DIR/lib/shared/export_path.sh"  # sets EXPORT_FILE

cp "$SESSION_FILE" "$EXPORT_FILE"                               # verbatim copy — no reformatting
echo "Exported raw jsonl to $EXPORT_FILE"
echo "Source: $SESSION_FILE"
