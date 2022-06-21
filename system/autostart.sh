#!/bin/bash
# startup script for a dedicated Pi for Pixelcade, systemd calls this via /etc/systemd/system/pixelcade.service
PIXELHOME=$HOME/pixelcade
PATH=$PIXELHOME/jdk/bin:$PATH

cd $PIXELHOME && java -jar pixelweb.jar -b &
sleep 10 && curl localhost:8080/arcade/stream/mame/pixelcade
#sleep 10 && cd /home/pi/pixelcade/system && ./pixelcade-startup.sh
