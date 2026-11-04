#!/bin/bash
# setup_old_chats.sh — block scam dir + create Old Chats dir.
# Expects: TARGET_DIR. Sets: OLD_CHATS_DIR.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.

_SHARED_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_SHARED_DIR/../../../lib/block/refuse_scam_dir.sh"
refuse_scam_old_chats "$TARGET_DIR"
OLD_CHATS_DIR="$TARGET_DIR/Old Chats"
mkdir -p "$OLD_CHATS_DIR"
