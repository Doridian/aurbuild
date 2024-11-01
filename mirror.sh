#!/bin/bash
set -euo pipefail

rm -rf repo_new/*
mkdir -p cache repo repo_new

REPODIR="$(realpath repo_new)"

for pkg in `cat ./packages.txt`; do
    if [ -z "$pkg" ]; then
        continue
    fi

    OLDREV=$(git -C "cache/$pkg" rev-parse HEAD 2>/dev/null || true)
    if [ ! -d "cache/$pkg" ]; then
        echo "Cloning $pkg"
        git clone -- "https://aur.archlinux.org/$pkg.git" "cache/$pkg"
    else
        echo "Updating $pkg"
        git -C "cache/$pkg" pull
    fi
    NEWREV=$(git -C "cache/$pkg" rev-parse HEAD)

    pushd "cache/${pkg}"
    if [ "$OLDREV" = "$NEWREV" -a -f .done ]; then
        echo "$pkg is up to date"
        cp -av *.pkg.tar.zst "${REPODIR}"
        popd
        continue
    fi

    rm -fv *.pkg.tar.zst
    makepkg --syncdeps --noconfirm --needed --force ${MAKEPKG_FLAGS-}
    if [ -z "${MAKEPKG_FLAGS-}" ]; then
        touch .done
        cp -av *.pkg.tar.zst "${REPODIR}"
    fi
    popd
done

if [ ! -z "${MAKEPKG_FLAGS-}" ]; then
    exit 0
fi

pushd repo_new
if [ ! -z "${GPG_KEY_ID-}" ]; then
    find . -type f -iname '*.pkg.tar*' -not -iname '*.sig' -print -exec gpg --batch --yes --detach-sign --use-agent -u "${GPG_KEY_ID}" {} \;
    find . -type f -iname '*.pkg.tar*' -not -iname '*.sig' -print0 | xargs -0 repo-add -k "${GPG_KEY_ID}" -s -v foxdenaur.db.tar.xz
else
    repo-add foxdenaur.db.tar.xz *.pkg.tar*
fi
popd

rsync --delete -av repo_new/ repo/
