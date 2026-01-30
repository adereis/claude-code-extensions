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

4. **For conflicts**:
   - Show diff
   - **Critically review** additions against project goals: extensions here should be generic and lean (reusable across projects, not bloated)
   - If bringing content from global → project, assess whether additions fit these goals; propose trimming verbose or overly-specific content
   - Present your assessment, then ask which version to keep (or offer a trimmed alternative)

5. **For missing items**: Ask which direction to copy

## Important

- This command (`sync.md`) lives only in `.claude/commands/` - do NOT sync it
- Only sync from project root directories (`commands/`, `agents/`, `skills/`, `hooks/`), not `.claude/commands/`
- Skills are directories - compare all files within each skill
- Hooks: only sync executable scripts (e.g., `.sh`), not README.md
- After syncing, remind user to commit in git and yadm as appropriate

## Hook Enablement Check

After syncing hooks, verify they're enabled in `~/.claude/settings.json`:

1. Read `~/.claude/settings.json`
2. For each hook script in `~/.claude/hooks/`, check if it appears in the `hooks` configuration
3. Report status:
   - ✓ Enabled (appears in settings.json)
   - ⚠ Not enabled (file exists but not configured)
4. For hooks not enabled: ask user if they want you to add the configuration to settings.json (use `hooks/README.md` as reference for the correct snippet)
