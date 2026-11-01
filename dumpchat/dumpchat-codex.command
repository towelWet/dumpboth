#!/bin/bash
set -uo pipefail

# dumpchat-codex.command — Dump the most recent Codex CLI session
# Usage:
#   dumpchat-codex.command                          → Old Chats/oldchatN.md
#   dumpchat-codex.command -append -suffix          → Old Chats/oldchatN-suffix.md
#   dumpchat-codex.command /path/to               → /path/to/Old Chats/oldchatN.md
#   dumpchat-codex.command /path/to -append -sfx  → /path/to/Old Chats/oldchatN-sfx.md

APPEND_SUFFIX=""
TARGET_DIR="$HOME"                                          # never the shell cwd

while [[ $# -gt 0 ]]; do
  case "$1" in
    home)
      TARGET_DIR="$HOME"                                    # /dumpboth may pass home through
      shift
      ;;
    -append|append)
      shift
      APPEND_SUFFIX="${1:-}"
      APPEND_SUFFIX="${APPEND_SUFFIX#-}"
      shift
      ;;
    *)
      TARGET_DIR="$1"
      shift
      ;;
  esac
done

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GUARD="$HERE/../lib/block/refuse_blocked_dir.sh"                 # release repo: lib/ beside dumpchat/
[ -f "$GUARD" ] || GUARD="$HERE/../dumpboth/lib/block/refuse_blocked_dir.sh"   # installed skills/ layout
source "$GUARD"
refuse_blocked_dir "$TARGET_DIR"
OLD_CHATS_DIR="$TARGET_DIR/Old Chats"
mkdir -p "$OLD_CHATS_DIR"

# Current Codex session — shared finder so dumpjsonl-codex picks the same file
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/codex-session-find.sh"
SESSION_FILE="$(codex_session_file)" || true

if [ -z "$SESSION_FILE" ] || [ ! -f "$SESSION_FILE" ]; then
  echo "Error: No Codex session file found in ~/.codex/sessions/"
  exit 1
fi

SESSION_ID=$(basename "$SESSION_FILE" .jsonl)

# /dumpboth forces shared number; else highest oldchatN across .md + .jsonl, plus one
if [ -n "${DUMP_FORCE_NUM:-}" ]; then
  NEXT_NUM="$DUMP_FORCE_NUM"
else
  NEXT_NUM=0
  for file in "$OLD_CHATS_DIR"/oldchat*.md "$OLD_CHATS_DIR"/oldchat*.jsonl; do
    [ -f "$file" ] || continue
    NUM=$(basename "$file" | sed 's/oldchat\([0-9]*\).*/\1/')
    [ "$NUM" -ge "$NEXT_NUM" ] 2>/dev/null && NEXT_NUM=$NUM
  done
  NEXT_NUM=$((NEXT_NUM + 1))
fi

if [ -n "$APPEND_SUFFIX" ]; then
  EXPORT_FILE="$OLD_CHATS_DIR/oldchat${NEXT_NUM}-${APPEND_SUFFIX}.md"
else
  EXPORT_FILE="$OLD_CHATS_DIR/oldchat${NEXT_NUM}.md"
fi

python3 << PYTHON_EOF > "$EXPORT_FILE"
import json, os

session_file = """$SESSION_FILE"""
session_id = """$SESSION_ID"""
target_dir = """$TARGET_DIR"""

# Header
print(" \u250c\u2500\u2500\u2500\u2500\u2500\u2510   Codex CLI")
print("\u2502 \u25c9 \u25c9 \u2502  OpenAI")
print(f"  \u2598\u2598 \u259d\u259d    {target_dir}")
print("")

SKIP_SYSTEM_CONTENT = {"<environment_context>", "<instructions>", "<system-reminder>", "<external_codex_"}   # last: Codex app UI marker, not user text

def is_system_content(text):
    """Check if text is a system injection (environment context, instructions, etc.)"""
    t = text.strip()
    for tag in SKIP_SYSTEM_CONTENT:
        if tag in t.lower() or t.startswith("# AGENTS.md") or t.startswith("# Codex Global"):
            return True
    return False

def parse_fn(data):
    """Parse a Codex response_item into (role, text) or (None, None)."""
    msg_type = data.get("type", "")
    if msg_type != "response_item":
        return None, None

    payload = data.get("payload", {})
    if not isinstance(payload, dict):
        return None, None

    payload_type = payload.get("type", "")
    if payload_type == "reasoning":
        return None, None
    if payload_type != "message":
        return None, None

    role = payload.get("role", "")
    if role not in ("user", "assistant"):
        return None, None

    content = payload.get("content", [])
    if not isinstance(content, list):
        return None, None

    texts = []
    for item in content:
        if isinstance(item, dict):
            text = item.get("text", "")
            if text and isinstance(text, str):
                texts.append(text)

    if not texts:
        return None, None

    combined = "\n\n".join(texts)
    return role, combined

with open(session_file, "r") as f:
    pending_assistant = ""
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            data = json.loads(line)
            role, text = parse_fn(data)
            if role and text:
                if role == "user":
                    if is_system_content(text):
                        continue
                    if pending_assistant:
                        print("\u23fa " + pending_assistant.strip())
                        print("")
                        pending_assistant = ""
                    print("\u276f " + text)
                    print("")
                elif role == "assistant":
                    # Accumulate consecutive assistant messages (deduplicate repeats)
                    clean = text.strip()
                    if pending_assistant:
                        # Only append if this chunk isn't already in the pending buffer
                        if clean and clean not in pending_assistant:
                            pending_assistant += "\n" + clean
                    else:
                        pending_assistant = clean
        except (json.JSONDecodeError, Exception):
            pass
    if pending_assistant:
        print("\u23fa " + pending_assistant.strip())
        print("")

print("")
print(f"Resume: codex --resume {session_id}")
print(f"Source: {session_file}")
PYTHON_EOF

echo "Exported Codex session to $EXPORT_FILE"
