#!/bin/bash
#

#Workaround due to Recalbox bug on event filter
ACTION="$2"
# we consider only expected event
case "$ACTION" in
  configurationchanged) ;;
  *) exit 0 ;;
esac

#Log for events filter debug
#echo "$(date '+%F %T') | $0 | args: $*" >> /recalbox/share/userscripts/Debug_args.log

# workaround to avoid conigurationchanged when reboot/shutdown event
[ -f /tmp/recalbox_rebooting ] && exit 0

PIXELCADEBASEURL="http://127.0.0.1:7070/"
PIXELCADETEXT="Setting" 

#curl "${PIXELCADEBASEURL}text?t=${PIXELCADETEXT}&l=1&c=red&event=FEScroll"
curl "${PIXELCADEBASEURL}text?t=${PIXELCADETEXT}&blink=500&c=red&event=FEScroll"
sleep 3
bash -c "$(cat /recalbox/share/userscripts/lastcurlconsolegame.txt)"