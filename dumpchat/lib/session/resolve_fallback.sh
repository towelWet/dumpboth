#!/bin/bash
# resolve_fallback.sh — scan non-Claude CLI dirs for newest session file.
# Called when Claude sessions yield nothing.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.

_dumpchat_resolve_fallback() {
  local candidates="" dir line candidate
  for dir in "$HOME/.codex/sessions" "$HOME/.gemini/tmp" "$HOME/.kilocode/storage/session" \
    "$HOME/.kilo/storage/session" "$HOME/.opencode" "$HOME/.god/sessions"; do
    [ -d "$dir" ] || continue
    while IFS= read -r -d '' file; do
      local mtime; mtime=$(stat -f '%m' "$file" 2>/dev/null) || continue
      candidates+=$'\n'"$mtime $file"
    done < <(find "$dir" -type f \( -name "*.jsonl" -o -name "*.json" -o -name "*.txt" \) -print0 2>/dev/null)
  done
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    candidate="${line#* }"
    [ -z "$candidate" ] || [ ! -r "$candidate" ] && continue
    if command grep -q "Hello memory agent" "$candidate" 2>/dev/null; then continue; fi
    echo "$candidate"; return 0
  done < <(printf '%s\n' "$candidates" | sort -rn)
  return 1
}
