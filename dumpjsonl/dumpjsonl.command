#!/bin/bash
set -uo pipefail
# dumpjsonl.command — export current CLI session as RAW jsonl (verbatim, no md conversion)
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.
# WHY: /find-claude-chat and training pipelines read the live ~/.claude/projects jsonl
# directly — this skill dumps that exact file, untouched, so "dumped" == "actual chat".
# Session discovery is NOT reimplemented here; it's sourced from dumpchat so both
# skills stay in sync on where sessions live (see dumpchat-session-find.sh).
# Usage: dumpjsonl.command [home] [-append -suffix] [uuid] [target_dir]

APPEND_SUFFIX=""
TARGET_DIR="$HOME"                                          # never the shell cwd; that counter is how a project minted oldchat3
SESSION_ID=""
UUID_RE='^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'

while [[ $# -gt 0 ]]; do
  case "$1" in
    home)         TARGET_DIR="$HOME"; shift ;;                     # /dumpjsonl home -> ~/Old Chats/
    append|-append) shift; APPEND_SUFFIX="${1:-}"; APPEND_SUFFIX="${APPEND_SUFFIX#-}"; shift ;;
    *)            [[ "$1" =~ $UUID_RE ]] && SESSION_ID="$1" || TARGET_DIR="$1"; shift ;;
  esac
done

# Block the Oct 20 project tree before any Old Chats directory is created.
DUMPBOTH_BLOCK="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"   # release repo: lib/ at repo root
source "$DUMPBOTH_BLOCK/lib/block/refuse_blocked_dir.sh"
refuse_blocked_dir "$TARGET_DIR"
OLD_CHATS_DIR="$TARGET_DIR/Old Chats"
mkdir -p "$OLD_CHATS_DIR"

# Reuse dumpchat's session finder directly — one source of truth for "which jsonl is current".
DUMPCHAT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../dumpchat" && pwd)"
source "$DUMPCHAT_DIR/dumpchat-session-find.sh"

if [[ -n "$SESSION_ID" ]]; then
  SESSION_FILE="$(dumpchat_resolve_session_file "$SESSION_ID")" || true
else
  SESSION_FILE="$(dumpchat_resolve_session_file)" || true
fi

if [[ -z "${SESSION_FILE:-}" || ! -r "$SESSION_FILE" ]]; then
  echo "Error: No session file found in any known CLI directory"; exit 1
fi

if [[ -n "${DUMP_FORCE_NUM:-}" ]]; then
  # /dumpboth sets this so md+jsonl land on the IDENTICAL number in one dump — no
  # race between the two auto-increment scans below.
  NEXT_NUM="$DUMP_FORCE_NUM"
else
  # SHARED counter with dumpchat's oldchatN.md — scans both extensions so /dumpjsonl and
  # /dumpchat advance the same sequence, so a pair can never get two numbers.
  NEXT_NUM=0
  for file in "$OLD_CHATS_DIR"/oldchat*.md "$OLD_CHATS_DIR"/oldchat*.jsonl; do
    [[ -f "$file" ]] || continue
    NUM=$(basename "$file" | sed 's/oldchat\([0-9]*\).*/\1/')
    [[ "$NUM" -ge "$NEXT_NUM" ]] 2>/dev/null && NEXT_NUM=$NUM
  done
  NEXT_NUM=$((NEXT_NUM + 1))
fi

[[ -n "$APPEND_SUFFIX" ]] \
  && EXPORT_FILE="$OLD_CHATS_DIR/oldchat${NEXT_NUM}-${APPEND_SUFFIX}.jsonl" \
  || EXPORT_FILE="$OLD_CHATS_DIR/oldchat${NEXT_NUM}.jsonl"

# Verbatim copy — no header, no footer, no reformatting. This IS the actual chat.
cp "$SESSION_FILE" "$EXPORT_FILE"
echo "Exported raw jsonl to $EXPORT_FILE"
echo "Source: $SESSION_FILE"
