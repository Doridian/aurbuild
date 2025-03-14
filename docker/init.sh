#!/bin/bash
set -euo pipefail

export WORKDIR="$(realpath "$(pwd)")"

rm -rf repo_new/*
mkdir -p cache repo repo_new

cd repo_new
"${WORKDIR}/repo-add.sh" repo_new.db.tar.xz
