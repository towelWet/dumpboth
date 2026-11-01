#!/usr/bin/env python3
# session_field.py — print one field from select-session.py's JSON on stdin.
# Why: keeps Python out of shell scripts. Missing field prints empty line.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.
import json, sys


def session_field(name):
    print(json.load(sys.stdin).get(name) or "")


if __name__ == "__main__":
    session_field(sys.argv[1])
