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

urlenc() { python3 -c 'import sys,urllib.parse; print(urllib.parse.quote(sys.argv[1], safe=""))' "$1"; }

# Handoff-prompten som limes inn hos agenten. Agent-uavhengig: gjelder både Claude
# Code og ZCode. Bygges ett sted (glaze-dev), som også fletter inn en pauset Glaze-kø.
build_handoff() { "$HOME/.local/bin/glaze-dev" handoff "$1" 2>/dev/null; }

# ZCode er en GUI-IDE, så "hvor"-valget gjelder ikke: vi gjør alltid den sømløse
# flyten. glaze-dev eier hele den (åpne arbeidsområde via deep link, ny tråd med
# Cmd+N, lim inn handoff med Cmd+V, aldri Enter) slik at Raycast og terminal deler
# nøyaktig samme logikk. Statuslinjene under vises rett i Raycast sitt output-panel.
if [[ "$tool" == zcode ]]; then
  "$HOME/.local/bin/glaze-dev" code --tool zcode "$1"
  exit 0
fi

case "$where" in
  desktop)
    # Claude Desktop: claude://-deeplink åpner Code-fanen på riktig mappe med
    # handoff-prompten ferdig utfylt (bruker trykker Enter selv). Har Glaze-
    # vibekoderen en pauset kø (f.eks. tomme kreditter), hentes den inn også.
    handoff="$(build_handoff "$1")"
    printf '%s' "$handoff" | pbcopy
    if open "claude://code/new?folder=$(urlenc "$src")&q=$(urlenc "$handoff")" 2>/dev/null; then
      osascript -e "display notification \"Åpner $1 i Claude Code med mappe og handoff. Trykk Enter der for å starte.\" with title \"Glaze: Edit $1\"" 2>/dev/null
      echo "Åpnet Claude Code (desktop) på '$1' med handoff-prompt. Trykk Enter der for å starte."
    else
      open -a Claude
      osascript -e "display notification \"Velg $1 i Code-fanen og lim inn handoff-prompten (Cmd+V).\" with title \"Glaze: Edit $1\"" 2>/dev/null
      echo "Åpnet Claude Desktop. Velg '$1' i Code-fanen og lim inn handoff-prompten (ligger på utklippstavlen)."
    fi ;;
  auto)
    term="$(launch_in_terminal "$cmd")"
    echo "Åpnet $label for '$1' i $term (auto)." ;;
  *)
    term="$(GLAZE_TERMINAL="$where" launch_in_terminal "$cmd")"
    echo "Åpnet $label for '$1' i $term." ;;
esac
