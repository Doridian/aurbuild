#!/bin/bash
set -euo pipefail

REPO='foxdenaur.db.tar.xz'

ARGS=("$@")
for i in "${!ARGS[@]}"; do
    ARGS[$i]="$(basename "${ARGS[$i]}")"
done

if [ ! -z "${GPG_KEY_ID-}" ]; then
    repo-add -n -R -p -k "${GPG_KEY_ID}" -s -v "$REPO" "$@"
else
    repo-add -n -R -p "$REPO" "$@"
fi
