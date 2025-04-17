#!/bin/bash
set -euo pipefail
set -x

usermod -u "${PUID}" aur
groupmod -g "${PGID}" aur
mkdir -p /home/aur/.gnupg /aur/repo /aur/cache
chown -R aur:aur /home/aur /aur/repo /aur/cache
chown aur:aur /aur
chmod 700 /home/aur /home/aur/.gnupg

rm -fv /var/lib/pacman/db.lck

if [ -f /gpg/key ]; then
    sudo -H -u aur gpg --no-tty --batch --allow-secret-key-import --yes --import /gpg/key
fi

sudo -H -u aur /aur/gpgtest.sh

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

while :; do
    echo '[MIRROR BEGIN]'
    subuild /aur/init.sh
    pacman_up || (pacman_clear && pacman_up)
    subuild /aur/mirror.sh || true
    echo '[MIRROR END]'

    current_epoch="$(date '+%s')"
    target_epoch="$(date -d "${BUILD_TIMESPEC-tomorrow 14:14}" '+%s')"
    sleep_seconds="$(( "$target_epoch" - "$current_epoch" ))"
    sleep "$sleep_seconds"
done
