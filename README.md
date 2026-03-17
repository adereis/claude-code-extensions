# Claude Code Extensions

A collection of reusable extensions for Claude Code: agents, skills, hooks, and scripts.

## Related

- [claude-sandbox](https://github.com/adereis/claude-sandbox) - Containerized environment for running Claude Code in autonomous mode
- [mcp-servers](https://github.com/adereis/mcp-servers) - MCP servers (protocol layer, portable across clients)

## Extension Types

This repo covers Claude Code's extension points:

| Type | Description |
|------|-------------|
| Hooks | Event handlers that modify Claude's behavior |
| Skills | Reusable capabilities invoked via `/skill-name` (includes custom slash commands) |
| Agents | Specialized AI for specific tasks |
| Settings | Useful settings.json configurations (statusline, etc.) |
| Scripts | Standalone tools that complement Claude Code |

## Structure

```
claude-code-extensions/
├── hooks/            # Event handlers
├── skills/           # Slash commands and auto-invoked capabilities
├── agents/           # Specialized AI for specific tasks
├── settings/         # Settings.json configurations
├── scripts/          # Standalone tools (session-resume, etc.)
├── README.md         # This file
└── CLAUDE.md         # Workflow and conventions
```

## Installing

**Using `/sync`** (recommended): From this project directory, run `/sync` inside Claude Code. It syncs all extension types (agents, skills, hooks) to `~/.claude/`, detects conflicts, and verifies hook enablement in `settings.json`.

**Manual installation:**

- **Hooks**: Copy scripts to `~/.claude/hooks/` and add configuration to `~/.claude/settings.json` (see `hooks/README.md` for each hook's config)
- **Skills**: Copy skill directories to `~/.claude/skills/`
- **Agents**: Copy agent files to `~/.claude/agents/`
- **Settings**: Copy scripts to `~/.claude/settings/` and add configuration to `~/.claude/settings.json` (see `settings/README.md`)

## License

MIT
