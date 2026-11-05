#!/bin/bash
# parse_simple_args.sh — parse basic dumpchat args: home, -append, id, target_dir.
# Used by CLI-specific dumpers (opencode, gemini, codex, kilo).
# Sets: APPEND_SUFFIX, TARGET_DIR, SESSION_ID (exact session to dump; empty = use CLI env var).
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.

APPEND_SUFFIX=""
TARGET_DIR="$HOME"                                              # never shell cwd
SESSION_ID=""                                                   # finders refuse when this AND env ID are empty

while [[ $# -gt 0 ]]; do
  case "$1" in
    home)           TARGET_DIR="$HOME"; shift ;;
    -append|append) shift; APPEND_SUFFIX="${1:-}"; APPEND_SUFFIX="${APPEND_SUFFIX#-}"; shift ;;
    id|-id|--id)    shift; SESSION_ID="${1:-}"; shift ;;        # `id <ID>` — IDs aren't always UUIDs (devin, opencode)
    *)              TARGET_DIR="$1"; shift ;;
  esac
done
