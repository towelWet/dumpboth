#!/bin/bash
# parse_mode.sh — detect cursor/devin mode + consume shorthand suffix.
# Expects: $1... (raw CLI args). Sets: CURSOR_MODE, DEVIN_MODE, USER_SUFFIX (partial).
# Shifts consumed args; remaining args left in DUMPBOTH_REMAINING_ARGS.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.

UUID_RE='^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
CURSOR_MODE=0
DEVIN_MODE=0
USER_SUFFIX=""
DUMPBOTH_REMAINING_ARGS=()

case "${1:-}" in
  cursor) CURSOR_MODE=1; shift
          # Shorthand: `dumpboth cursor mylabel` == append -mylabel
          if [[ $# -gt 0 && "$1" != "home" && "$1" != "append" && "$1" != "-append" && "$1" != "id" && ! "$1" =~ $UUID_RE && ! -d "$1" ]]; then
            USER_SUFFIX="${1#-}"; shift
          fi ;;
  devin)  DEVIN_MODE=1; shift
          # Shorthand: `dumpboth devin mylabel` == append -mylabel (`id` excluded: next token is session ID)
          if [[ $# -gt 0 && "$1" != "home" && "$1" != "append" && "$1" != "-append" && "$1" != "id" && ! "$1" =~ $UUID_RE && ! -d "$1" ]]; then
            USER_SUFFIX="${1#-}"; shift
          fi ;;
esac

DUMPBOTH_REMAINING_ARGS=("$@")                                  # pass unconsumed args downstream
