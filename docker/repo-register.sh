#!/bin/bash
set -euo pipefail

if [ -f /etc/.pacman.repo_new_added ]; then
    exit 0
fi

export REPODIR="$(realpath "$1")"

echo '[repo_new]' >> /etc/pacman.conf
echo "Server = file://${REPODIR}" >> /etc/pacman.conf
echo 'SigLevel = Never' >> /etc/pacman.conf

touch /etc/.pacman.repo_new_added

pacman -Sy --noconfirm
