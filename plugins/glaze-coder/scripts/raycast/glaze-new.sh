#!/bin/zsh
# @raycast.schemaVersion 1
# @raycast.title Glaze: New App
# @raycast.mode fullOutput
# @raycast.packageName Glaze Coder
# @raycast.icon 🟢
# @raycast.argument1 { "type": "text", "placeholder": "app name" }
#
# Runs glaze-dev directly (no Terminal needed): builds a new app and opens it.
export PATH="$HOME/.local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
"$HOME/.local/bin/glaze-dev" new "$1" --blank
osascript -e "display notification \"Bygg den ut med Claude Code (glaze-dev code $1)\" with title \"Glaze: $1 opprettet\"" 2>/dev/null
