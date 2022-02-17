#!/bin/bash

# let's detect if Pixelcade is USB connected, could be 0 or 1 so we need to check both
if ls /dev/ttyACM0 | grep -q '/dev/ttyACM0'; then
   #echo "Pixelcade LED Marquee Detected on ttyACM0"
   PixelcadePort="/dev/ttyACM0"
else
    if ls /dev/ttyACM1 | grep -q '/dev/ttyACM1'; then
        #echo "Pixelcade LED Marquee Detected on ttyACM1"
        PixelcadePort="/dev/ttyACM1"
    else
       #echo "Sorry, Pixelcade LED Marquee was not detected, pleasse ensure Pixelcade is USB connected to your device and the toggle switch on the Pixelcade board is pointing towards USB, exiting..."
       exit 1
    fi
fi

cd /userdata/system/pixelcade
/userdata/system/pixelcade/jdk/bin/java -jar -Dioio.SerialPorts=$PixelcadePort pixelweb.jar -b -s -e & # -e is the easter egg flag
