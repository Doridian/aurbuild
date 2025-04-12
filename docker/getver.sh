#!/bin/bash
set -euo pipefail

cd "$1"

if [ "${2-}" = 'update' ] && grep -q '^ *pkgver *()' PKGBUILD; then
    makepkg --check --nobuild --nodeps --noprepare --nocheck >&2
fi

CARCH="$(uname -m)"
source PKGBUILD
echo $pkgver
