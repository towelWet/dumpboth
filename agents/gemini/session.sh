#!/bin/bash
# session.sh — print current Gemini CLI session file.
# Why: fresh session may hold only metadata, so prefer newest of last 5 with real messages.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.
ROOT="$HOME/.gemini/tmp"
[[ -d "$ROOT" ]] || exit 1
NEWEST=()
while IFS= read -r FILE; do NEWEST+=("$FILE"); done < <(    # path-with-spaces safe
  find -L "$ROOT" -type f -name 'session-*.jsonl' -print0 2>/dev/null \
    | xargs -0 stat -f '%m %N' 2>/dev/null | sort -rn | head -5 | cut -d' ' -f2-)
[[ ${#NEWEST[@]} -gt 0 ]] || exit 1
for FILE in "${NEWEST[@]}"; do
  awk '/"type": ?"(user|gemini)"/ { hit = 1; exit } END { exit !hit }' "$FILE" && { echo "$FILE"; exit 0; }
done
echo "${NEWEST[0]}"                                         # none has messages yet: newest anyway
