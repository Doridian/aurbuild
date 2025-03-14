#!/bin/bash
set -euo pipefail

export WORKDIR="$(realpath "$(pwd)")"

mkdir -p cache repo

cd repo
"${WORKDIR}/repo-add.sh"
