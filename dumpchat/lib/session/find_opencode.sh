#!/bin/bash
# find_opencode.sh — find most recent OpenCode session file.
# Sets: SESSION_FILE. Checks jsonl in sessions/, root, then hierarchical JSON.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.

find_opencode_session() {
  SESSION_FILE=""
  local newest

  # Step 1: JSONL in ~/.opencode/sessions/
  if [ -d "$HOME/.opencode/sessions" ]; then
    newest=$(find "$HOME/.opencode/sessions" -type f -name "*.jsonl" -print0 2>/dev/null \
      | xargs -0 stat -f '%m %N' 2>/dev/null | sort -rn | head -1 | awk '{print $2}')
    [ -n "$newest" ] && [ -f "$newest" ] && SESSION_FILE="$newest" && return 0
  fi

  # Step 2: JSONL in root ~/.opencode/
  newest=$(find "$HOME/.opencode" -maxdepth 1 -type f -name "*.jsonl" -print0 2>/dev/null \
    | xargs -0 stat -f '%m %N' 2>/dev/null | sort -rn | head -1 | awk '{print $2}')
  [ -n "$newest" ] && [ -f "$newest" ] && SESSION_FILE="$newest" && return 0

  # Step 3: Hierarchical JSON in storage/session/message/
  local hier="$HOME/.opencode/storage/session/message"
  if [ -d "$hier" ]; then
    newest=$(find "$hier" -type f -name "*.json" -print0 2>/dev/null \
      | xargs -0 stat -f '%m %N' 2>/dev/null | sort -rn | head -1 | awk '{print $2}')
    [ -n "$newest" ] && [ -f "$newest" ] && SESSION_FILE="$newest" && return 0
  fi
  return 1
}
