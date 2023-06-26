#!/bin/bash

cd $HOME && cd pixelcade

if ls /dev/PIXELCADE0 | grep -q '/dev/PIXELCADE0'; then
   echo "Pixelcade LED Marquee Detected on /dev/PIXELCADE0"
   PixelcadePort="/dev/PIXELCADE0"
else
    if ls /dev/PIXELCADE1 | grep -q '/dev/PIXELCADE1'; then
        echo "Pixelcade LED Marquee Detected on /dev/PIXELCADE1"
        PixelcadePort="/dev/PIXELCADE1"
    else
       echo "Sorry, Pixelcade LED Marquee was not detected.${NEWLINE}Please ensure Pixelcade is USB connected to your Pi and the toggle switch on the Pixelcade board is pointing towards USB, exiting..."
        PixelcadePort="/dev/ttyACM0"
    fi
fi

i=0
# Start Pixelcade for first time (this happens on system boot up)
java -jar -Dioio.SerialPorts=${PixelcadePort} pixelweb.jar -b -s -a &  #-a flag means run pixelcade and then quit
last_pid=$!
while [ -d /proc/$last_pid ] #pixelcade should quit on it's own with -a flag but if not kill it
do
  sleep 1
  ((i++))
  if [[ $i -eq 15 ]]; then
    kill -KILL $last_pid
    break
  fi
done
# Start Pixelcade for the 2nd time which will work
java -jar -Dioio.SerialPorts=${PixelcadePort} pixelweb.jar -b -s -e & #-e is the easter egg flag

emulationstation #auto