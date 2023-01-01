#!/bin/bash
java_installed=false
install_succesful=false
auto_update=false
pizero=false
pi4=false
pi3=false
aarch64=false
aarch32=false
x86_32=false
x86_64=false
PixelcadePort=false
odroidn2=false
PIXELCADE_PRESENT=false #did we do an upgrade and pixelcade was already there
upgrade_artwork=false
upgrade_software=false
version=8  #increment this as the script is updated

#1) download the appropriate pixelweb binary
#2) download the ES scripts into the right folders
#3) run pixelweb with -install-artwork
#4) install init/startup scripts
#5) start pixelweb

#master script, detect the front end?


cat << "EOF"
       _          _               _
 _ __ (_)_  _____| | ___ __ _  __| | ___
| '_ \| \ \/ / _ \ |/ __/ _` |/ _` |/ _ \
| |_) | |>  <  __/ | (_| (_| | (_| |  __/
| .__/|_/_/\_\___|_|\___\__,_|\__,_|\___|
|_|
EOF

echo "       Pixelcade LED for Batocera : Installer Version $version    "
echo ""
echo "This script will install Pixelcade in your /userdata/system folder"
echo "Plese ensure you have at least 800 MB of free disk space in /userdata/system"
echo "Now connect Pixelcade to a free USB port on your device"
echo "Ensure the toggle switch on the Pixelcade board is pointing towards USB and not BT"
echo "Grab a coffee or tea as this installer will take around 15 minutes"

INSTALLPATH="${HOME}/"
SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

# let's make sure we have Baticera installation
if batocera-info | grep -q 'System'; then
        echo "Batocera Detected"
else
   echo "Sorry, Batocera was not detected, exiting..."
   exit 1
fi

killall java #if they still have the old java pixelweb

#killall java #need to stop pixelweb.jar if already running

if uname -m | grep -q 'aarch64'; then
   echo "${yellow}aarch64 Detected..."
   aarch64=true
fi

if uname -m | grep -q 'aarch32'; then
   echo "${yellow}aarch32 Detected..."
   aarch32=true
fi

if uname -m | grep -q 'armv6'; then
   echo "${yellow}aarch32 Detected..."
   aarch32=true
fi

if uname -m | grep -q 'x86'; then
   echo "${yellow}x86 32-bit Detected..."
   x86_32=true
fi

if uname -m | grep -q 'amd64'; then
   echo "${yellow}x86 64-bit Detected..."
   x86_64=true
fi

if uname -m | grep -q 'x86_64'; then
   echo "${yellow}x86 64-bit Detected..."
   x86_64=true
   x86_32=false
fi

if cat /proc/device-tree/model | grep -q 'Raspberry Pi 3'; then
   echo "${yellow}Raspberry Pi 3 detected..."
   pi3=true
fi

if cat /proc/device-tree/model | grep -q 'Pi 4'; then
   printf "${yellow}Raspberry Pi 4 detected...\n"
   pi4=true
fi

if cat /proc/device-tree/model | grep -q 'Pi Zero W'; then
   printf "${yellow}Raspberry Pi Zero detected...\n"
   pizero=true
fi

if cat /proc/device-tree/model | grep -q 'ODROID-N2'; then
   printf "${yellow}ODroid N2 or N2+ detected...\n"
   odroidn2=true
fi

echo "Installing Pixelcade Software..."

if [[ -f "${INSTALLPATH}master.zip" ]]; then #if the user killed the installer mid-stream,it's possible this file is still there so let's remove it to be sure before downloading, otherwise wget will download and rename to .1
   rm "${INSTALLPATH}master.zip"
fi

if [ ${PIXELCADE_PRESENT} == "false" ]; then  #skip this if the user already had pixelcade installed
    wget https://github.com/alinke/pixelcade/archive/refs/heads/master.zip
    unzip master.zip
    mv pixelcade-master pixelcade
fi

