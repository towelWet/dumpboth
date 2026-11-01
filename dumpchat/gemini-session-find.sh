#!/bin/bash
# gemini-session-find.sh — print path of current Gemini CLI session (.jsonl).
# Why: dumpchat-gemini (.md) and dumpjsonl-gemini (.jsonl) must pick the SAME session,
#      so both source this one finder instead of each guessing.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.

gemini_session_file() {
  local root="$HOME/.gemini/tmp" file
  [[ -d "$root" ]] || return 1
  local newest=()                                              # 5 newest by mtime, path-with-spaces safe
  while IFS= read -r file; do newest+=("$file"); done < <(
    find -L "$root" -type f -name "session-*.jsonl" -print0 2>/dev/null \
      | xargs -0 stat -f '%m %N' 2>/dev/null | sort -rn | head -5 | cut -d' ' -f2-)
  [[ ${#newest[@]} -gt 0 ]] || return 1
  for file in "${newest[@]}"; do                               # fresh session may hold only metadata so far
    awk '/"type": ?"(user|gemini)"/ { hit = 1; exit } END { exit !hit }' "$file" \
      && { echo "$file"; return 0; }                           # awk: no rg/grep dependency for end users
  done
  echo "${newest[0]}"                                          # none has messages yet → newest anyway
}
