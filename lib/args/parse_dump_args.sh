#!/bin/bash
# parse_dump_args.sh — read args of md.command and jsonl.command.
# Why: default is always home, never pwd: a leftover shell folder is not an archive.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.
source "$(dirname "${BASH_SOURCE[0]}")/uuid_pattern.sh"

parse_dump_args() {
  TARGET_DIR="$HOME"; APPEND_SUFFIX=""; SESSION_ID=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      home)           TARGET_DIR="$HOME"; shift ;;
      -append|append) APPEND_SUFFIX="${2:-}"; APPEND_SUFFIX="${APPEND_SUFFIX#-}"; shift 2 ;;
      *)              if [[ "$1" =~ $UUID_RE ]]; then SESSION_ID="$1"; else TARGET_DIR="$1"; fi; shift ;;
    esac
  done
}
