#!/bin/sh

for zone in /sys/class/thermal/thermal_zone*
do
  NUM=`basename $zone`
  NUM=${NUM#thermal_zone}
  TYPE=`cat $zone/type`
  TEMP=`cat $zone/temp`
  TRIP=""
  for trip in $zone/trip_point_*_temp
  do
    TNUM=`basename $trip | cut -d '_' -f 3`
    TTYPE=`cat $zone/trip_point_${TNUM}_type`
    TTEMP=`cat $trip`
    TTEMP=`awk "BEGIN {printf(\"%.1f°C\", $TTEMP / 1000)}"`
    TRIP="$TRIP, $TTYPE = $TTEMP"
  done
  awk "BEGIN {printf(\"zone%d: %5.1f°C ($TYPE$TRIP)\n\", $NUM, $TEMP / 1000)}"
done
