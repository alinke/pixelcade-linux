#!/bin/bash

# $6 = /recalbox/share/roms/atari2600/Activision Decathlon, The (USA).a26

#*************************************************
# These are parameters you can customize
INSTALLPATH=/etc/init.d/  # /userdata/system/
DISPLAYHIGHSCORES=yes
NUMBERHIGHSCORES=3  #number of high scores to scroll, choose 1 for example to only show the top score
CYCLEMODE=yes #cycle mode means we continually cycle between the game marquee and scrolling high scores. If set to no, then high scores will scroll only once on game launch and then display the game marquee
NUMBER_MARQUEE_LOOPS=10 #for cycle mode, the number of seconds a PNG will stay before going back to text, a GIF will always loop once independent of this param
HI2TXT_JAR=${INSTALLPATH}pixelcade/hi2txt/hi2txt.jar #hi2txt.jar AND hi2txt.zip must be in this folder, the Pixelcade installer puts them here by default
HI2TXT_DATA=${INSTALLPATH}pixelcade/hi2txt/hi2txt.zip
#*************************************************

PIXELCADEBASEURL="http://127.0.0.1:7070/"  # BASE URL for RESTful calls to Pixelcade, note localhost won't work if the user is not ethernet or wifi connected
#SYSTEM=$(basename $(dirname "$1")) #get just the console / system name like mame, nes, etc.
# GET SYSTEM FROM /recalbox/share/roms/atari2600/3-D Tic-Tac-Toe (USA).a26
PATHONLY=$(dirname "$6")                    # /recalbox/share/roms/atari2600
SYSTEM=$(basename "${PATHONLY}")            # atari2600

GAMENAME=$(basename "$6") #get rid of the path, just want the game name only
GAMENAME=$(echo "${GAMENAME%.*}") #remove the extension
GAMETITLE="$GAMENAME"  #then game title is not there so we'll use the rom name

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

nohighscore() {
  #echo "No .hi file exists for $1"
  PIXELCADEURL="text?t=Now%20Playing%20"$URLENCODED_TITLE"&l=1&game="$URLENCODED_GAMENAME"&system="$SYSTEM"&event=GameStart"
	curl -s "$PIXELCADEBASEURL$PIXELCADEURL" >> /dev/null 2>/dev/null &
  #now let's display the game marquee
  sleep 1 #TO DO for some reason, doesn't always work without this, in theory it should not be needed
  PIXELCADEURL="arcade/stream/"$SYSTEM"/"$URLENCODED_GAMENAME"?l=99999&event=GameStart" # use this one if you want a generic system/console marquee if the game marquee doesn't exist
  #PIXELCADEURL="arcade/stream/"$SYSTEM"/"$URLENCODED_FILENAME"?t="$URLENCODED_TITLE"" # use this one if you want scrolling text if the game marquee doesn't exist
  curl -s "$PIXELCADEBASEURL$PIXELCADEURL" >> /dev/null 2>/dev/null &
}

