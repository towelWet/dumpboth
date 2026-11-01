#!/usr/bin/env python3
# model/friendly_name.py — format Claude model id for humans: claude-sonnet-4-6 becomes Sonnet 4.6.
# Why: family comes from id itself, not a list, so new families format correctly with no edit here.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.
import re

PREFIX = "claude-"


def friendly_name(mid):
    """'claude-sonnet-4-6' → 'Sonnet 4.6'  |  None → 'Claude'"""
    if not mid:
        return "Claude"
    if not mid.startswith(PREFIX):                                   # other vendor's id: show exactly as written
        return mid
    parts = re.sub(r"\[.*\]$", "", mid[len(PREFIX):]).split("-")     # drop context suffix such as [1m]
    words = [p.capitalize() for p in parts if p.isalpha()]
    nums = [p for p in parts if p.isdigit() and len(p) <= 2]         # longer digit runs are date stamps
    return f"{' '.join(words)} {'.'.join(nums)}" if words and nums else mid
