#!/bin/bash
set -uo pipefail
# dumpjsonl-opencode.command — OpenCode session export to Old Chats/ as .jsonl.
# Why: pairs with dumpchat-opencode.command so /dumpboth opencode gets .md + .jsonl on one name.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.
# Usage: dumpjsonl-opencode.command [home] [-append -suffix] [target_dir]

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
FINDER_DIR="$SCRIPT_DIR/../dumpchat"
python3 "$FINDER_DIR/opencode-export.py" "$EXPORT_FILE" >/dev/null || exit 1
echo "Exported OpenCode jsonl to $EXPORT_FILE"
