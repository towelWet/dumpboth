#!/usr/bin/env python3
# shared_next_number.py — compute the ONE oldchatN number both md+jsonl will share.
# WHY IT EXISTS: dumpchat.command and dumpjsonl.command each auto-increment by
# scanning the dir independently — calling them back-to-back would let file #1
# claim N and file #2 claim N+1 (a race). /dumpboth computes N exactly ONCE here
# and forces both underlying scripts onto it via DUMP_FORCE_NUM.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.

import re                                            # extract the leading digits from oldchatN*.ext
import sys                                           # argv + stdout for CLI use
from pathlib import Path                             # directory scan


NUM_RE = re.compile(r"^oldchat(\d+)")                # matches "oldchat123-suffix.md" -> "123"


def shared_next_number(old_chats_dir: str) -> int:   # ONE function, per /split-files
    highest = 0
    root = Path(old_chats_dir)
    if not root.is_dir():
        return 1                                     # empty/missing dir -> start the sequence at 1
    for path in root.glob("oldchat*.md"):
        m = NUM_RE.match(path.name)
        if m:
            highest = max(highest, int(m.group(1)))
    for path in root.glob("oldchat*.jsonl"):
        m = NUM_RE.match(path.name)
        if m:
            highest = max(highest, int(m.group(1)))
    return highest + 1


if __name__ == "__main__":                           # python3 shared_next_number.py <old_chats_dir>
    sys.stdout.write(str(shared_next_number(sys.argv[1])))
