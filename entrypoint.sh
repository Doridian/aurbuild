#!/bin/bash
set -e
if [ ! -z "${GPG_KEY_DATA-}" ]; then
    if [ -z "${GPG_KEY_ID-}" ]; then
        echo 'GPG_KEY_ID is not set, but GPG_KEY_DATA is set. Please set GPG_KEY_ID to the key ID of the key.'
        exit 1
    fi
    gpg --import /dev/stdin <<<"${GPG_KEY_DATA}"
fi

while :;
do
    ./mirror.sh
    sleep 1h
done
