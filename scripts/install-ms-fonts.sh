#!/usr/bin/env bash
# Installs Microsoft's core fonts (Arial, Times New Roman, etc.), which
# fontspec documents load by name but TeX Live does not ship. Runs on the
# Ubuntu runner, where ttf-mscorefonts-installer is in multiverse; the full
# TeX Live image's Debian has it only in contrib, which is not enabled, so
# list-packages.sh gets these fonts by mounting the runner's copy instead.
set -euo pipefail

eula="msttcorefonts/accepted-mscorefonts-eula"
sudo debconf-set-selections <<< \
  "ttf-mscorefonts-installer $eula select true"
# sudo drops the environment by default, so pass DEBIAN_FRONTEND through env
# rather than exporting it
sudo env DEBIAN_FRONTEND=noninteractive apt-get update -q
sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y -q \
  --no-install-recommends fontconfig ttf-mscorefonts-installer
