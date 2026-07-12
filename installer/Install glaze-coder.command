#!/bin/zsh
# Double-click to install glaze-coder.
# Source: https://github.com/GaimsDevSoftware/glaze-coder
set -e
printf '\n  Installing glaze-coder. This downloads the latest version and sets it up.\n\n'
curl -fsSL https://raw.githubusercontent.com/GaimsDevSoftware/glaze-coder/main/install.sh | zsh
printf '\n  Done. You can close this window.\n\n'
