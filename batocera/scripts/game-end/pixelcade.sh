#!/bin/bash
# pixelcade end-game script
# right now we are just using this script for visual pinball and dmd switching
# If visual pinball was launched earlier, then pixelweb would have been stopped and tty control given to vpx dmd mode
# So when we have exited any game, we'll check if pixelweb is running and then launch it if not

process_name="pixelweb"
if ! pgrep -x "$process_name" > /dev/null; then
    cd /userdata/system/pixelcade && ./pixelweb -image "system/batocera.png" &
fi



