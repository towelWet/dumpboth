#!/usr/bin/env python3
# is_system_blob.py — true for injected context records.
# Why: they are not part of conversation.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.
def is_system_blob(text):
    return text.startswith(("<project_context", "<session_context"))
