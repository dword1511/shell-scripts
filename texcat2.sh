#!/bin/sh

if [ -z "${1}" ]; then
  echo "Usage: ${0} main.tex"
  exit 1
fi

for TOOL in pandoc iconv perl; do
  if [ -z `which "${TOOL}"` ]; then
    echo "Please install \`${TOOL}' and retry."
    exit 2
  fi
done

OUTFN=`echo "${1}" | sed 's/\.tex$\|$/\.txt/'`

pandoc "${1}" -t markdown | iconv -c -f utf-8 -t ascii//TRANSLIT | \
  perl -p0e '
    s/{\#[^\n]*}//smg;        # Remove bookmarks
    s/\[@[^\n\]]*\]//smg;     # Remove refs / cites
    s/\{\}//smg;              # Pandoc artifact
    s/\*\*//smg;              # Remove bold
    s/(\[\[|\]\])//smg;       # Pandoc artifact
    s/\$\\times\$/X/smg;      # Fixed math translit

    # Final cleaning up
    s/\s*([,\.\;\?!])/\1/smg; # Fix spaces before punctuations
    s/\n([^\n])/ \1/smg;      # Remove line-breaks within paragraph
    s/\n /\n\n/smg;           # Fix paragraph breaks
    s/ +/ /smg;               # Remove excessive space
    s/ *(-+|=+)\n/\n/smg;     # Remove title lines
  ' | \
cat > "${OUTFN}"
