#!/bin/bash
# find_codex.sh — find most recent Codex CLI session file.
# Sets: SESSION_FILE.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.

find_codex_session() {
  SESSION_FILE=""
  if [ -d "$HOME/.codex/sessions" ]; then
    SESSION_FILE=$(find "$HOME/.codex/sessions" -type f -name "rollout-*.jsonl" -print0 2>/dev/null \
      | xargs -0 stat -f '%m %N' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)
  fi
  [ -n "$SESSION_FILE" ] && [ -f "$SESSION_FILE" ] && return 0
  return 1
}
