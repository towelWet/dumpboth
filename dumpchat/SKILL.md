---
name: dumpchat
description: Export current session to Old Chats directory with auto-increment filename
---

# Dump Chat to Old Chats

## EXECUTE IMMEDIATELY

When invoked, run this command **without any other logic or reimplementation**:

```bash
~/.claude/skills/dumpboth/dumpchat/dumpchat.command [args]
```

Pass any user-provided args directly. Do not inline the logic. Do not reimagine it. Just run the script.

## `-append` Flag

If the user says `/dumpchat append -some-suffix`, run:

```bash
~/.claude/skills/dumpboth/dumpchat/dumpchat.command -append -some-suffix
```

This produces `oldchatN-some-suffix.md` where N is auto-incremented.

**Examples:**
- `/dumpchat` → `oldchat92.md`
- `/dumpchat append -ai-fuel-fix` → `oldchat92-ai-fuel-fix.md`
- `/dumpchat append -my-feature` → `oldchat92-my-feature.md`

## Specific Session ID

If user provides a bare UUID, dump that specific session:

```bash
~/.claude/skills/dumpboth/dumpchat/dumpchat.command 59ef6781-2722-4790-971d-22f8b1a40ec9
```

The script auto-detects UUID pattern and searches all CLI directories for a matching session file.

**Examples:**
- `/dumpchat 59ef6781-2722-4790-971d-22f8b1a40ec9` → dump that specific session
- `/dumpchat 59ef6781-2722-4790-971d-22f8b1a40ec9 append -my-label` → specific session with suffix
- User pastes a UUID after `/dumpchat` → pass it as first arg

The .command script handles:
- Copying listoldchats.command to skills folder if missing
- Creating Old Chats/ directory in current working directory if needed
- Running the export

## What It Does

**Canonical source is jsonl.** This skill exports jsonl → md for human reading. Markdown is never the training source.

