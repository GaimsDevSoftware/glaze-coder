#!/bin/zsh
# @raycast.schemaVersion 1
# @raycast.title Glaze: Edit App
# @raycast.mode fullOutput
# @raycast.packageName Glaze Coder
# @raycast.icon 🛠️
# @raycast.argument1 { "type": "text", "placeholder": "app name" }
# @raycast.argument2 { "type": "dropdown", "placeholder": "tool", "optional": true, "data": [{"title": "Claude Code", "value": "claude"}, {"title": "ZCode (z.ai)", "value": "zcode"}] }
# @raycast.argument3 { "type": "dropdown", "placeholder": "where", "optional": true, "data": [{"title": "Auto (running/last used terminal)", "value": "auto"}, {"title": "Terminal", "value": "terminal"}, {"title": "iTerm", "value": "iterm"}, {"title": "The desktop app", "value": "desktop"}] }
#
# The choices happen in the Raycast fields (dropdowns), no external dialog = never any
# focus trouble. Empty tool = Claude Code. Empty place = auto. New terminals: add them
# to the data list.
export PATH="$HOME/.local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
source "$HOME/glaze-coder/plugins/glaze-coder/scripts/terminal-launch.sh"

src="$("$HOME/.local/bin/glaze-dev" path "$1" 2>/dev/null)"
if [[ -z "$src" ]]; then
  echo "Found no app matching '$1'. Try 'Glaze: New App' first, or check the name."
  exit 0
fi

tool="${2:-claude}"
where="${3:-auto}"
[[ "$tool" == zcode ]] && label="ZCode" || label="Claude Code"
cmd="exec $HOME/.local/bin/glaze-dev code --tool '$tool' '$1'"

urlenc() { python3 -c 'import sys,urllib.parse; print(urllib.parse.quote(sys.argv[1], safe=""))' "$1"; }

# The handoff prompt that gets pasted into the agent. Agent-independent: applies to
# both Claude Code and ZCode. Built in one place (glaze-dev), which also merges in a
# paused Glaze queue.
build_handoff() { "$HOME/.local/bin/glaze-dev" handoff "$1" 2>/dev/null; }

# ZCode is a GUI IDE, so the "where" choice does not apply: we always do the seamless
# flow. glaze-dev owns all of it (open the workspace via deep link, new thread with
# Cmd+N, paste the handoff with Cmd+V, never Enter) so that Raycast and the terminal
# share exactly the same logic. The status lines below show up right in Raycast's
# output panel.
if [[ "$tool" == zcode ]]; then
  "$HOME/.local/bin/glaze-dev" code --tool zcode "$1"
  exit 0
fi

case "$where" in
  desktop)
    # Claude Desktop: the claude:// deep link opens the Code tab on the right folder
    # with the handoff prompt filled in (the user presses Enter themselves). If the
    # Glaze vibe coder has a paused queue (e.g. out of credits), it is pulled in too.
    handoff="$(build_handoff "$1")"
    printf '%s' "$handoff" | pbcopy
    if open "claude://code/new?folder=$(urlenc "$src")&q=$(urlenc "$handoff")" 2>/dev/null; then
      osascript -e "display notification \"Opening $1 in Claude Code with the folder and handoff. Press Enter there to start.\" with title \"Glaze: Edit $1\"" 2>/dev/null
      echo "Opened Claude Code (desktop) on '$1' with the handoff prompt. Press Enter there to start."
    else
      open -a Claude
      osascript -e "display notification \"Pick $1 in the Code tab and paste the handoff prompt (Cmd+V).\" with title \"Glaze: Edit $1\"" 2>/dev/null
      echo "Opened Claude Desktop. Pick '$1' in the Code tab and paste the handoff prompt (it is on the clipboard)."
    fi ;;
  auto)
    term="$(launch_in_terminal "$cmd")"
    echo "Opened $label for '$1' in $term (auto)." ;;
  *)
    term="$(GLAZE_TERMINAL="$where" launch_in_terminal "$cmd")"
    echo "Opened $label for '$1' in $term." ;;
esac
