#!/bin/bash
# pixelcade end-game script
# right now we are just using this script for visual pinball and dmd switching
# If visual pinball was launched earlier, then pixelweb would have been stopped and tty control given to vpx dmd mode
# So when we have exited any game, we'll check if pixelweb is running and then launch it if not

process_name="pixelweb"

# Check if the process is not running
if ! pgrep -x "$process_name" > /dev/null; then
    server="localhost"
    port=8080
    if ! nc -z "$server" "$port"; then
        curl -s localhost:8080/quit #to be on the safe side as we get into trouble if we start and it's already running
        cd /userdata/system/pixelcade && ./pixelweb -image "system/batocera.png" -startup -logfile pixelweb.log & #for some reason we don't get issues when logging is on
    fi
fi