cd ${INSTALLPATH}pixelcade

    if [[ $aarch64 == "true" ]]; then
          echo "${yellow}Installing Pixelcade 64-Bit for aarch64...${white}" #these will unzip and create the jdk folder
          curl -kLO https://github.com/alinke/pixelcade-linux/blob/main/core/linux-aarch64/pixelweb #this is a 64-bit small JRE , same one used on the ALU
          chmod +x ${INSTALLPATH}pixelweb
    elif [ "$aarch32" == "true" ]; then
          echo "${yellow}Installing Java JRE 11 32-Bit for aarch32...${white}"
          curl -kLO https://github.com/alinke/pixelcade-jre/raw/main/jdk-aarch32.zip
          unzip jdk-aarch32.zip
          chmod +x ${INSTALLPATH}pixelcade/jdk/bin/java
    elif [ "$x86_32" == "true" ]; then #pi zero is arm6 and cannot run the normal java :-( so have to get this special one
          echo "${yellow}Installing Pixelcade 32-Bit for X86...${white}"
          curl -kLO https://github.com/alinke/pixelcade-jre/raw/main/jdk-x86-32.zip
          unzip jdk-x86-32.zip
          chmod +x ${INSTALLPATH}pixelcade/jdk/bin/java
    elif [ "$x86_64" == "true" ]; then #pi zero is arm6 and cannot run the normal java :-( so have to get this special one
          echo "${yellow}Installing Pixelcade 64-Bit for X86...${white}"
          curl -kLO https://github.com/alinke/pixelcade-jre/raw/main/jdk-x86-64.zip
          unzip jdk-x86-64.zip
          chmod +x ${INSTALLPATH}pixelcade/jdk/bin/java
    else
      echo "${red}Sorry, do not have a Pixelcade version for your platform"
    fi

echo "${yellow}Installing Pixelcade Artwork...${white}"
cd ${INSTALLPATH}pixelcade && ./pixelweb -install-artwork

if [[ -d ${INSTALLPATH}ptemp ]]; then
    rm -r ${INSTALLPATH}ptemp
fi

#creating a temp dir for the Pixelcade system files
mkdir ${INSTALLPATH}ptemp
cd ${INSTALLPATH}ptemp

#get the Pixelcade system files
wget https://github.com/alinke/pixelcade-linux/archive/refs/heads/main.zip
unzip main.zip

if [[ ! -d ${INSTALLPATH}configs/emulationstation/scripts ]]; then #does the ES scripts folder exist, make it if not
    mkdir ${INSTALLPATH}configs/emulationstation/scripts
fi

