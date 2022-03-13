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
odroidn2=false
PIXELCADE_PRESENT=false #did we do an upgrade and pixelcade was already there
version=8  #increment this as the script is updated

cat << "EOF"
       _          _               _
 _ __ (_)_  _____| | ___ __ _  __| | ___
| '_ \| \ \/ / _ \ |/ __/ _` |/ _` |/ _ \
| |_) | |>  <  __/ | (_| (_| | (_| |  __/
| .__/|_/_/\_\___|_|\___\__,_|\__,_|\___|
|_|
EOF

echo "       Pixelcade LCD for Batocera : Installer Version $version    "
echo ""
echo "This script will install Pixelcade in your /userdata/system folder"

INSTALLPATH="${HOME}/"

# let's make sure we have Baticera installation
if batocera-info | grep -q 'System'; then
        echo "Batocera Detected"
else
   echo "Sorry, Batocera was not detected, exiting..."
   exit 1
fi

killall java #need to stop pixelweb.jar if already running

if [[ -d "${INSTALLPATH}pixelcade" ]]; then
    if [[ -f "${INSTALLPATH}pixelcade/pixelcade-version" ]]; then
      echo "Existing Pixelcade installation detected, checking version..."
      read -r currentVersion<${INSTALLPATH}pixelcade/pixelcade-version
      if [[ $currentVersion -lt $version ]]; then
            echo "Older Pixelcade version detected"
            while true; do
                read -p "You've got an older version of Pixelcade software, type y to upgrade your Pixelcade software (y/n) " yn
                case $yn in
                    [Yy]* ) upgrade_software=true; break;;
                    [Nn]* ) exit; break;;
                    * ) echo "Please answer y or n";;
                esac
            done
            while true; do
                read -p "Would you also like to get the latest Pixelcade artwork? (y/n) " yn
                case $yn in
                    [Yy]* ) upgrade_artwork=true; break;;
                    [Nn]* ) break;;
                    * ) echo "Please answer y or n";;
                esac
            done

            if [[ $upgrade_software = true && $upgrade_artwork = true ]]; then
                  updateartworkandsoftware
            elif [ "$upgrade_software" = true ]; then
                 echo "Upgrading Pixelcade software...";
            elif [ "$upgrade_artwork" = true ]; then
                 updateartwork #this will exit after artwork upgrade and not continue on for the software update
            fi

      else

        while true; do
            read -p "Your Pixelcade software vesion is up to date. Do you want to re-install? (y/n) " yn
            case $yn in
                [Yy]* ) upgrade_software=true; break;;
                [Nn]* ) exit; break;;
                * ) echo "Please answer y or n";;
            esac
        done

        while true; do
            read -p "Would you also like to get the latest Pixelcade artwork? (y/n) " yn
            case $yn in
                [Yy]* ) upgrade_artwork=true; break;;
                [Nn]* ) break;;
                * ) echo "Please answer y or n";;
            esac
        done

        if [[ $upgrade_software = true && $upgrade_artwork = true ]]; then
              updateartworkandsoftware
        elif [ "$upgrade_software" = true ]; then
             echo "Upgrading Pixelcade software...";
        elif [ "$upgrade_artwork" = true ]; then
             updateartwork #this will exit after artwork upgrade and not continue on for the software update
        fi
      fi
    fi
else
        mkdir ${INSTALLPATH}pixelcade
fi

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

cd ${INSTALLPATH}pixelcade
JDKDEST="${INSTALLPATH}pixelcade/jdk"

if [[ ! -d $JDKDEST ]]; then #does Java exist already
    if [[ $aarch64 == "true" ]]; then
          echo "${yellow}Installing Java JRE 11 64-Bit for aarch64...${white}" #these will unzip and create the jdk folder
          curl -kLO https://github.com/alinke/pixelcade-jre/raw/main/jdk-aarch64.zip #this is a 64-bit small JRE , same one used on the ALU
          unzip jdk-aarch64.zip
          chmod +x ${INSTALLPATH}pixelcade/jdk/bin/java
    elif [ "$aarch32" == "true" ]; then
          echo "${yellow}Installing Java JRE 11 32-Bit for aarch32...${white}"
          curl -kLO https://github.com/alinke/pixelcade-jre/raw/main/jdk-aarch32.zip
          unzip jdk-aarch32.zip
          chmod +x ${INSTALLPATH}pixelcade/jdk/bin/java
    elif [ "$x86_32" == "true" ]; then #pi zero is arm6 and cannot run the normal java :-( so have to get this special one
          echo "${yellow}Installing Java JRE 11 32-Bit for X86...${white}"
          curl -kLO https://github.com/alinke/pixelcade-jre/raw/main/jdk-x86-32.zip
          unzip jdk-x86-32.zip
          chmod +x ${INSTALLPATH}pixelcade/jdk/bin/java
    elif [ "$x86_64" == "true" ]; then #pi zero is arm6 and cannot run the normal java :-( so have to get this special one
          echo "${yellow}Installing Java JRE 11 64-Bit for X86...${white}"
          curl -kLO https://github.com/alinke/pixelcade-jre/raw/main/jdk-x86-64.zip
          unzip jdk-x86-64.zip
          chmod +x ${INSTALLPATH}pixelcade/jdk/bin/java
    else
      echo "${red}Sorry, do not have a Java JDK for your platform, you'll need to install a Java JDK or JRE manually under /userdata/system/jdk"
    fi
