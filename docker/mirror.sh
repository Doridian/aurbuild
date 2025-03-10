#!/bin/bash
set -euo pipefail

WORKDIR="$(realpath "$(pwd)")"

rm -rf repo_new/*
mkdir -p cache repo repo_new

./premirror.sh

REPODIR="$(realpath ./repo_new)"
HAD_ERRORS=""
HAD_FATAL_ERRORS=""
UPDATED_PACKAGES=""

if [ -f /gpg/pin ]; then
    gpg --use-agent --card-status
    gpg --use-agent --pinentry-mode loopback --passphrase-file /gpg/pin --yes --detach-sign -u "${GPG_KEY_ID}" --output /dev/null ./packages.txt
fi

signpkg() {
    if [ ! -z "${GPG_KEY_ID-}" ]; then
        find . -type f -iname '*.pkg.tar*' -not -iname '*.sig' -print0 | xargs -r -0 -n1 gpg --use-agent --no-tty --batch --yes --detach-sign -u "${GPG_KEY_ID}"
    fi
}

copypkg() {
    # Fail if no artifacts
    ls *.pkg.tar* 2>/dev/null >/dev/null || false
    # Try to re-sign if no signature
    ls *.sig 2>/dev/null >/dev/null || signpkg
    if [ ! -z "${1-}" ]; then
        # Try local install
        find . -type f -iname '*.pkg.tar*' -not -iname '*.sig' -print0 | xargs -r -0 sudo pacman -U --noconfirm --needed
    fi
    # Finally, copy if all is good
    cp -av -- *.pkg.tar* "${REPODIR}"
}

for pkg in `cat ./packages.txt`; do
    if [ -z "$pkg" ]; then
        continue
    fi
    if [ "${pkg:0:1}" = "#" ]; then
        continue
    fi

    do_install=''
    if [ "${pkg:0:1}" = "!" ]; then
        do_install=true
        pkg="${pkg:1}"
    fi

    if [[ "$pkg" == *":"* ]]; then
        gitrepo="$pkg"
        # Extract part after last slash, but before .git
        pkg="$(echo "$pkg" | rev | cut -d/ -f1 | rev | sed 's~.git$~~')"
    else
        gitrepo="https://aur.archlinux.org/$pkg.git"
    fi

    cd "${WORKDIR}"

    if [ ! -d "cache/$pkg" ]; then
        echo "Cloning $pkg"
        git clone -- "$gitrepo" "cache/$pkg"
    else
        echo "Updating $pkg"
        git -C "cache/$pkg" remote set-url origin "$gitrepo"
        git -C "cache/$pkg" fetch
    fi
    GIT_BRANCH="origin/$(git -C "cache/$pkg" branch --show-current)"

    OLDREV="$(cat "cache/$pkg/.done" 2>/dev/null || true)"
    NEWREV="$(git -C "cache/$pkg" rev-parse "${GIT_BRANCH}")"
    CACHEDIR="$(realpath "cache/$pkg")"

    if [ "$OLDREV" = "$NEWREV" ]; then
        echo "$pkg is up to date"
        cd "${CACHEDIR}"
        if copypkg "${do_install}"; then
            continue
        fi
        echo "$pkg failed to install pre-built. Rebuilding."
    fi

    BUILDDIR="/tmp/aurbuild-$pkg"
    rm -rf "${BUILDDIR}"
    mkdir -p "${BUILDDIR}"
    rsync --delete -a "${CACHEDIR}/" "${BUILDDIR}/"

    cd "${BUILDDIR}"
    rm -fv .done
    rm -fv *.pkg.tar*
    git clean -fdx
    git reset --hard "${GIT_BRANCH}"
    if makepkg --syncdeps --noconfirm --needed --force --clean --cleanbuild; then
        signpkg
        echo "${NEWREV}" > .done
        rsync --delete -a "${BUILDDIR}/" "${CACHEDIR}/"

        cd "${CACHEDIR}"
        copypkg "${do_install}"

        UPDATED_PACKAGES="${UPDATED_PACKAGES} ${pkg}"
    else
        echo "Failed to build $pkg"
        HAD_ERRORS="${HAD_ERRORS} ${pkg}"

        cd "${CACHEDIR}"
        copypkg "${do_install}" || HAD_FATAL_ERRORS="${HAD_FATAL_ERRORS} ${pkg}"
    fi
done

if [ ! -z "${HAD_ERRORS}" ]; then
    echo "[AURBUILD] Failed to build: ${HAD_ERRORS}"
fi

if [ ! -z "${HAD_FATAL_ERRORS}" ]; then
    echo "[AURBUILD] Failed build fatally: ${HAD_FATAL_ERRORS}"
    exit 1
fi

if [ -z "${UPDATED_PACKAGES}" -a -f "${WORKDIR}/repo/foxdenaur.db" ]; then
    echo '[AURBUILD] No packages updated. Skipping repo generation'
    exit 0
fi

echo "[AURBUILD] Updated packages: ${UPDATED_PACKAGES}"

cd "${WORKDIR}/repo_new"
rm -fv repo_new.*
if [ ! -z "${GPG_KEY_ID-}" ]; then
    find . -type f -iname '*.pkg.tar*' -not -iname '*.sig' -print0 | xargs -r -0 repo-add -k "${GPG_KEY_ID}" -s -v foxdenaur.db.tar.xz
else
    repo-add foxdenaur.db.tar.xz *.pkg.tar*
fi
cd "${WORKDIR}"

rsync --delete -av repo_new/ repo/
