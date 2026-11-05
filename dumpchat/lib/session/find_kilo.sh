#!/bin/bash
# find_kilo.sh — find Kilo (Kilocode) session directory for ONE exact session ID.
# ID source: `id <ID>` arg only (no Kilo env var known; CLI not installed to verify).
# Layout: storage/session/message/<sessionID>/*.json — dir name IS session ID.
# NEVER picks newest — newest-mtime guessing dumped wrong chats (oldchat694). No ID → refuse.
# Sets: SESSION_FILE (path to session dir, not a single file).
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.

find_kilo_session() {
  SESSION_FILE=""
  local want="${SESSION_ID:-}" root
  [ -n "$want" ] || { echo "Refusing: no Kilo session ID (pass: id <ID>)" >&2; return 1; }
  for root in "$HOME/.kilocode/storage/session/message" "$HOME/.kilo/storage/session/message"; do
    [ -d "$root/$want" ] && SESSION_FILE="$root/$want" && return 0   # exact dir name only
  done
  echo "Refusing: no Kilo session dir for $want" >&2; return 1
}
