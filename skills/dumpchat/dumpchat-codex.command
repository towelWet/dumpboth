#!/bin/bash
set -uo pipefail

# dumpchat-codex.command — Dump the most recent Codex CLI session
# Usage:
#   dumpchat-codex.command                          → Old Chats/oldchatN.md
#   dumpchat-codex.command -append -suffix          → Old Chats/oldchatN-suffix.md
#   dumpchat-codex.command /path/to/dir               → /path/to/dir/Old Chats/oldchatN.md
#   dumpchat-codex.command /path/to/dir -append -sfx  → /path/to/dir/Old Chats/oldchatN-sfx.md

APPEND_SUFFIX=""
TARGET_DIR="$HOME"                                          # never the shell cwd

while [[ $# -gt 0 ]]; do
  case "$1" in
    -append)
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

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../dumpboth/lib/block/refuse_scam_dir.sh"
refuse_scam_old_chats "$TARGET_DIR"
OLD_CHATS_DIR="$TARGET_DIR/Old Chats"
mkdir -p "$OLD_CHATS_DIR"

# Find the most recently modified Codex session
SESSION_FILE=""
if [ -d "$HOME/.codex/sessions" ]; then
  SESSION_FILE=$(find "$HOME/.codex/sessions" -type f -name "rollout-*.jsonl" -print0 2>/dev/null \
    | xargs -0 stat -f '%m %N' 2>/dev/null \
    | sort -rn \
    | head -1 \
    | cut -d' ' -f2-)
fi

if [ -z "$SESSION_FILE" ] || [ ! -f "$SESSION_FILE" ]; then
  echo "Error: No Codex session file found in ~/.codex/sessions/"
  exit 1
fi

SESSION_ID=$(basename "$SESSION_FILE" .jsonl)

# Find the highest existing oldchatN number and increment
NEXT_NUM=0
for file in "$OLD_CHATS_DIR"/oldchat*.md; do
  if [ -f "$file" ]; then
    NUM=$(basename "$file" | sed 's/oldchat\([0-9]*\).*/\1/')
    if [ "$NUM" -ge "$NEXT_NUM" ] 2>/dev/null; then
      NEXT_NUM=$NUM
    fi
  fi
done
NEXT_NUM=$((NEXT_NUM + 1))

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
print("\u2502 \u25c9 \u25c9 \u2502  GPT-5 \u00b7 OpenAI")
print(f"  \u2598\u2598 \u259d\u259d    {target_dir}")
print("")

SKIP_SYSTEM_CONTENT = {"<environment_context>", "<instructions>", "<system-reminder>"}

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
