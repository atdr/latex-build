#!/usr/bin/env bash
# Reports problems in a document that compiled: with LINT=true, chktex's
# findings for ROOT_FILE and the files it \inputs; with ANNOTATE_WARNINGS=true,
# the warnings in the final LaTeX log (undefined references and citations,
# overfull boxes, missing characters and font substitutions, package
# warnings). Each becomes a workflow annotation and a row in the job summary.
# Sets the step output warnings=<count>; never fails the step itself.
set -uo pipefail

log="$(basename "$ROOT_FILE" .tex).log"
summary="${GITHUB_STEP_SUMMARY:-/dev/null}"
count=0
rows=()

# Workflow commands end at a newline and treat % as an escape
escape() {
  local s=${1//%/%25}
  s=${s//$'\r'/%0D}
  printf '%s' "${s//$'\n'/%0A}"
}

# Markdown table cells cannot contain | or backticks unescaped
cell() {
  local s=${1//|/\\|} quote="'"
  printf '%s' "${s//\`/$quote}"
}

if [ "${LINT:-false}" = true ]; then
  # chktex is not in the document's package list, and the list must not
  # change because of it
  if ! command -v chktex > /dev/null; then
    tlmgr install chktex > /dev/null 2>&1 \
      || echo "::warning::Could not install chktex; skipping lint"
  fi
  if command -v chktex > /dev/null; then
    # file:line:column:number:message; chktex follows \input and \include
    while IFS=: read -r file line col num msg; do
      [ -n "$file" ] || continue
      echo "::warning file=$file,line=$line,col=$col,title=chktex" \
        "$num::$(escape "$msg")"
      rows+=("| chktex $num | \`$(cell "$file")\`:$line | $(cell "$msg") |")
      count=$((count + 1))
    done < <(chktex -q -f $'%f:%l:%c:%n:%m\n' "$ROOT_FILE" 2>/dev/null)
  fi
fi

if [ "${ANNOTATE_WARNINGS:-false}" = true ] && [ -f "$log" ]; then
  # compile.sh sets max_print_line, so each warning's first line is whole.
  # The log does not say which file a warning came from, so these are
  # annotations on the run rather than on a line of a file.
  while IFS= read -r warning; do
    echo "::warning title=LaTeX::$(escape "$warning")"
    rows+=("| LaTeX | | $(cell "$warning") |")
    count=$((count + 1))
  done < <(grep -E \
    -e '^(LaTeX|LaTeX Font|Package [^ ]+|Class [^ ]+) Warning: ' \
    -e '^Overfull \\[hv]box ' \
    -e '^Missing character: ' \
    "$log" \
    | grep -vE 'There were undefined (references|citations)|Label\(s\) may' \
    | grep -vE 'Rerun to get' \
    | awk '!seen[$0]++')
fi

if [ "$count" -gt 0 ]; then
  {
    echo "### $count document warning(s)"
    echo
    echo "| Source | Location | Warning |"
    echo "|---|---|---|"
    printf '%s\n' "${rows[@]}"
  } >> "$summary"
fi
echo "warnings=$count" >> "${GITHUB_OUTPUT:-/dev/null}"
