#!/bin/bash
# dispatch_pair.sh — run chat + jsonl dumper for active mode, capture exit codes.
# Expects: CURSOR_MODE, DEVIN_MODE, NEXT_NUM, FINAL_SUFFIX, PASSTHROUGH_ARGS,
# and all DUMP*_CMD vars from resolve_commands.sh.
# Exports: CHAT_RC, JSONL_RC.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.

set +u                                                          # "${arr[@]}" unbound under set -u when empty
CHAT_RC=0
JSONL_RC=0
if [[ "$CURSOR_MODE" -eq 1 ]]; then
  DUMP_FORCE_NUM="$NEXT_NUM" "$DUMPCHAT_CURSOR_CMD" "${PASSTHROUGH_ARGS[@]}" -append "$FINAL_SUFFIX" || CHAT_RC=$?
  DUMP_FORCE_NUM="$NEXT_NUM" "$DUMPJSONL_CURSOR_CMD" "${PASSTHROUGH_ARGS[@]}" -append "$FINAL_SUFFIX" || JSONL_RC=$?
elif [[ "$DEVIN_MODE" -eq 1 ]]; then
  DUMP_FORCE_NUM="$NEXT_NUM" "$DUMPCHAT_DEVIN_CMD" "${PASSTHROUGH_ARGS[@]}" -append "$FINAL_SUFFIX" || CHAT_RC=$?
  DUMP_FORCE_NUM="$NEXT_NUM" "$DUMPJSONL_DEVIN_CMD" "${PASSTHROUGH_ARGS[@]}" -append "$FINAL_SUFFIX" || JSONL_RC=$?
else
  DUMP_FORCE_NUM="$NEXT_NUM" "$DUMPCHAT_CMD" "${PASSTHROUGH_ARGS[@]}" -append "$FINAL_SUFFIX" || CHAT_RC=$?
  DUMP_FORCE_NUM="$NEXT_NUM" "$DUMPJSONL_CMD" "${PASSTHROUGH_ARGS[@]}" -append "$FINAL_SUFFIX" || JSONL_RC=$?
fi
set -u
