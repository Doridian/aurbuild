#!/bin/sh
set -ex

IMG_NAME="aurbuild-local"

docker build -t "${IMG_NAME}" .
docker run --rm -it -v "$(pwd)/packages.txt:/home/aur/docker/packages.txt:ro" -v "$(pwd)/cache:/home/aur/docker/cache" -v "$(pwd)/repo:/home/aur/docker/repo" -e "PUID=$(id -u)" -e "PGID=$(id -g)" "${IMG_NAME}"
