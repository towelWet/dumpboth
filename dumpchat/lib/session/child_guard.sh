#!/bin/bash
# child_guard.sh — when CLAUDE_CODE_CHILD_SESSION is set, search for real JSONL.
# SESSION_ID points at parent's JSONL (wrong chat). Search by content instead.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.

_dumpchat_child_guard() {
  DUMPCHAT_CHILD_SESSION=""
  [ -n "${CLAUDE_CODE_CHILD_SESSION:-}" ] || return 0           # no flag, proceed normally

  echo "⚠ CLAUDE_CODE_CHILD_SESSION is set — SESSION_ID points at parent." >&2
  echo "  Searching for this session's real JSONL..." >&2

  # Claude Code may not be writing this session to disk at all.
  # Check if ANY live JSONL was modified in the last 5 minutes (active session).
  local projects_dir newest_file newest_age now
  projects_dir="$(dumpchat_realpath "$HOME/.claude/projects")" 2>/dev/null || projects_dir="$HOME/.claude/projects"
  now=$(date +%s)

  newest_file=$(find "$projects_dir" -type f -name "*.jsonl" -newer /tmp/.dumpchat_5min_marker 2>/dev/null | head -1)
  # Create a 5-minute marker for find -newer
  touch -t "$(date -v-5M '+%Y%m%d%H%M.%S' 2>/dev/null || date -d '5 minutes ago' '+%Y%m%d%H%M.%S' 2>/dev/null)" /tmp/.dumpchat_5min_marker 2>/dev/null

  newest_file=$(find "$projects_dir" -type f -name "*.jsonl" -newer /tmp/.dumpchat_5min_marker 2>/dev/null | head -1)

  if [ -n "$newest_file" ] && [ -r "$newest_file" ]; then
    # Found a recently modified JSONL — but is it THIS session or the parent?
    # If it's the SESSION_ID file, it's the parent (wrong). Skip it.
    local parent_id="${CLAUDE_CODE_SESSION_ID:-}"
    local newest_basename; newest_basename=$(basename "$newest_file" .jsonl)
    if [[ "$newest_basename" == "$parent_id"* ]]; then
      echo "  Only active JSONL is parent's ($parent_id) — this session has no transcript." >&2
    else
      echo "  Found active JSONL: $newest_file" >&2
      DUMPCHAT_FOUND_FILE="$newest_file"                        # caller can use this
      return 0
    fi
  fi

  echo "" >&2
  echo "═══ CANNOT DUMP: no transcript for this session ═══" >&2
  echo "" >&2
  echo "CLAUDE_CODE_CHILD_SESSION is set. Claude Code is NOT writing" >&2
  echo "this conversation to any JSONL file on disk." >&2
  echo "" >&2
  echo "Fix for future sessions:" >&2
  echo "  1. Open a NEW terminal tab/window" >&2
  echo "  2. unset CLAUDE_CODE_CHILD_SESSION" >&2
  echo "  3. Start Claude Code fresh" >&2
  echo "" >&2
  echo "═══════════════════════════════════════════════════" >&2
  return 1
}
