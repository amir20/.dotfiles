#!/bin/bash
input=$(cat)
dir=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
dir_display=$(basename "$dir")
model=$(echo "$input" | jq -r '.model.display_name // ""')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
input_tokens=$(echo "$input" | jq -r '.context_window.current_usage.input_tokens // empty')
ctx_size=$(echo "$input" | jq -r '.context_window.context_window_size // empty')
lines_added=$(echo "$input" | jq -r '.cost.total_lines_added // empty')
lines_removed=$(echo "$input" | jq -r '.cost.total_lines_removed // empty')
rl_5h_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
rl_5h_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
rl_7d_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
rl_7d_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

# ANSI colors
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
RESET='\033[0m'
DIM='\033[2m'
BOLD='\033[1m'

# Git branch (skip optional lock to avoid interference)
git_branch=""
if [ -d "${dir}/.git" ] || git -C "$dir" rev-parse --git-dir > /dev/null 2>&1; then
  git_branch=$(git -C "$dir" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)
fi

# Build progress bar (10 blocks wide)
build_bar() {
  local pct="$1"
  local filled=$(( pct * 10 / 100 ))
  local empty=$(( 10 - filled ))
  local bar=""
  local i=0
  while [ $i -lt $filled ]; do
    bar="${bar}█"
    i=$(( i + 1 ))
  done
  i=0
  while [ $i -lt $empty ]; do
    bar="${bar}░"
    i=$(( i + 1 ))
  done
  echo "$bar"
}

# Pick bar color based on usage
bar_color() {
  local pct="$1"
  if [ "$pct" -ge 80 ]; then
    printf '\033[0;31m'   # red
  elif [ "$pct" -ge 50 ]; then
    printf '\033[0;33m'   # yellow
  else
    printf '\033[0;32m'   # green
  fi
}

# --- assemble output ---
output=$(printf "${CYAN}%s${RESET}" "$dir_display")

if [ -n "$git_branch" ]; then
  output="${output}$(printf " ${DIM}on${RESET} ${BOLD}%s${RESET}" "$git_branch")"
fi

if [ -n "$model" ]; then
  output="${output}$(printf " ${DIM}|${RESET} ${PURPLE}%s${RESET}" "$model")"
fi

if [ -n "$used_pct" ]; then
  pct=$(printf '%.0f' "$used_pct")
  bar=$(build_bar "$pct")
  bcolor=$(bar_color "$pct")

  # Format token counts compactly (e.g. 45k / 200k, 1.2m / 2m)
  fmt_tokens() {
    local n="$1"
    if [ "$n" -ge 1000000 ]; then
      awk -v n="$n" 'BEGIN { printf "%.1fm", n/1000000 }' | sed 's/\.0m/m/'
    else
      printf '%dk' $(( n / 1000 ))
    fi
  }
  token_info=""
  if [ -n "$ctx_size" ]; then
    used_tokens=$(awk -v c="$ctx_size" -v p="$used_pct" 'BEGIN { printf "%d", c * p / 100 }')
    token_info=" ${DIM}$(fmt_tokens "$used_tokens")/$(fmt_tokens "$ctx_size")${RESET}"
  fi

  output="${output}$(printf " ${DIM}|${RESET} ${bcolor}%s${RESET}${token_info} ${DIM}%s%%${RESET}" "$bar" "$pct")"
fi

# Format seconds-until-reset as compact duration (e.g. 2h14m, 3d4h)
fmt_reset() {
  local resets_at="$1"
  local now=$(date +%s)
  local diff=$(( resets_at - now ))
  [ "$diff" -le 0 ] && { printf 'now'; return; }
  local days=$(( diff / 86400 ))
  local hours=$(( (diff % 86400) / 3600 ))
  local mins=$(( (diff % 3600) / 60 ))
  if [ "$days" -gt 0 ]; then
    printf '%dd%dh' "$days" "$hours"
  elif [ "$hours" -gt 0 ]; then
    printf '%dh%dm' "$hours" "$mins"
  else
    printf '%dm' "$mins"
  fi
}

# Rate limit usage (Max plan)
render_limit() {
  local label="$1" pct_raw="$2" reset="$3"
  [ -z "$pct_raw" ] && return
  local pct=$(printf '%.0f' "$pct_raw")
  local bar=$(build_bar "$pct")
  local bcolor=$(bar_color "$pct")
  local reset_info=""
  [ -n "$reset" ] && reset_info=" ${DIM}↻$(fmt_reset "$reset")${RESET}"
  printf " ${DIM}|${RESET} ${DIM}%s${RESET} ${bcolor}%s${RESET} ${DIM}%s%%${RESET}%b" \
    "$label" "$bar" "$pct" "$reset_info"
}

output="${output}$(render_limit "5h" "$rl_5h_pct" "$rl_5h_reset")"
output="${output}$(render_limit "7d" "$rl_7d_pct" "$rl_7d_reset")"

if [ -n "$lines_added" ] || [ -n "$lines_removed" ]; then
  output="${output}$(printf " ${DIM}|${RESET} ${GREEN}+%s${RESET}${DIM}/${RESET}${RED}-%s${RESET}" "${lines_added:-0}" "${lines_removed:-0}")"
fi

printf '%s' "$output"
