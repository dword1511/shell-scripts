#!/bin/sh

set -e

if [ -z "${1}" ] || [ -z "${2}" ]; then
  echo "Flattens all graphics in a PDF"
  echo
  echo "NOTE: stacking of layers may change. Bitmaps and vector graphs will always be put in the background."
  echo "Bitmaps and vector graphs cannot be separated as they tend to mask each other without perserving the order."
  echo
  echo "Usage: ${0} input_file output_file [DPI] [quality]"
  echo
  echo "Default DPI is 150 and default quality is 90."
  exit 1
fi

if [ -z "${3}" ]; then
  dpi=150
else
  dpi="${3}"
fi
readonly dpi

if [ -z "${4}" ]; then
  quality=90
else
  quality="${4}"
fi
readonly quality

readonly num_pages=$(pdfinfo "${1}" | fgrep 'Pages:' | tr -s ' ' | cut -d ' ' -f 2)

readonly temp_dir=$(mktemp -d)

echo "DPI:" "${dpi}"
echo "Quality:" "${quality}"
echo "Pages:" "${num_pages}"
echo "Temp dir:" "${temp_dir}"

pdf_pages=""
for page in $(seq 1 "${num_pages}"); do
  echo "Processing page ${page}..."

  gs -q -o "${temp_dir}"/texts.pdf -sDEVICE=pdfwrite -dFILTERIMAGE -dFILTERVECTOR -dFirstPage="${page}" -dLastPage="${page}" "${1}"
  #gs -q -o "${temp_dir}"/vectors.pdf -sDEVICE=pdfwrite -dFILTERIMAGE -dFILTERTEXT -dFirstPage="${page}" -dLastPage="${page}" "${1}"
  #gs -q -o "${temp_dir}"/bitmaps.pdf -sDEVICE=pdfwrite -dFILTERTEXT -dFILTERVECTOR -dFirstPage="${page}" -dLastPage="${page}" "${1}"
  gs -q -o "${temp_dir}"/graphics.pdf -sDEVICE=pdfwrite -dFILTERTEXT -dFirstPage="${page}" -dLastPage="${page}" "${1}"

  #convert "${temp_dir}"/bitmaps.pdf -units PixelsPerInch -density "${dpi}" -strip -sampling-factor 4:2:0 -interlace Plane -gaussian-blur 0.2 -quality "${quality}" "${temp_dir}"/bitmaps.jpg
  #convert "${temp_dir}"/bitmaps.pdf -units PixelsPerInch -density "${dpi}" -strip "${temp_dir}"/bitmaps.png
  #optipng "${temp_dir}"/bitmaps.png 2> /dev/null
  convert "${temp_dir}"/graphics.pdf -units PixelsPerInch -density "${dpi}" -strip -sampling-factor 4:2:0 -interlace Plane -gaussian-blur 0.2 -quality "${quality}" "${temp_dir}"/graphics.jpg
  convert "${temp_dir}"/graphics.pdf -units PixelsPerInch -density "${dpi}" -strip "${temp_dir}"/graphics.png
  optipng "${temp_dir}"/graphics.png 2> /dev/null

  #if [ "$(stat -c '%s' "${temp_dir}"/bitmaps.jpg)" -lt "$(stat -c '%s' "${temp_dir}"/bitmaps.png)" ]; then
  if [ "$(stat -c '%s' "${temp_dir}"/graphics.jpg)" -lt "$(stat -c '%s' "${temp_dir}"/graphics.png)" ]; then
    echo "Using JPEG"
    #convert "${temp_dir}"/bitmaps.jpg -units PixelsPerInch -density "${dpi}" -quality "${quality}" "${temp_dir}"/bitmaps_flatten.pdf
    convert "${temp_dir}"/graphics.jpg -units PixelsPerInch -density "${dpi}" -quality "${quality}" "${temp_dir}"/graphics_flatten.pdf
  else
    echo "Using PNG"
    #convert "${temp_dir}"/bitmaps.png -units PixelsPerInch -density "${dpi}" -quality "${quality}" "${temp_dir}"/bitmaps_flatten.pdf
    convert "${temp_dir}"/graphics.png -units PixelsPerInch -density "${dpi}" -quality "${quality}" "${temp_dir}"/graphics_flatten.pdf
  fi

  #pdftk "${temp_dir}"/bitmaps_flatten.pdf stamp "${temp_dir}"/vectors.pdf output "${temp_dir}"/graphics_flatten.pdf
  pdftk "${temp_dir}"/graphics_flatten.pdf stamp "${temp_dir}"/texts.pdf output "${temp_dir}"/page-"${page}".pdf

  pdf_pages="${pdf_pages} ${temp_dir}/page-${page}.pdf"
done

pdftk ${pdf_pages} cat output ${temp_dir}/merged.pdf
# Use gs to remove duplicate fonts
gs -q -o "${2}" -sDEVICE=pdfwrite ${temp_dir}/merged.pdf

rm -rf -i "${temp_dir}"
