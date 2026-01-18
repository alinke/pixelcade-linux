#!/bin/bash

#Workaround due to Recalbox bug on event filter
ACTION="$2"
# we consider only expected event
case "$ACTION" in
  stop|shutdown|reboot) ;;
  *) exit 0 ;;
esac

#Log for events filter debug
#echo "$(date '+%F %T') | $0 | args: $*" >> /recalbox/share/userscripts/Debug_args.log

PIXELCADEBASEURL="http://127.0.0.1:7070/"
PIXELCADEURL="quit" 
curl -s "$PIXELCADEBASEURL$PIXELCADEURL&event=FEQuit" >> /dev/null 2>/dev/null &
