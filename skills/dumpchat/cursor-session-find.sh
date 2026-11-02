#!/bin/bash
# cursor-session-find.sh — resolve Cursor IDE main agent session jsonl.
# Sourced by dumpchat-cursor.command and dumpjsonl-cursor.command.
# Sets: SESSION_FILE, SESSION_ID (empty on failure).
# NEVER DELETE COMMENTS — explain every non-obvious line.

UUID_RE='^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'

find_main_sessions() {
  find "$HOME/.cursor/projects" -path "*/agent-transcripts/*/*.jsonl" ! -path "*/subagents/*" 2>/dev/null
}

is_main_session() {
  local f="$1"
  local stem parent
  stem="$(basename "$f" .jsonl)"
  parent="$(basename "$(dirname "$f")")"
  [[ "$stem" == "$parent" ]]
}

cursor_resolve_session() {
  local want_id="${1:-}"
  SESSION_FILE=""
  SESSION_ID=""

  if [[ -n "$want_id" ]]; then
    while IFS= read -r candidate; do
      if is_main_session "$candidate"; then
        SESSION_FILE="$candidate"
        break
      fi
    done < <(find "$HOME/.cursor/projects" -path "*/agent-transcripts/${want_id}/${want_id}.jsonl" 2>/dev/null)
  fi

  if [[ -z "$SESSION_FILE" || ! -f "$SESSION_FILE" ]]; then
    local newest="" newest_mtime=0 mtime candidate
    while IFS= read -r candidate; do
      [[ -f "$candidate" ]] || continue
      is_main_session "$candidate" || continue
      mtime=$(stat -f '%m' "$candidate" 2>/dev/null || echo 0)
      if [[ "$mtime" -ge "$newest_mtime" ]]; then
        newest_mtime=$mtime
        newest="$candidate"
      fi
    done < <(find_main_sessions)
    SESSION_FILE="$newest"
  fi

  if [[ -n "$SESSION_FILE" && -f "$SESSION_FILE" ]]; then
    SESSION_ID="$(basename "$SESSION_FILE" .jsonl)"
  fi
}
