#!/bin/bash
set -euo pipefail

usermod -u "${PUID}" aur
groupmod -g "${PGID}" aur
mkdir -p /home/aur/.gnupg
chown -R aur:aur /home/aur /aur/repo /aur/cache
chown aur:aur /aur
chmod 700 /home/aur /home/aur/.gnupg

rm -fv /var/lib/pacman/db.lck

if [ ! -z "${GPG_KEY_DATA-}" ]; then
    if [ -z "${GPG_KEY_ID-}" ]; then
        echo 'GPG_KEY_ID is not set, but GPG_KEY_DATA is set. Please set GPG_KEY_ID to the key ID of the key.'
        exit 1
    fi
    sudo  -H -u aur gpg --no-tty --batch --allow-secret-key-import --yes --import - <<<"${GPG_KEY_DATA}"
fi

if [ ! -z "${GPG_KEY_PATH-}" ]; then
    if [ -z "${GPG_KEY_ID-}" ]; then
        echo 'GPG_KEY_ID is not set, but GPG_KEY_PATH is set. Please set GPG_KEY_ID to the key ID of the key.'
        exit 1
    fi
    sudo -H -u aur gpg --no-tty --batch --allow-secret-key-import --yes --import "${GPG_KEY_PATH}"
fi

pacman_up() {
    pacman -Qm | cut -d' ' -f1 | xargs sudo pacman -R --noconfirm
    pacman -Syu --noconfirm --needed
}

pacman_clear() {
    yes | pacman -Scc
}

while :;
do
    echo '[MIRROR BEGIN]'
    pacman_up || (pacman_clear && pacman_up)
    sudo --preserve-env=GPG_KEY_ID -H -u aur ./mirror.sh || true
    echo '[MIRROR END]'
    sleep 1h
done
