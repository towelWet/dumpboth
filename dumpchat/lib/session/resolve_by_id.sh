#!/bin/bash
# resolve_by_id.sh — find session file by explicit UUID across all CLI dirs.
# Expects: realpath.sh and finder_find_by_id.sh already sourced.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.

_dumpchat_resolve_by_id() {
  local want_id="$1"
  local dir found
  for dir in \
    "$(dumpchat_realpath "$HOME/.claude/projects")" \
    "$HOME/.codex/sessions" "$HOME/.gemini/tmp" \
    "$HOME/.kilocode/storage/session" "$HOME/.kilo/storage/session" \
    "$HOME/.opencode" "$HOME/.god/sessions"; do
    [ -d "$dir" ] || continue
    found=$(find "$dir" -type f -name "${want_id}*.jsonl" 2>/dev/null | head -1)
    if [ -n "$found" ] && [ -f "$found" ]; then echo "$found"; return 0; fi
    if [[ "$dir" == *".claude/projects"* ]]; then
      found=$(dumpchat_finder_find_by_id "$dir" "$want_id")
      if [ -n "$found" ] && [ -r "$found" ]; then echo "$found"; return 0; fi
    fi
  done
  return 1
}
