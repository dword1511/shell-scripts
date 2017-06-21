#!/bin/sh

# This shell script verifies whether any files in the specific directory is
# affected by the NCQ TRIM firmware bug.
# See http://linux.slashdot.org/story/15/06/16/201217/trim-and-linux-tread-cautiously-and-keep-backups-handy
# Affected devices:
#   Micron_M500*
#   Crucial_CT*M500*
#   Micron_M5[15]0*
#   Crucial_CT*M550*
#   Crucial_CT*MX100*
#   Samsung SSD 8*
# Some firmware fixes are released. Meanwhile, newer kernel have proper
# blacklists to work the problems around.

if [ -z "$1" ]
then
  echo "Usage: $0 [directory|file]"
  exit 1
fi

if [ -d "$1" ]
then
  # Make the effect of lastest TRIM appear
  sudo sysctl vm.drop_caches=3

  echo "Entering \`$1'"
  find "$1" -type f -exec "$0" {} \;
else
  # currently very loose
  hexdump "$1" | egrep -q '^[0-9\.]+[24680]00 0000 0000 0000 0000 0000 0000 0000 0000' && echo "WARN: \`$1' is positive"
fi
