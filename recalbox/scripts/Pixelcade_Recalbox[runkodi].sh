#!/bin/bash
#

#Workaround due to Recalbox bug on event filter
ACTION="$2"
# we consider only expected event
case "$ACTION" in
  runkodi) ;;
  *) exit 0 ;;
esac

# Kodi is launched by EmulationStation with the runkodi event.
# We force Pixelcade to display Kodi like a normal console/system.

# BASE URL for RESTful calls to Pixelcade
PIXELCADEBASEURL="http://127.0.0.1:7070/"
SYSTEM="kodi"

if [ "$SYSTEM" != "" ]; then
    PIXELCADEURL="console/stream/${SYSTEM}/?event=FEScroll"
    curl -s "${PIXELCADEBASEURL}${PIXELCADEURL}" >> /dev/null 2>/dev/null &
    # echo "curl -s \"${PIXELCADEBASEURL}${PIXELCADEURL}\" >/dev/null 2>/dev/null &" > /recalbox/share/userscripts/lastcurlconsolegame.txt
fi

(sleep 2; bash "/recalbox/share/userscripts/Pixelcade_kodimonitor/Pixelcade_kodimonitor.sh") &
#(sleep 2; bash "/recalbox/share/userscripts/Pixelcade_kodimonitor/kodi_rpc_perf_autorun_v2.sh") &