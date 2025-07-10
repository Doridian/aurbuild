#!/bin/bash
set -euo pipefail

cd "$1"

if [ "${2-}" = 'update' ] && grep -q '^ *pkgver *()' PKGBUILD; then
    makepkg --check --nobuild --nodeps --noprepare --nocheck --skipinteg >/dev/null
fi

export CARCH="$(uname -m)"
set +u
source PKGBUILD
set -u
echo $pkgver
