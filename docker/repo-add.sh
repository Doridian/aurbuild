#!/bin/bash
set -euo pipefail

REPO="$1"
shift 1

ARGS=("$@")
for i in "${!ARGS[@]}"; do
    ARGS[$i]="$(basename "${ARGS[$i]}")"
done

if [ ! -z "${GPG_KEY_ID-}" ]; then
    repo-add -k "${GPG_KEY_ID}" -s -v "$REPO" "$@"
else
    repo-add "$REPO" "$@"
fi
