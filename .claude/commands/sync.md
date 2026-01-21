Sync extensions between this project and the global ~/.claude/ directory.

## Usage

```
/sync              # Sync all extension types
```

## Extension Types

| Type | Project | Global |
|------|---------|--------|
| Commands | `commands/` | `~/.claude/commands/` |
| Agents | `agents/` | `~/.claude/agents/` |
| Skills | `skills/` | `~/.claude/skills/` |
| Hooks | `hooks/` | `~/.claude/hooks/` |

## Task

For each extension type:

1. **Inventory both locations**: List all .md files (and subdirectories for skills)
2. **Compare**: For items in both, check if contents differ
3. **Report status**:
   - Only in project
   - Only in global
   - Identical (✓)
   - Differ (⚠ conflict)

4. **For conflicts**: Show diff, ask which version to keep (or manual merge)

5. **For missing items**: Ask which direction to copy

## Important

- This command (`sync.md`) lives only in `.claude/commands/` - do NOT sync it
- Only sync from project root directories (`commands/`, `agents/`, `skills/`, `hooks/`), not `.claude/commands/`
- Skills are directories - compare all files within each skill
- Hooks: only sync executable scripts (e.g., `.sh`), not README.md. Remind user to check hooks/README.md for settings.json configuration
- After syncing, remind user to commit in git and yadm as appropriate
