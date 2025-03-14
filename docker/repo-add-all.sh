#!/bin/bash
set -euo pipefail

REPO="$1"
GPG_ID="${2-}"

find . -maxdepth 1 -type f -iname '*.pkg.tar*' -not -iname '*.sig' -print0 | xargs -r -0 "${WORKDIR}/repo-add.sh" "$REPO" "$GPG_ID"
