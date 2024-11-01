#!/bin/bash
set -euo pipefail

set -x

rm -rf repo_new/*
mkdir -p cache repo repo_new

REPODIR="$(realpath ./repo_new)"
REGISTER_SCRIPT="$(realpath ./repo-register.sh)"

copypkg() {
    DBNEW="${REPODIR}/repo_new.db.new"
    rm -fv "${DBNEW}"
    find . -type f -iname '*.pkg.tar*' -print0 > "${DBNEW}"
    ( cat "${DBNEW}" && echo -n "${REPODIR}" ) | xargs -0 cp -av
    pushd "${REPODIR}"
    cat "${DBNEW}" | xargs -0 repo-add repo_new.db.tar.xz
    popd
    rm -fv "${DBNEW}"
    sudo "${REGISTER_SCRIPT}" "${REPODIR}"
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
    sudo pacman -Sy --noconfirm
    if makepkg --syncdeps --noconfirm --needed --force ${MAKEPKG_FLAGS-}; then
        if [ -z "${MAKEPKG_FLAGS-}" ]; then
            echo "${NEWREV}" > .done
            copypkg
        fi
    else
        echo "Failed to build $pkg"
        exit 1
    fi
    popd
done

if [ ! -z "${MAKEPKG_FLAGS-}" ]; then
    exit 0
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
