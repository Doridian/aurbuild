#!/bin/bash
set -euo pipefail

REPO="$1"
if [ ! -z "${2-}" ]; then
    cd "$2"
fi

find . -maxdepth 1 -type f -iname '*.pkg.tar*' -not -iname '*.sig' -print0 | xargs -r -0 "${WORKDIR}/repo-add.sh" "$REPO"
