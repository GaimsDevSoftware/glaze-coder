#!/bin/zsh
# @raycast.schemaVersion 1
# @raycast.title Glaze: New App
# @raycast.mode silent
# @raycast.packageName Glaze Coder
# @raycast.icon 🟢
# @raycast.argument1 { "type": "text", "placeholder": "app name" }
app="$1"
osascript -e "tell application \"Terminal\" to do script \"glaze-dev start '${app}'\"" \
          -e 'tell application "Terminal" to activate'
