#!/bin/sh
# **WiP**
# This is perhaps the only **working** (sort of) solution that filters large TeX projects into plain text (main content only) for spell checking.
# Yep, detex / dvi / html methods does not work for pdflatex or complicated projects.
# Tool candidates:
#   sed, awk, etc.: apparently not TeX-aware
#   pandoc: translate TeX into markdown, does not handle macros, does not handle multiple captions within one figure correctly
#   latexpand: handles inputs, includes and comments
#   de-macro: in-line macros (does not work here...)
#   detex/untex: handles almost nothing properly, just removes commands blindly
#   latex/htlatex: does not work with pdflatex

if [ -z "${1}" ]; then
  echo "Usage: ${0} main.tex"
  exit 1
fi

for tool in pandoc latexpand sed sponge; do
  if [ -z `which "${tool}"` ]; then
    echo "Please install '${tool}' and retry."
    exit 2
  fi
done

# Have to use a temporary file, size of variables are quite limited.
TMPFN="/tmp/texcat-$$"
# Replace ".tex" in input filename to ".txt" for output filename. If input filename does not end with ".tex", append ".txt".
OUTFN=`echo "${1}" | sed 's/\.tex$\|$/\.txt/'`

latexpand "${1}" > "${TMPFN}"

# Substitute "def"s.
# Cannot use space as delimiter. At least this does not appear often...
IFS='%'
# A hell of escape characters ... escape sed, then shell (twice for enclosed command!!)
for sedarg in `latexpand "${1}" | grep '\\\\def' | sed 's/^\\\def\\\\\([^{]*\){\(.*\)}.*$/s\/\\\\\1\/\2\/g%/' | sed 's/\\\\\(.\)/\\\\\\\\\1/g'`; do
  # sponge will absorb all output before opening the file and write-back, thus preventing destroying the content
  cat "${TMPFN}" | sed "${sedarg}" | sponge "${TMPFN}"
done

# Remove unnecessary newlines
sed ':a;N;$!{/\n$/!ba};s/[[:blank:]]*\n[[:blank:]]*/ /g;s/$/\n/' "${TMPFN}" | sponge "${TMPFN}"
# Fixed translations
cat "${TMPFN}" | \
    sed 's/\\xspace/ /g' | \
    sponge "${TMPFN}"

# Parse and cleanup
pandoc -f latex "${TMPFN}" --wrap=none -t markdown -o - | \
    sed 's/\[\^[^]]*\]//g' | \
    sed 's/^.*!\[.*\].*$//' | \
    sed 's/\[@[^]]*\]//g' | \
    sed 's/{[^}]*}//g' | \
    sed 's/$\\sim$/~/g' | \
    sed 's/\$[^$]*\$/Eqn\./g' | \
    sed 's/\\\[[^]]*\]/Ref\./g' | \
    sed 's/<span>//g' | \
    sed 's/<\/span>//g' | \
    sed 's/\*//g' | \
    sed 's/ \+/ /g' | \
    sed 's/ \+$//g' | \
    sed 's/ \([\.\,]\)/\1/g' | \
    cat - > ${OUTFN}

# TODO: extract all captions since pandoc does not handle them correctly
# latexpand main.tex | grep '\\caption' -C 2 | sed ':a;N;$!{/\n$/!ba};s/[[:blank:]]*\n[[:blank:]]*/ /g;s/$/\n/' | sed 's/--/\n/g' | sed 's/^.*\\caption//g;s/\\label.*$//g'

#rm "${TMPFN}"
