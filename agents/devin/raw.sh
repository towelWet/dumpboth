#!/bin/bash
# raw.sh — write newest Devin CLI session's message nodes to given file, untouched.
# Why: this is verbatim record; md.sh makes the readable one.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
DB="$("$HERE/locate-db")" || exit 1
SESSION="$("$HERE/select-session.py" "$DB")" || exit 1
ID="$(python3 "$HERE/session_field.py" id <<< "$SESSION")"
"$HERE/read-raw.py" "$DB" "$ID" > "$2"
