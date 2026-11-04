#!/bin/bash
# parse_target.sh — parse home/append/uuid/dir/suffix from remaining args.
# Expects: DUMPBOTH_REMAINING_ARGS (from parse_mode.sh), USER_SUFFIX (may be prefilled).
# Sets: TARGET_DIR, EXPLICIT_TARGET, PASSTHROUGH_ARGS, USER_SUFFIX (final).
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.

UUID_RE='^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
TARGET_DIR="$HOME"                                              # pwd minted oldchat1–3 in project folder on 2026-10-23
EXPLICIT_TARGET=0                                               # 1 only when user named home or a directory
PASSTHROUGH_ARGS=()

set -- "${DUMPBOTH_REMAINING_ARGS[@]}"                          # reload positional params

while [[ $# -gt 0 ]]; do
  case "$1" in
    home)           TARGET_DIR="$HOME"; EXPLICIT_TARGET=1; PASSTHROUGH_ARGS+=("home"); shift ;;
    append|-append) shift; USER_SUFFIX="${1:-}"; USER_SUFFIX="${USER_SUFFIX#-}"; shift ;;
    *)              if [[ "$1" =~ $UUID_RE || -d "$1" ]]; then
                      [[ -d "$1" ]] && EXPLICIT_TARGET=1 && TARGET_DIR="$1"
                      PASSTHROUGH_ARGS+=("$1")
                    else
                      USER_SUFFIX="${1#-}"                      # bare word = suffix shorthand
                    fi
                    shift ;;
  esac
done
