#!/bin/bash
# claude_candidates.sh — list "mtime path" lines for Claude session jsonls.
# Uses shell find first, Finder AppleScript fallback for EPERM (external .claude tree).
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.

dumpchat_claude_jsonl_candidates() {
  local root
  root="$(dumpchat_realpath "$HOME/.claude/projects")"          # needs realpath.sh sourced first
  [ -d "$root" ] || return 0

  local -a shell_lines=()
  while IFS= read -r -d '' file; do
    local mtime
    mtime=$(stat -f '%m' "$file" 2>/dev/null) || continue
    shell_lines+=("$mtime $file")
  done < <(find "$root" -type f -name "*.jsonl" -print0 2>/dev/null)

  if [ "${#shell_lines[@]}" -gt 0 ]; then
    printf '%s\n' "${shell_lines[@]}"
    return 0
  fi

  # Finder fallback when find is EPERM-blocked (external .claude tree).
  local p mtime
  while IFS= read -r p; do
    [ -z "$p" ] && continue
    mtime=$(stat -f '%m' "$p" 2>/dev/null) || continue
    echo "$mtime $p"
  done < <(osascript - "$root" <<'APPLESCRIPT' 2>/dev/null
on run argv
  set rootPOSIX to item 1 of argv
  set out to ""
  tell application "Finder"
    set rootFolder to folder (POSIX file rootPOSIX as alias)
    repeat with projFolder in every folder of rootFolder
      repeat with f in (every document file of projFolder whose name ends with ".jsonl")
        set out to out & (POSIX path of (f as alias)) & linefeed
      end repeat
    end repeat
  end repeat
  return out
end tell
APPLESCRIPT
)
}
