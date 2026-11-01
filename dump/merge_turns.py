#!/usr/bin/env python3
# merge_turns.py — join consecutive assistant chunks into one turn when agent asks for it.
# Why: some agents log one answer as many records; printing each reads as stutter.
# join=None keeps every record as own turn. dedupe=True drops chunks already in buffer.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.
def merge_turns(turns, join, dedupe):
    pending = None
    for role, text in turns:
        if join is None:
            yield role, text
        elif role == "assistant":
            clean = text.strip()
            if pending is None:
                pending = clean
            elif not dedupe or clean not in pending:
                pending += join + clean
        else:
            if pending:
                yield "assistant", pending
            pending = None
            yield role, text
    if pending:
        yield "assistant", pending
