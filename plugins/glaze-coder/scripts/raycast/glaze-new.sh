#!/bin/zsh
# @raycast.schemaVersion 1
# @raycast.title Glaze: New App
# @raycast.mode fullOutput
# @raycast.packageName Glaze Coder
# @raycast.icon 🟢
# @raycast.argument1 { "type": "text", "placeholder": "app name" }
# @raycast.argument2 { "type": "dropdown", "placeholder": "tool", "optional": true, "data": [{"title": "Claude Code", "value": "claude"}, {"title": "ZCode (z.ai)", "value": "zcode"}] }
#
# Creates an empty app and opens the coding tool with a start prompt (glaze-dev start).
# Tool: Claude Code (default) or ZCode. The terminal is picked automatically.
export PATH="$HOME/.local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
# Resolve terminal-launch.sh relative to this script rather than an assumed clone
# path: the repo can live anywhere (Raycast runs the script with a full path in $0).
source "${0:A:h}/../terminal-launch.sh"
tool="${2:-claude}"
[[ "$tool" == zcode ]] && label="ZCode" || label="Claude Code"
term="$(launch_in_terminal "exec $HOME/.local/bin/glaze-dev start --tool '$tool' '$1'")"
echo "Creating '$1' and opening $label in $term. Describe what the app should do there."
