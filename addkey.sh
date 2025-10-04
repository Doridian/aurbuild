#!/bin/bash
set -euo pipefail
set -x

gpg --batch --no-tty --recv-keys "$1"
gpg --batch --no-tty --export --armor "$1" > "./docker/keys/pgp/$1.asc"