havehighscore() {
  HIGHSCORE=$(echo $HIGHSCORE | sed 's/RANK|SCORE|NAME //') #remove RANK|SCORE|NAME from the string
  HIGHSCORE=$(echo $HIGHSCORE | sed 's/RANK|SCORE //') #some games only have RANK and SCORE, no NAMES
  HIGHSCORE=$(echo $HIGHSCORE | sed 's/# TOP SCORES //') #1944 has this extra text
  HIGHSCORE=$(echo $HIGHSCORE | tr ' ' '%') #add the % deliminator separating the high scores
  str=$HIGHSCORE
  HIGHSCORECOMBINED=""

  IFS='%'     # % is the delimiter for each high score
  read -ra ADDR <<< "$str"
  for i in "${ADDR[@]}"; do
      rank=$(echo $i | cut -d "|" -f 1)  # the output is this : 1|19130|DAA
      score=$(echo $i | cut -d "|" -f 2)
      score=$(echo $score | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta') #add thousands separator
      name=$(echo $i | cut -d "|" -f 3)
      HIGHSCORESINGLE="#${rank} ${score} ${name}"
      HIGHSCORECOMBINED="$HIGHSCORECOMBINED $HIGHSCORESINGLE"
  done
  #echo $HIGHSCORECOMBINED
  URLENCODED_TITLE=$(rawurlencode "$HIGHSCORECOMBINED")
  if [[ $CYCLEMODE = "yes" ]]; then
    PIXELCADEURL="arcade/stream/"$SYSTEM"/"$URLENCODED_GAMENAME"?t=$URLENCODED_TITLE&l=${NUMBER_MARQUEE_LOOPS}&event=GameStart&cycle"
		curl -s "$PIXELCADEBASEURL$PIXELCADEURL" >> /dev/null 2>/dev/null &
  else
		PIXELCADEURL="text?t="$URLENCODED_TITLE"&l=1&game="$URLENCODED_GAMENAME"&system="$SYSTEM"&event=GameStart"
		curl -s "$PIXELCADEBASEURL$PIXELCADEURL" >> /dev/null 2>/dev/null &
    #now let's display the game marquee
    sleep 1 #TO DO for some reason, doesn't always work without this, in theory it should not be needed
    PIXELCADEURL="arcade/stream/"$SYSTEM"/"$URLENCODED_GAMENAME"?l=99999&event=GameStart" # use this one if you want a generic system/console marquee if the game marquee doesn't exist
    #PIXELCADEURL="arcade/stream/"$SYSTEM"/"$URLENCODED_FILENAME"?t="$URLENCODED_TITLE"" # use this one if you want scrolling text if the game marquee doesn't exist
    curl -s "$PIXELCADEBASEURL$PIXELCADEURL" >> /dev/null 2>/dev/null &
  fi
}

# Main Code Start Here
	if [ "$SYSTEM" != "" ] && [ "$GAMENAME" != "" ]; then
  	  #clear the Pixelcade Queue, see http://pixelcade.org/api for info on the Queue feature
  		PIXELCADEURL="console/stream/black"
  		curl -s "$PIXELCADEBASEURL$PIXELCADEURL" >> /dev/null 2>/dev/null & #this was causing an issue on new pixelweb
			sleep 1 #TO DO for some reason, doesn't always work without this, in theory it should not be needed
			URLENCODED_GAMENAME=$(rawurlencode "$GAMENAME")
      URLENCODED_TITLE=$(rawurlencode "$GAMETITLE")
      #let's make a call here if this game has high scores
      #TO DO let's make sure hi2txt is installed too

      if [ -f $HI2TXT_JAR ] && [ -f $HI2TXT_DATA ] && [ $DISPLAYHIGHSCORES == "yes" ]; then

      #let's locate the .hi file which is tricky as we don't know which folder it's in so we'll use this logic
      #if rom path is mame, then we'll get it from /storage/roms/mame/hi
      #if rom path is arcade,then we'll get it from /storage/roms/arcade/mame2003-plus/hi
            #echo "system is "$SYSTEM
            if [ $SYSTEM == "mame" ]; then
                  HIPATH=/recalbox/share/saves/mame/mame2003-plus/hi
            elif [ $SYSTEM == "arcade" ]; then
                  HIPATH=/recalbox/share/saves/mame/mame/hi
            else
                  HIPATH=/recalbox/share/saves/mame/mame2003-plus/hi
            fi

            if [[ -f "${HIPATH}$GAMENAME.hi" ]]; then
                HIGHSCORE=$(${INSTALLPATH}pixelcade/jdk/bin/java -jar ${HI2TXT_JAR} -r ${HIPATH}$GAMENAME -max-lines $NUMBERHIGHSCORES -max-columns 3 -keep-field "SCORE" -keep-field "NAME" -keep-field "RANK")
                if [ "$HIGHSCORE" == "" ]; then
                    #echo "[ERROR] This game does not have high scores or does not support high scores"
                    nohighscore
                else
                    havehighscore
                fi
            else
              nohighscore
            fi
      else #hi2txt is not installed
        #echo "[ERROR] Please install these two hi2txt files here: $HI2TXT_JAR and $HI2TXT_DATA or you have turned off high scores"
        nohighscore
      fi
	else
		PIXELCADEURL="text?t=Error%20the%20system%20name%20or%20the%20game%20name%20is%20blank" # use this one if you want a generic system/console marquee if the game marquee doesn't exist, don't forget the %20 for spaces!
		curl -s "$PIXELCADEBASEURL$PIXELCADEURL" >> /dev/null 2>/dev/null &
	fi
