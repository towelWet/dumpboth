#!/bin/bash
# md.sh — print newest Devin CLI session as readable markdown.
# Why: Devin keeps sessions in SQLite; pipeline reads, removes noise, then renders.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
DB="$("$HERE/locate-db")" || exit 1
SESSION="$("$HERE/select-session.py" "$DB")" || exit 1
ID="$(python3 "$HERE/session_field.py" id <<< "$SESSION")"
MODEL="$(python3 "$HERE/session_field.py" model <<< "$SESSION")"
TITLE="$(python3 "$HERE/session_field.py" title <<< "$SESSION")"
"$HERE/read-messages.py" "$DB" "$ID" | "$HERE/normalize-messages.py" \
  | "$HERE/render-markdown.py" --model "$MODEL" --title "$TITLE" --dir "$(pwd)"
printf '\nResume: devin ls --select %s\nSession: %s\n' "$ID" "$ID"
