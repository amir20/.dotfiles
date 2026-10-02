#!/usr/bin/env bash
# Claude Code status line: model/effort, repo + git state, context, cost, rate limits.
# Input: session JSON on stdin. Output: 2 lines of ANSI-colored text.

input=$(cat)

IFS=$'\t' read -r MODEL EFFORT FAST THINKING STYLE CWD PROJ CTX API_MS ADD DEL RL5 RL5_AT RL7 RL7_AT CACHE_WARM CACHE_MISS <<<"$(
  printf '%s' "$input" | jq -r '
    [ (.model.display_name // "?"),
      (.effort.level // ""),
      (.fast_mode // false | tostring),
      (.thinking.enabled // true | tostring),
      (.output_style.name // ""),
      (.workspace.current_dir // .cwd // ""),
      (.workspace.project_dir // ""),
      (.context_window.used_percentage // -1 | tostring),
      (.cost.total_api_duration_ms // 0 | tostring),
      (.cost.total_lines_added // 0 | tostring),
      (.cost.total_lines_removed // 0 | tostring),
      (.rate_limits.five_hour.used_percentage // -1 | tostring),
      (.rate_limits.five_hour.resets_at // 0 | tostring),
      (.rate_limits.seven_day.used_percentage // -1 | tostring),
      (.rate_limits.seven_day.resets_at // 0 | tostring),
      (.prompt_cache.warm // true | tostring),
      (.prompt_cache.misses // 0 | tostring)
    ] | @tsv'
)"

R=$'\033[0m'; D=$'\033[2m'; B=$'\033[1m'
c() { printf '\033[38;5;%sm' "$1"; }
GRAY=$(c 244); DIM=$(c 240); BLUE=$(c 110); MAG=$(c 176)
GREEN=$(c 114); YELLOW=$(c 179); RED=$(c 203); CYAN=$(c 116)

# green < 50 <= yellow < 80 <= red
pct_color() { if [ "$1" -ge 80 ]; then printf '%s' "$RED"; elif [ "$1" -ge 50 ]; then printf '%s' "$YELLOW"; else printf '%s' "$GREEN"; fi; }

# bar <pct> <width> -> colored meter with eighth-block precision
PARTS=("" "▏" "▎" "▍" "▌" "▋" "▊" "▉")
bar() {
  local pct=$1 w=$2 i fill="" empty="" used
  [ "$pct" -lt 0 ] && pct=0
  [ "$pct" -gt 100 ] && pct=100
  local eighths=$(( pct * w * 8 / 100 ))
  local full=$(( eighths / 8 )) rem=$(( eighths % 8 ))
  for ((i=0;i<full;i++)); do fill+="█"; done
  used=$full
  if [ "$rem" -gt 0 ] && [ "$used" -lt "$w" ]; then fill+="${PARTS[$rem]}"; used=$((used+1)); fi
  for ((i=used;i<w;i++)); do empty+="░"; done
  printf '%s%s%s%s%s' "$(pct_color "$pct")" "$fill" "$DIM" "$empty" "$R"
}

# 4500 -> "1h15m", 300 -> "5m"
until_str() {
  local secs=$(( $1 - $(date +%s) ))
  [ "$secs" -le 0 ] && { printf 'now'; return; }
  local h=$((secs/3600)) m=$(((secs%3600)/60))
  if [ "$h" -gt 0 ]; then printf '%dh%02dm' "$h" "$m"; else printf '%dm' "$m"; fi
}

SEP="${DIM} · ${R}"

### line 1 — where you are
dir="${CWD##*/}"
if [ -n "$PROJ" ] && [ "$CWD" != "$PROJ" ] && [ "${CWD#"$PROJ"/}" != "$CWD" ]; then
  dir="${PROJ##*/}${DIM}/${R}${GRAY}${CWD#"$PROJ"/}${R}"
fi
line1="${CYAN}${dir}${R}"
right1=""
right2=""

cd "$CWD" 2>/dev/null
if git rev-parse --git-dir >/dev/null 2>&1; then
  branch=$(git symbolic-ref --quiet --short HEAD 2>/dev/null) || branch="${DIM}detached@${R}$(git rev-parse --short HEAD 2>/dev/null)"
  git_part="${MAG}⎇ ${branch}${R}"

  # Open PR for the branch, written by the ci-status mod.
  raw_branch=$(git symbolic-ref --quiet --short HEAD 2>/dev/null)
  pr_file="$HOME/.cache/claude-ci/pr-${raw_branch//\//-}"
  if [ -n "$raw_branch" ] && [ -s "$pr_file" ]; then
    git_part+=" ${BLUE}#$(cat "$pr_file")${R}"
  fi

  staged=0; unstaged=0; untracked=0
  while IFS= read -r l; do
    case "$l" in
      '??'*) untracked=$((untracked+1)) ;;
      *) [ "${l:0:1}" != " " ] && staged=$((staged+1)); [ "${l:1:1}" != " " ] && unstaged=$((unstaged+1)) ;;
    esac
  done < <(git status --porcelain 2>/dev/null)
  dirty=""
  [ "$staged" -gt 0 ] && dirty+=" ${GREEN}●${staged}${R}"
  [ "$unstaged" -gt 0 ] && dirty+=" ${YELLOW}✚${unstaged}${R}"
  [ "$untracked" -gt 0 ] && dirty+=" ${GRAY}?${untracked}${R}"
  [ -z "$dirty" ] && dirty=" ${GREEN}✓${R}"
  git_part+="$dirty"

  if ab=$(git rev-list --left-right --count '@{upstream}...HEAD' 2>/dev/null); then
    behind=${ab%%[[:space:]]*}; ahead=${ab##*[[:space:]]}
    [ "$ahead" -gt 0 ] && git_part+=" ${CYAN}↑${ahead}${R}"
    [ "$behind" -gt 0 ] && git_part+=" ${RED}↓${behind}${R}"
  else
    git_part+=" ${DIM}(no upstream)${R}"
  fi

  gd=$(git rev-parse --git-dir 2>/dev/null)
  { [ -d "$gd/rebase-merge" ] || [ -d "$gd/rebase-apply" ]; } && git_part+=" ${RED}REBASE${R}"
  [ -f "$gd/MERGE_HEAD" ] && git_part+=" ${RED}MERGE${R}"

  line1+="${SEP}${git_part}"

  # CI for HEAD, written by the ci-status mod (~/.claude/mods/ci-status).
  ci_file="$HOME/.cache/claude-ci/$(git rev-parse HEAD 2>/dev/null)"
  if [ -f "$ci_file" ]; then
    IFS=$'\t' read -r ci_state ci_detail < "$ci_file"
    case "$ci_state" in
      pass)  right1+="${SEP}${DIM}CI${R} ${GREEN}✓${R}" ;;
      run)   right1+="${SEP}${DIM}CI${R} ${YELLOW}◷ ${ci_detail}${R}" ;;
      fail)  right1+="${SEP}${DIM}CI${R} ${RED}✗ ${ci_detail}${R}" ;;
      error) right1+="${SEP}${DIM}CI ?${R}" ;;
    esac
  fi

fi

# Project segments: a project's own mod writes ~/.cache/claude-status/<repo path, / as ->
# with one `color<TAB>text` line per segment. Ignored once 10 minutes stale.
top=$(git rev-parse --show-toplevel 2>/dev/null)
seg_file="$HOME/.cache/claude-status/${top//\//-}"
if [ -n "$top" ] && [ -s "$seg_file" ] && [ $(( $(date +%s) - $(stat -f %m "$seg_file") )) -lt 600 ]; then
  while IFS=$'\t' read -r seg_color seg_text || [ -n "$seg_color" ]; do
    case "$seg_color" in
      green) col=$GREEN ;; yellow) col=$YELLOW ;; red) col=$RED ;; *) col=$DIM ;;
    esac
    [ -n "$seg_text" ] && right1+="${SEP}${col}${seg_text}${R}"
  done < "$seg_file"
fi

# Task progress, written by the task-progress mod as `percent<TAB>step` per session.
# Ignored once 30 minutes stale, so an abandoned task does not linger.
SID=$(printf '%s' "$input" | jq -r '.session_id // ""')
prog_file="$HOME/.cache/claude-progress/$SID"
if [ -n "$SID" ] && [ -s "$prog_file" ] && [ $(( $(date +%s) - $(stat -f %m "$prog_file") )) -lt 1800 ]; then
  IFS=$'\t' read -r prog_pct prog_step < "$prog_file"
  if [ "$prog_pct" -ge 0 ] 2>/dev/null; then
    prog_fill=""; prog_empty=""
    prog_full=$(( prog_pct * 12 / 100 ))
    for ((i=0;i<prog_full;i++)); do prog_fill+="█"; done
    for ((i=prog_full;i<12;i++)); do prog_empty+="░"; done
    prog_col=$BLUE; [ "$prog_pct" -ge 100 ] && prog_col=$GREEN
    right1+="${SEP}${prog_col}${prog_fill}${DIM}${prog_empty}${R} ${prog_col}${prog_pct}%${R} ${GRAY}${prog_step}${R}"
  fi
fi

if [ "$ADD" != "0" ] || [ "$DEL" != "0" ]; then
  line1+="${SEP}${GREEN}+${ADD}${R} ${RED}-${DEL}${R}"
fi

### line 2 — what the session is costing
model="${BLUE}${MODEL}${R}"
[ -n "$EFFORT" ] && model+="${DIM}/${EFFORT}${R}"
[ "$FAST" = "true" ] && model+=" ${YELLOW}⚡${R}"
[ "$THINKING" = "false" ] && model+=" ${DIM}(no think)${R}"
line2="$model"

if [ "$CTX" -ge 0 ] 2>/dev/null; then
  line2+="${SEP}${DIM}ctx${R} $(bar "$CTX" 20) $(pct_color "$CTX")${CTX}%${R}"
fi
[ "$CACHE_WARM" = "false" ] && line2+=" ${DIM}cold${R}"
[ "$CACHE_MISS" != "0" ] && line2+=" ${YELLOW}miss×${CACHE_MISS}${R}"

if [ "$RL5" -ge 0 ] 2>/dev/null; then
  right2+="${SEP}${DIM}5h${R} $(bar "$RL5" 14) $(pct_color "$RL5")${RL5}%${R} ${DIM}↻$(until_str "$RL5_AT")${R}"
fi
if [ "$RL7" -ge 0 ] 2>/dev/null; then
  right2+="${SEP}${DIM}7d${R} $(bar "$RL7" 14) $(pct_color "$RL7")${RL7}%${R}"
fi

# Left group, padding, right group: the line spans the terminal. Claude Code indents
# the status line and needs a column spare, so leave 4. Too narrow, just join them.
WIDTH=$(( ${COLUMNS:-120} - 4 ))
vislen() { local t; t=$(printf '%s' "$1" | sed $'s/\x1b\\[[0-9;]*m//g'); printf '%s' "${#t}"; }
spread() {
  local left=$1 right=${2#"$SEP"}
  [ -z "$right" ] && { printf '%s' "$left"; return; }
  local gap=$(( WIDTH - $(vislen "$left") - $(vislen "$right") ))
  if [ "$gap" -lt 2 ]; then printf '%s%s%s' "$left" "$SEP" "$right"; return; fi
  printf '%s%*s%s' "$left" "$gap" '' "$right"
}

printf '%s\n%s' "$(spread "$line1" "$right1")" "$(spread "$line2" "$right2")"
