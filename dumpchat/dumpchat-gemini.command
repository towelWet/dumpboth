#!/bin/bash
set -uo pipefail
# dumpchat-gemini.command — thin orchestrator: dump most recent Gemini CLI session.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/lib/shared/parse_simple_args.sh" "$@"      # sets APPEND_SUFFIX, TARGET_DIR
source "$SCRIPT_DIR/lib/shared/setup_old_chats.sh"              # blocks scam dir, sets OLD_CHATS_DIR
source "$SCRIPT_DIR/lib/session/find_gemini.sh"                 # provides find_gemini_session()
find_gemini_session || { echo "Error: No Gemini session found in ~/.gemini/tmp/"; exit 1; }
source "$SCRIPT_DIR/lib/shared/next_number.sh"                  # sets NEXT_NUM
EXPORT_EXT=md source "$SCRIPT_DIR/lib/shared/export_path.sh"    # sets EXPORT_FILE

python3 "$SCRIPT_DIR/lib/parse_session.py" "$SESSION_FILE" gemini "$TARGET_DIR" > "$EXPORT_FILE"
echo "Exported session to $EXPORT_FILE (gemini)"
