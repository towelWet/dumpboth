#!/bin/bash
# resolve_commands.sh — resolve paths to all 6 child dumper commands.
# Expects: DUMPBOTH_SCRIPT_DIR.
# Exports: DUMPCHAT_CMD, DUMPJSONL_CMD, plus cursor/devin variants.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.

DUMPCHAT_CMD="$DUMPBOTH_SCRIPT_DIR/dumpchat/dumpchat.command"
DUMPJSONL_CMD="$DUMPBOTH_SCRIPT_DIR/dumpjsonl/dumpjsonl.command"
DUMPCHAT_CURSOR_CMD="$DUMPBOTH_SCRIPT_DIR/dumpchat/dumpchat-cursor.command"
DUMPJSONL_CURSOR_CMD="$DUMPBOTH_SCRIPT_DIR/dumpjsonl/dumpjsonl-cursor.command"
DUMPCHAT_DEVIN_CMD="$DUMPBOTH_SCRIPT_DIR/dumpchat/dumpchat-devin.command"
DUMPJSONL_DEVIN_CMD="$DUMPBOTH_SCRIPT_DIR/dumpjsonl/dumpjsonl-devin.command"
