#!/bin/bash
# parse_uuid_args.sh — parse args with UUID support: home, -append, uuid, target_dir.
# Used by Claude/Cursor dumpers that accept session UUIDs.
# Sets: APPEND_SUFFIX, TARGET_DIR, SESSION_ID.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.

APPEND_SUFFIX=""
TARGET_DIR="$HOME"                                              # never shell cwd
SESSION_ID=""
UUID_RE='^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'

while [[ $# -gt 0 ]]; do
  case "$1" in
    home)           TARGET_DIR="$HOME"; shift ;;
    -append|append) shift; APPEND_SUFFIX="${1:-}"; APPEND_SUFFIX="${APPEND_SUFFIX#-}"; shift ;;
    id|-id|--id)    shift; SESSION_ID="${1:-}"; shift ;;        # explicit `id <ID>` form, same as bare uuid
    *)              [[ "$1" =~ $UUID_RE ]] && SESSION_ID="$1" || TARGET_DIR="$1"; shift ;;
  esac
done
