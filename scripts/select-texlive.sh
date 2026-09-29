#!/usr/bin/env bash
# Picks where to install TeX Live VERSION (a release year, or latest) from,
# for zauguin/install-texlive. Sets the step outputs version and repository,
# and TEXLIVE (e.g. "TeX Live 2017") for the release notes.
set -euo pipefail

out="${GITHUB_OUTPUT:-/dev/null}"
if [ "$VERSION" = latest ]; then
  echo "TEXLIVE=TeX Live (latest)" >> "${GITHUB_ENV:-/dev/null}"
  exit 0
fi
echo "version=$VERSION" >> "$out"
echo "TEXLIVE=TeX Live $VERSION" >> "${GITHUB_ENV:-/dev/null}"
# A past release installs from its final, frozen state (plain HTTP, as older
# installers cannot download over HTTPS). The current release has no such
# archive yet, so install-texlive picks a mirror for it.
historic=http://ftp.math.utah.edu/pub/tex/historic/systems/texlive
repository="$historic/$VERSION/tlnet-final"
if curl -sfIL "$repository/install-tl-unx.tar.gz" > /dev/null; then
  echo "repository=$repository" >> "$out"
fi
