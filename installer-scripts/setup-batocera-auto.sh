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
version=7  #increment this as the script is updated

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

INSTALLPATH="/userdata/system/"

killall java
mkdir ${INSTALLPATH}pixelcade

updateartworkandsoftware() {

cd ${INSTALLPATH}

if [[ -f "${INSTALLPATH}master.zip" ]]; then #if the user killed the installer mid-stream,it's possible this file is still there so let's remove it to be sure before downloading, otherwise wget will download and rename to .1
   rm "${INSTALLPATH}master.zip"
fi

if [[ -d "${INSTALLPATH}pixelcade-master" ]]; then #if the user killed the installer mid-stream,it's possible this file is still there so let's remove it to be sure before downloading, otherwise wget will download and rename to .1
   rm -r "${INSTALLPATH}pixelcade-master"
fi

if [[ ! -d "${INSTALLPATH}pixelcade/user-modified-pixelcade-artwork" ]]; then #we use this to track artwork changes the user made so we can copy them back during artwork updates
   mkdir "${INSTALLPATH}pixelcade/user-modified-pixelcade-artwork"
fi

#find all files that are newer than .initial-date and put them into /ptemp/modified.tgz
echo "Backing up your artwork modifications..."

if [[ -f "${INSTALLPATH}pixelcade/system/.initial-date" ]]; then #our initial date stamp file is there
    cd ${INSTALLPATH}pixelcade
    find . -path './user-modified-pixelcade-artwork' -prune -o -not -name "*.rgb565" -not -name "pixelcade-version" \
    -not -name "*.txt" -not -name "decoded" -not -name "*.ini" -not -name "*.csv" -not -name "*.log" -not -name "*.log.1" \
    -not -name "*.sh" -not -name "*.zip" -not -name "*.jar" -not -name "*.css" -not -name "*.js" -not -name "*.html" \
    -not -name "*.rules" -newer ${INSTALLPATH}pixelcade/system/.initial-date \
    -print0 | sed "s/'/\\\'/" | xargs -0 tar --no-recursion \
    -cf ${INSTALLPATH}pixelcade/user-modified-pixelcade-artwork/changed.tgz
    #unzip the file
    cd "${INSTALLPATH}pixelcade/user-modified-pixelcade-artwork"
    tar -xvf changed.tgz
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
rsync -avruh --progress ${INSTALLPATH}pixelcade-master/. ${INSTALLPATH}pixelcade/
# ok so now copy back in here the files from ptemp

if [[ -f "${INSTALLPATH}pixelcade/system/.initial-date" ]]; then
   echo "Copying your modified artwork..."
   cp -f -r -v "${INSTALLPATH}pixelcade/user-modified-pixelcade-artwork/." "${INSTALLPATH}pixelcade/"
fi

echo "Cleaning up, this will take a bit..."
rm -r ${INSTALLPATH}pixelcade-master
rm ${INSTALLPATH}master.zip

cd ${INSTALLPATH}pixelcade
PIXELCADE_PRESENT=true
}

#Start main script here

if [[ -d "${INSTALLPATH}pixelcade" ]]; then #if pixelcade is already there, let's update artwork including copying over user modded artwork
    updateartworkandsoftware
fi

cd ${INSTALLPATH}

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
cp -r -f ${INSTALLPATH}ptemp/pixelcade-linux-main/hi2txt ${INSTALLPATH} #for high scores

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

if [[ ! -f ${INSTALLPATH}custom.sh ]]; then #custom.sh is not there so let's use ours
   if [[ $odroidn2 == "true" || "$x86_64" == "true" || "$x86_32" == "true" ]]; then  #if we have an Odroid N2+ (am assuming Odroid N2 is same behavior) or x86, Pixelcade will hang on first start so a special startup script is needed to get around this issue which also had to be done for the ALU
        cp ${INSTALLPATH}ptemp/pixelcade-linux-main/batocera/odroidn2/auto/custom.sh ${INSTALLPATH} #note this will overwrite existing scripts
    else
        cp ${INSTALLPATH}ptemp/pixelcade-linux-main/batocera/auto/custom.sh ${INSTALLPATH} #note this will overwrite existing scripts
    fi
