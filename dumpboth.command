#!/bin/bash
set -uo pipefail
# dumpboth.command — dump BOTH .md (dumpchat) and .jsonl (dumpjsonl) for the current
# session, on the SAME oldchatN number and the SAME random tag, so the two artifacts
# can never silently drift apart. Thin orchestrator only — all real logic lives in
# lib/ (one function per file); this file just wires the pieces.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.
# Usage: dumpboth.command [cursor|devin|codex|gemini|opencode] [home] [-append -suffix|suffix] [uuid] [target_dir]
#        dumpboth.command detect [home|target_dir]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DUMPCHAT_CMD="$SCRIPT_DIR/dumpchat/dumpchat.command"
DUMPJSONL_CMD="$SCRIPT_DIR/dumpjsonl/dumpjsonl.command"
DUMPCHAT_CURSOR_CMD="$SCRIPT_DIR/dumpchat/dumpchat-cursor.command"
DUMPJSONL_CURSOR_CMD="$SCRIPT_DIR/dumpjsonl/dumpjsonl-cursor.command"
DUMPCHAT_DEVIN_CMD="$SCRIPT_DIR/dumpchat/dumpchat-devin.command"
DUMPJSONL_DEVIN_CMD="$SCRIPT_DIR/dumpjsonl/dumpjsonl-devin.command"
DUMPCHAT_CODEX_CMD="$SCRIPT_DIR/dumpchat/dumpchat-codex.command"
DUMPJSONL_CODEX_CMD="$SCRIPT_DIR/dumpjsonl/dumpjsonl-codex.command"
DUMPCHAT_GEMINI_CMD="$SCRIPT_DIR/dumpchat/dumpchat-gemini.command"
DUMPJSONL_GEMINI_CMD="$SCRIPT_DIR/dumpjsonl/dumpjsonl-gemini.command"
DUMPCHAT_OPENCODE_CMD="$SCRIPT_DIR/dumpchat/dumpchat-opencode.command"
DUMPJSONL_OPENCODE_CMD="$SCRIPT_DIR/dumpjsonl/dumpjsonl-opencode.command"
UUID_RE='^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'

# ---- detect mode -----------------------------------------------------------
if [[ "${1:-}" == "detect" ]]; then
  shift
  TARGET_DIR="$HOME"
  [[ "${1:-}" == "home" ]] && TARGET_DIR="$HOME"
  [[ -n "${1:-}" && "${1:-}" != "home" ]] && TARGET_DIR="$1"
  OLD_CHATS_DIR="$TARGET_DIR/Old Chats"
  python3 "$SCRIPT_DIR/lib/detect/cli.py" "$OLD_CHATS_DIR"
  exit $?
fi

