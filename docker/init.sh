#!/bin/bash
set -euo pipefail

mkdir -p /aur/repo /aur/cache
exec /aur/repo-add.sh