fi

if [[ -f "${INSTALLPATH}master.zip" ]]; then #if the user killed the installer mid-stream,it's possible this file is still there so let's remove it to be sure before downloading, otherwise wget will download and rename to .1
   rm "${INSTALLPATH}master.zip"
fi

if [[ -d ${INSTALLPATH}ptemp ]]; then
    rm -r ${INSTALLPATH}ptemp
fi

#creating a temp dir for the Pixelcade system files
mkdir ${INSTALLPATH}ptemp
cd ${INSTALLPATH}ptemp
if [[ ! -d ${INSTALLPATH}ptemp/pixelcade-linux-main ]]; then
    rm -r ${INSTALLPATH}ptemp/pixelcade-linux-main
fi
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
sed -i 's/port=COM99/port=COM89/' ${INSTALLPATH}pixelcade/settings.ini
sed -i 's/CYCLEMODE=yes/CYCLEMODE=no/' ${INSTALLPATH}configs/emulationstation/scripts/game-start/01-pixelcade.sh #cycle mode won't work with LCD
# need to remove a few lines in console.csv
sed -i '/all,mame/d' ${INSTALLPATH}pixelcade/console.csv
sed -i '/favorites,mame/d' ${INSTALLPATH}pixelcade/console.csv
sed -i '/recent,mame/d' ${INSTALLPATH}pixelcade/console.csv

if [[ ! -f ${INSTALLPATH}custom.sh ]]; then #does a startup-script already exist
    cp ${INSTALLPATH}ptemp/pixelcade-linux-main/batocera/custom.sh ${INSTALLPATH} #note this will overwrite existing scripts
else                                                     #custom.sh is already there so leave it alone if pixelcade is already there or if not, add it
  if cat ${INSTALLPATH}custom.sh | grep -q 'pixelcade'; then
      echo "Pixelcade was already added to custom.sh, skipping..."
  else
      echo "Adding Pixelcade Listener auto start to custom.sh ..."
      sed -i -e "\$acd '${INSTALLPATH}'pixelcade && '${INSTALLPATH}'pixelcade/jdk/bin/java -jar pixelweb.jar -b &" ${INSTALLPATH}custom.sh
  fi
fi

chmod +x ${INSTALLPATH}custom.sh

cd ${INSTALLPATH}pixelcade

echo "Checking for Pixelcade LCDs..."
${INSTALLPATH}pixelcade/jdk/bin/java -jar pixelcadelcdfinder.jar -nogui #check for Pixelcade LCDs

${INSTALLPATH}pixelcade/jdk/bin/java -jar pixelweb.jar -b & #run pixelweb in the background\

# let's send a test image and see if it displays
sleep 8
cd ${INSTALLPATH}pixelcade
${INSTALLPATH}pixelcade/jdk/bin/java -jar pixelcade.jar -m stream -c mame -g 1941

#let's write the version so the next time the user can try and know if he/she needs to upgrade
echo $version > ${INSTALLPATH}pixelcade/pixelcade-version

echo "Cleaning Up..."
cd ${INSTALLPATH}
rm ${INSTALLPATH}/ptemp
if [[ -f ${INSTALLPATH}jdk.zip ]]; then
    rm ${INSTALLPATH}jdk.zip
fi

rm setup-batocera-lcd.sh
if [[ -d ${INSTALLPATH}ptemp ]]; then
    rm -r ${INSTALLPATH}ptemp
fi

echo "INSTALLATION COMPLETE , please now reboot and then the Pixelcade logo should be display on Pixelcade"
install_succesful=true
touch ${INSTALLPATH}pixelcade/system/.initial-date

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
