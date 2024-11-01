#!/bin/sh
set -euo pipefail

set -x

rm -f packages.raw
pacman -Qm > packages.raw

cat packages.raw packages.txt | \
    cut -d' ' -f1 | \
    grep -v "\-debug$" | \
    sort | \
    uniq > packages.new

rm -f packages.txt packages.raw
mv packages.new packages.txt
