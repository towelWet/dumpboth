#!/bin/bash
# child_guard.sh — handle CLAUDE_CODE_CHILD_SESSION: check if JSONL is real.
# Flag can be leaked env var (transcript exists) or real (no transcript).
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.

_dumpchat_child_guard() {
  DUMPCHAT_CHILD_SESSION=""
  [ -n "${CLAUDE_CODE_CHILD_SESSION:-}" ] || return 0           # no flag, nothing to do
  [ -n "${CLAUDE_CODE_SESSION_ID:-}" ] || return 0              # no ID to check

  local projects_dir session_file
  projects_dir="$(dumpchat_realpath "$HOME/.claude/projects")"
  session_file=$(find "$projects_dir" -type f -name "${CLAUDE_CODE_SESSION_ID}*.jsonl" 2>/dev/null | head -1)

  if [ -n "$session_file" ] && [ -r "$session_file" ]; then     # file exists — check age
    local file_age now mtime
    now=$(date +%s)
    mtime=$(stat -f '%m' "$session_file" 2>/dev/null || echo 0)
    file_age=$(( now - mtime ))
    if [ "$file_age" -lt 3600 ]; then                           # modified in last hour = active
      echo "⚠ CLAUDE_CODE_CHILD_SESSION set but JSONL is active (${file_age}s old) — using it." >&2
      return 0                                                  # proceed normally with SESSION_ID
    fi
  fi

  echo "⚠ No active JSONL for session $CLAUDE_CODE_SESSION_ID." >&2
  echo "  Skipping SESSION_ID, falling through to newest-file scan." >&2
  DUMPCHAT_CHILD_SESSION=1                                      # skip SESSION_ID shortcut
  return 0                                                      # never hard-block
}
