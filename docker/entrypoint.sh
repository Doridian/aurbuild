#!/bin/bash
set -euo pipefail

usermod -u "${PUID}" aur
groupmod -g "${PGID}" aur
chown -R aur:aur /home/aur /aur/repo /aur/cache
chown aur:aur /aur

if [ ! -z "${GPG_KEY_DATA-}" ]; then
    if [ -z "${GPG_KEY_ID-}" ]; then
        echo 'GPG_KEY_ID is not set, but GPG_KEY_DATA is set. Please set GPG_KEY_ID to the key ID of the key.'
        exit 1
    fi
    sudo -H -u aur gpg --import - <<<"${GPG_KEY_DATA}"
fi

while :;
do
    echo '[MIRROR BEGIN]'
    pacman -Syu --noconfirm --needed
    sudo -H -u aur ./mirror.sh
    echo '[MIRROR END]'
    sleep 1h
done
