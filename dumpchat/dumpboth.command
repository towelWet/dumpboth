#!/bin/bash
set -uo pipefail
# dumpboth.command (dumpchat/) — legacy thin orchestrator: dump md + jsonl same number.
# NOTE: prefer top-level dumpboth.command which has tag matching + desync detection.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/lib/shared/parse_uuid_args.sh" "$@"        # sets APPEND_SUFFIX, TARGET_DIR, SESSION_ID
source "$SCRIPT_DIR/lib/shared/setup_old_chats.sh"              # blocks scam dir, sets OLD_CHATS_DIR
source "$SCRIPT_DIR/lib/shared/next_number.sh"                  # sets NEXT_NUM

# 1. MD dump via dumpchat.command (force same number)
DUMP_ARGS=()
[[ "$TARGET_DIR" == "$HOME" ]] && DUMP_ARGS+=(home)
[[ -n "$APPEND_SUFFIX" ]] && DUMP_ARGS+=(-append "-$APPEND_SUFFIX")
[[ -n "$SESSION_ID" ]] && DUMP_ARGS+=("$SESSION_ID")
DUMP_FORCE_NUM="$NEXT_NUM" "$SCRIPT_DIR/dumpchat.command" ${DUMP_ARGS[@]+"${DUMP_ARGS[@]}"}

# 2. JSONL copy (same number, raw session file)
source "$SCRIPT_DIR/dumpchat-session-find.sh"
if [[ -n "$SESSION_ID" ]]; then
  SESSION_FILE="$(dumpchat_resolve_session_file "$SESSION_ID")" || true
else
  SESSION_FILE="$(dumpchat_resolve_session_file)" || true
fi
if [[ -n "${SESSION_FILE:-}" && -r "$SESSION_FILE" ]]; then
  EXPORT_EXT=jsonl DUMP_FORCE_NUM="$NEXT_NUM" source "$SCRIPT_DIR/lib/shared/export_path.sh"
  cp "$SESSION_FILE" "$EXPORT_FILE"
  echo "Copied JSONL to $EXPORT_FILE"
else
  echo "Warning: could not find session JSONL to copy"
fi
