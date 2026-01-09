#!/bin/bash

Workaround due to Recalbox bug on event filter
ACTION="$2"
# we consider only expected event
case "$ACTION" in
  gamelistbrowsing|rundemo|startgameclip) ;;
  *) exit 0 ;;
esac

# param1 -action, param2 gamelistbrowsing, param3 -statefile, param4 /tmp/es_state.inf, param5 -param, param6 /recalbox/share/roms/atari2600/A-Team, The (USA).a26
# $6 is what we want
#/recalbox/share/roms/mame/88games.zip
#/recalbox/share/roms/atari2600/3-D Tic-Tac-Toe (USA).a26
#/recalbox/share_init/roms/apple2gs/Cogito2 (Brutal Deluxe Software).2mg

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
PIXELCADEBASEURL="http://127.0.0.1:7070/"

### System and GameName handling (works even when games are in subfolders) ###
ROMPATH="${6%/}"
# SYSTEM = first path segment after "/roms/" (works even if the ROM is inside a subfolder)
if [[ "$ROMPATH" == *"/roms/"* ]]; then
  AFTER="${ROMPATH#*/roms/}"   # e.g.: pcenginecd/Bonk III/...cue
  SYSTEM="${AFTER%%/*}"        # e.g.: pcenginecd
else
  SYSTEM="$(basename "$(dirname "$ROMPATH")")"
fi
# GAMENAME = file/folder name (last path element)
GAMENAME="$(basename "$ROMPATH")"
# If it's a file, strip the extension (fixes the old ${GAMENAME%.} issue)
if [ -f "$ROMPATH" ]; then
  GAMENAME="${GAMENAME%.*}"
fi
# Optional (often better for CD systems): if it's a .cue, use the game folder name instead
if [[ "$ROMPATH" == *.cue ]]; then
  GAMENAME="$(basename "$(dirname "$ROMPATH")")"
fi
##############################################################################

PREVIOUSGAMESELECTED=$(curl -s "http://127.0.0.1:7070/currentgame") #api call that gets the last game that was selected, returns mame,digdug
PREVIOUSGAMESELECTED=$(echo $PREVIOUSGAMESELECTED | cut -d "," -f 2)  # we just want digdug
CURRENTGAMESELECTED="$GAMENAME"

echo "$PREVIOUSGAMESELECTED" > /etc/init.d/pixelcade/lastgame.txt  #for debugging, we're not actually use this file
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