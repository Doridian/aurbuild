#!/bin/bash
set -euo pipefail
set -x

if [ -f /gpg/pin ]; then
    gpgconf --kill gpg-agent
    gpg --use-agent --card-status
    gpg --use-agent --pinentry-mode loopback --passphrase-file /gpg/pin --yes --detach-sign -u "${GPG_KEY_ID}" --output /dev/null /aur/packages.txt
elif [ -f /gpg/key ]; then
    # Fixed key file
    true
else
    echo 'WARNING: Package signing disabled!'
    exit 0
fi

if [ -z "${GPG_KEY_ID-}" ]; then
    echo 'GPG_KEY_ID is not set, but package signing is enabled'
    exit 1
fi
