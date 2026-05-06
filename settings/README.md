# Settings

Claude Code settings configurations. Add these snippets to your `~/.claude/settings.json`.

## statusline.sh

A two-row columnar statusline with dim headers and colored values. Adapts to your setup — vim mode only appears if enabled, quota shows rate-limit percentage or falls back to session cost, and memory detection works on both Linux and macOS.

**Example output** (with vim mode enabled):
```
mode      workspace               branch   profile   model        context    quota       memory
[NORMAL]  ~/projects/my-app       main*+%  pro       Opus 4.6     23% used   42% used    312.5 MB
```

**Columns:**

| Column | Color | Description |
|--------|-------|-------------|
| mode | Bold magenta | Vim mode indicator (only when vim mode is on) |
| workspace | Bold blue | Working directory (`~` shorthand for `$HOME`) |
| branch | Yellow | Git branch + status indicators (`*` dirty, `+` staged, `%` untracked) |
| profile | Cyan/Yellow | `pro` (subscription) or `vertex` (Vertex AI) |
| model | Green | Active model display name |
| context | Green→Yellow→Red | Context window usage, color-coded by tier |
| quota | Green→Yellow→Red | 5-hour rate limit usage (or session `cost` as fallback) |
| memory | Cyan | Claude Code process RSS memory |

**Color thresholds** (context and quota):
- **Green**: < 50% used
- **Yellow**: 50–79% used
- **Red**: ≥ 80% used

**Installation:**

1. Copy `statusline.sh` to `~/.claude/settings/`
2. Make it executable: `chmod +x ~/.claude/settings/statusline.sh`
3. Add to `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/settings/statusline.sh",
    "refreshInterval": 10
  }
}
```

**Platform notes:**

- **Linux**: Memory detection reads `/proc/<pid>/status` (VmRSS)
- **macOS**: Memory detection uses `ps -o rss=`
- Requires `jq` and `git` in `$PATH`

**Customization:**

The script uses ANSI escape codes for colors. To change them, modify the `\033[XXm` sequences:
- `31` = red, `32` = green, `33` = yellow, `34` = blue, `35` = magenta, `36` = cyan
- `01;XX` = bold, `2m` = dim (used for headers)

To hide a column, comment out or remove its `col` call near the end of the script.
