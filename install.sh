#!/bin/zsh
# One-shot installer for glaze-coder: puts `glaze-dev` on your PATH and links
# Glaze's skills into ~/.claude/skills. Safe to re-run.
emulate -L zsh
set -e
DIR="${0:A:h}"
LAUNCHER="$DIR/plugins/glaze-coder/scripts/glaze-dev"

[[ -f "$LAUNCHER" ]] || { print -u2 "❌ Could not find $LAUNCHER"; exit 1; }
chmod +x "$LAUNCHER"
mkdir -p "$HOME/.local/bin"
ln -sf "$LAUNCHER" "$HOME/.local/bin/glaze-dev"
print -r -- "✓ Linked glaze-dev → ~/.local/bin/glaze-dev"

# Link Glaze's bundled skills into ~/.claude so your own Claude Code knows Glaze.
"$HOME/.local/bin/glaze-dev" skills 2>/dev/null || true

case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) print -r -- "⚠  Add ~/.local/bin to PATH, put this in ~/.zshrc:"
     print -r -- '     export PATH="$HOME/.local/bin:$PATH"' ;;
esac

print -r -- ""
print -r -- "Done. Easiest way to start a new app:"
print -r -- '   glaze-dev start "My App"'
