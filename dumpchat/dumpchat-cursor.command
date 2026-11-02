#!/bin/bash
set -uo pipefail

# dumpchat-cursor.command — Dump a Cursor IDE agent session transcript
# Usage:
#   dumpchat-cursor.command                          → ~/Old Chats/oldchatN.md (most recent main session)
#   dumpchat-cursor.command home                     → ~/Old Chats/oldchatN.md
#   dumpchat-cursor.command <uuid>                   → dump that session
#   dumpchat-cursor.command -append -suffix            → Old Chats/oldchatN-suffix.md
#   dumpchat-cursor.command home <uuid> -append -sfx   → ~/Old Chats/oldchatN-sfx.md
#   dumpchat-cursor.command /path/to/dir                 → /path/to/dir/Old Chats/oldchatN.md

APPEND_SUFFIX=""
# ~/Old Chats unless the caller names home or a directory. pwd is not a destination:
# the shell cwd is often a leftover project from the previous command (2026-10-23).
TARGET_DIR="$HOME"
SESSION_ID=""
UUID_RE='^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'

while [[ $# -gt 0 ]]; do
  case "$1" in
    home)
      TARGET_DIR="$HOME"
      shift
      ;;
    -append|append)
      shift
      APPEND_SUFFIX="${1:-}"
      APPEND_SUFFIX="${APPEND_SUFFIX#-}"
      shift
      ;;
    *)
      if [[ "$1" =~ $UUID_RE ]]; then
        SESSION_ID="$1"
      else
        TARGET_DIR="$1"
      fi
      shift
      ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Same block as dumpboth: this project folder is not ~/Old Chats.
source "$SCRIPT_DIR/../lib/block/refuse_scam_dir.sh"
refuse_scam_old_chats "$TARGET_DIR"
OLD_CHATS_DIR="$TARGET_DIR/Old Chats"
mkdir -p "$OLD_CHATS_DIR"
source "$SCRIPT_DIR/cursor-session-find.sh"
cursor_resolve_session "$SESSION_ID"

if [[ -z "${SESSION_FILE:-}" || ! -f "$SESSION_FILE" ]]; then
  echo "Error: No Cursor main session jsonl found under ~/.cursor/projects/*/agent-transcripts/"
  exit 1
fi

if [[ -n "${DUMP_FORCE_NUM:-}" ]]; then
  # /dumpboth sets this so md+jsonl land on the IDENTICAL number in one dump.
  NEXT_NUM="$DUMP_FORCE_NUM"
else
  NEXT_NUM=0
  for file in "$OLD_CHATS_DIR"/oldchat*.md "$OLD_CHATS_DIR"/oldchat*.jsonl; do
    [[ -f "$file" ]] || continue
    NUM=$(basename "$file" | sed 's/oldchat\([0-9]*\).*/\1/')
    [[ "$NUM" -ge "$NEXT_NUM" ]] 2>/dev/null && NEXT_NUM=$NUM
  done
  NEXT_NUM=$((NEXT_NUM + 1))
fi

if [[ -n "$APPEND_SUFFIX" ]]; then
  EXPORT_FILE="$OLD_CHATS_DIR/oldchat${NEXT_NUM}-${APPEND_SUFFIX}.md"
else
  EXPORT_FILE="$OLD_CHATS_DIR/oldchat${NEXT_NUM}.md"
fi

export SESSION_FILE SESSION_ID TARGET_DIR
python3 << 'PYTHON_EOF' > "$EXPORT_FILE"
import json, os, re, sys

session_file = os.environ["SESSION_FILE"]
session_id = os.environ["SESSION_ID"]
target_dir = os.environ["TARGET_DIR"]

USER_QUERY_RE = re.compile(r"<user_query>\s*(.*?)\s*</user_query>", re.S)
STRIP_TAGS_RE = re.compile(r"<[^>]+>")

def extract_user_text(text):
    m = USER_QUERY_RE.search(text)
    if m:
        return m.group(1).strip()
    cleaned = STRIP_TAGS_RE.sub("", text).strip()
    return cleaned if cleaned else text.strip()

def summarize_tool(item):
    name = item.get("name", "unknown")
    inp = item.get("input") or {}
    if not isinstance(inp, dict):
        return f"Tool: {name}"
    if "command" in inp:
        cmd = str(inp["command"]).replace("\n", " ")
        if len(cmd) > 140:
            cmd = cmd[:137] + "..."
        return f"Tool: {name}\n{cmd}"
    if "path" in inp:
        extra = ""
        if "description" in inp:
            extra = f" — {inp['description']}"
        return f"Tool: {name}\npath: {inp['path']}{extra}"
    if "description" in inp:
        return f"Tool: {name}\n{inp['description']}"
    parts = []
    for k, v in list(inp.items())[:4]:
        s = str(v).replace("\n", " ")
        if len(s) > 80:
            s = s[:77] + "..."
        parts.append(f"{k}: {s}")
    return "Tool: " + name + ("\n" + "\n".join(parts) if parts else "")

def flatten_content(content):
    if not isinstance(content, list):
        return []
    out = []
    for item in content:
        if not isinstance(item, dict):
            continue
        t = item.get("type")
        if t == "text":
            text = item.get("text", "")
            if text:
                out.append(text)
        elif t == "tool_use":
            out.append(summarize_tool(item))
    return out

def format_user(text):
    return extract_user_text(text)

def flush_assistant(buf, lines_out):
    if buf:
        lines_out.append(("assistant", buf.strip()))

lines_out = []

with open(session_file, "r", encoding="utf-8", errors="replace") as f:
    assistant_buf = None
    for raw in f:
        line = raw.strip()
        if not line:
            continue
        try:
            data = json.loads(line)
        except json.JSONDecodeError:
            continue

        if data.get("type") == "turn_ended":
            continue

        role = data.get("role")
        if role not in ("user", "assistant"):
            continue

        msg = data.get("message") or {}
        content = msg.get("content") or []
        chunks = flatten_content(content)
        if not chunks:
            continue

        combined = "\n\n".join(chunks)

        if role == "user":
            flush_assistant(assistant_buf, lines_out)
            assistant_buf = None
            lines_out.append(("user", format_user(combined)))
        else:
            if assistant_buf is None:
                assistant_buf = combined
            elif combined not in assistant_buf:
                assistant_buf += "\n\n" + combined

flush_assistant(assistant_buf, lines_out)

print(" ◈ ◈ ◈ ◈ ◈   Cursor IDE")
print("  ◈ ◈ ◈    Composer Agent")
print(f"  ▘▘ ▝▝    {target_dir}")
print("")

for role, text in lines_out:
    if role == "user":
        print("\u276f " + text)
        print("")
    else:
        print("\u23fa " + text)
        print("")

print("")
print(f"Resume: cursor agent --resume {session_id}")
print(f"Source: {session_file}")
PYTHON_EOF

echo "Exported Cursor session to $EXPORT_FILE"