#pixelcade core files
echo "${yellow}Installing Pixelcade Core Files...${white}"
cp -f ${INSTALLPATH}ptemp/pixelcade-linux-main/core/* ${INSTALLPATH}pixelcade #the core Pixelcade files, no sub-folders in this copy
#pixelcade system folder
cp -a -f ${INSTALLPATH}ptemp/pixelcade-linux-main/system ${INSTALLPATH}pixelcade #system folder, .initial-date will go in here
#pixelcade scripts for emulationstation events
#copy over the custom scripts
echo "${yellow}Installing Pixelcade EmulationStation Scripts...${white}"
cp -r -f ${INSTALLPATH}ptemp/pixelcade-linux-main/batocera/scripts ${INSTALLPATH}configs/emulationstation #note this will overwrite existing scripts
find ${INSTALLPATH}configs/emulationstation/scripts -type f -iname "*.sh" -exec chmod +x {} \; #make all the scripts executble
#hi2txt for high score scrolling
echo "${yellow}Installing hi2txt for High Scores...${white}"
cp -r -f ${INSTALLPATH}ptemp/pixelcade-linux-main/hi2txt ${INSTALLPATH}pixelcade #for high scores

# set the Batocera logo as the startup marquee
sed -i 's/startupLEDMarqueeName=arcade/startupLEDMarqueeName=batocera/' ${INSTALLPATH}pixelcade/settings.ini

if [[ $odroidn2 == "true" || "$x86_64" == "true" || "$x86_32" == "true" ]]; then
    echo "${yellow}Setting Pixelcade Explicit Port for Odroid N2 or X86...${white}"
    sed -i "s|port=COM99|port=${PixelcadePort}|" "${INSTALLPATH}pixelcade/settings.ini"
fi
# need to remove a few lines in console.csv
sed -i '/all,mame/d' ${INSTALLPATH}pixelcade/console.csv
sed -i '/favorites,mame/d' ${INSTALLPATH}pixelcade/console.csv
sed -i '/recent,mame/d' ${INSTALLPATH}pixelcade/console.csv

if [[ ! -f ${INSTALLPATH}custom.sh ]]; then #custom.sh is not there already so let's use ours
   if [[ $odroidn2 == "true" || "$x86_64" == "true" || "$x86_32" == "true" ]]; then  #if we have an Odroid N2+ (am assuming Odroid N2 is same behavior) or x86, Pixelcade will hang on first start so a special startup script is needed to get around this issue which also had to be done for the ALU
        cp ${INSTALLPATH}ptemp/pixelcade-linux-main/batocera/odroidn2/custom.sh ${INSTALLPATH} #note this will overwrite existing scripts
    else
        cp ${INSTALLPATH}ptemp/pixelcade-linux-main/batocera/custom.sh ${INSTALLPATH} #note this will overwrite existing scripts
    fi
else                                                     #custom.sh is already there so leave it alone if pixelcade is already there or if not, add it
  if cat ${INSTALLPATH}custom.sh | grep -q 'pixelcade'; then
      echo "Pixelcade was already added to custom.sh, skipping..."
  else
      echo "Adding Pixelcade Listener auto start to your existing custom.sh ..."
      if [[ $odroidn2 == "true" || "$x86_64" == "true" || "$x86_32" == "true" ]]; then
        cp ${INSTALLPATH}ptemp/pixelcade-linux-main/batocera/odroidn2/custom.sh ${INSTALLPATH}pixelcade/system/autostart.sh
        chmod +x ${INSTALLPATH}pixelcade/system/autostart.sh
        echo "/bin/sh ${INSTALLPATH}pixelcade/system/autostart.sh" >> ${INSTALLPATH}custom.sh #append pixelcade's autostart.sh to the existing custom.sh
    else
        cp ${INSTALLPATH}ptemp/pixelcade-linux-main/batocera/custom.sh ${INSTALLPATH}pixelcade/system/autostart.sh
        chmod +x ${INSTALLPATH}pixelcade/system/autostart.sh
        echo "/bin/sh ${INSTALLPATH}pixelcade/system/autostart.sh" >> ${INSTALLPATH}custom.sh #append pixelcade's autostart.sh to the existing custom.sh
    fi
  fi
fi

chmod +x ${INSTALLPATH}custom.sh

cd ${INSTALLPATH}pixelcade

if [[ $odroidn2 == "true" || "$x86_64" == "true" || "$x86_32" == "true" ]]; then #start up work around for Odroid N2 or X86 64 bit
  source ${INSTALLPATH}custom.sh
  sleep 8
  cd ${INSTALLPATH}pixelcade
  ${INSTALLPATH}pixelcade/jdk/bin/java -jar pixelcade.jar -m stream -c mame -g 1941  # let's send a test image and see if it displays
else
  ${INSTALLPATH}pixelcade/jdk/bin/java -jar pixelweb.jar -b & #run pixelweb in the background
  sleep 8
  cd ${INSTALLPATH}pixelcade
  ${INSTALLPATH}pixelcade/jdk/bin/java -jar pixelcade.jar -m stream -c mame -g 1941 # let's send a test image and see if it displays
fi

echo "Cleaning Up..."
cd ${INSTALLPATH}

if [[ -f master.zip ]]; then
    rm master.zip
fi

rm ${SCRIPTPATH}/setup-batocera.sh

if [[ -d ${INSTALLPATH}ptemp ]]; then
    rm -r ${INSTALLPATH}ptemp
fi

echo ""
echo "**** INSTALLATION COMPLETE ****"
install_succesful=true

echo " "
while true; do
    read -p "Is the 1941 Game Logo Displaying on Pixelcade Now? (y/n)" yn
    case $yn in
        [Yy]* ) echo "INSTALLATION COMPLETE , please now reboot and then Pixelcade will be controlled by Batocera" && install_succesful=true; break;;
        [Nn]* ) echo "It may still be ok and try rebooting, you can also refer to https://pixelcade.org/download-pi/ for troubleshooting steps" && exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

if [ "$install_succesful" = true ] ; then
  while true; do
      read -p "Reboot Now? (y/n)" yn
      case $yn in
          [Yy]* ) reboot; break;;
          [Nn]* ) echo "Please reboot when you get a chance" && exit;;
          * ) echo "Please answer yes or no.";;
      esac
  done
fi
