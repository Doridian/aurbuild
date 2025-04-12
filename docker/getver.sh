#!/bin/bash
set -euo pipefail

cd "$1"

if [ "${2-}" = 'update' ] && grep -q '^ *pkgver *()' PKGBUILD; then
    makepkg --check --nobuild --nodeps >&2
fi

# PKGBUILDs can be all kinds of crazy, so disable errors
set +euo pipefail
source PKGBUILD
echo $pkgver
