#!/bin/sh
programma='bin/vlpesarobot'

if ps ax | grep -v grep | grep $programma > /dev/null
then
  echo "@VLpesaro_bot e' attivo $(date '+%F %T %Z')"
else
  cd /home/pi/ruby/VLpesaro-bot && ruby bin/vlpesarobot &
  echo "@VLpesaro_bot era spento ed e' stato riattivato $(date '+%F %T %Z')"
fi
exit
