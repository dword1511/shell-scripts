#!/bin/sh

# Rename photos received via WeiXin to appropriate file names with EXIF information.
# TODO: handle exceptions where there is no/incomplete EXIF information.

for fn in "${@}"
do
  dt=`exiftool "${fn}" | fgrep 'Date/Time Original' | head -1 | cut -d ':' -f '2-8' | sed -e 's/  */ /g' -e 's/[:]//g' -e 's/ /_/g'`
  newfn="IMG${dt}.jpg"
  mv -i "${fn}" "${newfn}"
done
