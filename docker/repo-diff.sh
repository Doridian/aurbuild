#!/bin/bash
rm -f /tmp/inrepo /tmp/incache

find /aur/repo -iname '*.pkg.tar*' -printf '%f\n' | sort > /tmp/inrepo
find /aur/cache -iname '*.pkg.tar*' -printf '%f\n' | sort > /tmp/incache

echo '> means only in repo'
echo '< means only in cache'
echo '=============== START ==============='
diff /tmp/incache /tmp/inrepo
echo '================ END ================'

rm -f /tmp/inrepo /tmp/incache
