#!/bin/zsh
# @raycast.schemaVersion 1
# @raycast.title Glaze: Edit App
# @raycast.mode fullOutput
# @raycast.packageName Glaze Coder
# @raycast.icon 🛠️
# @raycast.argument1 { "type": "text", "placeholder": "app name" }
# @raycast.argument2 { "type": "dropdown", "placeholder": "verktøy", "optional": true, "data": [{"title": "Claude Code", "value": "claude"}, {"title": "ZCode (z.ai)", "value": "zcode"}] }
# @raycast.argument3 { "type": "dropdown", "placeholder": "hvor", "optional": true, "data": [{"title": "Auto (kjørende/sist brukte terminal)", "value": "auto"}, {"title": "Terminal", "value": "terminal"}, {"title": "iTerm", "value": "iterm"}, {"title": "Desktop-appen", "value": "desktop"}] }
#
# Valgene skjer i Raycast-feltene (dropdown), ingen ekstern dialog = aldri fokustrøbbel.
# Tomt verktøy = Claude Code. Tomt sted = auto. Nye terminaler: legg til i data-listen.
export PATH="$HOME/.local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
source "$HOME/glaze-coder/plugins/glaze-coder/scripts/terminal-launch.sh"

src="$("$HOME/.local/bin/glaze-dev" path "$1" 2>/dev/null)"
if [[ -z "$src" ]]; then
  echo "Fant ingen app som matcher '$1'. Prøv 'Glaze: New App' først, eller sjekk navnet."
  exit 0
fi

tool="${2:-claude}"
where="${3:-auto}"
[[ "$tool" == zcode ]] && label="ZCode" || label="Claude Code"
cmd="exec $HOME/.local/bin/glaze-dev code --tool '$tool' '$1'"

case "$where" in
  desktop)
    printf '%s' "$src" | pbcopy
    if [[ "$tool" == zcode ]]; then
      open -a ZCode "$src" 2>/dev/null || open -a ZCode 2>/dev/null
      osascript -e "display notification \"Åpner $1 i ZCode. Stien ligger også på utklippstavlen.\" with title \"Glaze: Edit $1\"" 2>/dev/null
      echo "Åpnet ZCode på '$1' (stien er på utklippstavlen)."
    else
      open -a Claude
      osascript -e "display notification \"Velg $1 under Recents i Code-fanen. Stien ligger på utklippstavlen.\" with title \"Glaze: Edit $1\"" 2>/dev/null
      echo "Åpnet Claude Desktop. Velg '$1' i Code-fanen (stien er på utklippstavlen)."
    fi ;;
  auto)
    term="$(launch_in_terminal "$cmd")"
    echo "Åpnet $label for '$1' i $term (auto)." ;;
  *)
    term="$(GLAZE_TERMINAL="$where" launch_in_terminal "$cmd")"
    echo "Åpnet $label for '$1' i $term." ;;
esac
