#!/bin/bash
#

#Log for events filter debug
#echo "$(date '+%F %T') | $0 | args: $*" >> /recalbox/share/userscripts/Debug_args.log

PIXELCADEBASEURL="http://127.0.0.1:7070/"
PIXELCADETEXT="Scrap%20Done" 

curl "${PIXELCADEBASEURL}text?t=${PIXELCADETEXT}&size={24}&blink={0}&c=green&event=FEScroll"
sleep 3
bash -c "$(cat /recalbox/share/userscripts/lastcurlconsolegame.txt)"
