#!/bin/bash
#

#Workaround due to Recalbox bug on event filter
ACTION="$2"
# we consider only expected event
case "$ACTION" in
  shutdown) ;;
  *) exit 0 ;;
esac

#Log for events filter debug
#echo "$(date '+%F %T') | $0 | args: $*" >> /recalbox/share/userscripts/Debug_args.log

PIXELCADEBASEURL="http://127.0.0.1:7070/"
PIXELCADETEXT="Shutdown%20Recalbox" 

curl ${PIXELCADEBASEURL}minilcd/clear
curl "${PIXELCADEBASEURL}minilcd/centertext?text=Shutdown%20Recalbox&row=1"
curl "${PIXELCADEBASEURL}max7219/matrix/text?text=Shutdown&brightness=10&font=0&loops=3&speed=200"
curl ${PIXELCADEBASEURL}max7219/7seg/clear
curl ${PIXELCADEBASEURL}ledstrip/clear

curl "${PIXELCADEBASEURL}text?t=${PIXELCADETEXT}&l=1&c=red&event=FEQuit"