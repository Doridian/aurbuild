#!/bin/bash
set -euo pipefail
set -x

sed '~passphrase-file~d' -i /home/aur/.gnupg/gpg.conf /root/.gnupg/gpg.conf
if [ -f /gpg/passphrase ]; then
    echo 'passphrase-file /gpg/passphrase' >> /home/aur/.gnupg/gpg.conf
    echo 'passphrase-file /gpg/passphrase' >> /root/.gnupg/gpg.conf
fi

if [ -f /gpg/key ]; then
    # Fixed key file
elif [ -f /gpg/pin ]; then
    gpgconf --kill gpg-agent
    gpg --use-agent --card-status
    gpg --use-agent --yes --detach-sign -u "${GPG_KEY_ID}" --output /dev/null /aur/packages.txt
else
    echo 'WARNING: Package signing disabled!'
    exit 0
fi

if [ -z "${GPG_KEY_ID-}" ]; then
    echo 'GPG_KEY_ID is not set, but package signing is enabled'
    exit 1
fi
