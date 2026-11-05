#!/bin/bash
# find_gemini.sh — find Gemini CLI session file for ONE exact session ID.
# ID source: `id <ID>` arg only (no Gemini env var known; CLI not installed to verify).
# Files: ~/.gemini/tmp/<proj>/chats/session-<timestamp>-<first 8 of ID>.jsonl; line 1 holds
# full "sessionId". Match filename by 8-char prefix, then confirm line 1 starts with that ID.
# NEVER picks newest — newest-mtime guessing dumped wrong chats (oldchat694). No ID → refuse.
# Sets: SESSION_FILE.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.

find_gemini_session() {
  SESSION_FILE=""
  local want="${SESSION_ID:-}" f hits=0
  [ -n "$want" ] || { echo "Refusing: no Gemini session ID (pass: id <ID>)" >&2; return 1; }
  while IFS= read -r -d '' f; do
    head -1 "$f" | command grep -qF "\"sessionId\":\"$want" || continue   # confirm real ID, not just name
    SESSION_FILE="$f"; hits=$((hits + 1))
  done < <(find -L "$HOME/.gemini/tmp" -type f -name "session-*-${want:0:8}.jsonl" -print0 2>/dev/null)
  [ "$hits" -eq 1 ] && return 0                                 # exactly one match, else ambiguous/missing
  echo "Refusing: $hits Gemini session files match $want (need exactly 1)" >&2
  SESSION_FILE=""; return 1
}
