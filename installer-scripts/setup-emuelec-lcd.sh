#!/bin/bash
java_installed=false
install_succesful=false
auto_update=false #this doesn't do anything, keep on false
PIXELCADE_PRESENT=false
version=7  #increment this as the script is updated
upgrade_software=false
upgrade_artwork=false

cat << "EOF"
       _          _               _
 _ __ (_)_  _____| | ___ __ _  __| | ___
| '_ \| \ \/ / _ \ |/ __/ _` |/ _` |/ _ \
| |_) | |>  <  __/ | (_| (_| | (_| |  __/
| .__/|_/_/\_\___|_|\___\__,_|\__,_|\___|
|_|
EOF

echo "       Pixelcade LCD for EmuELEC : Installer Version $version    "
echo ""
echo "This script will install Pixelcade in your /storage/roms folder"

INSTALLPATH="/storage/roms/"

# let's make sure we have EmuELEC installation
if lsb_release -a | grep -q 'EmuELEC'; then
        echo "EmuELEC Detected"
else
   echo "Sorry, EmuELEC was not detected, exiting..."
   exit 1
fi

killall java #need to stop pixelweb.jar if already running

# let's check the version and only proceed if the user has an older version
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
      else
        while true; do
            read -p "Your Pixelcade software vesion is up to date. Do you want to re-install? (y/n) " yn
            case $yn in
                [Yy]* ) upgrade_software=true; break;;
                [Nn]* ) exit; break;;
                * ) echo "Please answer y or n";;
            esac
        done
      fi
    fi
else
    mkdir ${INSTALLPATH}pixelcade
fi

JDKDEST="${HOME}/roms/bios/jdk"
JDKNAME="zulu18.0.45-ea-jdk18.0.0-ea.18"
CDN="https://cdn.azul.com/zulu/bin"

# Alternate just for reference
#CDN="https://cdn.azul.com/zulu-embedded/bin"

mkdir -p "${JDKDEST}"

OLDVERSION="$(cat ${JDKDEST}/eeversion 2>/dev/null)"
if [ "${JDKNAME}" != "${OLDVERSION}" ]; then
   JDKINSTALLED="no"
   rm -rf "${JDKDEST}"
   mkdir -p "${JDKDEST}"
fi

if [ "${JDKINSTALLED}" == "no" ]; then
echo -e "GET http://google.com HTTP/1.0\n\n" | nc google.com 80
if [ $? -ne 0 ]; then
    echo "No internet connection, exiting..."
    text_viewer -e -w -t "No Internet!" -m "You need to be connected to the internet to download the JDK\nNo internet connection, exiting...";
    exit 1
