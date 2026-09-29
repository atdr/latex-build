#!/usr/bin/env bash
# Registers TeX Live's own fonts with fontconfig. TeX Live ships Inconsolata,
# Fira Sans, EB Garamond etc. as files under its own tree, not as system
# fonts, so fontconfig (which XeTeX and LuaTeX ask to resolve a font name)
# does not know about them until that tree is registered.
#
# Run after TeX Live is installed and on PATH, both on the runner (via sudo)
# and as root inside the full TeX Live image. Microsoft's core fonts come
# from install-system-fonts.sh instead.
set -euo pipefail

sudo=""
[ "$(id -u)" -eq 0 ] || sudo=sudo

root=$(kpsewhich -var-value TEXMFROOT)
$sudo mkdir -p /etc/fonts/conf.d
$sudo tee /etc/fonts/conf.d/09-texlive.conf > /dev/null <<EOF
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <dir>$root/texmf-dist/fonts/opentype</dir>
  <dir>$root/texmf-dist/fonts/truetype</dir>
  <dir>$root/texmf-dist/fonts/type1</dir>
</fontconfig>
EOF
# Without fc-cache, fontconfig scans the directories on first use instead
if command -v fc-cache > /dev/null; then
  $sudo fc-cache -f
fi
