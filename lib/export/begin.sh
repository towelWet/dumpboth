#!/bin/bash
# begin.sh — shared start of every dump: read args, guard folder, pick numbered file name.
# Why: same steps were pasted into a dozen scripts and had begun to drift. Sourced, not run.
# Args: <md|jsonl> <agent> [home|dir] [uuid] [-append suffix]. Sets ROOT, AGENT_DIR, SESSION_ID, TARGET_DIR, EXPORT_FILE.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.
EXT="$1"; AGENT="$2"; shift 2
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
AGENT_DIR="$ROOT/agents/$AGENT"
if [[ ! -d "$AGENT_DIR" ]]; then
  echo "Error: unknown agent: $AGENT" >&2; exit 1
fi
source "$ROOT/lib/args/parse_dump_args.sh"
parse_dump_args "$@"                                        # sets TARGET_DIR, APPEND_SUFFIX, SESSION_ID
source "$ROOT/lib/block/refuse_blocked_dir.sh"
refuse_blocked_dir "$TARGET_DIR"
OLD_CHATS="$TARGET_DIR/Old Chats"
mkdir -p "$OLD_CHATS"
NUMBER="${DUMP_FORCE_NUM:-$(python3 "$ROOT/lib/counter/shared_next_number.py" "$OLD_CHATS")}"   # dumpboth forces one number per pair
EXPORT_FILE="$OLD_CHATS/oldchat$NUMBER${APPEND_SUFFIX:+-$APPEND_SUFFIX}.$EXT"
