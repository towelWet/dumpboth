#!/bin/bash
# child_guard.sh — handle CLAUDE_CODE_CHILD_SESSION flag without guessing.
# Flag does NOT mean SESSION_ID is wrong: verified 2026-11-05, CHILD=1 sessions still
# write their own transcript to <SESSION_ID>.jsonl. Old guard ignored ID and grabbed
# arbitrary recent JSONL via `find | head -1` → dumped previous chat (oldchat694).
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.

_dumpchat_child_guard() {
  local want_id="${1:-}"                                        # ID resolve.sh is about to use
  [ -n "${CLAUDE_CODE_CHILD_SESSION:-}" ] || return 0           # no flag, nothing to check
  [ -n "$want_id" ] && return 0                                 # flag + ID → trust exact ID, no search

  echo "═══ CANNOT DUMP: CLAUDE_CODE_CHILD_SESSION set and no session ID ═══" >&2
  echo "  Refusing to guess by mtime. Pass uuid: dumpboth.command home <uuid>" >&2
  return 1                                                      # never fall back to newest/recent
}
