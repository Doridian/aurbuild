#!/bin/bash
set -euo pipefail

ln -sf /dev/stderr /dev/log
ln -sf /dev/stderr /dev/console

usermod -u "${PUID}" aur
groupmod -g "${PGID}" aur
mkdir -p /home/aur/.gnupg /aur/repo /aur/cache
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

exec /usr/bin/crond -f -s -i
