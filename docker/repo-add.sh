#!/bin/bash
set -euo pipefail

cd /aur/repo
REPO='foxdenaur.db.tar.xz'

ARGS=("$@")
for i in "${!ARGS[@]}"; do
    ARGS[$i]="$(basename "${ARGS[$i]}")"
done

if [ ! -z "${GPG_KEY_ID-}" ]; then
    repo-add -R -k "${GPG_KEY_ID}" -s -v "$REPO" "$@"
else
    repo-add -R "$REPO" "$@"
fi
