#!/bin/bash
# check_results.sh — verify at least one dumper succeeded, report result.
# Expects: CHAT_RC, JSONL_RC, CURSOR_MODE, DEVIN_MODE, TAG, NEXT_NUM.
# Exits 1 if both dumpers failed. Prints summary on success.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.

if [[ "$CHAT_RC" -ne 0 && "$JSONL_RC" -ne 0 ]]; then
  echo "dumpboth: BOTH dumpers failed (chat=$CHAT_RC, jsonl=$JSONL_RC) — no files written" >&2
  exit 1
fi

MODE=cli
[[ $CURSOR_MODE -eq 1 ]] && MODE=cursor
[[ $DEVIN_MODE -eq 1 ]] && MODE=devin
echo "dumpboth: tag=$TAG number=$NEXT_NUM mode=$MODE"
