#!/bin/bash
# parse_simple_args.sh — parse basic dumpchat args: home, -append, target_dir.
# Used by CLI-specific dumpers (opencode, gemini, codex, kilo).
# Sets: APPEND_SUFFIX, TARGET_DIR.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.

APPEND_SUFFIX=""
TARGET_DIR="$HOME"                                              # never shell cwd

while [[ $# -gt 0 ]]; do
  case "$1" in
    home)           TARGET_DIR="$HOME"; shift ;;
    -append|append) shift; APPEND_SUFFIX="${1:-}"; APPEND_SUFFIX="${APPEND_SUFFIX#-}"; shift ;;
    *)              TARGET_DIR="$1"; shift ;;
  esac
done
