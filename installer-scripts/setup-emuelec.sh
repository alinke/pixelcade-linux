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

echo "       Pixelcade LED for EmuELEC : Installer Version $version    "
echo ""
echo "This script will install Pixelcade in your /storage/roms folder"
echo "Plese ensure you have at least 800 MB of free disk space in /storage/roms"
echo "Now connect Pixelcade to a free USB port on your device (Odroid, Android Box, etc)"
echo "Ensure the toggle switch on the Pixelcade board is pointing towards USB and not BT"
echo "Grab a coffee or tea as this installer will take around 15 minutes"

INSTALLPATH="/storage/roms/"

updateartwork() {  #this is needed for rom names with spaces

  cd ${INSTALLPATH}

  if [[ -f "${INSTALLPATH}master.zip" ]]; then #if the user killed the installer mid-stream,it's possible this file is still there so let's remove it to be sure before downloading, otherwise wget will download and rename to .1
     rm "${INSTALLPATH}master.zip"
  fi

  if [[ -d "${INSTALLPATH}pixelcade-master" ]]; then #if the user killed the installer mid-stream,it's possible this file is still there so let's remove it to be sure before downloading, otherwise wget will download and rename to .1
     rm -r "${INSTALLPATH}pixelcade-master"
  fi

  if [[ ! -d "${INSTALLPATH}user-modified-pixelcade-artwork" ]]; then
     mkdir "${INSTALLPATH}user-modified-pixelcade-artwork"
  fi
  #let's get the files that have been modified since the initial install as they would have been overwritten

  #find all files that are newer than .initial-date and put them into /ptemp/modified.tgz
  echo "Backing up any artwork that you have added or changed..."

  if [[ -f "${INSTALLPATH}pixelcade/system/.initial-date" ]]; then #our initial date stamp file is there
     cd ${INSTALLPATH}pixelcade
     find . -not -name "*.rgb565" -not -name "pixelcade-version" -not -name "*.txt" -not -name "decoded" -not -name "*.ini" -not -name "*.csv" -not -name "*.log" -not -name "*.sh" -not -name "*.zip" -not -name "*.jar" -not -name "*.css" -not -name "*.js" -not -name "*.html" -not -name "*.rules" -newer ${INSTALLPATH}pixelcade/system/.initial-date -print0 | sed "s/'/\\\'/" | xargs -0 tar --no-recursion -cf ${INSTALLPATH}user-modified-pixelcade-artwork/changed.tgz
     #unzip the file
     cd "${INSTALLPATH}user-modified-pixelcade-artwork"
     tar -xvzf changed.tgz
     rm changed.tgz
     #dont' delete the folder because initial date gets reset so we need continusly to track what the user changed during each update in this folder
  else
      echo "[ERROR] ${INSTALLPATH}pixelcade/system/.initial-date does not exist, any custom or modified artwork you have done will not backup and will be overwritten"
  fi

  cd ${INSTALLPATH}
  wget https://github.com/alinke/pixelcade/archive/refs/heads/master.zip
  unzip master.zip
  echo "Copying over new artwork..."
  # not that because of github the file dates of pixelcade-master will be today's date and thus newer than the destination
  # now let's overwrite with the pixelcade repo and because the repo files are today's date, they will be newer and copy over
  #rsync -avruh --exclude '*.jar' --exclude '*.csv' --exclude '*.ini' --exclude '*.log' --exclude '*.cfg' --exclude emuelec --exclude batocera --exclude recalbox --progress ${INSTALLPATH}pixelcade-master/. ${INSTALLPATH}pixelcade/ #this is going to reset the last updated date
  rsync -aruh --exclude '*.jar' --exclude '*.csv' --exclude '*.ini' --exclude '*.log' --exclude '*.cfg' --exclude emuelec --exclude batocera --exclude recalbox ${INSTALLPATH}pixelcade-master/. ${INSTALLPATH}pixelcade/ #this is going to reset the last updated date
  # ok so now copy back in here the files from ptemp

  if [[ -f "${INSTALLPATH}pixelcade/system/.initial-date" ]]; then
     cp -r -v "${INSTALLPATH}user-modified-pixelcade-artwork/." "${INSTALLPATH}pixelcade/"
  fi

  echo "Cleaning up, this will take a bit..."
  rm -r ${INSTALLPATH}pixelcade-master
  rm ${INSTALLPATH}master.zip

  cd ${INSTALLPATH}pixelcade
  ${INSTALLPATH}bios/jdk/bin/java -jar pixelweb.jar -b & #run pixelweb in the background\
  touch ${INSTALLPATH}pixelcade/system/.initial-date
  exit 1
}