else      #custom.sh is already there so just add pixelcade startup to it
  if cat ${INSTALLPATH}custom.sh | grep -q 'pixelcade'; then   #pixelcade mod already there, let's skip
      echo "Pixelcade was already added to custom.sh, skipping..."
  else
      echo "Adding Pixelcade Listener auto start to custom.sh ..."
      if [[ $odroidn2 == "true" || "$x86_64" == "true" || "$x86_32" == "true" ]]; then
          cp ${INSTALLPATH}ptemp/pixelcade-linux-main/batocera/odroidn2/auto/custom.sh ${INSTALLPATH}pixelcade/system/autostart.sh
          chmod +x ${INSTALLPATH}pixelcade/system/autostart.sh
          echo "/bin/sh ${INSTALLPATH}pixelcade/system/autostart.sh" >> ${INSTALLPATH}custom.sh #append pixelcade's autostart.sh to the existing custom.sh
      else
          cp ${INSTALLPATH}ptemp/pixelcade-linux-main/batocera/auto/custom.sh ${INSTALLPATH}pixelcade/system/autostart.sh
          chmod +x ${INSTALLPATH}pixelcade/system/autostart.sh
          echo "/bin/sh ${INSTALLPATH}pixelcade/system/autostart.sh" >> ${INSTALLPATH}custom.sh #append pixelcade's autostart.sh to the existing custom.sh
      fi
  fi
fi

chmod +x ${INSTALLPATH}custom.sh

cd ${INSTALLPATH}pixelcade

echo "Checking for Pixelcade LCDs..."
${INSTALLPATH}pixelcade/jdk/bin/java -jar pixelcadelcdfinder.jar -nogui #check for Pixelcade LCDs

if [[ $odroidn2 == "true" || "$x86_64" == "true" || "$x86_32" == "true" ]]; then #start up work around for Odroid N2 or X86 64 bit
  source ${INSTALLPATH}custom.sh
  sleep 8
  cd ${INSTALLPATH}pixelcade
  ${INSTALLPATH}pixelcade/jdk/bin/java -jar pixelcade.jar -m stream -c mame -g batocera  # let's send a test image and see if it displays
else
  ${INSTALLPATH}pixelcade/jdk/bin/java -jar pixelweb.jar -b & #run pixelweb in the background
  sleep 8
  cd ${INSTALLPATH}pixelcade
  ${INSTALLPATH}pixelcade/jdk/bin/java -jar pixelcade.jar -m stream -c mame -g batocera # let's send a test image and see if it displays
fi

#let's write the version so the next time the user can try and know if he/she needs to upgrade
echo $version > ${INSTALLPATH}pixelcade/pixelcade-version

echo "Cleaning Up..."
cd ${INSTALLPATH}

if [[ -f master.zip ]]; then
    rm master.zip
fi

if [[ -f jdk-aarch64.zip ]]; then
    rm jdk-aarch64.zip
fi

if [[ -f jdk-aarch32.zip ]]; then
    rm jdk-aarch32.zip
fi

if [[ -f jdk-x86-32.zip ]]; then
    rm jdk-x86-32.zip
fi

if [[ -f jdk-x86-64.zip ]]; then
    rm jdk-x86-64.zip
fi

if [[ -d ${INSTALLPATH}ptemp ]]; then
    rm -r ${INSTALLPATH}ptemp
fi

echo ""
echo "**** INSTALLATION COMPLETE ****"
install_succesful=true
touch ${INSTALLPATH}pixelcade/system/.initial-date

echo " "
echo "INSTALLATION COMPLETE , please now reboot and then Pixelcade will be controlled by Batocera"
