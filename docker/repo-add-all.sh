#!/bin/bash
set -euo pipefail

find /aur/repo -maxdepth 1 -type f -iname '*.pkg.tar*' -not -iname '*.sig' -print0 | xargs -r -0 /aur/repo-add.sh
