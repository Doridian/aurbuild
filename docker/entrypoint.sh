#!/bin/bash
set -euo pipefail
set -x

usermod -u "${PUID}" aur
groupmod -g "${PGID}" aur

mkdir -p /home/aur/.gnupg /aur/repo /aur/cache /aur/tmp/gpg
cp /gpg/* /aur/tmp/gpg/
chown -R aur:aur /home/aur /aur/repo /aur/cache /aur/tmp
chown aur:aur /aur
chmod 700 /home/aur /home/aur/.gnupg /aur/tmp

rm -fv /var/lib/pacman/db.lck

pacman_up() {
    # This gets rid of all local packages, such that we only have repo packages
    pacman -Qm | cut -d' ' -f1 | xargs sudo pacman -R --noconfirm
    # Those (repo packages) get updated here
    pacman -Syu --noconfirm --needed
}

pacman_clear() {
    yes | pacman -Scc
}

_subuilder_raw() {
    sudo --preserve-env=GPG_KEY_ID -H -u aur "$@"
}

subuilder() {
    if [ -z "${UNSHARE_MOUNT_BUILDER-}" ]; then
        _subuilder_raw "$@"
    else
        _subuilder_raw unshare -c --keep-caps -m "$@"
    fi
}

subuilder /aur/gpgtest.sh
cat /home/aur/.gnupg/gpg.conf > /root/.gnupg/gpg.conf

BUILD_TIMESPEC="${BUILD_TIMESPEC-14:14}"

while :; do
    current_epoch="$(date '+%s')"
    target_epoch="$(date -d "today ${BUILD_TIMESPEC}" '+%s')"
    if [ "$target_epoch" -lt "$current_epoch" ]; then
        target_epoch="$(date -d "tomorrow ${BUILD_TIMESPEC}" '+%s')"
    fi
    sleep_seconds="$(( "$target_epoch" - "$current_epoch" ))"
    sleep "$sleep_seconds" || true

    echo '[MIRROR BEGIN]'
    subuilder /aur/init.sh
    pacman_up || (pacman_clear && pacman_up)
    subuilder /aur/mirror.sh || true
    echo '[MIRROR END]'
done
