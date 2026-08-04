#!/bin/zsh
# terminal-launch.sh - pick and start the right terminal for interactive commands.
# Usage:  source terminal-launch.sh; launch_in_terminal "<command>"
# Override:  GLAZE_TERMINAL=iterm|terminal|ghostty|kitty|alacritty|wezterm

_tl_installed() { # <App.app name> -> full path or empty
  local a
  for a in "/Applications/$1" "/Applications/Utilities/$1" "/System/Applications/Utilities/$1" "$HOME/Applications/$1"; do
    [[ -d "$a" ]] && { print -r -- "$a"; return 0; }
  done
  return 1
}

_tl_lastused() { # <app path> -> epoch (0 if unknown)
  local d="$(mdls -raw -name kMDItemLastUsedDate "$1" 2>/dev/null)"
  [[ -z "$d" || "$d" == "(null)" ]] && { print 0; return; }
  date -j -f "%Y-%m-%d %H:%M:%S %z" "$d" +%s 2>/dev/null || print 0
}

_tl_pick() {
  # 1) Manual choice
  case "${GLAZE_TERMINAL:l}" in
    iterm)     print iTerm;     return ;;
    terminal)  print Terminal;  return ;;
    ghostty)   print Ghostty;   return ;;
    kitty)     print kitty;     return ;;
    alacritty) print Alacritty; return ;;
    wezterm)   print WezTerm;   return ;;
  esac
  # 2) A running terminal wins
  pgrep -qx iTerm2    && { print iTerm;     return; }
  pgrep -qx ghostty   && { print Ghostty;   return; }
  pgrep -qx kitty     && { print kitty;     return; }
  pgrep -qx alacritty && { print Alacritty; return; }
  pgrep -qx wezterm-gui && { print WezTerm; return; }
  pgrep -qx Terminal  && { print Terminal;  return; }
  # 3) Most recently used of the installed ones
  local best="Terminal" best_ts=-1 name path ts
  for name in iTerm Ghostty kitty Alacritty WezTerm Terminal; do
    path="$(_tl_installed "$name.app")" || continue
    ts="$(_tl_lastused "$path")"
    (( ts > best_ts )) && { best="$name"; best_ts=$ts; }
  done
  print -r -- "$best"
}

launch_in_terminal() { # <command to run interactively>
  local cmd="$1" term="$(_tl_pick)"
  local esc="${cmd//\\/\\\\}"; esc="${esc//\"/\\\"}"   # escape for an AppleScript string
  case "$term" in
    iTerm)
      osascript -e 'tell application "iTerm" to activate' \
                -e "tell application \"iTerm\" to create window with default profile command \"zsh -lc \\\"$esc\\\"\"" \
      || osascript -e "tell application \"iTerm\"
        activate
        set w to (create window with default profile)
        tell current session of w to write text \"$esc\"
      end tell" ;;
    Ghostty)    open -na Ghostty    --args -e zsh -lc "$cmd" ;;
    kitty)      open -na kitty      --args zsh -lc "$cmd" ;;
    Alacritty)  open -na Alacritty  --args -e zsh -lc "$cmd" ;;
    WezTerm)    open -na WezTerm    --args start -- zsh -lc "$cmd" ;;
    *)
      osascript -e 'tell application "Terminal" to activate' \
                -e "tell application \"Terminal\" to do script \"$esc\"" ;;
  esac
  print -r -- "$term"
}
