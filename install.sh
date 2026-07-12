#!/bin/zsh
# Installer for glaze-coder.
#
# Run straight from the web (clones the repo for you):
#   curl -fsSL https://raw.githubusercontent.com/GaimsDevSoftware/glaze-coder/main/install.sh | zsh
#
# Or from a cloned copy, where it can ask you what to install:
#   ./install.sh
#
# It always installs the core glaze-dev command. When run in a terminal it asks
# which extra parts you want. Piped from curl it installs everything.
#
# You can also pick parts without being asked, by setting any of these to 1 or 0:
#   GLAZE_SKILLS=1   Glaze skills for Claude Code
#   GLAZE_PLUGIN=1   Claude Code plugin (/glaze-coder:glaze)
#   GLAZE_RAYCAST=1  Open Raycast to finish adding its commands
emulate -L zsh
setopt pipe_fail 2>/dev/null

REPO_URL="https://github.com/GaimsDevSoftware/glaze-coder.git"
green() { print -P "%F{green}$1%f"; }
warn()  { print -P "%F{yellow}$1%f"; }
head()  { print -P "%F{cyan}%B$1%b%f"; }

# Ask a yes/no question. ask <default:y|n> <prompt>. Returns 0 for yes.
# Falls back to the default when there is no terminal (for example curl | zsh).
ask() {
  local def="$1" prompt="$2" hint ans
  [[ "$def" == y ]] && hint="[Y/n]" || hint="[y/N]"
  if [[ ! -t 0 ]]; then
    [[ "$def" == y ]]; return
  fi
  read "ans?  $prompt $hint: "
  [[ -z "$ans" ]] && ans="$def"
  [[ "$ans" == [Yy]* ]]
}

# Decide whether to install an optional part. want <ENV_VALUE> <default> <prompt>.
want() {
  local env="$1" def="$2" prompt="$3"
  case "$env" in
    1|true|yes) return 0 ;;
    0|false|no) return 1 ;;
  esac
  ask "$def" "$prompt"
}

# 1. Find the repo, or clone it if we are running standalone (piped from curl).
SELF_DIR="${0:A:h}"
if [[ -f "$SELF_DIR/plugins/glaze-coder/scripts/glaze-dev" ]]; then
  REPO="$SELF_DIR"
else
  REPO="$HOME/glaze-coder"
  if [[ -d "$REPO/.git" ]]; then
    print "Updating existing $REPO ..."
    git -C "$REPO" pull --quiet --ff-only || warn "Could not update, using existing copy."
  else
    print "Cloning glaze-coder into $REPO ..."
    git clone --quiet "$REPO_URL" "$REPO" || { print -u2 "Clone failed. Is git installed?"; exit 1; }
  fi
fi

LAUNCHER="$REPO/plugins/glaze-coder/scripts/glaze-dev"
[[ -f "$LAUNCHER" ]] || { print -u2 "Could not find $LAUNCHER"; exit 1; }
chmod +x "$LAUNCHER" "$REPO"/plugins/glaze-coder/scripts/raycast/*.sh 2>/dev/null

print ""
head "Installing glaze-coder"
if [[ -t 0 ]]; then
  print "The core command is always installed. You choose the extra parts below."
  print "Press Enter to accept the suggestion in brackets."
fi
print ""

# 2. Core: link the launcher onto PATH. Always installed, everything builds on it.
head "Core: the glaze-dev command"
print "  The engine that creates, builds and runs your apps. Needed for everything else."
mkdir -p "$HOME/.local/bin"
ln -sf "$LAUNCHER" "$HOME/.local/bin/glaze-dev"
green "  Installed glaze-dev -> ~/.local/bin/glaze-dev"

# Make sure ~/.local/bin is on PATH (add to ~/.zshrc once if missing).
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  if ! grep -qs 'HOME/.local/bin' "$HOME/.zshrc" 2>/dev/null; then
    print 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
  fi
  export PATH="$HOME/.local/bin:$PATH"
  warn "  Added ~/.local/bin to PATH (restart your terminal, or run: source ~/.zshrc)"
fi
print ""

# 3. Glaze skills for Claude Code.
head "Glaze skills for Claude Code  (recommended)"
print "  Links Glaze's own guides into ~/.claude so Claude Code knows how Glaze apps"
print "  are built and follows the right steps. Safe to install. Recommended for everyone."
if want "$GLAZE_SKILLS" y "Install the Glaze skills?"; then
  "$HOME/.local/bin/glaze-dev" skills >/dev/null 2>&1 || true
  green "  Installed Glaze skills into ~/.claude"
else
  print "  Skipped."
fi
print ""

# 4. Claude Code plugin.
head "Claude Code plugin  (recommended)"
print "  Adds the /glaze-coder:glaze command inside Claude Code, which lists your apps"
print "  and starts building. Works in the Claude Code terminal and desktop app."
if ! command -v claude >/dev/null 2>&1; then
  warn "  Claude Code was not found on your PATH, so this part is skipped."
  warn "  Install Claude Code, then run: claude plugin install glaze-coder"
elif want "$GLAZE_PLUGIN" y "Install the Claude Code plugin?"; then
  claude plugin marketplace add GaimsDevSoftware/glaze-coder >/dev/null 2>&1 || true
  if claude plugin install glaze-coder >/dev/null 2>&1 \
     || claude plugin install glaze-coder@glaze-coder-marketplace >/dev/null 2>&1; then
    green "  Installed the Claude Code plugin (/glaze-coder:glaze)"
  else
    warn "  Could not install automatically. Run: claude plugin install glaze-coder"
  fi
else
  print "  Skipped."
fi
print ""

# 5. Raycast commands.
RAYCAST_DIR="$REPO/plugins/glaze-coder/scripts/raycast"
head "Raycast commands  (optional)"
print "  Buttons in Raycast to make a new app, build and run, or edit an app, with no"
print "  terminal. Only useful if you have Raycast. Adding the folder needs one click"
print "  in Raycast settings, so this opens Raycast and copies the folder path for you."
command -v pbcopy >/dev/null 2>&1 && printf '%s' "$RAYCAST_DIR" | pbcopy
if want "$GLAZE_RAYCAST" n "Open Raycast now to finish setup?"; then
  "$HOME/.local/bin/glaze-dev" raycast >/dev/null 2>&1 || open -a Raycast 2>/dev/null || \
    warn "  Could not open Raycast. Add this folder by hand: $RAYCAST_DIR"
  print "  In Raycast: Settings > Extensions > Script Commands > Add Directories,"
  print "  then press Cmd+Shift+G, paste, Enter, Open. The path is on your clipboard."
else
  print "  Skipped. To set it up later, run: glaze-dev raycast"
fi
print ""

green "Done."
print "Start a new app now:"
print '   glaze-dev start "My App"'
print ""
