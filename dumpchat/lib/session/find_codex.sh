#!/bin/bash
# find_codex.sh — find Codex CLI rollout file for ONE exact session ID.
# ID source: `id <ID>` arg (SESSION_ID), else CODEX_THREAD_ID / CODEX_SESSION_ID that Codex
# exports to its shell commands (names verified in codex 0.150.1 binary strings 2026-11-05).
# NEVER picks newest — newest-mtime guessing dumped wrong chats (oldchat694). No ID → refuse.
# Sets: SESSION_FILE.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.

find_codex_session() {
  SESSION_FILE=""
  local want="${SESSION_ID:-${CODEX_THREAD_ID:-${CODEX_SESSION_ID:-}}}"   # arg wins, then Codex env
  [ -n "$want" ] || { echo "Refusing: no Codex session ID (pass: id <ID>)" >&2; return 1; }
  # -L: ~/.codex/sessions may be a symlink (external drive); plain find returned nothing (old bug).
  # Filename ends in session ID: rollout-<timestamp>-<ID>.jsonl.
  SESSION_FILE=$(find -L "$HOME/.codex/sessions" -type f -name "rollout-*-${want}.jsonl" 2>/dev/null | head -1)
  [ -n "$SESSION_FILE" ] && [ -f "$SESSION_FILE" ] && return 0
  echo "Refusing: no Codex rollout file for session $want" >&2; return 1
}
