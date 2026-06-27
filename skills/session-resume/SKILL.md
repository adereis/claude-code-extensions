---
name: session-resume
description: Smart session resume with enriched history
argument-hint: "[-n count] [-v] [-a]"
---

Show enriched session history and help the user resume a session.

## Steps

1. Run: `python3 ~/.claude/skills/session-resume/claude-code-session-resume.py --skill $ARGUMENTS`
2. Present the output to the user. Each session shows its title, a few prompts,
   and the commits made; the header line includes the session ID.
3. Ask which session they'd like to resume.
4. When they pick one, tell them to run: `/resume <session-id>`

Pass through any user arguments (e.g., `-n 20`, `-v`, `--all`). The `--skill`
flag already forces plain, color-free output suitable for piping.