fi
    echo "Downloading JDK please be patient..."
    cd ${JDKDEST}/..
    wget "${CDN}/${JDKNAME}-linux_aarch64.tar.gz"
    echo "Inflating JDK please be patient..."
    tar xvfz ${JDKNAME}-linux_aarch64.tar.gz ${JDKNAME}-linux_aarch64/lib
    tar xvfz ${JDKNAME}-linux_aarch64.tar.gz ${JDKNAME}-linux_aarch64/bin
    tar xvfz ${JDKNAME}-linux_aarch64.tar.gz ${JDKNAME}-linux_aarch64/conf
    rm ${JDKNAME}-linux_aarch64/lib/*.zip
    mv ${JDKNAME}-linux_aarch64/* ${JDKDEST}
    rm -rf ${JDKNAME}-linux_aarch64*

    for del in jmods include demo legal man DISCLAIMER LICENSE readme.txt release Welcome.html; do
        rm -rf ${JDKDEST}/${del}
    done
    echo "JDK done! loading core!"
    cp -rf /usr/lib/libretro/freej2me-lr.jar ${HOME}/roms/bios
    echo "${JDKNAME}" > "${JDKDEST}/eeversion"
fi

if [[ -d ${INSTALLPATH}ptemp ]]; then
    rm -r ${INSTALLPATH}ptemp
fi

#creating a temp dir for the Pixelcade system files
mkdir ${INSTALLPATH}ptemp
cd ${INSTALLPATH}ptemp

#get the Pixelcade system files
wget https://github.com/alinke/pixelcade-linux/archive/refs/heads/main.zip
unzip main.zip

if [[ ! -d /storage/.emulationstation/scripts ]]; then #does the ES scripts folder exist, make it if not
    mkdir /storage/.emulationstation/scripts
fi

#pixelcade core files
echo "${yellow}Installing Pixelcade Core Files...${white}"

cp -f ${INSTALLPATH}ptemp/pixelcade-linux-main/core/* ${INSTALLPATH}pixelcade #the core Pixelcade files, no sub-folders in this copy
#pixelcade system folder
cp -a -f ${INSTALLPATH}ptemp/pixelcade-linux-main/system ${INSTALLPATH}pixelcade #system folder, .initial-date will go in here
#pixelcade scripts for emulationstation events
#copy over the custom scripts
echo "${yellow}Installing Pixelcade EmulationStation Scripts...${white}"
cp -r -f ${INSTALLPATH}ptemp/pixelcade-linux-main/emuelec/scripts /storage/.emulationstation #note this will overwrite existing scripts
find /storage/.emulationstation/scripts -type f -iname "*.sh" -exec chmod +x {} \; #make all the scripts executble
#hi2txt for high score scrolling
echo "${yellow}Installing hi2txt for High Scores...${white}"
cp -r -f ${INSTALLPATH}ptemp/pixelcade-linux-main/hi2txt ${INSTALLPATH} #for high scores

# let's make sure we have EmuELEC installation
if lsb_release -a | grep -q '4.4-TEST'; then
        echo "EmuELEC 4.4-TEST Detected so let's copy over the patched retroarch for RetroAchievements"
        cp -f ${INSTALLPATH}ptemp/pixelcade-linux-main/retroarch/retroarch /emuelec/bin/retroarch
        chmod +x /emuelec/bin/retroarch
fi

# set the emuelec logo as the startup marquee
sed -i 's/startupLEDMarqueeName=arcade/startupLEDMarqueeName=emuelec/' ${INSTALLPATH}pixelcade/settings.ini
sed -i 's/port=COM99/port=COM89/' ${INSTALLPATH}pixelcade/settings.ini
sed -i 's/CYCLEMODE=yes/CYCLEMODE=no/' /storage/.emulationstation/scripts/game-start/01-pixelcade.sh #cycle mode won't work with LCD
# need to remove a few lines in console.csv
sed -i 's/startupLEDMarqueeName=arcade/startupLEDMarqueeName=emuelec/' ${INSTALLPATH}pixelcade/console.csv
sed -i '/all,mame/d' ${INSTALLPATH}pixelcade/console.csv
sed -i '/favorites,mame/d' ${INSTALLPATH}pixelcade/console.csv
sed -i '/recent,mame/d' ${INSTALLPATH}pixelcade/console.csv

if cat /storage/.config/custom_start.sh | grep -q 'pixelcade'; then
    echo "Pixelcade was already added to custom_start.sh, skipping..."
else
    echo "Adding Pixelcade Listener auto start to custom_start.sh ..."
    sed -i '/^"before")/a cd '${INSTALLPATH}'pixelcade && '${INSTALLPATH}'bios/jdk/bin/java -jar pixelweb.jar -b &' /storage/.config/custom_start.sh  #insert this line after "before"
fi

#lastly let's just check for Pixelcade LCD
cd ${INSTALLPATH}pixelcade
echo "Checking for Pixelcade LCDs..."
${INSTALLPATH}bios/jdk/bin/java -jar pixelcadelcdfinder.jar -nogui #check for Pixelcade LCDs

${INSTALLPATH}bios/jdk/bin/java -jar pixelweb.jar -b & #run pixelweb in the background\

chmod +x /storage/.config/custom_start.sh

# let's send a test image and see if it displays
sleep 8
cd ${INSTALLPATH}pixelcade
${INSTALLPATH}bios/jdk/bin/java -jar pixelcade.jar -m stream -c mame -g 1941

echo "Cleaning up..."
if [[ -d ${INSTALLPATH}ptemp ]]; then
    rm -r ${INSTALLPATH}ptemp
fi

if [[ -f ${INSTALLPATH}setup-emuelec.sh ]]; then
    rm ${INSTALLPATH}setup-emuelec.sh
fi

if [[ -f /storage/setup-emuelec.sh ]]; then
    rm /storage/setup-emuelec.sh
fi

#let's write the version so the next time the user can try and know if he/she needs to upgrade
echo $version > ${INSTALLPATH}pixelcade/pixelcade-version
touch ${INSTALLPATH}pixelcade/system/.initial-date
echo "INSTALLATION COMPLETE , please now reboot and then the Pixelcade logo should be display on Pixelcade"
install_succesful=true

echo " "
while true; do
    read -p "Is the 1941 Game Logo Displaying on Pixelcade LCD Now? (y/n)" yn
    case $yn in
        [Yy]* ) echo "INSTALLATION COMPLETE , please now reboot and then Pixelcade will be controlled by EmuELEC" && install_succesful=true; break;;
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
