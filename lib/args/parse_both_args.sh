#!/bin/bash
# parse_both_args.sh — read args of dumpboth.command.
# Why: agent names come from agents/ folders, so new agent needs no edit here.
# A bare word that is not folder or uuid is suffix: dumpboth codex mytag.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.
source "$(dirname "${BASH_SOURCE[0]}")/uuid_pattern.sh"

parse_both_args() {
  local agents="$1"; shift
  AGENT="claude"; SUFFIX=""; TARGET_DIR="$HOME"; SESSION_ID=""
  while [[ $# -gt 0 ]]; do
    if   [[ "$1" == "home" ]]; then TARGET_DIR="$HOME"
    elif [[ "$1" == "append" || "$1" == "-append" ]]; then shift; SUFFIX="${1:-}"; SUFFIX="${SUFFIX#-}"
    elif [[ "$1" =~ $UUID_RE ]]; then SESSION_ID="$1"
    elif [[ -d "$agents/$1" ]]; then AGENT="$1"
    elif [[ -d "$1" ]]; then TARGET_DIR="$1"
    else SUFFIX="${1#-}"; fi
    [[ $# -gt 0 ]] && shift
  done
}
