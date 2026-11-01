#!/bin/bash
# session.sh — print Claude Code session file: named uuid, running session, else newest.
# Why: CLAUDE_CODE_SESSION_ID is exact inside Claude Code; newest is only a guess from outside.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.
ROOT="$(cd "$HOME/.claude/projects" 2>/dev/null && pwd -P)" || exit 1   # physical path: projects is often a symlink
WANT="${1:-${CLAUDE_CODE_SESSION_ID:-}}"
if [[ -n "$WANT" ]]; then
  find "$ROOT" -type f -name "$WANT*.jsonl" -not -path '*/subagents/*' 2>/dev/null | head -1
else
  find "$ROOT" -type f -name '*.jsonl' -not -path '*/subagents/*' -print0 2>/dev/null \
    | xargs -0 stat -f '%m %N' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-
fi
