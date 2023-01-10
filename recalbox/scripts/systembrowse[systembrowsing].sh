#!/bin/bash

#
# $6 = The system/console identifier from ES (ex. mame, nes, snes...)

# BASE URL for RESTful calls to Pixelcade
PIXELCADEBASEURL="http://127.0.0.1:7070/"
SYSTEM=$6

if [ "$SYSTEM" != "" ]; then
    PIXELCADEURL="console/stream/"$SYSTEM"/?event=FEScroll"
    curl -s "$PIXELCADEBASEURL$PIXELCADEURL" >> /dev/null 2>/dev/null &
fi
