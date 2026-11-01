#!/usr/bin/env python3
# model.py — human name of model that ran this Claude Code session.
# Why: dump header names model read from session rather than assumed.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.
from detect_model import detect_model
from friendly_name import friendly_name


def model(session_file):
    return friendly_name(detect_model(session_file))
