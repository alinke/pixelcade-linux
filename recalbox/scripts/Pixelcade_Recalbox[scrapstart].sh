#!/bin/bash
#

PIXELCADEBASEURL="http://127.0.0.1:7070/"
PIXELCADETEXT="Scrap%20Running" 

curl "${PIXELCADEBASEURL}text?t=${PIXELCADETEXT}&scroll=false&c=blue&event=FEScroll"