#!/usr/bin/env bash
# Checks that the .tex, .cls and .sty files tracked under ROOT_FILE's
# directory are formatted as tex-fmt would format them, reading the
# repository's tex-fmt.toml if it has one. .bib files are left out: they are
# usually exported from a reference manager. Annotates each change tex-fmt
# would make, adds the diff to the job summary, and fails if any file would
# change.
set -uo pipefail

# The release that callers' pre-commit hooks should pin too; TEX_FMT_VERSION
# overrides it
version="${TEX_FMT_VERSION:-0.5.7}"
dir=$(dirname "$ROOT_FILE")
summary="${GITHUB_STEP_SUMMARY:-/dev/null}"

if ! command -v tex-fmt > /dev/null; then
  bin="${RUNNER_TEMP:-/tmp}/tex-fmt"
  mkdir -p "$bin"
  url="https://github.com/WGUNDERWOOD/tex-fmt/releases/download"
  curl -sSfL "$url/v$version/tex-fmt-x86_64-linux.tar.gz" \
    | tar xz -C "$bin" || {
    echo "::error::Could not download tex-fmt $version"
    exit 1
  }
  export PATH="$bin:$PATH"
fi
echo "Checking with $(tex-fmt --version)"

failed=0
while IFS= read -r file; do
  tex-fmt --check --quiet "$file" > /dev/null 2>&1 && continue
  failed=$((failed + 1))
  diff=$(tex-fmt --print "$file" | diff -u "$file" -)
  # One annotation per hunk, at its first changed line
  awk 'NR <= 2 { next }
    /^@@/ { match($0, /-[0-9]+/); n = substr($0, RSTART + 1, RLENGTH - 1)
      hit = 0; next }
    !hit && /^[-+]/ { print n; hit = 1 }
    /^[ -]/ { n++ }' <<< "$diff" | while read -r line; do
    echo "::error file=$file,line=$line,title=tex-fmt::Not formatted;" \
      "run tex-fmt on this file"
  done
  {
    echo "#### \`$file\`"
    echo
    echo '```diff'
    tail -n +3 <<< "$diff"
    echo '```'
    echo
  } >> "$summary"
done < <(git ls-files -- "$dir/*.tex" "$dir/*.cls" "$dir/*.sty")

if [ "$failed" -gt 0 ]; then
  echo "::error::$failed file(s) not formatted with tex-fmt $version"
  exit 1
fi
echo "All files formatted"
