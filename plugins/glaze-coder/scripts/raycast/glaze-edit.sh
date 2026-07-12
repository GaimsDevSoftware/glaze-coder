#!/bin/zsh
# @raycast.schemaVersion 1
# @raycast.title Glaze: Edit App
# @raycast.mode fullOutput
# @raycast.packageName Glaze Coder
# @raycast.icon 🛠️
# @raycast.argument1 { "type": "text", "placeholder": "app name" }
#
# Popup lar deg velge hvor redigeringen skal åpnes: en installert terminal
# eller Claude Code i Desktop-appen. Auto = kjørende/sist brukte terminal.
export PATH="$HOME/.local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
source "$HOME/glaze-coder/plugins/glaze-coder/scripts/terminal-launch.sh"

src="$("$HOME/.local/bin/glaze-dev" path "$1" 2>/dev/null)"
if [[ -z "$src" ]]; then
  echo "Fant ingen app som matcher '$1'. Prøv 'Glaze: New App' først, eller sjekk navnet."
  exit 0
fi

# Bygg valglisten dynamisk fra det som faktisk er installert
choices=("Auto (kjørende/sist brukte terminal)")
for name in Terminal iTerm Ghostty kitty Alacritty WezTerm; do
  _tl_installed "$name.app" >/dev/null && choices+=("$name")
done
[[ -d /Applications/Claude.app ]] && choices+=("Claude Code (Desktop-appen)")

aslist=""
for c in "${choices[@]}"; do aslist+="\"$c\", "; done
aslist="${aslist%, }"

pick="$(osascript -e "try
  tell application \"System Events\" to set frontmost of process \"osascript\" to true
end try
choose from list {$aslist} with title \"Glaze: Edit $1\" with prompt \"Hvor vil du åpne redigeringen?\" default items {\"${choices[1]}\"}" 2>/dev/null)"
[[ -z "$pick" || "$pick" == "false" ]] && { echo "Avbrutt."; exit 0; }

cmd="exec $HOME/.local/bin/glaze-dev code '$1'"
case "$pick" in
  "Claude Code (Desktop-appen)")
    printf '%s' "$src" | pbcopy
    open -a Claude
    osascript -e "display notification \"Velg $1 under Recents i Code-fanen. Stien ligger på utklippstavlen.\" with title \"Glaze: Edit $1\"" 2>/dev/null
    echo "Åpnet Claude Desktop. Velg '$1' i Code-fanen (stien er på utklippstavlen)." ;;
  Auto*)
    term="$(launch_in_terminal "$cmd")"
    echo "Åpnet Claude Code for '$1' i $term (auto)." ;;
  *)
    term="$(GLAZE_TERMINAL="${pick:l}" launch_in_terminal "$cmd")"
    echo "Åpnet Claude Code for '$1' i $term." ;;
esac
