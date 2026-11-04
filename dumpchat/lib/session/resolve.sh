#!/bin/bash
# resolve.sh — orchestrator: resolve session file via UUID, env var, or newest.
# Sources single-purpose helpers; each concern in its own file.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.

_SESSION_LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_SESSION_LIB/realpath.sh"                              # portable realpath
source "$_SESSION_LIB/finder_find_by_id.sh"                     # Finder EPERM fallback
source "$_SESSION_LIB/claude_candidates.sh"                     # list Claude jsonls
source "$_SESSION_LIB/resolve_by_id.sh"                         # UUID lookup across CLIs
source "$_SESSION_LIB/child_guard.sh"                           # child session search + refuse
source "$_SESSION_LIB/resolve_claude.sh"                        # newest Claude session
source "$_SESSION_LIB/resolve_fallback.sh"                      # newest non-Claude session

dumpchat_resolve_session_file() {
  local want_id="${1:-}"

  if [ -n "$want_id" ]; then                                    # explicit UUID requested
    _dumpchat_resolve_by_id "$want_id"; return $?
  fi

  _dumpchat_child_guard || return 1                             # searches, refuses if nothing

  if [ -n "${DUMPCHAT_FOUND_FILE:-}" ]; then                    # child guard found a non-parent JSONL
    echo "$DUMPCHAT_FOUND_FILE"; return 0
  fi

  if [ -n "${CLAUDE_CODE_SESSION_ID:-}" ]; then                 # normal session, use env var
    _dumpchat_resolve_by_id "$CLAUDE_CODE_SESSION_ID" && return 0
  fi

  _dumpchat_resolve_claude && return 0                          # Claude-first newest scan
  _dumpchat_resolve_fallback                                    # other CLIs as fallback
}
