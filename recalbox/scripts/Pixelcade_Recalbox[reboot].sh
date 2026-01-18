#!/bin/bash
#

#Workaround due to Recalbox bug on event filter
ACTION="$2"
# we consider only expected event
case "$ACTION" in
  reboot) ;;
  *) exit 0 ;;
esac

#Log for events filter debug
#echo "$(date '+%F %T') | $0 | args: $*" >> /recalbox/share/userscripts/Debug_args.log

PIXELCADEBASEURL="http://127.0.0.1:7070/"
PIXELCADETEXT="Reebot%20Recalbox" 

curl "${PIXELCADEBASEURL}text?t=${PIXELCADETEXT}&l=1&c=yellow&event=FEQuit"