# Claude Code Extensions

## Purpose

Reusable extensions for Claude Code. New extensions are developed collaboratively, with discussion before implementation.

## Interaction Workflow

**Every change follows this pattern:**

1. **Explain first**: Before implementing, explain:
   - What we're about to do
   - Why it works this way
   - How it fits into the bigger picture

2. **Implement**: Make the change after discussion

3. **Document learnings**: In the appropriate place (see below)

4. **Commit with context**: Commits explain "why" for future reference

## Where Documentation Goes

| Content | Location |
|---------|----------|
| Workflow, patterns, conventions | CLAUDE.md (this file) |
| Extension concepts, usage | README.md |
| Extension-specific details | `<extension-type>/README.md` |

**CLAUDE.md is NOT for domain knowledge.** Don't add Claude Code internals, extension API details, or learned technical facts here. This file is strictly about *how we work*, not *what we're learning*.

## Commit Message Guidelines

Commits are **learning artifacts**, not changelogs. They capture what we discussed and discovered, so someone can learn by reading `git log`.

```
Short summary (50-72 chars)

What this change does and why it matters.
Key concepts introduced or discovered.
Non-obvious details worth remembering.
```

Good commit messages answer:
- What concept did we explore?
- Why does it work this way?
- What wasn't obvious until we tried it?

Small fixes can be brief. Conceptual changes deserve thorough messages. See existing commits for examples.

---

## Extension Patterns

### Skill + Agent Pattern

For complex skills that need specialized behavior, use a thin skill that delegates to an agent:

1. **Skill** (`skills/foo/SKILL.md`): User-facing entry point with frontmatter and brief instructions.
2. **Agent** (`agents/foo.md`): Contains the detailed instructions, checklists, and logic.

Use `context: fork` and `agent: <agent-name>` in the skill frontmatter to delegate execution.

Note: `.claude/skills/` is for project-specific skills (e.g., `/sync` for this repo). `skills/` at repo root is for reusable skills to distribute.

### Skill + Script Pattern

For skills that wrap a standalone script, bundle the script inside the skill directory:

1. **Script** (`scripts/foo.py`): Standalone tool, usable directly from CLI.
2. **Skill copy** (`skills/foo/foo.py`): Identical copy bundled with the skill.
3. **SKILL.md** (`skills/foo/SKILL.md`): References `~/.claude/skills/foo/foo.py` so it works globally after sync.

`/sync` keeps the skill directory (including the script) in sync with `~/.claude/skills/`. The `scripts/` copy is the primary development location — update it first, then copy into the skill directory before syncing.

### Adding Hooks

When adding a new hook to `hooks/`:

1. Create the hook script in `hooks/`
2. Document it in `hooks/README.md` with:
   - What it does
   - The JSON configuration snippet for `settings.json`
   - Any notable behavior or caveats
3. Sync to `~/.claude/hooks/` for immediate use

## Relationship to MCP

MCP servers are a separate concern (protocol layer). See [mcp-servers](https://github.com/adereis/mcp-servers).

- MCP = portable across clients (Claude Code, Claude Desktop, etc.)
- Extensions here = Claude Code-specific