updateartworkandsoftware() {  #this is needed for rom names with spaces

cd ${INSTALLPATH}

if [[ -f "${INSTALLPATH}master.zip" ]]; then #if the user killed the installer mid-stream,it's possible this file is still there so let's remove it to be sure before downloading, otherwise wget will download and rename to .1
   rm "${INSTALLPATH}master.zip"
fi

if [[ -d "${INSTALLPATH}pixelcade-master" ]]; then #if the user killed the installer mid-stream,it's possible this file is still there so let's remove it to be sure before downloading, otherwise wget will download and rename to .1
   rm -r "${INSTALLPATH}pixelcade-master"
fi

if [[ ! -d "${INSTALLPATH}user-modified-pixelcade-artwork" ]]; then
   mkdir "${INSTALLPATH}user-modified-pixelcade-artwork"
fi

#find all files that are newer than .initial-date and put them into /ptemp/modified.tgz
echo "Backing up your artwork modifications..."

if [[ -f "${INSTALLPATH}pixelcade/system/.initial-date" ]]; then #our initial date stamp file is there
   cd ${INSTALLPATH}pixelcade
   find . -not -name "*.rgb565" -not -name "pixelcade-version" -not -name "*.txt" -not -name "decoded" -not -name "*.ini" -not -name "*.csv" -not -name "*.log" -not -name "*.sh" -not -name "*.zip" -not -name "*.jar" -not -name "*.css" -not -name "*.js" -not -name "*.html" -not -name "*.rules" -newer ${INSTALLPATH}pixelcade/system/.initial-date -print0 | sed "s/'/\\\'/" | xargs -0 tar --no-recursion -cf ${INSTALLPATH}user-modified-pixelcade-artwork/changed.tgz
   #unzip the file
   cd "${INSTALLPATH}user-modified-pixelcade-artwork"
   tar -xvzf changed.tgz
   rm changed.tgz
   #dont' delete the folder because initial date gets reset so we need continusly to track what the user changed during each update in this folder
else
    echo "[ERROR] ${INSTALLPATH}pixelcade/system/.initial-date does not exist, any custom or modified artwork you have done will not backup and will be overwritten"
fi

cd ${INSTALLPATH}
wget https://github.com/alinke/pixelcade/archive/refs/heads/master.zip
unzip master.zip
echo "Copying over new artwork..."
# not that because of github the file dates of pixelcade-master will be today's date and thus newer than the destination
# now let's overwrite with the pixelcade repo and because the repo files are today's date, they will be newer and copy over
#rsync -avruh --progress ${INSTALLPATH}pixelcade-master/. ${INSTALLPATH}pixelcade/
rsync -aruh ${INSTALLPATH}pixelcade-master/. ${INSTALLPATH}pixelcade/
# ok so now copy back in here the files from ptemp

if [[ -f "${INSTALLPATH}pixelcade/system/.initial-date" ]]; then
   cp -r -v "${INSTALLPATH}user-modified-pixelcade-artwork/." "${INSTALLPATH}pixelcade/"
fi

echo "Cleaning up, this will take a bit..."
rm -r ${INSTALLPATH}pixelcade-master
rm ${INSTALLPATH}master.zip

cd ${INSTALLPATH}pixelcade
PIXELCADE_PRESENT=true
}

# let's detect if Pixelcade is USB connected, could be 0 or 1 so we need to check both
if ls /dev/ttyACM0 | grep -q '/dev/ttyACM0'; then
   echo "Pixelcade LED Marquee Detected on ttyACM0"
else
    if ls /dev/ttyACM1 | grep -q '/dev/ttyACM1'; then
        echo "Pixelcade LED Marquee Detected on ttyACM1"
    else
       echo "Sorry, Pixelcade LED Marquee was not detected, pleasse ensure Pixelcade is USB connected to your Pi and the toggle switch on the Pixelcade board is pointing towards USB, exiting..."
       exit 1
    fi
fi

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
                  [Nn]* ) upgrade_software=false; break;;
                    * ) echo "Please answer y or n";;
                esac
            done
            while true; do
                read -p "Would you also like to get the latest Pixelcade artwork? (y/n) " yn
                case $yn in
                  [Yy]* ) upgrade_artwork=true; break;;
                  [Nn]* ) upgrade_artwork=false; break;;
                    * ) echo "Please answer y or n";;
                esac
            done

            if [[ "$upgrade_software" = true && "$upgrade_artwork" = true ]]; then
                  updateartworkandsoftware
            elif [[ "$upgrade_software" = true && "$upgrade_artwork" = false ]]; then
                 echo "Upgrading Pixelcade software only and skipping artwork update...";
                 PIXELCADE_PRESENT=true #telling not to re-install Pixelcade
            elif [[ "$upgrade_software" = false && "$upgrade_artwork" = true ]]; then
                 updateartwork #this will exit after artwork upgrade and not continue on for the software update
            else
                 echo "Not updating Pixelcade software or artwork, exiting...";
                 exit
            fi

      else

        while true; do
            read -p "Your Pixelcade software vesion is up to date. Do you want to re-install? (y/n) " yn
            case $yn in
              [Yy]* ) upgrade_software=true; break;;
              [Nn]* ) upgrade_software=false; break;;
                * ) echo "Please answer y or n";;
            esac
        done

        while true; do
            read -p "Would you also like to get the latest Pixelcade artwork? (y/n) " yn
            case $yn in
              [Yy]* ) upgrade_artwork=true; break;;
              [Nn]* ) upgrade_artwork=false; break;;
                * ) echo "Please answer y or n";;
            esac
        done

        if [[ "$upgrade_software" = true && "$upgrade_artwork" = true ]]; then
              updateartworkandsoftware
        elif [[ "$upgrade_software" = true && "$upgrade_artwork" = false ]]; then
             echo "Upgrading Pixelcade software only and skipping artwork update...";
             PIXELCADE_PRESENT=true #telling not to re-install Pixelcade
        elif [[ "$upgrade_software" = false && "$upgrade_artwork" = true ]]; then
             updateartwork #this will exit after artwork upgrade and not continue on for the software update
        else
             echo "Not updating Pixelcade software or artwork, exiting...";
             exit
        fi

      fi
    fi
fi

#. /etc/profile

#ee_console enable
#echo "Checking JDK..." > /dev/console

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


if [ ${PIXELCADE_PRESENT} == "false" ]; then  #skip this if the user already had pixelcade
  echo "Installing Pixelcade from GitHub Repo..."
  cd ${INSTALLPATH}
  git clone --depth 1 git://github.com/alinke/pixelcade.git
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
    read -p "Is the 1941 Game Logo Displaying on Pixelcade Now? (y/n)" yn
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
