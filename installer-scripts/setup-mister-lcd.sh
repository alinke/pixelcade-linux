#!/bin/bash
stretch_os=false
buster_os=false
ubuntu_os=false
retropie=false
pizero=false
pi4=false
java_installed=false
install_succesful=false
auto_update=false
attractmode=false
black=`tput setaf 0`
red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
blue=`tput setaf 4`
magenta=`tput setaf 5`
white=`tput setaf 7`
reset=`tput sgr0`
version=5  #increment this as the script is updated
#echo "${red}red text ${green}green text${reset}"

cat << "EOF"
       _          _               _
 _ __ (_)_  _____| | ___ __ _  __| | ___
| '_ \| \ \/ / _ \ |/ __/ _` |/ _` |/ _ \
| |_) | |>  <  __/ | (_| (_| | (_| |  __/
| .__/|_/_/\_\___|_|\___\__,_|\__,_|\___|
|_|
EOF

echo "${magenta}       Pixelcade LCD for MiSTer : Installer Version $version    ${white}"
echo ""


#do we have an upgraded MiSTer?
if [ -f "/media/fat/linux/_user-startup.sh" ] || [ -f "/media/fat/linux/user-startup.sh" ]; then
      echo "${yellow}Pixelcade is compatible with your version of MiSTer, Good${white}"
else
      echo "${yellow}Pixelcade is not compatible with this version of MiSTer, please upgrade to the latest MiSTer first${white}"
      exit 1
fi

#is Pixelcade already installed?
if [[ -d "/media/fat/pixelcade" ]]; then
            while true; do
                read -p "${magenta}You already have MiSTer Pixelcade installed. If you continue, this installer will remove Pixelcade and re-install, do you want to continue? (y/n) ${white}" yn
                case $yn in
                    [Yy]* ) cd /media/fat && sudo rm -r pixelcade; break;;
                    [Nn]* ) exit; break;;
                    * ) echo "Please answer y or n";;
                esac
      done
fi

# TO DO ask user if they want to install on SD card or USB
if [[ -d "/media/fat" ]]; then
  echo "${yellow}/media/fat exists, good${white}"
else
   echo "${yellow}/media/fat does not exist, sorry setup cannot continue, please add an SD card or external storage..."
   exit 1
fi

echo "${yellow}Downloading Pixelcade MiSTer from GitHub Repo https://github.com/alinke/pixelcade-mister-lcd/tree/master...${white}"
mkdir /media/fat/pixelcade
cd /media/fat/
curl -k -LO https://github.com/alinke/pixelcade-mister-lcd/archive/refs/heads/main.zip
echo "${yellow}Unzipping...${white}"
unzip -o /media/fat/main.zip
echo "${yellow}Cleaning Up...${white}"
rm /media/fat/main.zip
cp -R /media/fat/pixelcade-mister-lcd-main/pixelcade /media/fat/
rm -r /media/fat/pixelcade-mister-lcd-main
echo "${yellow}Adding Pixelcade MiSTer to Startup...${white}"
chmod +x /media/fat/pixelcade/runpixelcade.sh

if [[ -f "/media/fat/linux/_user-startup.sh" ]]; then
  echo "${yellow}Enabling user-startup.sh so Pixelcade can start automatically when MiSTer boots up..."
  mv /media/fat/linux/_user-startup.sh /media/fat/linux/user-startup.sh
else
  echo "${yellow}user-startup.sh was already enabled so Pixelcade can start automatically when MiSTer boots up, good..."
fi

cd /media/fat/linux

grep -qxF 'cd /media/fat/pixelcade && ./runpixelcade.sh' user-startup.sh || echo 'cd /media/fat/pixelcade && ./runpixelcade.sh' >> user-startup.sh
chmod +x /media/fat/linux/user-startup.sh

echo "${yellow}Modifying MiSTer.ini to turn on current game logging which is needed for Pixelcade...${white}"

cd /media/fat
if [[ -f "/media/fat/MiSTer.ini" ]]; then
      echo "${yellow}Updating your existing MiSTer.ini${white}"
      sed -i '/^\[MiSTer\]/a\log_file_entry=1' MiSTer.ini
elif [[ -f "/media/fat/MiSTer_example.ini" ]]; then
      echo "${yellow}Adding MiSTer.ini${white}"
      mv /media/fat/MiSTer_example.ini /media/fat/MiSTer.ini
      sed -i '/^\[MiSTer\]/a\log_file_entry=1' MiSTer.ini
      exit 1
else
      #then worst case we need to copy over a mister.ini
      echo "${yellow}Copying vanilla MiSTer.ini${white}"
      cp /media/fat/pixelcade/MiSTer.ini /media/fat/MiSTer.ini
fi

chmod +x /media/fat/pixelcade/runpixelcade.sh

cd /media/fat/pixelcade && ./runpixelcade.sh

echo "${yellow}Installation Complete, Please Reboot your MiSTer...${white}"
while true; do
    read -p "${magenta}Reboot Now? (y/n)${white}" yn
    case $yn in
        [Yy]* ) sudo reboot; break;;
        [Nn]* ) echo "${yellow}Please reboot when you get a chance" && exit;;
        * ) echo "Please answer yes or no.";;
    esac
done
