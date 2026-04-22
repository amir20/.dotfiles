#!/bin/bash
input=$(cat)
dir=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
dir_display=$(basename "$dir")
model=$(echo "$input" | jq -r '.model.display_name // ""')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
input_tokens=$(echo "$input" | jq -r '.context_window.current_usage.input_tokens // empty')
ctx_size=$(echo "$input" | jq -r '.context_window.context_window_size // empty')

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

  # Format token counts compactly (e.g. 45k / 200k)
  token_info=""
  if [ -n "$input_tokens" ] && [ -n "$ctx_size" ]; then
    used_k=$(( input_tokens / 1000 ))
    total_k=$(( ctx_size / 1000 ))
    token_info=" ${DIM}${used_k}k/${total_k}k${RESET}"
  fi

  output="${output}$(printf " ${DIM}|${RESET} ${bcolor}%s${RESET}${token_info} ${DIM}%s%%${RESET}" "$bar" "$pct")"
fi

printf '%s' "$output"
