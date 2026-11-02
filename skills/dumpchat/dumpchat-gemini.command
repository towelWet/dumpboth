#!/bin/bash
set -uo pipefail

# dumpchat-gemini — Gemini CLI session dumper
# Usage:
#   dumpchat-gemini.command                          → Old Chats/oldchatN.md
#   dumpchat-gemini.command -append -suffix          → Old Chats/oldchatN-suffix.md
#   dumpchat-gemini.command /path/to/dir               → /path/to/dir/Old Chats/oldchatN.md
#   dumpchat-gemini.command /path/to/dir -append -sfx  → /path/to/dir/Old Chats/oldchatN-sfx.md
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

# Find the most recently modified Gemini session
ALL_CANDIDATES=""
if [ -d "$HOME/.gemini/tmp" ]; then
  while IFS= read -r -d '' file; do
    mtime=$(stat -f '%m' "$file" 2>/dev/null)
    [ -n "$mtime" ] && ALL_CANDIDATES+="$mtime $file"$'\n'
  done < <(find "$HOME/.gemini/tmp" -type f -name "session-*.jsonl" -print0 2>/dev/null)
fi

# Try the 5 most recent files, picking the first one with actual user/gemini messages
SESSION_FILE=""
while IFS= read -r candidate; do
    candidate_file=$(echo "$candidate" | awk '{print $2}')
    if [ -n "$candidate_file" ] && [ -f "$candidate_file" ]; then
        has_content=$(python3 -c "
import json
try:
    with open('$candidate_file') as f:
        for line in f:
            line = line.strip()
            if not line: continue
            try:
                d = json.loads(line)
                t = d.get('type','')
                if t in ('user','gemini','assistant'):
                    print('found')
                    break
            except: pass
except: pass
" 2>/dev/null)
        if [ "$has_content" = "found" ]; then
            SESSION_FILE="$candidate_file"
            break
        fi
    fi
done < <(echo "$ALL_CANDIDATES" | sort -rn | head -5)

if [ -z "$SESSION_FILE" ]; then
    SESSION_FILE=$(echo "$ALL_CANDIDATES" | sort -rn | head -1 | awk '{print $2}')
fi

if [ -z "$SESSION_FILE" ] || [ ! -f "$SESSION_FILE" ]; then
  echo "Error: No Gemini session file found in ~/.gemini/tmp/"
  exit 1
fi

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
