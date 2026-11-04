#!/bin/bash
# find_gemini.sh — find most recent Gemini CLI session file (with content check).
# Sets: SESSION_FILE.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.

find_gemini_session() {
  SESSION_FILE=""
  [ -d "$HOME/.gemini/tmp" ] || return 1

  local all_candidates=""
  while IFS= read -r -d '' file; do
    local mtime; mtime=$(stat -f '%m' "$file" 2>/dev/null)
    [ -n "$mtime" ] && all_candidates+="$mtime $file"$'\n'
  done < <(find "$HOME/.gemini/tmp" -type f -name "session-*.jsonl" -print0 2>/dev/null)

  # Try 5 most recent, pick first with actual user/gemini messages
  while IFS= read -r candidate; do
    local cfile; cfile=$(echo "$candidate" | awk '{print $2}')
    [ -n "$cfile" ] && [ -f "$cfile" ] || continue
    local has_content; has_content=$(python3 -c "
import json
try:
    with open('$cfile') as f:
        for line in f:
            line=line.strip()
            if not line: continue
            try:
                d=json.loads(line)
                if d.get('type','') in ('user','gemini','assistant'): print('found'); break
            except: pass
except: pass
" 2>/dev/null)
    if [ "$has_content" = "found" ]; then SESSION_FILE="$cfile"; return 0; fi
  done < <(echo "$all_candidates" | sort -rn | head -5)

  # Fallback: newest regardless of content
  SESSION_FILE=$(echo "$all_candidates" | sort -rn | head -1 | awk '{print $2}')
  [ -n "$SESSION_FILE" ] && [ -f "$SESSION_FILE" ] && return 0
  return 1
}
