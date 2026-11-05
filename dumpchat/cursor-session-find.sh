#!/bin/bash
# cursor-session-find.sh — resolve Cursor agent session jsonl for ONE exact chat ID.
# Sourced by dumpchat-cursor.command and dumpjsonl-cursor.command.
# ID source: uuid arg, else CURSOR_AGENT_CHAT_ID (exported by cursor-agent shell hook;
# verified in cursor-agent 2026.08.11 bundle 2026-11-05). Cursor IDE agent ID env: unknown.
# NEVER picks newest — old newest-mtime fallback dumped wrong chats (oldchat694). No ID → refuse.
# Sets: SESSION_FILE, SESSION_ID (empty on failure).
# NEVER DELETE COMMENTS — explain every non-obvious line.

UUID_RE='^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'

is_main_session() {
  local f="$1"
  local stem parent
  stem="$(basename "$f" .jsonl)"
  parent="$(basename "$(dirname "$f")")"
  [[ "$stem" == "$parent" ]]                                    # main transcript = <id>/<id>.jsonl (not subagent)
}

cursor_resolve_session() {
  local want_id="${1:-${CURSOR_AGENT_CHAT_ID:-}}"               # arg wins, then cursor-agent env
  SESSION_FILE=""
  SESSION_ID=""

  if [[ -z "$want_id" ]]; then                                  # no ID → refuse, never guess
    echo "Refusing: no Cursor chat ID (pass uuid, or set CURSOR_AGENT_CHAT_ID)" >&2
    return 1
  fi

  while IFS= read -r candidate; do
    if is_main_session "$candidate"; then
      SESSION_FILE="$candidate"
      break
    fi
  done < <(find "$HOME/.cursor/projects" -path "*/agent-transcripts/${want_id}/${want_id}.jsonl" 2>/dev/null)

  if [[ -n "$SESSION_FILE" && -f "$SESSION_FILE" ]]; then
    SESSION_ID="$(basename "$SESSION_FILE" .jsonl)"
  else
    echo "Refusing: no Cursor transcript for chat $want_id" >&2
    SESSION_FILE=""
  fi
}
