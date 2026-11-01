#!/bin/bash
# raw.sh — write OpenCode session as JSONL to given file.
# Why: sessions live in SQLite; official export command is stable way out. Set OPENCODE_SESSION_ID for exact session.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.
python3 "$(dirname "$0")/export.py" "$2"
