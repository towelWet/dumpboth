#!/bin/bash
# resolve_claude.sh — find newest non-memory Claude session JSONL.
# Expects: claude_candidates.sh already sourced.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.

_dumpchat_resolve_claude() {
  local candidates line candidate
  candidates="$(dumpchat_claude_jsonl_candidates)"              # mtime-prefixed lines
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    candidate="${line#* }"                                      # strip mtime prefix
    [ -z "$candidate" ] || [ ! -r "$candidate" ] && continue
    if command grep -q "Hello memory agent" "$candidate" 2>/dev/null; then continue; fi
    echo "$candidate"; return 0                                 # newest non-memory wins
  done < <(printf '%s\n' "$candidates" | sort -rn)
  return 1
}
