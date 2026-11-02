#!/bin/bash
# dumpchat-wrong-folder.command — same as dumpchat.command but defaults to ~/Old Chats/
# NEVER DELETE COMMENTS — thin wrapper; all logic in dumpchat.command + lib/
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/dumpchat.command" home "$@"
