#!/bin/bash
set -euo pipefail
set -x

if [ -z "${GPG_KEY_ID-}" ]; then
    echo 'WARNING: Package signing disabled (GPG_KEY_ID not set)!'
    exit 0
fi

sed '/passphrase-file/d' -i /home/aur/.gnupg/gpg.conf /root/.gnupg/gpg.conf
if [ -f /gpg/passphrase ]; then
    echo 'passphrase-file /gpg/passphrase' >> /home/aur/.gnupg/gpg.conf
    echo 'passphrase-file /gpg/passphrase' >> /root/.gnupg/gpg.conf
fi

gpgconf --kill gpg-agent

if [ -f /gpg/key ]; then
    gpg --no-tty --batch --allow-secret-key-import --yes --import /gpg/key
else
    gpg --card-status
fi
gpg --yes --detach-sign -u "${GPG_KEY_ID}" --output /dev/null /aur/gpgtest.sh
