# dumpboth

dumpboth saves your AI coding chat as `.md` + `.jsonl`.

![/dumpboth typed in live Claude Code chat, saving matching md and jsonl pair](docs/images/dumpboth.png)

## Easy install

For example, Claude Code:

Drag this repo into ~/.claude/skills

![Dragging this repo into ~/.claude/skills](docs/images/install.gif)

Can't see `.claude`? Press Cmd+Shift+. in Finder.

## Use

```text
/dumpboth
/dumpboth mylabel
```

Your chats land in `~/Old Chats/`.

dumpboth saves only the chat whose session ID it's given; it never guesses "newest".
Claude Code: ID read from `CLAUDE_CODE_SESSION_ID`. Codex, Devin and cursor-agent:
their session env var is read when set. Otherwise, pass the ID:

```text
/dumpboth cursor <chat-uuid>
/dumpboth devin id <session-id>
/dumpchat gemini id <session-id>
```

No ID or no matching file → it refuses and writes nothing.

## Also see

[DBV](https://github.com/towelWet/dbv), a Mac chat viewer for your saved Claude chats.

[dumpconvert](https://github.com/towelWet/dumpconvert) turns them into a training dataset.
