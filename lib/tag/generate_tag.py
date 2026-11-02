#!/usr/bin/env python3
# generate_tag.py — mint a random matching tag shared by one md+jsonl dump pair.
# WHY IT EXISTS: numbers alone can desync if /dumpchat and /dumpjsonl are ever run
# independently again later — the tag is a second, content-free identifier that
# proves two files came from the SAME /dumpboth invocation even if their numbers drift.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.

import os                                            # os.urandom is the entropy source
import sys                                           # sys.argv/stdout for CLI use


def generate_tag() -> str:                           # ONE function, per /split-files
    # 4 random bytes -> 8 lowercase hex chars. Short enough to stay readable in a
    # filename, long enough that two dumps colliding is astronomically unlikely.
    return os.urandom(4).hex()


if __name__ == "__main__":                           # allow `python3 generate_tag.py` from bash
    sys.stdout.write(generate_tag())
