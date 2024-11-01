#!/bin/sh
set -ex

IMG_NAME="aurbuild-local"

export PUID="$(id -u)"
export PGID="$(id -g)"
if [ ! -z "${SUDO_UID-}" ]; then
    export PUID="${SUDO_UID}"
fi
if [ ! -z "${SUDO_GID-}" ]; then
    export PGID="${SUDO_GID}"
fi

docker build -t "${IMG_NAME}" .
docker run --rm -it -v "$(pwd)/packages.txt:/aur/packages.txt:ro" -v "$(pwd)/cache:/aur/cache" -v "$(pwd)/repo:/aur/repo" -e PUID -e PGID "${IMG_NAME}"
