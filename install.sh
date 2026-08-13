#!/bin/zsh
# Installer for glaze-coder.
#
# Run from a reviewed local copy:
#   git clone https://github.com/GaimsDevSoftware/glaze-coder.git
#   cd glaze-coder
#   ./install.sh
#
# It always installs the core glaze-dev command. When run in a terminal it asks
# which extra parts you want.
#
# You can also pick parts without being asked, by setting any of these to 1 or 0:
#   GLAZE_SKILLS=1   Glaze skills for Claude Code
#   GLAZE_CLAUDE=1   Try to install Claude Code with npm when it is missing
#   GLAZE_PLUGIN=1   Claude Code plugin (/glaze-coder:glaze)
#   GLAZE_RAYCAST=1  Open Raycast to finish adding its commands
#   GLAZE_ALLOW_REMOTE_BOOTSTRAP=1
#                     Allow a standalone install.sh to download the repo archive
#   GLAZE_REF=<tag>   Download that exact tag instead of the main branch. Callers
#                     that fetched a pinned install.sh should pass the same tag,
#                     so the code that runs is the code that was reviewed. An
#                     existing local checkout is never modified when this is set.
emulate -L zsh
setopt pipe_fail 2>/dev/null

REPO_URL="https://github.com/GaimsDevSoftware/glaze-coder.git"
# GitHub serves /archive/<ref>.tar.gz for both branches and tags.
REF="${GLAZE_REF:-main}"
ARCHIVE_URL="https://github.com/GaimsDevSoftware/glaze-coder/archive/${REF}.tar.gz"
green() { print -P "%F{green}$1%f"; }
warn()  { print -P "%F{yellow}$1%f"; }
head()  { print -P "%F{cyan}%B$1%b%f"; }

# Ask a yes/no question. ask <default:y|n> <prompt>. Returns 0 for yes.
# Falls back to the default when there is no terminal.
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

