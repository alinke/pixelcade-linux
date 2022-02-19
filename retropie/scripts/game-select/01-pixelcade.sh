#!/bin/bash

#
# $1 = The system/console identifier from ES (ex. mame, nes, snes...)
# $2 = The full path of the rom file (ex. /storage/roms/snes/ACME Animation Factory (USA).zip)
# $3 = The name of the game associated to the rom file in ES (ex. 688 Attack Sub [MEGADRIVE])
# $4 = Reason for the event to be fired from ES
#		input         - game selected via the UI
#		randomvideo   - video being played
#		requestedgame - game selected on startup or reload * game-select only
#		slideshow     - slideshow
#
#arcade // /home/pi/RetroPie/roms/arcade/aligator.zip // Alligator Hunt // input


#note for collections, it seems $3 contains [system] which we can use for the collections

rawurlencode() {  #this is needed for rom names with spaces
  local string="${1}"
  local strlen=${#string}
  local encoded=""
  local pos c o

  for (( pos=0 ; pos<strlen ; pos++ )); do
     c=${string:$pos:1}
     case "$c" in
        [-_.~a-zA-Z0-9] ) o="${c}" ;;
        * )               printf -v o '%%%02x' "'$c"
     esac
     encoded+="${o}"
  done
  echo "${encoded}"    # You can either set a return variable (FASTER)
  REPLY="${encoded}"   #+or echo the result (EASIER)... or both... :p
}

# BASE URL for RESTful calls to Pixelcade
PIXELCADEBASEURL="http://127.0.0.1:8080/"
#SYSTEM=$1
SYSTEM=$(basename $(dirname "$2")) #note we could use $1 here but $1 will breakdown if this is a collection so it's better to get the system from the actual rom path
GAMENAME=$(basename "$2") #get rid of the path, just want the game name only
GAMENAME=$(echo "${GAMENAME%.*}") #remove the extension
PREVIOUSGAMESELECTED=$(curl "http://127.0.0.1:8080/currentgame") #api call that gets the last game that was selected, returns mame,digdug
PREVIOUSGAMESELECTED=$(echo $PREVIOUSGAMESELECTED | cut -d "," -f 2)  # we just want digdug
CURRENTGAMESELECTED="$GAMENAME"

echo "$PREVIOUSGAMESELECTED" > /home/pi/pixelcade/lastgame.txt  #for debugging, we're not actually use this file

#let's skip the call if the current game is the same as the last game selected to avoid a marquee flicker
if [ "$CURRENTGAMESELECTED" != "$PREVIOUSGAMESELECTED" ]; then
  if [ "$SYSTEM" != "" ] && [ "$GAMENAME" != "" ]; then
    URLENCODED_GAMENAME=$(rawurlencode "$GAMENAME") #fyi, if we don't urlencode, games with spaces won't work
    URLENCODED_TITLE=$(rawurlencode "$3")
    PIXELCADEURL="arcade/stream/"$SYSTEM"/"$URLENCODED_GAMENAME"?event=FEScroll" # use this one if you want a generic system/console marquee if the game marquee doesn't exist
    #PIXELCADEURL="arcade/stream/"$SYSTEM"/"$URLENCODED_FILENAME"?t="$URLENCODED_TITLE"" # use this one if you want scrolling text if the game marquee doesn't exist
    curl -s "$PIXELCADEBASEURL$PIXELCADEURL" >> /dev/null 2>/dev/null &
  else
    PIXELCADEURL="text?t=Error%20the%20system%20name%20or%20the%20game%20name%20is%20blank" # use this one if you want a generic system/console marquee if the game marquee doesn't exist, don't forget the %20 for spaces!
    curl -s "$PIXELCADEBASEURL$PIXELCADEURL" >> /dev/null 2>/dev/null &
  fi
fi
