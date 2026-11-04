#!/bin/bash
# next_number.sh — compute next oldchatN number, respecting DUMP_FORCE_NUM.
# Expects: OLD_CHATS_DIR. Sets: NEXT_NUM.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.

if [[ -n "${DUMP_FORCE_NUM:-}" ]]; then
  NEXT_NUM="$DUMP_FORCE_NUM"                                    # /dumpboth locks md+jsonl to same number
else
  NEXT_NUM=0
  for file in "$OLD_CHATS_DIR"/oldchat*.md "$OLD_CHATS_DIR"/oldchat*.jsonl; do
    [[ -f "$file" ]] || continue
    NUM=$(basename "$file" | sed 's/oldchat\([0-9]*\).*/\1/')
    [[ "$NUM" -ge "$NEXT_NUM" ]] 2>/dev/null && NEXT_NUM=$NUM
  done
  NEXT_NUM=$((NEXT_NUM + 1))
fi
