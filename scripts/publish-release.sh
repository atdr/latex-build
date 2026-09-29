#!/usr/bin/env bash
# Attaches the compiled PDF to a release tagged build-<short SHA>, creating
# the release or, for a rebuild of the same commit, replacing its PDF and
# notes. WARNING, if set, is added to the notes.
set -euo pipefail

pdf="$(basename "$ROOT_FILE" .tex).pdf"
short=${SHA::7}
tag="build-$short"
# Link the commit explicitly, so the notes show the short SHA wherever they
# are read, not only where GitHub autolinks a full one
commit="[$short]($GITHUB_SERVER_URL/$GITHUB_REPOSITORY/commit/$SHA)"
notes="Compiled from $GITHUB_REF_NAME at $commit using $TEXLIVE."
if [ -n "${WARNING:-}" ]; then
  notes="$notes"$'\n\n'"⚠️ $WARNING"
fi

if gh release view "$tag" > /dev/null 2>&1; then
  # Rebuild of the same commit (e.g. with another TeX Live version)
  gh release upload "$tag" "$pdf" --clobber
  gh release edit "$tag" --notes "$notes"
else
  gh release create "$tag" "$pdf" \
    --target "$SHA" \
    --title "Build $short ($(git log -1 --format=%cs "$SHA"))" \
    --notes "$notes"
fi
