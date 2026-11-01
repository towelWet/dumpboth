#!/bin/bash
# md.sh — print OpenCode session as readable markdown.
# Why: renders from same export as raw.sh, so .md and .jsonl describe same session.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.
HERE="$(dirname "$0")"
RAW="$(python3 "$HERE/export.py" /dev/stdout 2>/dev/null)" || { echo "Error: no OpenCode session found" >&2; exit 1; }
printf '%s\n' "$RAW" | python3 "$HERE/render_md.py" /dev/stdin
