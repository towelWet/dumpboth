#!/bin/bash
# resolve.sh — orchestrator: resolve session file by EXACT ID only (arg or env var).
# NEVER picks "newest"/recent JSONL — that heuristic dumped wrong chats (oldchat694 = dup of 693).
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.

_SESSION_LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_SESSION_LIB/realpath.sh"                              # portable realpath
source "$_SESSION_LIB/finder_find_by_id.sh"                     # Finder EPERM fallback
source "$_SESSION_LIB/resolve_by_id.sh"                         # UUID lookup across CLIs
source "$_SESSION_LIB/child_guard.sh"                           # refuse if CHILD flag + no own ID
# resolve_claude.sh / resolve_fallback.sh (newest-mtime scans) intentionally NOT sourced — banned 2026-11-05.

dumpchat_resolve_session_file() {
  local want_id="${1:-${CLAUDE_CODE_SESSION_ID:-}}"            # explicit uuid arg wins, else this session's env ID

  _dumpchat_child_guard "$want_id" || return 1                  # informational under CHILD flag; refuses only if no ID

  if [ -z "$want_id" ]; then                                    # no ID at all → refuse, never guess
    echo "═══ CANNOT DUMP: no session ID (CLAUDE_CODE_SESSION_ID unset, no uuid arg) ═══" >&2
    echo "  Pass uuid explicitly: dumpboth.command home <uuid>" >&2
    return 1
  fi

  _dumpchat_resolve_by_id "$want_id" && return 0                # exact file for that ID
  echo "═══ CANNOT DUMP: no JSONL found for session $want_id ═══" >&2
  return 1                                                      # refuse — no newest fallback
}
