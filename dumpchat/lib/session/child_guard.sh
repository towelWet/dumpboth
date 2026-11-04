#!/bin/bash
# child_guard.sh — block dump in child/resumed session where JSONL belongs to parent.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.

_dumpchat_child_guard() {
  if [ -n "${CLAUDE_CODE_SESSION_ID:-}" ] && [ -n "${CLAUDE_CODE_CHILD_SESSION:-}" ]; then
    echo "ERROR: transcript saving is off (child/resumed session)." >&2
    echo "JSONL $CLAUDE_CODE_SESSION_ID belongs to parent session — current work is not in it." >&2
    echo "Start a fresh session (not --resume) so transcript saving is on, then dump." >&2
    return 1
  fi
  return 0
}
