#!/bin/zsh
# @raycast.schemaVersion 1
# @raycast.title Glaze: New App
# @raycast.mode fullOutput
# @raycast.packageName Glaze Coder
# @raycast.icon 🟢
# @raycast.argument1 { "type": "text", "placeholder": "app name" }
# @raycast.argument2 { "type": "dropdown", "placeholder": "verktøy", "optional": true, "data": [{"title": "Claude Code", "value": "claude"}, {"title": "ZCode (z.ai)", "value": "zcode"}] }
#
# Lager en tom app og åpner kodeverktøyet direkte med startprompt (glaze-dev start).
# Verktøy: Claude Code (standard) eller ZCode. Terminal velges automatisk.
export PATH="$HOME/.local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
source "$HOME/glaze-coder/plugins/glaze-coder/scripts/terminal-launch.sh"
tool="${2:-claude}"
[[ "$tool" == zcode ]] && label="ZCode" || label="Claude Code"
term="$(launch_in_terminal "exec $HOME/.local/bin/glaze-dev start --tool '$tool' '$1'")"
echo "Oppretter '$1' og åpner $label i $term. Beskriv hva appen skal gjøre der."
