#!/bin/bash
rm -f /tmp/in_cache /tmp/in_repo

find /aur/cache -iname '*.pkg.tar*' -printf '%f\n' | sort > /tmp/in_cache
find /aur/repo -iname '*.pkg.tar*' -printf '%f\n' | sort > /tmp/in_repo

echo '============== SUMMARY =============='
wc --total=never -l /tmp/in_cache /tmp/in_repo
echo '=============== DELTA ==============='
echo '> means only in repo'
echo '< means only in cache'
echo '=============== START ==============='
diff /tmp/in_cache /tmp/in_repo
echo '================ END ================'

rm -f /tmp/in_cache /tmp/in_repo
