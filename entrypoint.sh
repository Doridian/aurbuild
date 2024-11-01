#!/bin/bash
set -euo pipefail

usermod -u "${PUID}" aur
groupmod -g "${PGID}" aur
chown -R aur:aur /home/aur

if [ ! -z "${GPG_KEY_DATA-}" ]; then
    if [ -z "${GPG_KEY_ID-}" ]; then
        echo 'GPG_KEY_ID is not set, but GPG_KEY_DATA is set. Please set GPG_KEY_ID to the key ID of the key.'
        exit 1
    fi
    sudo -H -u aur gpg --import /dev/stdin <<<"${GPG_KEY_DATA}"
fi

while :;
do
    pacman -Syu --noconfirm --needed
    sudo -H -u aur ./mirror.sh
    sleep 1h
done
