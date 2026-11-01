#!/bin/bash
set -uo pipefail

# dumpchat-gemini — Gemini CLI session dumper
# Usage:
#   dumpchat-gemini.command                          → Old Chats/oldchatN.md
#   dumpchat-gemini.command -append -suffix          → Old Chats/oldchatN-suffix.md
#   dumpchat-gemini.command /path/to               → /path/to/Old Chats/oldchatN.md
#   dumpchat-gemini.command /path/to -append -sfx  → /path/to/Old Chats/oldchatN-sfx.md
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

# Current Gemini session — shared finder so dumpjsonl-gemini picks the same file
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/gemini-session-find.sh"
SESSION_FILE="$(gemini_session_file)" || true

if [ -z "$SESSION_FILE" ] || [ ! -f "$SESSION_FILE" ]; then
  echo "Error: No Gemini session file found in ~/.gemini/tmp/"
  exit 1
fi

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

export SESSION_FILE TARGET_DIR
python3 << 'PYTHON_EOF' > "$EXPORT_FILE"
import json, os, sys

session_file = os.environ["SESSION_FILE"]
target_dir = os.environ["TARGET_DIR"]

model_name = None

def extract_text(content):
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        for item in content:
            if isinstance(item, dict) and "text" in item:
                t = item.get("text", "")
                if t:
                    return t
    return ""

lines_out = []
assistant_buf = None

with open(session_file, "r") as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            data = json.loads(line)
        except json.JSONDecodeError:
            continue

        msg_type = data.get("type", "")

        # Skip meta lines
        if not msg_type:
            continue
        if "$set" in data:
            continue
        if msg_type == "info":
            continue

        if msg_type == "user":
            # Flush accumulated assistant block before user message
            if assistant_buf is not None:
                lines_out.append(("assistant", assistant_buf))
                assistant_buf = None
            text = extract_text(data.get("content", []))
            if text:
                lines_out.append(("user", text))

        elif msg_type in ("gemini", "assistant"):
            text = extract_text(data.get("content", ""))
            if text:
                if assistant_buf is None:
                    assistant_buf = text
                else:
                    assistant_buf += "\n\n" + text
                if model_name is None:
                    model_name = data.get("model", None)

# Flush trailing assistant block
if assistant_buf is not None:
    lines_out.append(("assistant", assistant_buf))

if model_name is None:
    model_name = "Gemini CLI"

# Header
print(" \u2606 \u2606 \u2606 \u2606 \u2606   Gemini CLI")
print(f"  \u2606 \u2606 \u2606    {model_name}")
print(f"  \u2598\u2598 \u259d\u259d    {target_dir}")
print("")

for role, text in lines_out:
    if role == "user":
        print("\u276f " + text)
        print("")
    else:
        print("\u23fa " + text)
        print("")

print("")
print("Resume: gemini")
print(f"Source: {session_file}")
PYTHON_EOF

echo "Exported session to $EXPORT_FILE (gemini)"
