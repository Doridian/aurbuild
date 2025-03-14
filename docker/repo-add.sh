#!/bin/bash
set -euo pipefail

REPO="$1"
GPG_ID="$2"
shift 2

ARGS=("$@")
for i in "${!ARGS[@]}"; do
    ARGS[$i]="$(basename "${ARGS[$i]}")"
done

if [ ! -z "$GPG_ID" ]; then
    repo-add -k "$GPG_ID" -s -v "$REPO" "$@"
else
    repo-add "$REPO" "$@"
fi
