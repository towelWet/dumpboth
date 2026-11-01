#!/bin/bash
# session.sh — print Cursor main agent session: named uuid, else newest.
# Why: main session file is named after its folder; others are subagents.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.
ROOT="$HOME/.cursor/projects"
WANT="${1:-}"
if [[ -n "$WANT" ]]; then
  HIT="$(find "$ROOT" -path "*/agent-transcripts/$WANT/$WANT.jsonl" 2>/dev/null | head -1)"
  [[ -n "$HIT" ]] && { echo "$HIT"; exit 0; }
fi
NEWEST=""; NEWEST_TIME=0
while IFS= read -r FILE; do
  [[ "$(basename "$FILE" .jsonl)" == "$(basename "$(dirname "$FILE")")" ]] || continue
  TIME="$(stat -f '%m' "$FILE" 2>/dev/null || echo 0)"
  if [[ "$TIME" -ge "$NEWEST_TIME" ]]; then NEWEST_TIME="$TIME"; NEWEST="$FILE"; fi
done < <(find "$ROOT" -path '*/agent-transcripts/*/*.jsonl' ! -path '*/subagents/*' 2>/dev/null)
echo "$NEWEST"
