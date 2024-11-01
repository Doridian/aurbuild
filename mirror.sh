#!/bin/bash
set -euo pipefail

mkdir -p cache repo

for pkg in `cat ./packages.txt`; do
    if [ ! -d "cache/$pkg" ]; then
        echo "Cloning $pkg"
        git clone -- "https://aur.archlinux.org/$pkg.git" "cache/$pkg"
    else
        echo "Updating $pkg"
        git -C "cache/$pkg" pull
    fi
    git -C "cache/$pkg" submodule update --init --recursive
done
