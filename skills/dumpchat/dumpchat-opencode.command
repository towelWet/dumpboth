#!/bin/bash
set -uo pipefail

# dumpchat-opencode.command — dump most recent OpenCode session
# Usage:
#   dumpchat-opencode.command                          → Old Chats/oldchatN.md
#   dumpchat-opencode.command -append -suffix          → Old Chats/oldchatN-suffix.md
#   dumpchat-opencode.command /path/to/dir               → /path/to/dir/Old Chats/oldchatN.md
#   dumpchat-opencode.command /path/to/dir -append -sfx  → /path/to/dir/Old Chats/oldchatN-sfx.md

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

# ═══════════════════════════════════════════════
# Find the most recently modified OpenCode session
# ═══════════════════════════════════════════════

SESSION_FILE=""
SESSION_ID=""
SESSION_TYPE=""  # "jsonl" or "hierarchical"

# Step 1: Check for JSONL files in ~/.opencode/ (simplest)
if [ -d "$HOME/.opencode/sessions" ]; then
  NEWEST_JSONL=$(find "$HOME/.opencode/sessions" -type f -name "*.jsonl" -print0 2>/dev/null \
    | xargs -0 stat -f '%m %N' 2>/dev/null \
    | sort -rn \
    | head -1 \
    | awk '{print $2}')
  if [ -n "$NEWEST_JSONL" ] && [ -f "$NEWEST_JSONL" ]; then
    SESSION_FILE="$NEWEST_JSONL"
    SESSION_TYPE="jsonl"
  fi
fi

# Step 2: Also check root ~/.opencode/ for JSONL files
if [ -z "$SESSION_FILE" ]; then
  NEWEST_ROOT_JSONL=$(find "$HOME/.opencode" -maxdepth 1 -type f -name "*.jsonl" -print0 2>/dev/null \
    | xargs -0 stat -f '%m %N' 2>/dev/null \
    | sort -rn \
    | head -1 \
    | awk '{print $2}')
  if [ -n "$NEWEST_ROOT_JSONL" ] && [ -f "$NEWEST_ROOT_JSONL" ]; then
    SESSION_FILE="$NEWEST_ROOT_JSONL"
    SESSION_TYPE="jsonl"
  fi
fi

# Step 3: Fall back to hierarchical JSON in ~/.opencode/storage/session/message/
if [ -z "$SESSION_FILE" ]; then
  HIER_DIR="$HOME/.opencode/storage/session/message"
  if [ -d "$HIER_DIR" ]; then
    # Find session dirs with at least one .json file, sorted by most recent
    NEWEST_SESSION_DIR=$(find "$HIER_DIR" -type f -name "*.json" -print0 2>/dev/null \
      | xargs -0 stat -f '%m %N' 2>/dev/null \
      | sort -rn \
      | head -1 \
      | awk '{print $2}' \
      | xargs dirname)
    if [ -n "$NEWEST_SESSION_DIR" ] && [ -d "$NEWEST_SESSION_DIR" ]; then
      SESSION_FILE="$NEWEST_SESSION_DIR"
      SESSION_TYPE="hierarchical"
      SESSION_ID=$(basename "$NEWEST_SESSION_DIR")
    fi
  fi
fi

# Step 4: Check ~/.opencode/storage/session/message/ recursively for any JSON
if [ -z "$SESSION_FILE" ]; then
  HIER_DIR="$HOME/.opencode/storage/session/message"
  if [ -d "$HIER_DIR" ]; then
    NEWEST_JSON=$(find "$HIER_DIR" -type f -name "*.json" -print0 2>/dev/null \
      | xargs -0 stat -f '%m %N' 2>/dev/null \
      | sort -rn \
      | head -1 \
      | awk '{print $2}')
    if [ -n "$NEWEST_JSON" ] && [ -f "$NEWEST_JSON" ]; then
      SESSION_FILE="$NEWEST_JSON"
      SESSION_TYPE="single_json"
    fi
  fi
fi

if [ -z "$SESSION_FILE" ]; then
  echo "No OpenCode sessions found."
  exit 0
fi

