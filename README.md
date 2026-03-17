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

## Installing Hooks

1. Copy hook scripts to `~/.claude/hooks/`
2. Add configuration to `~/.claude/settings.json` (see `hooks/README.md` for each hook's config)

## Installing Settings

1. Copy scripts to `~/.claude/settings/`
2. Add configuration to `~/.claude/settings.json` (see `settings/README.md` for details)

## License

MIT
