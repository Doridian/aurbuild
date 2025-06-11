#!/bin/bash
set -euo pipefail
set -x

gpg --recv-keys "$1"
gpg --export --armor "$1" > "./docker/keys/pgp/$1.asc"
