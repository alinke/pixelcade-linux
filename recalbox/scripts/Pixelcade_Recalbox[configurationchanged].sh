#!/bin/bash
#
# workaround to avoid conigurationchanged when reboot/shutdown event
[ -f /tmp/recalbox_rebooting ] && exit 0

PIXELCADEBASEURL="http://127.0.0.1:7070/"
PIXELCADETEXT="Configuration%20Change" 

curl "${PIXELCADEBASEURL}text?t=${PIXELCADETEXT}&l=1&c=red&event=FEScroll"