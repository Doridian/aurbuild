#!/bin/bash
set -euo pipefail

rm -rf repo_new/*
mkdir -p cache repo repo_new

REPODIR="$(realpath ./repo_new)"
HAD_ERRORS=""
UPDATED_PACKAGES=""

copypkg() {
    cp -av -- *.pkg.tar* "${REPODIR}"
    find . -type f -iname '*.pkg.tar*' -not -iname '*.sig' -print0 | xargs -0 sudo pacman -U --noconfirm --needed
}

for pkg in `cat ./packages.txt`; do
    if [ -z "$pkg" ]; then
        continue
    fi
    if [ "${pkg:0:1}" = "#" ]; then
        continue
    fi

    if [[ "$pkg" == *":"* ]]; then
        gitrepo="$pkg"
        # Extract part after last slash, but before .git
        pkg="$(echo "$pkg" | rev | cut -d/ -f1 | rev | sed 's~.git$~~')"
    else
        gitrepo="https://aur.archlinux.org/$pkg.git"
    fi

    if [ ! -d "cache/$pkg" ]; then
        echo "Cloning $pkg"
        git clone -- "$gitrepo" "cache/$pkg"
    else
        echo "Updating $pkg"
        git -C "cache/$pkg" remote set-url origin "$gitrepo"
        git -C "cache/$pkg" fetch
    fi
    git -C "cache/$pkg" checkout HEAD
    git -C "cache/$pkg" reset --hard "origin/$(git -C "cache/$pkg" branch --show-current)"

    OLDREV=$(cat "cache/$pkg/.done" 2>/dev/null || true)
    NEWREV=$(git -C "cache/$pkg" rev-parse HEAD)

    pushd "cache/${pkg}"
    if [ "$OLDREV" = "$NEWREV" ]; then
        echo "$pkg is up to date"
        if copypkg; then
            popd
            continue
        fi
        echo "$pkg failed to install pre-built. Rebuilding."
    fi

    rm -fv .done
    rm -fv *.pkg.tar*
    git clean -fdx
    if makepkg --syncdeps --noconfirm --needed --force --clean --cleanbuild; then
        if [ ! -z "${GPG_KEY_ID-}" ]; then
            find . -type f -iname '*.pkg.tar*' -not -iname '*.sig' -print -exec gpg --no-tty --batch --yes --detach-sign -u "${GPG_KEY_ID}" {} \;
        fi
        echo "${NEWREV}" > .done
        copypkg
    else
        echo "Failed to build $pkg"
        HAD_ERRORS="${HAD_ERRORS} ${pkg}"
    fi
    UPDATED_PACKAGES="${UPDATED_PACKAGES} ${pkg}"
    popd
done

if [ ! -z "${HAD_ERRORS}" ]; then
    echo "Failed to build: ${HAD_ERRORS}"
    exit 1
fi

if [ -z "${UPDATED_PACKAGES}" -a -f repo/foxdenaur.db ]; then
    echo 'No packages updated. Skipping repo generation'
    exit 0
fi

pushd repo_new
rm -fv repo_new.*
if [ ! -z "${GPG_KEY_ID-}" ]; then
    find . -type f -iname '*.pkg.tar*' -not -iname '*.sig' -print0 | xargs -0 repo-add -k "${GPG_KEY_ID}" -s -v foxdenaur.db.tar.xz
else
    repo-add foxdenaur.db.tar.xz *.pkg.tar*
fi
popd

rsync --delete -av repo_new/ repo/
