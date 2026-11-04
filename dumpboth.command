#!/bin/bash
set -uo pipefail
# dumpboth.command — pure orchestrator, sources lib/ pieces only.
# Dumps BOTH .md + .jsonl on same oldchatN number + same random tag.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.
# Usage: dumpboth.command [cursor|devin] [home] [-append -suffix|suffix] [uuid] [target_dir]
#        dumpboth.command detect [home|target_dir]

DUMPBOTH_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DUMPBOTH_SCRIPT_DIR                                      # child scripts need this

source "$DUMPBOTH_SCRIPT_DIR/lib/detect/dispatch.sh" "$@"       # exits if detect mode
source "$DUMPBOTH_SCRIPT_DIR/lib/args/parse_mode.sh" "$@"       # detects cursor/devin mode + shorthand suffix
source "$DUMPBOTH_SCRIPT_DIR/lib/args/parse_target.sh"         # parses home/append/uuid/dir from remaining args
source "$DUMPBOTH_SCRIPT_DIR/lib/args/resolve_target.sh"        # enforces cursor-home, blocks scam dirs, sets OLD_CHATS_DIR
source "$DUMPBOTH_SCRIPT_DIR/lib/tag/build_suffix.sh"           # computes NEXT_NUM, TAG, FINAL_SUFFIX
source "$DUMPBOTH_SCRIPT_DIR/lib/execute/resolve_commands.sh"    # resolves 6 child dumper paths
source "$DUMPBOTH_SCRIPT_DIR/lib/execute/dispatch_pair.sh"      # runs chat + jsonl dumpers, captures CHAT_RC/JSONL_RC
source "$DUMPBOTH_SCRIPT_DIR/lib/execute/check_results.sh"      # exits 1 if both failed, prints summary
