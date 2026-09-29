#!/usr/bin/env bash
# Installs system packages that Overleaf provides but TeX Live does not:
#
# - Ghostscript: xdvipdfmx converts EPS figures by running TeX Live's
#   rungs, which runs the system gs (see setup-rungs.sh); without it the
#   image is dropped and xdvipdfmx fails with "pdf_ref_obj(): passed
#   invalid object".
# - Microsoft's core fonts (Arial, Times New Roman, etc.), which fontspec
#   documents load by name;
# - Inconsolata: TeX Live's copy is the zi4 variant, whose family name is
#   "Inconsolatazi4", so \setmonofont{Inconsolata} finds only this one.
#
# Runs on the Ubuntu runner, where ttf-mscorefonts-installer is in
# multiverse; the full TeX Live image's Debian has it only in contrib, which
# is not enabled, so update_packages mounts the runner's copies into it
# instead (see SYSTEM_FONT_DIRS in build.yml).
set -euo pipefail

eula="msttcorefonts/accepted-mscorefonts-eula"
sudo debconf-set-selections <<< \
  "ttf-mscorefonts-installer $eula select true"
# sudo drops the environment by default, so pass DEBIAN_FRONTEND through env
# rather than exporting it
sudo env DEBIAN_FRONTEND=noninteractive apt-get update -q
sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y -q \
  --no-install-recommends fontconfig ghostscript \
  ttf-mscorefonts-installer fonts-inconsolata

