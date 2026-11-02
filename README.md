# dumpboth

Claude Code skill: `/dumpboth` saves your AI coding chat as `.md` + `.jsonl`, on one matching name.

![/dumpboth typed in live Claude Code chat, saving matching md and jsonl pair](docs/images/dumpboth.png)

## Install

```sh
cp -R skills/* ~/.claude/skills/
```

This repo holds 3 skills that call each other, so install all 3: `dumpboth`, `dumpchat`, `dumpjsonl`.
Needs Python 3 and Bash.

## Use

In Claude Code:

```text
/dumpboth
/dumpboth mylabel
/dumpboth detect
```

Files land in `~/Old Chats/`. Add `cursor` or `devin` to save those sessions instead.

Full instructions: [skills/dumpboth/SKILL.md](skills/dumpboth/SKILL.md).

## See also

[dbv](https://github.com/towelWet/dbv): read saved chats on Mac.

[dumpconvert](https://github.com/towelWet/dumpconvert): turn saved chats into training dataset.
