#!/bin/bash

#Workaround due to Recalbox bug on event filter
ACTION="$2"
# we consider only expected event
case "$ACTION" in
  gamelistbrowsing|rundemo|startgameclip) ;;
  *) exit 0 ;;
esac

#Filter if param6 is empty
[ -n "${6:-}" ] || exit 0

#Log for events filter debug
#echo "$(date '+%F %T') | $0 | args: $*" >> /recalbox/share/userscripts/Debug_args.log

# param1 -action, param2 gamelistbrowsing, param3 -statefile, param4 /tmp/es_state.inf, param5 -param, param6 /recalbox/share/roms/atari2600/A-Team, The (USA).a26
# $6 is what we want
#/recalbox/share/roms/mame/88games.zip
#/recalbox/share/roms/atari2600/3-D Tic-Tac-Toe (USA).a26
#/recalbox/share_init/roms/apple2gs/Cogito2 (Brutal Deluxe Software).2mg

rawurlencode() {
  # URL-encode a string using proper UTF-8 percent-encoding.
  # Fixes cases like "Français" / "Español" that were previously encoded as %e7 / %f1 (latin-1)
  # instead of the correct UTF-8 %C3%A7 / %C3%B1.
  #
  # Keeps the same behavior as the original function:
  # - prints the encoded string (so you can do: var=$(rawurlencode "$x"))
  # - also sets REPLY (so you can do: rawurlencode "$x"; var="$REPLY" without a subshell)
  local encoded
  encoded="$(python3 -c 'import os,sys,urllib.parse
b = os.fsencode(sys.argv[1])
try:
    s = b.decode("utf-8")
except UnicodeDecodeError:
    s = b.decode("latin-1")
print(urllib.parse.quote(s, safe="-_.~"))' "$1")"
  REPLY="$encoded"
  printf '%s\n' "$encoded"
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
# SCUMMVM: strip .scummvm even if ROMPATH isn't a regular file
if [[ "${GAMENAME,,}" == *.scummvm ]]; then
  GAMENAME="${GAMENAME%.scummvm}"
fi
# Optional (often better for CD systems): if it's a .cue inside a per-game folder, use the folder name instead
if [[ "${ROMPATH,,}" == *.cue ]]; then
  parent="$(basename "$(dirname "$ROMPATH")")"
  # si le .cue est directement dans /roms/<system>/, ne pas remplacer (sinon on obtient "psx")
  if [ "$parent" != "$SYSTEM" ]; then
    GAMENAME="$parent"
  fi
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
    [ "${2:-}" = "gamelistbrowsing" ] && echo "curl -s \"${PIXELCADEBASEURL}${PIXELCADEURL}\" >/dev/null 2>/dev/null &" > /recalbox/share/userscripts/lastcurlconsolegame.txt

  else
    PIXELCADEURL="text?t=Error%20the%20system%20name%20or%20the%20game%20name%20is%20blank" # use this one if you want a generic system/console marquee if the game marquee doesn't exist, don't forget the %20 for spaces!
    curl -s "$PIXELCADEBASEURL$PIXELCADEURL" >> /dev/null 2>/dev/null &
  fi
fi

