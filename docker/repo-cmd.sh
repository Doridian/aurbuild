#!/bin/bash
set -euo pipefail

CMD="$1"
shift 1

cd /aur/repo
REPO='foxdenaur.db.tar.xz'

if [ ! -z "${GPG_KEY_ID-}" ]; then
    "$CMD" -R -k "${GPG_KEY_ID}" -s -v "$REPO" "$@"
else
    "$CMD" -R "$REPO" "$@"
fi
