#!/bin/zsh
# @raycast.schemaVersion 1
# @raycast.title Glaze: Edit App
# @raycast.mode silent
# @raycast.packageName Glaze Coder
# @raycast.icon 🛠️
# @raycast.argument1 { "type": "text", "placeholder": "app name" }
# @raycast.argument2 { "type": "text", "placeholder": "what to change (optional)", "optional": true }
app="$1"; msg="$2"
osascript -e "tell application \"Terminal\" to do script \"glaze-dev code '${app}' ${msg:+\\\"$msg\\\"}\"" \
          -e 'tell application "Terminal" to activate'
