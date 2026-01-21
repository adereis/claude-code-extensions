# Claude Code Extensions

A collection of reusable extensions for Claude Code: commands, agents, skills, hooks, and plugins.

## Related

- [claude-sandbox](https://github.com/adereis/claude-sandbox) - Experimental Claude Code projects and prototypes
- [mcp-servers](https://github.com/adereis/mcp-servers) - MCP servers (protocol layer, portable across clients)

## Extension Types

This repo covers Claude Code's extension points:

| Type | Description |
|------|-------------|
| Plugins | Comprehensive bundles (commands + agents + skills + hooks + MCP servers) |
| Hooks | Event handlers that modify Claude's behavior |
| Skills | Capabilities Claude can auto-invoke based on context |
| Agents | Specialized AI for specific tasks |
| Commands | Custom slash commands |

## Structure

```
claude-code-extensions/
├── plugins/          # Full plugin bundles
├── hooks/            # Event handlers
├── skills/           # Auto-invoked capabilities
├── agents/           # Specialized AI for specific tasks
├── commands/         # Slash commands
├── README.md         # This file
└── CLAUDE.md         # Workflow and conventions
```

## License

MIT
