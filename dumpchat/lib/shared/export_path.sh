#!/bin/bash
# export_path.sh — build EXPORT_FILE from number + suffix.
# Expects: OLD_CHATS_DIR, NEXT_NUM, APPEND_SUFFIX.
# Sets: EXPORT_FILE. Caller passes extension via EXPORT_EXT (default: md).
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.

EXPORT_EXT="${EXPORT_EXT:-md}"
[[ -n "$APPEND_SUFFIX" ]] \
  && EXPORT_FILE="$OLD_CHATS_DIR/oldchat${NEXT_NUM}-${APPEND_SUFFIX}.${EXPORT_EXT}" \
  || EXPORT_FILE="$OLD_CHATS_DIR/oldchat${NEXT_NUM}.${EXPORT_EXT}"
