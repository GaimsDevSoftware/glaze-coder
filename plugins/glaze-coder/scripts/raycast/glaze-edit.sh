#!/bin/zsh
# @raycast.schemaVersion 1
# @raycast.title Glaze: Edit App
# @raycast.mode fullOutput
# @raycast.packageName Glaze Coder
# @raycast.icon 🛠️
# @raycast.argument1 { "type": "text", "placeholder": "app name" }
#
# Terminal-independent: opens the app's source folder and copies the edit command.
# Editing with Claude Code needs a terminal, so this hands you the exact command
# instead of spawning one (works even if your Terminal is misbehaving).
export PATH="$HOME/.local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
src="$("$HOME/.local/bin/glaze-dev" path "$1" 2>/dev/null)"
if [ -n "$src" ]; then
  open "$src"
  printf '%s' "glaze-dev code '$1'" | pbcopy
  echo "Åpnet kildemappen for '$1'."
  echo "Kommando kopiert til utklippstavlen:  glaze-dev code '$1'"
  echo "Lim den inn i terminalen din, eller bruk /glaze-coder:glaze i Claude Code."
else
  echo "Fant ingen app som matcher '$1'. Prøv 'Glaze: New App' først, eller sjekk navnet."
fi
