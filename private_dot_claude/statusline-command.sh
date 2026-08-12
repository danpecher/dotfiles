#!/bin/bash
# Claude Code status line — Nerd Font icons, Starship-style spacing
input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')
model=$(echo "$input" | jq -r '.model.display_name')
remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')
vim_mode=$(echo "$input" | jq -r '.vim.mode // empty')

# Project name (basename of workspace dir)
project=$(basename "$cwd")

# Git branch (skip optional lock, no error output)
branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null)

# Nerd Font icons (UTF-8 byte sequences)
#  U+F07C folder_open = \xef\x81\xbc
#  U+E0A0 branch      = \xee\x82\xa0
#  U+F0E7 bolt        = \xef\x83\xa7
# 󰘔 U+F0614 gauge     = \xf3\xb0\x98\x94

# Build the line
line=""

# Vim mode (icon only, color-coded)
#  U+F192 dot_circle  = \xef\x86\x92 (NORMAL)
#  U+F040 pencil      = \xef\x81\x80 (INSERT)
#  U+F06E eye         = \xef\x81\xae (VISUAL)
if [ -n "$vim_mode" ]; then
  if [ "$vim_mode" = "NORMAL" ]; then
    line="${line}$(printf '\033[1;34m\xef\x86\x92\033[0m')"
  elif [ "$vim_mode" = "INSERT" ]; then
    line="${line}$(printf '\033[1;32m\xef\x81\x80\033[0m')"
  elif [ "$vim_mode" = "VISUAL" ]; then
    line="${line}$(printf '\033[1;33m\xef\x81\xae\033[0m')"
  fi
  line="${line} "
fi

# Project name (cyan, bold)  folder icon
line="${line}$(printf '\033[1;36m\xef\x81\xbc %s\033[0m' "$project")"

# Git branch (green)  branch icon
if [ -n "$branch" ]; then
  line="${line}  $(printf '\033[32m\xee\x82\xa0 %s\033[0m' "$branch")"
fi

# Model (magenta)  bolt icon
line="${line}  $(printf '\033[35m\xef\x83\xa7 %s\033[0m' "$model")"

# Context used (color-coded: green < 50%, yellow 50-75%, red > 75%)
if [ -n "$remaining" ]; then
  used=$((100 - remaining))
  if [ "$used" -lt 50 ]; then
    ctx_color="32" # green
  elif [ "$used" -lt 75 ]; then
    ctx_color="33" # yellow
  else
    ctx_color="31" # red
  fi
  line="${line}  $(printf '\033[%sm\xf3\xb0\x98\x94 %s%%\033[0m' "$ctx_color" "$used")"
fi

# Caveman mode indicator (only shown when active)
# Icons:  U+F06D flame = \xef\x81\xad
#   full  → red    🔥
#   lite  → yellow 🔥
#   ultra → bright red/bold 🔥
if [ -n "$caveman_mode" ]; then
  if [ "$caveman_mode" = "full" ]; then
    line="${line}  $(printf '\033[38;5;172m[CAVEMAN]\033[0m')"
  else
    SUFFIX=$(printf '%s' "$caveman_mode" | tr '[:lower:]' '[:upper:]')
    line="${line}  $(printf '\033[38;5;172m[CAVEMAN:%s]\033[0m' "$SUFFIX")"
  fi
fi

printf '%s' "$line"