# Extract session ID for the resume line
if [ -z "$SESSION_ID" ]; then
  case "$SESSION_TYPE" in
    jsonl)
      SESSION_ID=$(basename "$SESSION_FILE" .jsonl)
      ;;
    hierarchical)
      # already set above
      ;;
    single_json)
      SESSION_ID=$(basename "$(dirname "$SESSION_FILE")")
      ;;
    *)
      SESSION_ID=$(basename "$SESSION_FILE" | sed 's/\.[^.]*$//')
      ;;
  esac
fi

# ═══════════════════════════════════════════════
# Auto-increment oldchatN.md
# ═══════════════════════════════════════════════

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

# ═══════════════════════════════════════════════
# Parse session and write Markdown
# ═══════════════════════════════════════════════

python3 << PYTHON_EOF > "$EXPORT_FILE"
import json, os, sys, glob as globmod

session_file = """$SESSION_FILE"""
session_type = """$SESSION_TYPE"""
session_id = """$SESSION_ID"""
target_dir = """$TARGET_DIR"""

# ── Header ──
print(" ╭────╮   OpenCode")
print("│▾▾▾│  OpenCode AI")
print(f"  ▘▘ ▝▝    {target_dir}")
print("")

# ── Collect messages from hierarchical JSON session dir ──
def collect_hierarchical_messages(session_dir):
    """Read all .json files in a session directory, sorted by filename."""
    messages = []
    json_files = sorted(globmod.glob(os.path.join(session_dir, "*.json")))
    for fp in json_files:
        try:
            with open(fp, "r") as f:
                data = json.load(f)
            messages.append((fp, data))
        except (json.JSONDecodeError, Exception):
            pass
    return messages

def collect_jsonl_messages(jsonl_path):
    """Read JSONL file line by line."""
    messages = []
    try:
        with open(jsonl_path, "r") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    data = json.loads(line)
                    messages.append((jsonl_path, data))
                except (json.JSONDecodeError, Exception):
                    pass
    except Exception:
        pass
    return messages

def parse_msg(data):
    """Parse a single message JSON object. Returns (role, text) or (None, None)."""
    role = data.get("role", "")
    content = data.get("content", "")
    text = ""

    if isinstance(content, str):
        text = content
    elif isinstance(content, list):
        for item in content:
            if isinstance(item, dict) and "text" in item:
                text = item["text"]
                break
            elif isinstance(item, dict) and item.get("type") == "text":
                text = item.get("text", "")
                if text:
                    break
            elif isinstance(item, str):
                text = item
                break

    if role and text:
        # Skip system-reminder injections and command stubs
        if text.strip().startswith("<system-reminder>"):
            return None, None
        if "<command-message>" in text or "<command-name>" in text:
            return None, None
        return role, text

    # Try nested message format
    msg = data.get("message", {})
    if msg:
        role = msg.get("role", "")
        content = msg.get("content", "")
        if isinstance(content, str):
            text = content
        elif isinstance(content, list):
            for item in content:
                if isinstance(item, dict) and "text" in item:
                    text = item["text"]
                    break
                elif isinstance(item, dict) and item.get("type") == "text":
                    text = item.get("text", "")
                    if text:
                        break

    if role and text:
        if text.strip().startswith("<system-reminder>"):
            return None, None
        if "<command-message>" in text or "<command-name>" in text:
            return None, None
        return role, text

    return None, None

# ── Load and parse ──
raw_messages = []
if session_type == "hierarchical":
    raw_messages = collect_hierarchical_messages(session_file)
elif session_type in ("jsonl", "single_json"):
    raw_messages = collect_jsonl_messages(session_file)
else:
    raw_messages = collect_jsonl_messages(session_file)

if not raw_messages:
    print("(No messages in session)")
else:
    for _, data in raw_messages:
        role, text = parse_msg(data)
        if role and text:
            if role == "user":
                print("\u276f " + text)
                print("")
            elif role in ("assistant", "opencode", "model"):
                print("\u23fa " + text)
                print("")

# ── Resume line ──
print("")
print(f"Resume: opencode --resume {session_id}")
print(f"Source: {session_file}")

PYTHON_EOF

echo "Exported session to $EXPORT_FILE (opencode)"
