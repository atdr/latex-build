#!/usr/bin/env bash
# Makes TeX Live's rungs, which xdvipdfmx runs to convert EPS figures, work
# with only the listed packages installed. The generated list records the
# programs latexmk runs, not those xdvipdfmx starts, so rungs may be absent
# (TeX Live 2016) or present without the script it launches (recent
# releases). On Unix rungs only runs gs, so write that in its place, next
# to xdvipdfmx in TeX Live's bin directory. Run after TeX Live is installed.
set -euo pipefail

bin=$(dirname "$(command -v xdvipdfmx)")
rm -f "$bin/rungs"
printf '#!/bin/sh\nexec gs "$@"\n' > "$bin/rungs"
chmod +x "$bin/rungs"
