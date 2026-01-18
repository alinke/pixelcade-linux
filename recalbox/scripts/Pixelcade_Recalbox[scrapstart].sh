#!/bin/bash
#

#Log for events filter debug
#echo "$(date '+%F %T') | $0 | args: $*" >> /recalbox/share/userscripts/Debug_args.log

###blink function is limited at 9 characters max

PIXELCADEBASEURL="http://127.0.0.1:7070/"
PIXELCADETEXT="Scraping" 

curl "${PIXELCADEBASEURL}text?t=${PIXELCADETEXT}&blink=500&c=blue&event=FEScroll"