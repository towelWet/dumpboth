#!/usr/bin/env python3
# summarize_tool.py — one tool call as short readable lines.
# Why: full tool input would swamp transcript; limits are cosmetic only.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.
COMMAND_MAX, VALUE_MAX, MAX_FIELDS = 140, 80, 4


def summarize_tool(item):
    name, data = item.get("name", "unknown"), item.get("input") or {}
    if not isinstance(data, dict):
        return f"Tool: {name}"
    if "command" in data:
        command = str(data["command"]).replace("\n", " ")
        return f"Tool: {name}\n{command if len(command) <= COMMAND_MAX else command[:COMMAND_MAX - 3] + '...'}"
    if "path" in data:
        extra = f" — {data['description']}" if "description" in data else ""
        return f"Tool: {name}\npath: {data['path']}{extra}"
    if "description" in data:
        return f"Tool: {name}\n{data['description']}"
    parts = []
    for key, value in list(data.items())[:MAX_FIELDS]:
        text = str(value).replace("\n", " ")
        parts.append(f"{key}: {text if len(text) <= VALUE_MAX else text[:VALUE_MAX - 3] + '...'}")
    return "Tool: " + name + ("\n" + "\n".join(parts) if parts else "")
