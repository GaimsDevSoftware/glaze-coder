#!/bin/zsh
# One-command installer for glaze-coder.
#
# Run straight from the web (clones the repo for you):
#   curl -fsSL https://raw.githubusercontent.com/GaimsDevSoftware/glaze-coder/main/install.sh | zsh
#
# Or from a cloned copy:
#   ./install.sh
#
# It links `glaze-dev` onto your PATH, links Glaze's skills into ~/.claude, and
# (if Claude Code is installed) adds the marketplace and installs the plugin.
emulate -L zsh
setopt pipe_fail 2>/dev/null

REPO_URL="https://github.com/GaimsDevSoftware/glaze-coder.git"
green() { print -P "%F{green}$1%f"; }
warn()  { print -P "%F{yellow}$1%f"; }

# 1. Find the repo, or clone it if we're running standalone (piped from curl).
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

# 2. Link the launcher onto PATH.
mkdir -p "$HOME/.local/bin"
ln -sf "$LAUNCHER" "$HOME/.local/bin/glaze-dev"
green "Linked glaze-dev -> ~/.local/bin/glaze-dev"

# 3. Make sure ~/.local/bin is on PATH (add to ~/.zshrc once if missing).
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  if ! grep -qs 'HOME/.local/bin' "$HOME/.zshrc" 2>/dev/null; then
    print 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
  fi
  export PATH="$HOME/.local/bin:$PATH"
  warn "Added ~/.local/bin to PATH (restart your terminal, or run: source ~/.zshrc)"
fi

# 4. Link Glaze's own skills into ~/.claude so Claude Code knows Glaze.
"$HOME/.local/bin/glaze-dev" skills >/dev/null 2>&1 || true
green "Linked Glaze skills into ~/.claude"

# 5. If Claude Code is present, install the plugin too (idempotent).
if command -v claude >/dev/null 2>&1; then
  claude plugin marketplace add GaimsDevSoftware/glaze-coder >/dev/null 2>&1 || true
  if claude plugin install glaze-coder >/dev/null 2>&1; then
    green "Installed the Claude Code plugin (/glaze-coder:glaze)"
  else
    claude plugin install glaze-coder@glaze-coder-marketplace >/dev/null 2>&1 \
      && green "Installed the Claude Code plugin (/glaze-coder:glaze)" \
      || warn "Claude Code plugin not installed. Run: claude plugin install glaze-coder"
  fi
fi

# 6. Optional Raycast step: copy the scripts path so it is one paste away.
RAYCAST_DIR="$REPO/plugins/glaze-coder/scripts/raycast"
command -v pbcopy >/dev/null 2>&1 && printf '%s' "$RAYCAST_DIR" | pbcopy

print ""
green "Done."
print "Start a new app now:"
print '   glaze-dev start "My App"'
print ""
print "Optional (Raycast): Settings > Extensions > Script Commands > Add Directories,"
print "then paste (the path is on your clipboard):"
print "   $RAYCAST_DIR"
