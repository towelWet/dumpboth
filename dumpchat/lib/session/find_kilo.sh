#!/bin/bash
# find_kilo.sh — find most recent Kilo (Kilocode) session directory.
# Sets: SESSION_FILE (path to session dir, not a single file).
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.

find_kilo_session() {
  SESSION_FILE=""
  local roots=("$HOME/.kilocode/storage/session/message" "$HOME/.kilo/storage/session/message")
  local newest_mtime=0 newest_dir=""

  for root in "${roots[@]}"; do
    [ -d "$root" ] || continue
    for sd in "$root"/*/; do
      [ -d "$sd" ] || continue
      for fp in "$sd"*.json; do
        [ -f "$fp" ] || continue
        local mtime; mtime=$(stat -f '%m' "$fp" 2>/dev/null) || continue
        if [ "$mtime" -gt "$newest_mtime" ]; then
          newest_mtime=$mtime; newest_dir="$sd"
        fi
      done
    done
  done

  [ -n "$newest_dir" ] && SESSION_FILE="${newest_dir%/}" && return 0
  return 1
}
