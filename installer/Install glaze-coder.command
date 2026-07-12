#!/bin/zsh
# Double-click to install glaze-coder.
# Source: https://github.com/GaimsDevSoftware/glaze-coder
set -e
tmp="$(mktemp -t glaze-coder-install)"
trap 'rm -f "$tmp"' EXIT

printf '\n  Getting the latest glaze-coder installer...\n\n'
curl -fsSL https://raw.githubusercontent.com/GaimsDevSoftware/glaze-coder/main/install.sh -o "$tmp"

# Run it directly (not piped) so it can ask which parts you want.
zsh "$tmp"

printf '\n  You can close this window now.\n\n'
