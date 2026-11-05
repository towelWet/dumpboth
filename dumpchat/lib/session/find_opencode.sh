#!/bin/bash
# find_opencode.sh — find legacy OpenCode session file/dir for ONE exact session ID.
# ID source: `id <ID>` arg only (opencode 1.18.21 exports no session-ID env var; checked 2026-11-05).
# Checks legacy layouts: sessions/<ID>.jsonl, root <ID>.jsonl, storage/session/message/<ID>/.
# KNOWN GAP: opencode 1.18 stores chats in ~/.local/share/opencode/opencode.db — not read here.
# NEVER picks newest — newest-mtime guessing dumped wrong chats (oldchat694). No ID → refuse.
# Sets: SESSION_FILE.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.

find_opencode_session() {
  SESSION_FILE=""
  local want="${SESSION_ID:-}" p
  [ -n "$want" ] || { echo "Refusing: no OpenCode session ID (pass: id <ID>)" >&2; return 1; }
  for p in "$HOME/.opencode/sessions/$want.jsonl" "$HOME/.opencode/$want.jsonl" \
           "$HOME/.opencode/storage/session/message/$want"; do
    [ -e "$p" ] && SESSION_FILE="$p" && return 0                # dir form parsed by kilo parser (ALSO_HANDLES)
  done
  echo "Refusing: no OpenCode session for $want (opencode.db not supported)" >&2; return 1
}
