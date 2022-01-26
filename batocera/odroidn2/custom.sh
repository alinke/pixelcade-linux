#!/bin/bash
cd ~/pixelcade
i=0
# Start Pixelcade for first time (this happens on system boot up)
/userdata/system/jdk/bin/java -jar pixelweb.jar -b -a &  #-a flag means run pixelcade and then quit
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
/userdata/system/jdk/bin/java -jar pixelweb.jar -b -e & # -e is the easter egg flag
