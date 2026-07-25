#!/bin/zsh
# Double-click to install glaze-coder.
# Source: https://github.com/GaimsDevSoftware/glaze-coder
set -e
tmpdir="$(mktemp -d -t glaze-coder-install)"
trap 'rm -rf "$tmpdir"' EXIT

printf '\n  Getting the latest glaze-coder installer...\n\n'
curl -fsSL https://github.com/GaimsDevSoftware/glaze-coder/archive/refs/heads/main.tar.gz -o "$tmpdir/glaze-coder.tar.gz"
tar -xzf "$tmpdir/glaze-coder.tar.gz" -C "$tmpdir"
repo="$tmpdir/glaze-coder-main"
installer="$repo/install.sh"

printf '  Source: https://github.com/GaimsDevSoftware/glaze-coder/archive/refs/heads/main.tar.gz\n'
printf '  Installer: %s\n' "$installer"
printf '  SHA-256: '
shasum -a 256 "$installer" | awk '{print $1}'
printf '\n'
printf '  This script runs with your macOS user privileges and may install Claude Code plugin code.\n'
printf '  Review it first: less "%s"\n\n' "$installer"
printf '  Run this installer now? [y/N]: '
read ans
case "$ans" in
  [Yy]*) ;;
  *) printf '\n  Cancelled. Nothing was installed.\n\n'; exit 0 ;;
esac

# Run it from the downloaded local repo copy so the script does not fetch and
# execute another mutable remote script.
zsh "$installer"

printf '\n  You can close this window now.\n\n'
