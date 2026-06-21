#!/usr/bin/env bash
# Claude Code status line — two-row columnar layout
# Row 1: dim column headers  |  Row 2: colored values
#
# Fields (when available):
#   vim mode | workspace | branch | profile | model | context | quota/cost | memory
#
# Context and quota columns change color by usage tier:
#   green (<50%) → yellow (50-79%) → red (≥80%)
#
# Platform support: Linux and macOS (memory detection adapts automatically)
#
# Usage: Configure in ~/.claude/settings.json:
#   "statusLine": {
#     "type": "command",
#     "command": "~/.claude/statusline.sh",
#     "refreshInterval": 10
#   }

input=$(cat)

# ── Platform detection (once) ───────────────────────────────────────
_PLATFORM=$(uname -s)

# ── Helpers ──────────────────────────────────────────────────────────

pad() {
  local gap=$(( $2 - ${#1} ))
  (( gap < 0 )) && gap=0
  printf '%s%*s' "$1" "$gap" ''
}

_proc_comm() {
  case "$_PLATFORM" in
    Linux)  cat "/proc/$1/comm" 2>/dev/null ;;
    Darwin) ps -o comm= -p "$1" 2>/dev/null | xargs basename 2>/dev/null ;;
  esac
}

_proc_ppid() {
  case "$_PLATFORM" in
    Linux)  awk '/^PPid:/ {print $2}' "/proc/$1/status" 2>/dev/null ;;
    Darwin) ps -o ppid= -p "$1" 2>/dev/null | tr -d ' ' ;;
  esac
}

_proc_rss_kb() {
  case "$_PLATFORM" in
    Linux)  awk '/^VmRSS:/ {print $2}' "/proc/$1/status" 2>/dev/null ;;
    Darwin) ps -o rss= -p "$1" 2>/dev/null | tr -d ' ' ;;
  esac
}

# ── Extract all fields in one jq call ────────────────────────────────
# Each value on its own line — avoids bash IFS tab-stripping bug where
# leading/consecutive tabs are silently dropped, shifting all fields.

{
  read -r vim_mode
  read -r cwd
  read -r model_val
  read -r ctx_pct
  read -r q
  read -r cost_val
} < <(printf '%s' "$input" | jq -r '
    def val: if . == null then "" else tostring end;
    (.vim.mode | val),
    (.workspace.current_dir | val),
    ((if .model | type == "array" then .model[0].display_name
      elif .model | type == "object" then .model.display_name
      else .model end) | val),
    (.context_window.used_percentage | val),
    (.rate_limits.five_hour.used_percentage | val),
    (.cost.total_cost_usd | val)')

short_cwd="${cwd/#$HOME/\~}"

# ── Git branch + dirty state ────────────────────────────────────────

git_val=""
if [ -n "$cwd" ] && git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
  branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null ||
           git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null || true)
  d="" s="" u=""
  git -C "$cwd" --no-optional-locks diff --quiet 2>/dev/null || d='*'
  git -C "$cwd" --no-optional-locks diff --cached --quiet 2>/dev/null || s='+'
  git -C "$cwd" --no-optional-locks ls-files --others --exclude-standard 2>/dev/null \
    | head -1 | grep -q . && u='?' || true
  git_val="${branch}${d}${s}${u}"
fi

# ── Profile (vertex / subscription) ─────────────────────────────────

if [ -n "${CLAUDE_CODE_USE_VERTEX:-}" ] && [ "${CLAUDE_CODE_USE_VERTEX}" != '0' ]; then
  profile_val="vertex"  profile_clr="\033[33m"
else
  profile_val="pro"     profile_clr="\033[36m"
fi

# ── Context — color by usage tier ────────────────────────────────────

ctx_val="" ctx_clr="\033[32m"
if [ -n "$ctx_pct" ]; then
  ctx_int=${ctx_pct%%.*}
  if [ "${ctx_int:-0}" -ge 80 ] 2>/dev/null; then
    ctx_clr="\033[31m"
  elif [ "${ctx_int:-0}" -ge 50 ] 2>/dev/null; then
    ctx_clr="\033[33m"
  fi
  ctx_val=$(printf '%.0f%% used' "$ctx_pct")
fi

# ── Quota — 5-hour rate limit (subscription only) ────────────────────

quota_val="" quota_clr="\033[32m"
if [ -n "$q" ]; then
  qi=${q%%.*}
  if [ "${qi:-0}" -ge 80 ] 2>/dev/null; then
    quota_clr="\033[31m"
  elif [ "${qi:-0}" -ge 50 ] 2>/dev/null; then
    quota_clr="\033[33m"
  fi
  quota_val=$(printf '%.0f%% used' "$q")
fi

# ── Cost — estimated session cost (all backends) ─────────────────────

cost_disp=""
[ -n "$cost_val" ] && cost_disp=$(printf '$%.4f' "$cost_val")

# ── Process memory (walk up to find Claude Code's node process) ──────

mem_val=""
cc_pid=$PPID
comm=$(_proc_comm "$cc_pid")
case "$comm" in
  node|claude) ;;
  *) cc_pid=$(_proc_ppid "$cc_pid") ;;
esac
if [ -n "$cc_pid" ]; then
  vmrss=$(_proc_rss_kb "$cc_pid")
  if [ -n "$vmrss" ] && [ "$vmrss" -gt 0 ] 2>/dev/null; then
    mem_val=$(awk "BEGIN {printf \"%.1f MB\", $vmrss / 1024}")
  fi
fi

# ── Build two-row output ────────────────────────────────────────────

DIM="\033[2m"  RST="\033[0m"  BOLD="\033[1m"
SEP="   "
hdr="" val=""

col() {
  local h="$1" v="$2" c="$3"
  local w=${#v}; (( ${#h} > w )) && w=${#h}
  hdr+="${DIM}$(pad "$h" "$w")${RST}${SEP}"
  val+="${c}$(pad "$v" "$w")${RST}${SEP}"
}

[ -n "$vim_mode" ] && col "mode" "[${vim_mode:0:3}]" "\033[1;35m"
col "workspace" "$short_cwd" "${BOLD}\033[34m"
[ -n "$git_val" ]   && col "branch"     "$git_val"     "\033[33m"
                       col "profile"    "$profile_val" "$profile_clr"
[ -n "$model_val" ] && col "model"      "$model_val"   "\033[32m"
[ -n "$ctx_val" ]   && col "context"    "$ctx_val"     "$ctx_clr"
[ -n "$quota_val" ] && col "quota"      "$quota_val"   "$quota_clr"
[ -n "$cost_disp" ] && col "cost"       "$cost_disp"   "\033[36m"
[ -n "$mem_val" ]   && col "memory"     "$mem_val"     "\033[36m"

printf '%b\n%b' "$hdr" "$val"
