#!/bin/bash
#

# workaround to avoid sleep when startgameclip event
grep -Eq '^emulationstation\.screensaver\.type=(dim|black)$' /recalbox/share/system/recalbox.conf || exit 0

#Workaround due to Recalbox bug on event filter
ACTION="$2"
# we consider only expected event
case "$ACTION" in
  sleep) ;;
  *) exit 0 ;;
esac

#Log for events filter debug
#echo "$(date '+%F %T') | $0 | args: $*" >> /recalbox/share/userscripts/Debug_args.log

PIXELCADEBASEURL="http://127.0.0.1:7070/"

#curl "{$PIXELCADEBASEURL}clock?nointerrupt&clockType=pacman&12h=false&showSeconds=true&event=FEScreenSaver"
curl "{$PIXELCADEBASEURL}attract?nointerrupt&event=FEScreenSaver"
