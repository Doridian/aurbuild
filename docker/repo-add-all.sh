#!/bin/bash
set -euo pipefail

find . -maxdepth 1 -type f -iname '*.pkg.tar*' -not -iname '*.sig' -print0 | xargs -r -0 "${WORKDIR}/repo-add.sh"
