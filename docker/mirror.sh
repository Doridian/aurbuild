#!/bin/bash
set -euo pipefail

set -x

rm -rf repo_new/*
mkdir -p cache repo repo_new

REPODIR="$(realpath ./repo_new)"
REGISTER_SCRIPT="$(realpath ./repo-register.sh)"
HAD_ERRORS=""

copypkg() {
    cp -av -- *.pkg.tar* "${REPODIR}"
}

for pkg in `cat ./packages.txt`; do
    if [ -z "$pkg" ]; then
        continue
    fi
    if [ "${pkg:0:1}" = "#" ]; then
        continue
    fi

    if [ ! -d "cache/$pkg" ]; then
        echo "Cloning $pkg"
        git clone -- "https://aur.archlinux.org/$pkg.git" "cache/$pkg"
    else
        echo "Updating $pkg"
        git -C "cache/$pkg" pull
    fi

    OLDREV=$(cat "cache/$pkg/.done" 2>/dev/null || true)
    NEWREV=$(git -C "cache/$pkg" rev-parse HEAD)

    pushd "cache/${pkg}"
    if [ "$OLDREV" = "$NEWREV" ]; then
        echo "$pkg is up to date"
        copypkg
        popd
        continue
    fi

    rm -fv .done
    rm -fv *.pkg.tar*
    if makepkg --syncdeps --noconfirm --needed --force --install; then
        echo "${NEWREV}" > .done
        copypkg
    else
        echo "Failed to build $pkg"
        HAD_ERRORS="yes"
    fi
    popd
done

if [ ! -z "${HAD_ERRORS}" ]; then
    exit 1
fi

pushd repo_new
rm -fv repo_new.*
if [ ! -z "${GPG_KEY_ID-}" ]; then
    find . -type f -iname '*.pkg.tar*' -not -iname '*.sig' -print -exec gpg --no-tty --batch --yes --detach-sign -u "${GPG_KEY_ID}" {} \;
    find . -type f -iname '*.pkg.tar*' -not -iname '*.sig' -print0 | xargs -0 repo-add -k "${GPG_KEY_ID}" -s -v foxdenaur.db.tar.xz
else
    repo-add foxdenaur.db.tar.xz *.pkg.tar*
fi
popd

rsync --delete -av repo_new/ repo/
