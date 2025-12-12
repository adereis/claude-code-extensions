# Claude Code Extensions - Learning Project

## Purpose

Educational project for learning Claude Code's extension mechanisms.
The depth of exploration is calibrated through conversation.

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

(Filled in as we establish patterns)

## Relationship to MCP

MCP servers are a separate concern (protocol layer). See [mcp-servers](https://github.com/adereis/mcp-servers).

Plugins can *contain* MCP servers, but we keep them separate:
- MCP = portable across clients (Claude Code, Claude Desktop, etc.)
- Extensions here = Claude Code-specific
