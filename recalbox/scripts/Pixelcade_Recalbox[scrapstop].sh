#!/bin/bash
#

PIXELCADEBASEURL="http://127.0.0.1:7070/"
PIXELCADETEXT="Scrap%20Done" 

curl "${PIXELCADEBASEURL}text?t=${PIXELCADETEXT}&l=1&c=green&event=FEScroll"