add_glaze_node_to_path() {
  local base="" cand
  for cand in \
    "$HOME/Library/Application Support/app.glaze.macos.main" \
    "$HOME/Library/Application Support/"app.glaze.macos.*(/N) ; do
    [[ -d "$cand/node/runtime" ]] && { base="$cand"; break; }
  done
  [[ -n "$base" ]] || return 0
  local bins=("$base"/node/runtime/*/bin(N))
  (( ${#bins} )) && export PATH="${bins[1]}:$PATH"
}

install_claude_code() {
  command -v npm >/dev/null 2>&1 || return 1
  print "  Installing Claude Code with npm..."
  npm install -g @anthropic-ai/claude-code >/dev/null 2>&1
}

bootstrap_repo() {
  local target="$1"
  if [[ -d "$target/.git" ]]; then
    # A pinned install must not touch a checkout the user owns and may be working
    # in: no pull, no checkout, no detached HEAD. Their copy wins.
    if [[ -n "${GLAZE_REF:-}" ]]; then
      print "Using existing $target as is (pinned install does not modify a local checkout)."
      return 0
    fi
    print "Updating existing $target ..."
    if command -v git >/dev/null 2>&1; then
      git -C "$target" pull --quiet --ff-only || warn "Could not update, using existing copy."
    else
      warn "git is not installed; using existing copy."
    fi
    return 0
  fi

  if [[ -d "$target/plugins/glaze-coder" ]]; then
    warn "Using existing $target (git is not available to update it)."
    return 0
  fi

  if command -v git >/dev/null 2>&1; then
    print "Cloning glaze-coder into $target ($REF) ..."
    git clone --quiet --branch "$REF" --depth 1 "$REPO_URL" "$target" || return 1
    return 0
  fi

  if command -v curl >/dev/null 2>&1 && command -v tar >/dev/null 2>&1; then
    print "git is not installed; downloading glaze-coder as an archive ($REF)..."
    local tmp; tmp="$(mktemp -d)" || return 1
    mkdir -p "${target:h}"
    curl -fsSL "$ARCHIVE_URL" -o "$tmp/glaze-coder.tar.gz" || { rm -rf "$tmp"; return 1; }
    tar -xzf "$tmp/glaze-coder.tar.gz" -C "$tmp" || { rm -rf "$tmp"; return 1; }
    # GitHub names the extracted folder after the ref (glaze-coder-main,
    # glaze-coder-0.2.1, ...), so find it rather than assuming the branch.
    local -a extracted; extracted=("$tmp"/glaze-coder-*(N/))
    (( ${#extracted} )) || { rm -rf "$tmp"; return 1; }
    rm -rf "$target"
    mv "${extracted[1]}" "$target" || { rm -rf "$tmp"; return 1; }
    rm -rf "$tmp"
    return 0
  fi

  print -u2 "Could not download glaze-coder automatically."
  print -u2 "Requirement: install git or curl, then run the installer again."
  return 1
}

add_glaze_node_to_path

# 1. Find the repo, or clone it if we are running standalone.
SELF_DIR="${0:A:h}"
if [[ -f "$SELF_DIR/plugins/glaze-coder/scripts/glaze-dev" ]]; then
  REPO="$SELF_DIR"
else
  REPO="$HOME/glaze-coder"
  case "${GLAZE_ALLOW_REMOTE_BOOTSTRAP:-}" in
    1|true|yes)
      warn "Standalone installer mode: downloading the repo archive because only install.sh is present."
      bootstrap_repo "$REPO" || { print -u2 "Install failed. See the requirement above."; exit 1; }
      ;;
    *)
      print -u2 "This installer must be run from a local glaze-coder checkout."
      print -u2 "Recommended:"
      print -u2 "  git clone https://github.com/GaimsDevSoftware/glaze-coder.git"
      print -u2 "  cd glaze-coder"
      print -u2 "  ./install.sh"
      print -u2 ""
      print -u2 "If you intentionally reviewed this standalone script and want it to download"
      print -u2 "the repo archive, rerun with: GLAZE_ALLOW_REMOTE_BOOTSTRAP=1 zsh install.sh"
      exit 1
      ;;
  esac
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

# 3. Glaze skills for your coding tool(s).
if [[ -d "$HOME/.zcode" ]]; then
  head "Glaze skills for Claude Code and ZCode  (recommended)"
  print "  Links Glaze's own guides into ~/.claude and ~/.zcode so both Claude Code and"
  print "  ZCode know how Glaze apps are built. Safe to install. Recommended for everyone."
else
  head "Glaze skills for Claude Code  (recommended)"
  print "  Links Glaze's own guides into ~/.claude so Claude Code knows how Glaze apps"
  print "  are built and follows the right steps. Safe to install. Recommended for everyone."
fi
if want "$GLAZE_SKILLS" y "Install the Glaze skills?"; then
  "$HOME/.local/bin/glaze-dev" skills >/dev/null 2>&1 || true
  green "  Installed Glaze skills"
  [[ -d "$HOME/.zcode" ]] && green "  ZCode found: skills linked into ~/.zcode too"
else
  print "  Skipped."
fi
print ""

# 4. Claude Code plugin.
head "Claude Code plugin  (recommended)"
print "  Adds the /glaze-coder:glaze command inside Claude Code, which lists your apps"
print "  and starts building. Works in the Claude Code terminal and desktop app."
warn "  This installs plugin code from the GaimsDevSoftware/glaze-coder marketplace."
warn "  Install it only if you trust that repository and its future updates."
if ! command -v claude >/dev/null 2>&1; then
  warn "  Claude Code was not found on your PATH."
  if want "$GLAZE_CLAUDE" n "Install Claude Code now with npm?"; then
    if install_claude_code && command -v claude >/dev/null 2>&1; then
      green "  Installed Claude Code"
      warn "  Run 'claude' once after this installer to log in."
    else
      warn "  Could not install Claude Code automatically."
      warn "  Requirement: install it from https://claude.com/product/claude-code, then run 'claude' to log in."
    fi
  else
    warn "  Requirement: install Claude Code from https://claude.com/product/claude-code, then run 'claude' to log in."
  fi
fi
if command -v claude >/dev/null 2>&1 && want "$GLAZE_PLUGIN" y "Install the Claude Code plugin?"; then
  claude plugin marketplace add GaimsDevSoftware/glaze-coder >/dev/null 2>&1 || true
  if claude plugin install glaze-coder >/dev/null 2>&1 \
     || claude plugin install glaze-coder@glaze-coder-marketplace >/dev/null 2>&1; then
    green "  Installed the Claude Code plugin (/glaze-coder:glaze)"
  else
    warn "  Could not install automatically. Run: claude plugin install glaze-coder"
  fi
elif command -v claude >/dev/null 2>&1; then
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

# 6. Guided check of the whole setup (Glaze, Claude Code, skills, AI engines).
print ""
if [[ -t 0 ]]; then
  if ask y "Run the setup check now? (verifies Glaze, Claude Code and the AI engines)"; then
    "$HOME/.local/bin/glaze-dev" setup || true
  fi
else
  print "Tip: run 'glaze-dev setup' for a guided check of the whole setup."
fi

print ""
green "Done."
print "Start a new app now:"
print '   glaze-dev start "My App"'
print ""