1. **Detects current session** - finds the most recently modified JSONL in `~/.claude/projects/` that is NOT a memory agent session (skips files containing "Hello memory agent")
2. **Reads session data** - loads the conversation from JSONL format
3. **Converts to markdown** - formats conversation as readable markdown with speaker labels
4. **Auto-increments filename** - checks existing `oldchat*.md` files and saves as next number
5. **Saves to Old Chats/** - outputs to `./Old Chats/oldchatN.md` in current working directory
6. **Writes Source footer** - appends `Source: ~/.claude/projects/-Users-time/<uuid>.jsonl` for jsonl recovery

## Output Format

```markdown
▐▛███▜▌   Claude Code v2.1.75
▝▜█████▛▘  Haiku 4.5 · Claude Pro
  ▘▘ ▝▝    /path/to/working/directory

❯ [user message]

⏺ [claude response]

[alternating user/claude messages...]

Resume: claude --resume <session-id>
```

## Auto-Increment

Finds the highest `oldchatN.md` file and increments by 1:
- `oldchat1.md`, `oldchat2.md` → saves as `oldchat3.md`
- No files → saves as `oldchat1.md`

## 'Wrong Folder' Recovery

If the user says **'wrong folder'** or **'/dumpchat home'** (or variants: Home, HOME), run the home variant:

```bash
~/.claude/skills/dumpboth/dumpchat/dumpchat-wrong-folder.command [args]
```

This exports to `~/Old Chats/` instead of the current working directory.

**Examples:**
- User says `wrong folder` after `/dumpchat` → runs dumpchat-wrong-folder.command
- User says `/dumpchat wrong folder` → runs dumpchat-wrong-folder.command
- User says `/dumpchat home` → runs dumpchat-wrong-folder.command
- User says `/dumpchat Home` or `/dumpchat HOME` → runs dumpchat-wrong-folder.command

## Other CLI Support

Four additional scripts handle sessions from other AI CLIs. Each has the same interface as `dumpchat.command`:

| Script | CLI | Session Location | Format |
|--------|-----|-----------------|--------|
| `dumpchat-codex.command` | Codex (OpenAI) | `~/.codex/sessions/YYYY/MM/DD/rollout-*.jsonl` | JSONL: `response_item` messages |
| `dumpchat-gemini.command` | Gemini CLI (Google) | `~/.gemini/tmp/<project>/chats/session-*.jsonl` | JSONL: `type: user|gemini` lines |
| `dumpchat-kilo.command` | Kilo Code | `~/.kilocode/storage/session/message/*/*.json` | Hierarchical JSON per message |
| `dumpchat-opencode.command` | OpenCode | `~/.opencode/storage/session/message/*/*.json` | Hierarchical JSON per message |
| `dumpchat-devin.command` | Devin CLI | `~/.local/share/devin/cli/sessions.db` | SQLite: `sessions` + `message_nodes` tables |
| `dumpchat-cursor.command` | Cursor (IDE agent) | `~/.cursor/projects/*/agent-transcripts/<uuid>/<uuid>.jsonl` | JSONL role/user/assistant |

All scripts support the same `-append -suffix` flag and custom target directory argument. Each outputs to `Old Chats/oldchatN.md` with the correct CLI branding, header, and resume command.

**Examples:**
- `/dumpchat gemini` → runs dumpchat-gemini.command
- `/dumpchat codex` → runs dumpchat-codex.command
- `/dumpchat devin` → runs dumpchat-devin.command
- `/dumpchat cursor` → runs dumpchat-cursor.command
- `/dumpchat gemini append -my-fix` → runs dumpchat-gemini.command -append -my-fix
- `/dumpchat cursor append -foo` → runs dumpchat-cursor.command -append -foo
- `/dumpchat cursor <uuid>` → runs dumpchat-cursor.command `<uuid>`

## Auto-Comment (DEFAULT ON)

After every dump, **always** run `/comment-file` on the output file automatically — no keyword needed.

**How to handle:**
1. Run the dump normally
2. After dump succeeds and output path is known, invoke the `/comment-file` skill on that path

The `comment` keyword is still accepted for backwards compatibility but is now a no-op (commenting is always on).

## Triggers

Use when:
- Session is ending and you want to archive it
- You want to save a conversation for reference
- You need to clear context but keep history
- User reports 'wrong folder' — use dumpchat-wrong-folder.command variant
- `/dumpchat gemini` — export current Gemini CLI session
- `/dumpchat codex` — export current Codex session
- `/dumpchat kilo` — export current Kilo session
- `/dumpchat opencode` — export current OpenCode session
- `/dumpchat devin` — export current Devin CLI session
- `/dumpchat cursor` — export current Cursor IDE agent session
- `/dumpchat cursor append -suffix` — Cursor session with suffix
- `/dumpchat cursor <uuid>` — export a specific Cursor session by UUID

## Example of improper skill use (common and stupid)

⏺ Bash(~/.claude/skills/dumpboth/dumpchat/dumpchat-wrong-folder.command -append -site-re)
Exported session to ~/Old Chats/oldchat474-site-re.md

⏺ Skill(comment-file)
Successfully loaded skill
2 PostToolUse hooks ran

⏺ Bash(head -50 "~/Old Chats/oldchat474-site-re.md")
 ▐▛███▜▌   Claude Code
▝▜█████▛▘  Haiku 4.5 · Claude Pro
  ▘▘ ▝▝    ~

❯ Hello memory agent, you are continuing to observe the primary Claude session.

## Training data hierarchy — jsonl first

```
1. PRIMARY:   ~/.claude/projects/-Users-time/<uuid>.jsonl (canonical live session)
2. RECOVER:   Source footer in dumpchat md → hunt UUID on your other drives
3. VERIFY:    /find-claude-chat spot-check 3-5 domain terms before training
4. CONVERT:   jsonl → messages format for Unsloth (preserve tool calls + full turns)
5. NEVER DEFAULT: meta-rev/train.jsonl, tyom md chunks, unsloth/alpaca-cleaned Hub, or derivatives without explicit user opt-in
```

Markdown dumps are **human export only**. Train on recovered jsonl, not md. See **`/unsloth`** and **`/tyom`** for the conversion + training pipeline.