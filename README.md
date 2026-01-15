# Claude Code Extensions

Learning project for Claude Code-specific extension mechanisms.

## Scope

This repo covers Claude Code's extension points:

| Type | Description |
|------|-------------|
| Plugins | Comprehensive bundles (commands + agents + skills + hooks + MCP servers) |
| Hooks | Event handlers that modify Claude's behavior |
| Skills | Capabilities Claude can auto-invoke based on context |
| Agents | Specialized AI for specific tasks |
| Commands | Custom slash commands |

For MCP servers (the protocol layer), see [mcp-servers](https://github.com/adereis/mcp-servers).

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
