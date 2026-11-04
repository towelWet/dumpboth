#!/bin/bash
# build_suffix.sh — compute NEXT_NUM, TAG, and FINAL_SUFFIX.
# Expects: DUMPBOTH_SCRIPT_DIR, OLD_CHATS_DIR, USER_SUFFIX.
# Exports: NEXT_NUM, TAG, FINAL_SUFFIX.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.

NEXT_NUM="$(python3 "$DUMPBOTH_SCRIPT_DIR/lib/counter/shared_next_number.py" "$OLD_CHATS_DIR")"
TAG="$(python3 "$DUMPBOTH_SCRIPT_DIR/lib/tag/generate_tag.py")"

if [[ -n "$USER_SUFFIX" ]]; then
  FINAL_SUFFIX="${USER_SUFFIX}-${TAG}"                          # user label + random tag
else
  FINAL_SUFFIX="$TAG"                                           # random tag only
fi
