#!/bin/bash
set -euo pipefail

/aur/premirror.sh

REPODIR="$(realpath /aur/repo)"
HAD_ERRORS=""
HAD_FATAL_ERRORS=""
UPDATED_PACKAGES=""

/aur/gpgtest.sh

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

    # Finally, copy if all is good
    cp -av -- *.pkg.tar* "${REPODIR}"
    find . -maxdepth 1 -type f -iname '*.pkg.tar*' -not -iname '*.sig' -print0 | xargs -r -0 /aur/repo-add.sh

    sudo pacman -Sy --noconfirm || true
}

for pkg in `cat /aur/packages.txt`; do
    if [ -z "$pkg" ]; then
        continue
    fi
    pkg="$(echo "$pkg" | tr -d '\r\n\t ')"
    if [ "${pkg:0:1}" = "#" ]; then
        continue
    fi

    pkgsubdir=''
    if [[ "$pkg" == *"!"* ]]; then
        gitrepo="$(echo "$pkg" | cut -d'!' -f1)"
        pkgsubdir="$(echo "$pkg" | cut -d'!' -f2)"
        pkg="$(echo "$pkg" | cut -d'!' -f3)"
    elif [[ "$pkg" == *":"* ]]; then
        gitrepo="$pkg"
        # Extract part after last slash, but before .git
        pkg="$(echo "$pkg" | rev | cut -d/ -f1 | rev | sed 's~.git$~~')"
    else
        gitrepo="https://aur.archlinux.org/$pkg.git"
    fi

    pkgroot="/aur/cache/$pkg"
    pkgdir="$pkgroot"
    if [ ! -z "$pkgsubdir" ]; then
        pkgdir="$pkgroot/$pkgsubdir"
    fi

    echo "[DIAG] pkg=$pkg pkgroot=$pkgroot pkgdir=$pkgdir gitrepo=$gitrepo"

    if [ ! -d "$pkgroot" ]; then
        echo "Cloning $pkg"
        git clone -- "$gitrepo" "$pkgroot"
    else
        echo "Updating $pkg"
        git -C "$pkgroot" remote set-url origin "$gitrepo"
        git -C "$pkgroot" fetch
    fi

    GIT_BRANCH="origin/$(git -C "$pkgroot" branch --show-current)"

    OLD_GITREV="$(cat "$pkgdir/.done.gitrev" 2>/dev/null || true)"
    NEW_GITREV="$(git -C "$pkgroot" rev-parse "${GIT_BRANCH}")"

    OLD_PKGVER="$(cat "$pkgdir/.done.pkgver" 2>/dev/null || true)"
    NEW_PKGVER="$(/aur/getver.sh "$pkgdir" update)"

    for trynum in `seq 1 2`; do
        # This seems a little hacky to put in the loop...
        # But this way, the .lastcheck update below only has to be
        # written once, and we don't duplicate code
        if [ "$OLD_GITREV" = "$NEW_GITREV" ] && [ "$OLD_PKGVER" = "$NEW_PKGVER" ]; then
            echo "$pkg is up to date"
            break
        fi

        cd "$pkgdir"
        rm -fv .done.gitrev .done.pkgver
        rm -fv *.pkg.tar*
        rm -rf pkg src
        git reset --hard "${GIT_BRANCH}"
        if makepkg --syncdeps --noconfirm --needed --force --cleanbuild; then
            signpkg
            echo "${NEW_GITREV}" > .done.gitrev
            /aur/getver.sh . > .done.pkgver
            copypkg
            UPDATED_PACKAGES="${UPDATED_PACKAGES} ${pkg}"
            break
        elif [ $trynum -le 1 ]; then
            echo "Failed to build $pkg, retrying after git clean"
            git clean -fdx
        else
            echo "Failed to build $pkg after retrying, giving up"
            HAD_ERRORS="${HAD_ERRORS} ${pkg}"
        fi
    done

    cd "$pkgdir"
    rm -rf pkg src

    date > "$pkgroot/.lastcheck"
    if [ ! -z "$pkgsubdir" ]; then
        date > "$pkgdir/.lastcheck"
    fi
done

if [ ! -z "${HAD_ERRORS}" ]; then
    echo "[AURBUILD] Failed to build: ${HAD_ERRORS}"
fi

if [ ! -z "${HAD_FATAL_ERRORS}" ]; then
    echo "[AURBUILD] Failed build fatally: ${HAD_FATAL_ERRORS}"
    exit 1
fi

if [ -z "${UPDATED_PACKAGES}" ]; then
    echo '[AURBUILD] No packages updated'
else
    echo "[AURBUILD] Updated packages: ${UPDATED_PACKAGES}"
fi
