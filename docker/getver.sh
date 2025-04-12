#!/bin/bash
set -euo pipefail

cd "$1"

if [ "${2-}" = 'update' ]; then
    makepkg --check --nobuild >&2
fi

source PKGBUILD
echo $pkgver
