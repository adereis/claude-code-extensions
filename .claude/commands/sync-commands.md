Sync slash commands between this project and the global ~/.claude/commands/ directory.

## Locations

- **Project**: `commands/` in this repository (tracked by git)
- **Global**: `~/.claude/commands/` (tracked by yadm)

## Task

1. **Inventory both locations**: List all .md files in each
2. **Compare**: For files that exist in both, check if contents differ
3. **Report status**:
   - Files only in project
   - Files only in global
   - Files in both that are identical (✓)
   - Files in both that differ (⚠ conflict)

4. **For conflicts**: Show a diff and ask which version to keep (or if manual merge is needed)

5. **For missing files**: Ask which direction to copy

## Important

- The `sync-commands.md` file itself (this command) lives only in the project `.claude/commands/` - do NOT sync it to global
- Only sync files from the project's `commands/` directory (not `.claude/commands/`)
- After syncing, remind the user to commit changes in both git and yadm as appropriate
