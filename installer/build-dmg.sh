#!/bin/zsh
# Build the glaze-coder installer DMG from the files in this folder.
# Usage: installer/build-dmg.sh [output.dmg]
set -euo pipefail
here="${0:A:h}"
out="${1:-$here/../glaze-coder-installer.dmg}"
stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT

cp "$here/Install glaze-coder.command" "$stage/"
cp "$here/READ ME FIRST.txt" "$stage/"
chmod +x "$stage/Install glaze-coder.command"

rm -f "$out"
hdiutil create -volname "glaze-coder" -srcfolder "$stage" -ov -format UDZO "$out" >/dev/null
echo "Built: $out"
