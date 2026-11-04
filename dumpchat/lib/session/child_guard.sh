#!/bin/bash
# child_guard.sh — warn on child/resumed session; skip env var shortcut but don't block.
# Sets DUMPCHAT_CHILD_SESSION=1 so caller skips SESSION_ID (points at parent, not current).
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.

_dumpchat_child_guard() {
  DUMPCHAT_CHILD_SESSION=""                                     # default: not a child
  if [ -n "${CLAUDE_CODE_SESSION_ID:-}" ] && [ -n "${CLAUDE_CODE_CHILD_SESSION:-}" ]; then
    echo "⚠ Child/resumed session — SESSION_ID points at parent, skipping it." >&2
    echo "  Falling through to newest-file resolution instead." >&2
    DUMPCHAT_CHILD_SESSION=1                                    # signal: don't trust SESSION_ID
  fi
  return 0                                                      # never block, always continue
}
