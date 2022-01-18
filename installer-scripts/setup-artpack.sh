#!/bin/bash

java_installed=false
install_succesful=false
lcd_marquee=false
black=`tput setaf 0`
red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
blue=`tput setaf 4`
magenta=`tput setaf 5`
white=`tput setaf 7`
reset=`tput sgr0`

cat << "EOF"
       _          _               _
 _ __ (_)_  _____| | ___ __ _  __| | ___
| '_ \| \ \/ / _ \ |/ __/ _` |/ _` |/ _ \
| |_) | |>  <  __/ | (_| (_| | (_| |  __/
| .__/|_/_/\_\___|_|\___\__,_|\__,_|\___|
|_|
EOF

echo "${magenta}  Pixelcade Art Pack 1 Installer   ${white}"
echo ""
echo "${red}IMPORTANT:${white} This script will work on a Pi 2, Pi Zero W, Pi 3B, Pi 3B+, Pi 4, and EmuELEC"
echo "Now connect Pixelcade to a free USB port on your Pi or EmuElEC device"
echo "Ensure the toggle switch on the Pixelcade board is pointing towards USB and not BT"

# let's check if we have EmuELEC
if lsb_release -a | grep -q 'EmuELEC'; then
        echo "EmuELEC Detected"

        if [ ! -d "/storage/roms/pixelcade" ]
        then
            echo "Pixelcade is not installed"
            echo "Please install Pixelcade from http://pixelcade.org first and then re-run this installer"
            exit 1
        fi

        INSTALLPATH="/storage/roms/"

        echo "${green}Starting Download...${green}"
        cd $HOME
        curl -LO pixelcade.org/pi/222333.jar
        ${INSTALLPATH}bios/jdk/bin/java -jar 222333.jar

        if [[ -d "${INSTALLPATH}pixelcade-artpack-master" ]]; then
          echo "${yellow}Cleaning Up...${white}"
           rm -r ${INSTALLPATH}pixelcade-artpack-master
        fi

        if [[ -f "${INSTALLPATH}pixelcade-artpack-master.zip" ]]; then
           rm ${INSTALLPATH}pixelcade-artpack-master.zip
        fi

        if [[ -f "${INSTALLPATH}591333.jar" ]]; then
           rm ${INSTALLPATH}591333.jar
        fi

        if [[ -f "${INSTALLPATH}222333.jar" ]]; then
           rm ${INSTALLPATH}222333.jar
        fi

        if [[ -f "${INSTALLPATH}setup-artpack.sh" ]]; then
           rm ${INSTALLPATH}setup-artpack.sh
        fi

elif batocera-info | grep -q 'System'; then
        echo "Batocera Detected"
        INSTALLPATH="/userdata/system/"

        if [ ! -d "${INSTALLPATH}pixelcade" ]
        then
            echo "Pixelcade is not installed"
            echo "Please install Pixelcade from http://pixelcade.org first and then re-run this installer"
            exit 1
        fi

        echo "${green}Starting Download...${green}"
        cd $INSTALLPATH
        curl -LO pixelcade.org/pi/222444.jar
        ${INSTALLPATH}jdk/bin/java -jar 222444.jar

        if [[ -d "${INSTALLPATH}pixelcade-artpack-master" ]]; then
          echo "${yellow}Cleaning Up...${white}"
           rm -r ${INSTALLPATH}pixelcade-artpack-master
        fi

        if [[ -f "${INSTALLPATH}pixelcade-artpack-master.zip" ]]; then
           rm ${INSTALLPATH}pixelcade-artpack-master.zip
        fi

        if [[ -f "${INSTALLPATH}591333.jar" ]]; then
           rm ${INSTALLPATH}591333.jar
        fi

        if [[ -f "${INSTALLPATH}222444.jar" ]]; then
           rm ${INSTALLPATH}222444.jar
        fi

        if [[ -f "${INSTALLPATH}setup-artpack.sh" ]]; then
           rm ${INSTALLPATH}setup-artpack.sh
        fi
else
   echo "Proceeding with Pi Installation"
   HOME="/home/pi/"

   if [ ! -d "/home/pi/pixelcade" ]
   then
       echo "${yellow}Pixelcade is not installed${white}"
       echo "${yellow}Please install Pixelcade from http://pixelcade.org first and then re-run this installer${white}"
       exit 1
   fi

   if type -p java ; then
     echo "${yellow}Java detected..."
     java_installed=true
   elif [[ -n "$JAVA_HOME" ]] && [[ -x "$JAVA_HOME/bin/java" ]];  then
     echo "${yellow}Java detected..."
     java_installed=true
   else
      echo "${yellow}Java is not installed, please install Pixelcade for Pi first at http://pixelcade.org...${white}"
      java_installed=false
      exit 1
   fi

   # we have all the pre-requisites so let's continue
   sudo apt-get -y update

   echo "${yellow}Installing Git...${white}"
   sudo apt -y install git

   # let's delete the art pack if already there and download new so we have the latest and greatest
   if [[ -d "/home/pi/pixelcade-artpack" ]]; then
     echo "${yellow}Removing Existing Art Pack...${white}"
     cd /home/pi/ && sudo rm -r pixelcade-artpack
   fi

   echo "${green}Starting Download...${green}"
   cd $HOME
   curl -LO pixelcade.org/pi/222111.jar
   java -jar 222111.jar

   # now let's cleanup
   if [[ -d "${HOME}pixelcade-artpack" ]]; then
     echo "${yellow}Cleaning Up...${white}"
     sudo rm -r ${HOME}pixelcade-artpack
   fi

   if [[ -f "${HOME}591333.jar" ]]; then
     sudo rm ${HOME}591333.jar
   fi

   if [[ -f "${HOME}222111.jar" ]]; then
     sudo rm ${HOME}222111.jar
   fi

   if [[ -f "${HOME}setup-artpack.sh" ]]; then
     sudo rm ${HOME}setup-artpack.sh
   fi

   if [[ -f "${HOME}esmod-pi4.deb" ]]; then
     sudo rm ${HOME}esmod-pi4.deb
   fi

   if [[ -f "${HOME}setup.sh" ]]; then
     sudo rm ${HOME}setup.sh
   fi

   if [[ -f "${HOME}pixelweb.jar" ]]; then
     sudo rm ${HOME}pixelweb.jar
   fi
fi
