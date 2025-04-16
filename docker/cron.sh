#!/bin/bash
set -euo pipefail

pacman_up() {
    # This gets rid of all local packages, such that we only have repo packages
    pacman -Qm | cut -d' ' -f1 | xargs sudo pacman -R --noconfirm
    # Those (repo packages) get updated here
    pacman -Syu --noconfirm --needed
}

pacman_clear() {
    yes | pacman -Scc
}

subuild() {
    sudo --preserve-env=GPG_KEY_ID -H -u aur "$@"
}

echo '[MIRROR BEGIN]'
subuild /aur/init.sh
pacman_up || (pacman_clear && pacman_up)
subuild /aur/mirror.sh || true
echo '[MIRROR END]'