# ---- dump-both mode ---------------------------------------------------------
CURSOR_MODE=0
DEVIN_MODE=0
CODEX_MODE=0
GEMINI_MODE=0
OPENCODE_MODE=0
USER_SUFFIX=""
TARGET_DIR="$HOME"                                          # never pwd: a stray project folder is not an archive
EXPLICIT_TARGET=0                                          # 1 only when the user named home or a directory
PASSTHROUGH_ARGS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    cursor)         CURSOR_MODE=1; shift
                    # Shorthand: `dumpboth cursor mytag` == append -mytag
                    if [[ $# -gt 0 && "$1" != "home" && "$1" != "append" && "$1" != "-append" && ! "$1" =~ $UUID_RE && ! -d "$1" ]]; then
                      USER_SUFFIX="${1#-}"
                      shift
                    fi
                    ;;
    devin)          DEVIN_MODE=1; shift
                    # Shorthand: `dumpboth devin mytag` == append -mytag (mirror of cursor)
                    if [[ $# -gt 0 && "$1" != "home" && "$1" != "append" && "$1" != "-append" && ! "$1" =~ $UUID_RE && ! -d "$1" ]]; then
                      USER_SUFFIX="${1#-}"
                      shift
                    fi
                    ;;
    codex)          CODEX_MODE=1; shift
                    # Shorthand: `dumpboth codex mytag` == append -mytag (mirror of cursor/devin)
                    if [[ $# -gt 0 && "$1" != "home" && "$1" != "append" && "$1" != "-append" && ! "$1" =~ $UUID_RE && ! -d "$1" ]]; then
                      USER_SUFFIX="${1#-}"
                      shift
                    fi
                    ;;
    gemini)         GEMINI_MODE=1; shift
                    # Shorthand: `dumpboth gemini mytag` == append -mytag (mirror of cursor/devin)
                    if [[ $# -gt 0 && "$1" != "home" && "$1" != "append" && "$1" != "-append" && ! "$1" =~ $UUID_RE && ! -d "$1" ]]; then
                      USER_SUFFIX="${1#-}"
                      shift
                    fi
                    ;;
    opencode)       OPENCODE_MODE=1; shift
                    # Shorthand: `dumpboth opencode mytag` == append -mytag (mirror of cursor/devin)
                    if [[ $# -gt 0 && "$1" != "home" && "$1" != "append" && "$1" != "-append" && ! "$1" =~ $UUID_RE && ! -d "$1" ]]; then
                      USER_SUFFIX="${1#-}"
                      shift
                    fi
                    ;;
    home)           TARGET_DIR="$HOME"; EXPLICIT_TARGET=1; PASSTHROUGH_ARGS+=("home"); shift ;;
    append|-append) shift; USER_SUFFIX="${1:-}"; USER_SUFFIX="${USER_SUFFIX#-}"; shift ;;
    *)              # uuid → pass through; existing dir → pass through; bare word → treat as suffix (same shorthand cursor/devin have)
                    if [[ "$1" =~ $UUID_RE || -d "$1" ]]; then
                      [[ -d "$1" ]] && EXPLICIT_TARGET=1 && TARGET_DIR="$1"
                      PASSTHROUGH_ARGS+=("$1")
                    else
                      USER_SUFFIX="${1#-}"                  # strip leading dash if present
                    fi
                    shift ;;

  esac
done

# Cursor dumps never follow the shell cwd. A leftover pwd (the last project a build
# cd'd into) is not an archive. No named directory means ~/Old Chats, and that decision is passed
# to the child dumpers so they cannot resolve pwd on their own.
if [[ "$CURSOR_MODE" -eq 1 && "$EXPLICIT_TARGET" -eq 0 ]]; then
  TARGET_DIR="$HOME"
  PASSTHROUGH_ARGS+=("home")
fi

# Block the project folder that minted oldchat1–3. Home is the only real archive.
source "$SCRIPT_DIR/lib/block/refuse_blocked_dir.sh"
refuse_blocked_dir "$TARGET_DIR"
OLD_CHATS_DIR="$TARGET_DIR/Old Chats"
mkdir -p "$OLD_CHATS_DIR"

NEXT_NUM="$(python3 "$SCRIPT_DIR/lib/counter/shared_next_number.py" "$OLD_CHATS_DIR")"
TAG="$(python3 "$SCRIPT_DIR/lib/tag/generate_tag.py")"

if [[ -n "$USER_SUFFIX" ]]; then
  FINAL_SUFFIX="${USER_SUFFIX}-${TAG}"
else
  FINAL_SUFFIX="$TAG"
fi

# "${arr[@]}" is unbound under `set -u` when the array is empty.
set +u
if [[ "$CURSOR_MODE" -eq 1 ]]; then
  DUMP_FORCE_NUM="$NEXT_NUM" "$DUMPCHAT_CURSOR_CMD" "${PASSTHROUGH_ARGS[@]}" -append "$FINAL_SUFFIX"
  DUMP_FORCE_NUM="$NEXT_NUM" "$DUMPJSONL_CURSOR_CMD" "${PASSTHROUGH_ARGS[@]}" -append "$FINAL_SUFFIX"
elif [[ "$DEVIN_MODE" -eq 1 ]]; then
  # Devin CLI: readable .md + verbatim message_nodes .jsonl, same number+tag. Both
  # auto-select the current session (most recent in the Devin CLI sessions.db).
  DUMP_FORCE_NUM="$NEXT_NUM" "$DUMPCHAT_DEVIN_CMD" "${PASSTHROUGH_ARGS[@]}" -append "$FINAL_SUFFIX"
  DUMP_FORCE_NUM="$NEXT_NUM" "$DUMPJSONL_DEVIN_CMD" "${PASSTHROUGH_ARGS[@]}" -append "$FINAL_SUFFIX"
elif [[ "$CODEX_MODE" -eq 1 ]]; then
  # Codex: readable .md + verbatim rollout .jsonl, same number+tag. Both source
  # dumpchat/codex-session-find.sh, so they pick the SAME session file.
  DUMP_FORCE_NUM="$NEXT_NUM" "$DUMPCHAT_CODEX_CMD" "${PASSTHROUGH_ARGS[@]}" -append "$FINAL_SUFFIX"
  DUMP_FORCE_NUM="$NEXT_NUM" "$DUMPJSONL_CODEX_CMD" "${PASSTHROUGH_ARGS[@]}" -append "$FINAL_SUFFIX"
elif [[ "$GEMINI_MODE" -eq 1 ]]; then
  # Gemini CLI: readable .md + verbatim session .jsonl, same number+tag, same file
  # via dumpchat/gemini-session-find.sh.
  DUMP_FORCE_NUM="$NEXT_NUM" "$DUMPCHAT_GEMINI_CMD" "${PASSTHROUGH_ARGS[@]}" -append "$FINAL_SUFFIX"
  DUMP_FORCE_NUM="$NEXT_NUM" "$DUMPJSONL_GEMINI_CMD" "${PASSTHROUGH_ARGS[@]}" -append "$FINAL_SUFFIX"
elif [[ "$OPENCODE_MODE" -eq 1 ]]; then
  # OpenCode: both sides come from `opencode export` of newest non-empty session.
  DUMP_FORCE_NUM="$NEXT_NUM" "$DUMPCHAT_OPENCODE_CMD" "${PASSTHROUGH_ARGS[@]}" -append "$FINAL_SUFFIX"
  DUMP_FORCE_NUM="$NEXT_NUM" "$DUMPJSONL_OPENCODE_CMD" "${PASSTHROUGH_ARGS[@]}" -append "$FINAL_SUFFIX"
else
  DUMP_FORCE_NUM="$NEXT_NUM" "$DUMPCHAT_CMD" "${PASSTHROUGH_ARGS[@]}" -append "$FINAL_SUFFIX"
  DUMP_FORCE_NUM="$NEXT_NUM" "$DUMPJSONL_CMD" "${PASSTHROUGH_ARGS[@]}" -append "$FINAL_SUFFIX"
fi
set -u

MODE=cli; [[ $CURSOR_MODE -eq 1 ]] && MODE=cursor; [[ $DEVIN_MODE -eq 1 ]] && MODE=devin; [[ $CODEX_MODE -eq 1 ]] && MODE=codex; [[ $GEMINI_MODE -eq 1 ]] && MODE=gemini; [[ $OPENCODE_MODE -eq 1 ]] && MODE=opencode
echo "dumpboth: tag=$TAG number=$NEXT_NUM mode=$MODE"
