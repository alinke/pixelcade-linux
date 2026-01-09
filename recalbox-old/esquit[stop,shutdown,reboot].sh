#!/bin/bash

#
# $1 = quit mode, "reboot" or "shutdown"
#
PIXELCADEBASEURL="http://127.0.0.1:7070/"
PIXELCADEURL="quit" 
curl -s "$PIXELCADEBASEURL$PIXELCADEURL" >> /dev/null 2>/dev/null &
