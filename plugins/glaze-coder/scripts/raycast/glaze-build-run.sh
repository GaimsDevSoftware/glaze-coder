#!/bin/zsh
# @raycast.schemaVersion 1
# @raycast.title Glaze: Build & Run App
# @raycast.mode fullOutput
# @raycast.packageName Glaze Coder
# @raycast.icon 🚀
# @raycast.argument1 { "type": "text", "placeholder": "app name" }
#
# Runs glaze-dev directly (no Terminal needed): builds the app and opens it.
export PATH="$HOME/.local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
"$HOME/.local/bin/glaze-dev" br "$1"
