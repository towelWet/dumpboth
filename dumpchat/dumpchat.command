#!/bin/bash
set -uo pipefail
# dumpchat.command — thin orchestrator: export current CLI session to Old Chats/oldchatN.md
# NEVER DELETE COMMENTS — parsing logic lives in lib/; see lib/parse_session.py
# Update comments with the code; do not strip them.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/lib/shared/parse_uuid_args.sh" "$@"        # sets APPEND_SUFFIX, TARGET_DIR, SESSION_ID
source "$SCRIPT_DIR/lib/shared/setup_old_chats.sh"              # blocks scam dir, sets OLD_CHATS_DIR

source "$SCRIPT_DIR/dumpchat-session-find.sh"                   # provides dumpchat_resolve_session_file()
if [[ -n "$SESSION_ID" ]]; then
  SESSION_FILE="$(dumpchat_resolve_session_file "$SESSION_ID")" || true
else
  SESSION_FILE="$(dumpchat_resolve_session_file)" || true
fi
[[ -z "${SESSION_FILE:-}" || ! -r "$SESSION_FILE" ]] && { echo "Error: No session file found"; exit 1; }

# Detect CLI type from session path
CLI_TYPE="unknown"
case "$SESSION_FILE" in
  *"/.claude/"*)   CLI_TYPE="claude" ;;
  *"/.codex/"*)    CLI_TYPE="codex" ;;
  *"/.gemini/"*)   CLI_TYPE="gemini" ;;
  *"/.kilocode/"*|*"/.kilo/"*) CLI_TYPE="kilo" ;;
  *"/.opencode/"*) CLI_TYPE="opencode" ;;
  *"/.god/"*)      CLI_TYPE="god" ;;
esac

source "$SCRIPT_DIR/lib/shared/next_number.sh"                  # sets NEXT_NUM
EXPORT_EXT=md source "$SCRIPT_DIR/lib/shared/export_path.sh"    # sets EXPORT_FILE

python3 "$SCRIPT_DIR/lib/parse_session.py" "$SESSION_FILE" "$CLI_TYPE" "$TARGET_DIR" > "$EXPORT_FILE"
echo "Exported session to $EXPORT_FILE"
