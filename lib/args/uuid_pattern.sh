#!/bin/bash
# uuid_pattern.sh — pattern for session ids given on command line.
# Why: both arg parsers must agree on what counts as session id.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.
UUID_RE='^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
