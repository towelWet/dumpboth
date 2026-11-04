#!/bin/bash
# finder_find_by_id.sh — find session file by ID via Finder (EPERM fallback).
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.

dumpchat_finder_find_by_id() {
  local root="$1"
  local sid="$2"
  [ -n "$root" ] && [ -n "$sid" ] || return 1
  osascript - "$root" "$sid" <<'APPLESCRIPT' 2>/dev/null
on run argv
  set rootPOSIX to item 1 of argv
  set sid to item 2 of argv
  tell application "Finder"
    set rootFolder to folder (POSIX file rootPOSIX as alias)
    repeat with projFolder in every folder of rootFolder
      try
        set targetFile to (first item of projFolder whose name starts with sid and name ends with ".jsonl")
        return POSIX path of (targetFile as alias)
      end try
    end repeat
  end repeat
  return ""
end run
APPLESCRIPT
}
