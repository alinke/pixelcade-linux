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
PIXELCADETEXT="Reboot%20Recalbox"

curl "${PIXELCADEBASEURL}text?t=${PIXELCADETEXT}&l=1&c=yellow&event=FEQuit"

curl ${PIXELCADEBASEURL}minilcd/clear
curl "${PIXELCADEBASEURL}minilcd/centertext?text=REBOOTING&row=1"
curl "${PIXELCADEBASEURL}max7219/matrix/text?text=REBOOT&brightness=10&font=0&loops=3&speed=200"
curl ${PIXELCADEBASEURL}max7219/7seg/clear
curl ${PIXELCADEBASEURL}ledstrip/clear