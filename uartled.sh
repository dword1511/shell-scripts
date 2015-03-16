#!/bin/sh

# Usage: $0 [device] [ton_ms] [toff_ms]

BAUD=9600

stty -F $1 9600

# Need long strings to obtain good voltage
# This timing is *about* right
awk "
BEGIN {
  ton  = $2 * $BAUD / 1000 / 40
  toff = $3 * $BAUD / 1000 / 40

  while (1) {
    i = ton
    while (i > 0) {
      print \"\xff\xff\xff\xff\"
      i --
    }
    i = toff
    while (i > 0) {
      print \"\x00\x00\x00\x00\"
      i --
    }
  }

}
" > $1
