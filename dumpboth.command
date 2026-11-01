#!/bin/bash
# dumpboth.command — save current AI chat as .md + .jsonl on same number and tag.
# Why: two separate dumps can drift; one number and tag ties each pair together.
# Usage: dumpboth.command [agent] [home|dir] [-append suffix|suffix] [uuid]
#        dumpboth.command detect [home|dir]
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "${1:-}" == "detect" ]]; then
  [[ -n "${2:-}" && "${2:-}" != "home" ]] && DIR="$2" || DIR="$HOME"
  exec python3 "$ROOT/lib/detect/cli.py" "$DIR/Old Chats"
fi

source "$ROOT/lib/args/parse_both_args.sh"
parse_both_args "$ROOT/agents" "$@"                         # sets AGENT, SUFFIX, TARGET_DIR, SESSION_ID
source "$ROOT/lib/block/refuse_blocked_dir.sh"
refuse_blocked_dir "$TARGET_DIR"
OLD_CHATS="$TARGET_DIR/Old Chats"
mkdir -p "$OLD_CHATS"

NUMBER="$(python3 "$ROOT/lib/counter/shared_next_number.py" "$OLD_CHATS")"
TAG="$(python3 "$ROOT/lib/tag/generate_tag.py")"
NAME="${SUFFIX:+$SUFFIX-}$TAG"                              # user suffix first, random tag always last

for kind in md jsonl; do                                    # same number + name, so pair cannot split
  DUMP_FORCE_NUM="$NUMBER" "$ROOT/dump/$kind.command" "$AGENT" "$TARGET_DIR" ${SESSION_ID:+"$SESSION_ID"} -append "$NAME"
done
echo "dumpboth: tag=$TAG number=$NUMBER mode=$AGENT"
