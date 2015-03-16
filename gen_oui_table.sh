#!/bin/sh

# This script generates oui_table.h from http://standards.ieee.org/develop/regauth/oui/oui.txt

URL='http://standards.ieee.org/develop/regauth/oui/oui.txt'
TXT='oui.txt'
DAT='oui.dat'
OUT='oui_table.h'

wget -c $URL -O - | \
tee $TXT | \
grep '^\ \ [A-F0-9]\{2\}-[A-F0-9]\{2\}-[A-F0-9]\{2\}' | \
sed -r -e 's/\ \ (.*)\ \ \ \(hex\)\t\t/\1\ /g' > $DAT

cat > $OUT << EOF
#ifndef __OUI_H__
#define __OUI_H__

#ifndef OUI_VENDOR_STR_SIZE
#define OUI_VENDOR_STR_SIZE 128
#endif /* OUI_VENDOR_STR_SIZE */

#include <stdint.h>

struct oui_entry {
  /* OUI Prefix, bytes 1-3 in MAC Addresses */
  uint8_t mac1;
  uint8_t mac2;
  uint8_t mac3;

  /* Vendor name */
  char vendor[OUI_VENDOR_STR_SIZE];
} oui_table[] = {
EOF

# Recently they have gone from LF to CRLF, which breaks the script totally...

cat $DAT | \
sed -e 's/\"/\\\"/g' | \
sed -e 's/\r//g' | \
sed -r -e 's/^([A-F0-9]{2})-([A-F0-9]{2})-([A-F0-9]{2})\ (.*)$/\ \ \{0x\1, 0x\2, 0x\3, \"\4\"\},/g' >> $OUT

cat >> $OUT << EOF
};

#define OUI_SIZE (sizeof(oui_table) / sizeof(oui_table[0]))

#endif /* __OUI_H__ */

EOF
