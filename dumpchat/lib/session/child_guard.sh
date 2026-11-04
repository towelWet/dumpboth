#!/bin/bash
# child_guard.sh — detect inherited CLAUDE_CODE_CHILD_SESSION and refuse dump.
# When this flag is set, Claude Code does NOT write a transcript JSONL for the
# current session. The SESSION_ID env var points at the PARENT's JSONL, which
# contains DIFFERENT conversation content. Dumping it would silently export the
# wrong chat — a scam. The only honest action is to refuse and explain the fix.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.

_dumpchat_child_guard() {
  if [ -n "${CLAUDE_CODE_CHILD_SESSION:-}" ]; then
    echo "" >&2
    echo "═══ CANNOT DUMP: transcript saving is off ═══" >&2
    echo "" >&2
    echo "CLAUDE_CODE_CHILD_SESSION is set in this shell." >&2
    echo "Claude Code is NOT writing a JSONL for this conversation." >&2
    echo "SESSION_ID ($CLAUDE_CODE_SESSION_ID) belongs to the PARENT — dumping" >&2
    echo "it would silently export the wrong chat." >&2
    echo "" >&2
    echo "Fix: open a NEW terminal tab/window, then start Claude Code." >&2
    echo "  Or: unset CLAUDE_CODE_CHILD_SESSION before starting." >&2
    echo "  Or: restart with CLAUDE_CODE_FORCE_SESSION_PERSISTENCE=1" >&2
    echo "" >&2
    echo "═══════════════════════════════════════════════" >&2
    return 1
  fi
  return 0
}
