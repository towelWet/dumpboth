#!/bin/bash
# resolve_target.sh — enforce cursor-home rule + block scam dirs.
# Expects CURSOR_MODE, EXPLICIT_TARGET, TARGET_DIR, PASSTHROUGH_ARGS
# already set (by parse_args.sh). Exports OLD_CHATS_DIR.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.

# Cursor dumps never follow shell cwd — leftover pwd (last project a build
# cd'd into) is not an archive. No named dir means ~/Old Chats.
if [[ "$CURSOR_MODE" -eq 1 && "$EXPLICIT_TARGET" -eq 0 ]]; then
  TARGET_DIR="$HOME"
  PASSTHROUGH_ARGS+=("home")
fi

# Block project folder that minted oldchat1–3. Home is only real archive.
DUMPBOTH_SCRIPT_DIR="${DUMPBOTH_SCRIPT_DIR:?must be set by caller}"
source "$DUMPBOTH_SCRIPT_DIR/lib/block/refuse_scam_dir.sh"
refuse_scam_old_chats "$TARGET_DIR"

OLD_CHATS_DIR="$TARGET_DIR/Old Chats"
mkdir -p "$OLD_CHATS_DIR"
