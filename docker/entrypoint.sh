#!/bin/bash
set -euo pipefail
set -x

socat UNIX-LISTEN:/dev/log STDERR &
_socat_pid=$!
trap "kill -9 $_socat_pid" EXIT

usermod -u "${PUID}" aur
groupmod -g "${PGID}" aur
mkdir -p /home/aur/.gnupg /aur/repo /aur/cache
chown -R aur:aur /home/aur /aur/repo /aur/cache
chown aur:aur /aur
chmod 700 /home/aur /home/aur/.gnupg

rm -fv /var/lib/pacman/db.lck

_has_gpg=0

if [ -f /gpg/pin ]; then
    _has_gpg=1
    sudo -H -u aur gpg --use-agent --card-status
elif [ -f /gpg/key ]; then
    _has_gpg=1
    sudo -H -u aur gpg --no-tty --batch --allow-secret-key-import --yes --import "${GPG_KEY_PATH}"
fi

if [ -z "${GPG_KEY_ID-}" ]; then
    echo 'GPG_KEY_ID is not set, but /gpg/key or /gpg/pin exist.'
    exit 1
fi

/usr/bin/crond -f -s -i
