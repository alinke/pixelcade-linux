#!/bin/bash
stretch_os=false
buster_os=false
ubuntu_os=false
jessie_os=false
retropie=false
pizero=false
pi4=false
pi3=false
java_installed=false
install_succesful=false
PIXELCADE_PRESENT=false #did we do an upgrade and pixelcade was already there
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
upgrade_artwork=false
upgrade_software=false
version=11  #increment this as the script is updated
es_minimum_version=2.11.0
es_version=default
NEWLINE=$'\n'

#curl -kLO -H "Cache-Control: no-cache" https://raw.githubusercontent.com/alinke/pixelcade-linux/main/installer-scripts/setup-retropie.sh && chmod +x setup-retropie.sh && ./setup-retropie.sh

cat << "EOF"
       _          _               _
 _ __ (_)_  _____| | ___ __ _  __| | ___
| '_ \| \ \/ / _ \ |/ __/ _` |/ _` |/ _ \
| |_) | |>  <  __/ | (_| (_| | (_| |  __/
| .__/|_/_/\_\___|_|\___\__,_|\__,_|\___|
|_|
EOF

echo "       Pixelcade LED for RetroPie : Installer Version $version    "
echo ""
echo "This script will install Pixelcade LED software in $HOME/pixelcade"
echo "Pi 3 and Pi 4 family of devices are supported"
echo "Plese ensure you have at least 800 MB of free disk space in $HOME"
echo "Now connect Pixelcade to a free USB port on your device"
echo "Ensure the toggle switch on the Pixelcade board is pointing towards USB and not BT"
echo "Grab a coffee or tea as this installer will take between 10 and 20 minutes"

INSTALLPATH=$HOME"/"

# let's see what installation we have
if lsb_release -a | grep -q 'stretch'; then
        echo "${yellow}Linux Stretch Detected${white}"
        stretch_os=true
        echo "Installing curl..."
        sudo apt install -y curl
elif cat /etc/os-release | grep -q 'stretch'; then
       echo "${yellow}Linux Stretch Detected${white}"
       stretch_os=true
       echo "Installing curl..."
       sudo apt install -y curl
elif cat /etc/os-release | grep -q 'jessie'; then
      echo "${yellow}Linux Jessie Detected${white}"
      jessie_os=true
      echo "Installing curl..."
      sudo apt install -y curl
elif lsb_release -a | grep -q 'buster'; then
      echo "${yellow}Linux Buster Detected${white}"
      buster_os=true
      echo "Installing curl..."
      sudo apt install -y curl
elif cat /etc/os-release | grep -q 'buster'; then
      echo "${yellow}Linux Buster Detected${white}"
      buster_os=true
      echo "Installing curl..."
      sudo apt install -y curl
elif lsb_release -a | grep -q 'ubuntu'; then
      echo "${yellow}Ubuntu Linux Detected${white}"
      ubuntu_os=true
      echo "Installing curl..."
      sudo apt install -y curl
fi

#Now we need to check if we have the ES version that includes the game-select and system-select events
#ES verion Data Points
# Jan '23 BEFORE Pi updater: Version 2.10.1rp, built Dec 26 2021 - 16:25:37
# Jan '23 on Pi 4 after Pi updater: Version 2.11.0rp, built Dec 10 2022 - 12:26:20
# so looks like we need 2.11

es_version=$(cd /usr/bin && ./emulationstation -h | grep 'Version')
es_version=${es_version#*Version } #get onlly the line with Version
es_version=${es_version%,*} # keep all text before the comma // Version 2.10.1rp, built Dec 26 2021 - 16:25:37, built Dec 26 2021 - 16:25:37
es_version_numeric=$(echo $es_version | sed 's/[^0-9.]*//g') #now remove all letters // Version 2.10.1rp ==> 2.10.1
es_version_result=$(echo $es_version_numeric $es_minimum_version | awk '{if ($1 >= $2) print "pass"; else print "fail"}')

if [[ ! $es_version_result == "pass" ]]; then #we need to update to the latest EmulationStation to get the new game-select and system-select events
    while true; do
        read -p "${red}[IMPORTANT] Pixelcade needs EmulationStation version $es_minimum_version or higher${NEWLINE}You have EmulationStation version $es_version_numeric${NEWLINE}Type y to upgrade your RetroPie and EmulationStation now${NEWLINE}And then choose < Update > from the upcoming RetroPie GUI menu (y/n)${white}" yn
        case $yn in
          [Yy]* ) sudo ~/RetroPie-Setup/retropie_setup.sh; break;;
          [Nn]* ) echo "${yellow}Continuing Pixelcade installation without RetroPie update, NOT RECOMMENDED${white}"; break;;
            * ) echo "Please answer y or n";;
        esac
    done
else
  echo "${green}Your EmulationStation version $es_version is good & meets the minimum EmulationStation version $es_minimum_version that is required for Pixelcade${white}"
fi

updateartwork() {  #this is needed for rom names with spaces

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
    #let's get the files that have been modified since the initial install as they would have been overwritten

    #find all files that are newer than .initial-date and put them into /ptemp/modified.tgz
    echo "Backing up any artwork that you have added or changed..."

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
    echo "${yellow}Copying over new artwork...${white}"
    # not that because of github the file dates of pixelcade-master will be today's date and thus newer than the destination
    # now let's overwrite with the pixelcade repo and because the repo files are today's date, they will be newer and copy over
    rsync -avruh --exclude '*.jar' --exclude '*.csv' --exclude '*.ini' --exclude '*.log' --exclude '*.cfg' --exclude '*.git' --exclude emuelec --exclude batocera --exclude recalbox --progress ${INSTALLPATH}pixelcade-master/. ${INSTALLPATH}pixelcade/ #this is going to reset the last updated date
    # ok so now copy back in here the files from ptemp

    if [[ -f "${INSTALLPATH}pixelcade/system/.initial-date" ]]; then
       echo "Copying your modified artwork..."
       cp -f -r -v "${INSTALLPATH}pixelcade/user-modified-pixelcade-artwork/." "${INSTALLPATH}pixelcade/"
    fi

    echo "${yellow}Cleaning up, this will take a bit...${white}"
    rm -r ${INSTALLPATH}pixelcade-master
    rm ${INSTALLPATH}master.zip

    cd ${INSTALLPATH}pixelcade

    ${INSTALLPATH}pixelcade/jdk/bin/java -jar pixelweb.jar -b & #run pixelweb in the background\
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

#******************* MAIN SCRIPT START ******************************
if ! command -v lsusb  &> /dev/null; then
    echo "${red}lsusb command not be found so cannot check if Pixelcade is USB connected${white}"
else
   if lsusb | grep -q '1b4f:0008'; then
      echo "${yellow}Pixelcade LED Marquee Detected${white}"
   elif lsusb | grep -q '2e8a:1050'; then 
      echo "${yellow}Pixelcade LED Marquee Detected${white}"
   else  
      echo "${red}Sorry, Pixelcade LED Marquee was not detected, pleasse ensure Pixelcade is USB connected to your Pi and the toggle switch on the Pixelcade board is pointing towards USB, exiting...${white}"
      exit 1
   fi
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

#let's check if retropie is installed
if [[ -f "/opt/retropie/configs/all/autostart.sh" ]]; then
  echo "RetroPie installation detected..."
  retropie=true
else
   echo "${yellow}RetroPie is not installed..."
fi

if cat /proc/device-tree/model | grep -q 'Pi 4'; then
   echo "${yellow}Raspberry Pi 4 detected..."
   pi4=true
fi

if cat /proc/device-tree/model | grep -q 'Raspberry Pi 3'; then
   echo "${yellow}Raspberry Pi 3 detected..."
   pi3=true
fi

if cat /proc/device-tree/model | grep -q 'Pi Zero W'; then
   echo "${yellow}Raspberry Pi Zero detected..."
   pizero=true
fi

if type -p java ; then
  echo "${yellow}Java already installed, skipping..."
  java_installed=true
elif [[ -n "$JAVA_HOME" ]] && [[ -x "$JAVA_HOME/bin/java" ]];  then
  echo "${yellow}Java already installed, skipping..."
  java_installed=true
else
   echo "${yellow}Java not found, let's install Java...${white}"
   java_installed=false
fi

if cat ~/.bashrc |  grep "^[^#;]" | grep -q 'pixelcade'; then  #export PATH="$HOME/pixelcade/jdk/bin:$PATH"
    echo "${yellow}Removing the light Java that was bundled with the newer Pixelcade software, we'll need to re-install Java...${white}"
    sed -e '/pixelcade/ s/^#*/#/' -i ~/.bashrc #comment out the line
    java_installed=false #we'll need to re-install java
fi

# we have all the pre-requisites so let's continue
sudo apt-get -y update

if [ "$java_installed" = false ] ; then #only install java if it doesn't exist
    if [ "$pizero" = true ] ; then
      echo "${yellow}Installing Zulu Java 8...${white}"
      sudo mkdir /opt/jdk/
      cd /opt/jdk
      sudo curl -kLO http://pixelcade.org/pi/zulu8.46.0.225-ca-jdk8.0.252-linux_aarch32hf.tar.gz
      sudo tar -xzvf zulu8.46.0.225-ca-jdk8.0.252-linux_aarch32hf.tar.gz
      sudo update-alternatives --install /usr/bin/java java /opt/jdk/zulu8.46.0.225-ca-jdk8.0.252-linux_aarch32hf/bin/java 252
      sudo update-alternatives --install /usr/bin/javac javac /opt/jdk/zulu8.46.0.225-ca-jdk8.0.252-linux_aarch32hf/bin/javac 252
    elif [ "$stretch_os" = true ]; then
      #sudo apt-get -y install oracle-java8-jdk
      echo "${yellow}Installing Zulu Java 8...${white}"
      sudo mkdir /opt/jdk/
      cd /opt/jdk
      sudo curl -kLO http://pixelcade.org/pi/zulu8.46.0.225-ca-jdk8.0.252-linux_aarch32hf.tar.gz
      sudo tar -xzvf zulu8.46.0.225-ca-jdk8.0.252-linux_aarch32hf.tar.gz
      sudo update-alternatives --install /usr/bin/java java /opt/jdk/zulu8.46.0.225-ca-jdk8.0.252-linux_aarch32hf/bin/java 252
      sudo update-alternatives --install /usr/bin/javac javac /opt/jdk/zulu8.46.0.225-ca-jdk8.0.252-linux_aarch32hf/bin/javac 252
    elif [ "$buster_os" = true ]; then #pi zero is arm6 and cannot run the normal java :-( so have to get this special one
      echo "${yellow}Installing Zulu Java 8...${white}"
      sudo mkdir /opt/jdk/
      cd /opt/jdk
      sudo curl -kLO http://pixelcade.org/pi/zulu8.46.0.225-ca-jdk8.0.252-linux_aarch32hf.tar.gz
      sudo tar -xzvf zulu8.46.0.225-ca-jdk8.0.252-linux_aarch32hf.tar.gz
      sudo update-alternatives --install /usr/bin/java java /opt/jdk/zulu8.46.0.225-ca-jdk8.0.252-linux_aarch32hf/bin/java 252
      sudo update-alternatives --install /usr/bin/javac javac /opt/jdk/zulu8.46.0.225-ca-jdk8.0.252-linux_aarch32hf/bin/javac 252
    elif [ "$jessie_os" = true ]; then #pi zero is arm6 and cannot run the normal java :-( so have to get this special one
      echo "${yellow}Installing Zulu Java 8...${white}"
      sudo mkdir /opt/jdk/
      cd /opt/jdk
      sudo curl -kLO http://pixelcade.org/pi/zulu8.46.0.225-ca-jdk8.0.252-linux_aarch32hf.tar.gz
      sudo tar -xzvf zulu8.46.0.225-ca-jdk8.0.252-linux_aarch32hf.tar.gz
      sudo update-alternatives --install /usr/bin/java java /opt/jdk/zulu8.46.0.225-ca-jdk8.0.252-linux_aarch32hf/bin/java 252
      sudo update-alternatives --install /usr/bin/javac javac /opt/jdk/zulu8.46.0.225-ca-jdk8.0.252-linux_aarch32hf/bin/javac 252
    elif [ "$ubuntu_os" = true ]; then
        echo "${yellow}Installing Java OpenJDK 11...${white}"
        sudo apt-get -y install openjdk-11-jre
    else
      echo "${yellow}Installing Zulu Java 8...${white}"
      sudo mkdir /opt/jdk/
      cd /opt/jdk
      sudo curl -kLO http://pixelcade.org/pi/zulu8.46.0.225-ca-jdk8.0.252-linux_aarch32hf.tar.gz
      sudo tar -xzvf zulu8.46.0.225-ca-jdk8.0.252-linux_aarch32hf.tar.gz
      sudo update-alternatives --install /usr/bin/java java /opt/jdk/zulu8.46.0.225-ca-jdk8.0.252-linux_aarch32hf/bin/java 252
      sudo update-alternatives --install /usr/bin/javac javac /opt/jdk/zulu8.46.0.225-ca-jdk8.0.252-linux_aarch32hf/bin/javac 252
    fi
fi

echo "${yellow}Installing Git...${white}"
sudo apt -y install git

# this is where pixelcade will live but if it's already there, then we need to do a refresh and not a git clone

if [ "$PIXELCADE_PRESENT" = false ] ; then       # if true, then it means we already did the refresh above so skip this
  echo "${yellow}Installing Pixelcade from GitHub Repo...${white}"
  cd /home/pi
  git clone --depth 1 https://github.com/alinke/pixelcade.git
  cd /home/pi/pixelcade
  git config user.email "sample@sample.com"
  git config user.name "sample"
fi

if [[ -d ${INSTALLPATH}ptemp ]]; then
    sudo rm -r ${INSTALLPATH}ptemp
fi

mkdir ${INSTALLPATH}ptemp
cd ${INSTALLPATH}ptemp
if [[ ! -d ${INSTALLPATH}ptemp/pixelcade-linux-main ]]; then
    sudo rm -r ${INSTALLPATH}ptemp/pixelcade-linux-main
fi

echo "${yellow}Installing Pixelcade System Files...${white}"
#get the Pixelcade system files
wget https://github.com/alinke/pixelcade-linux/archive/refs/heads/main.zip
unzip main.zip
#git clone --depth 1 https://github.com/alinke/pixelcade-linux.git #we could do git clone here but batocera doesn't support git so let's be consistent with the code

if [[ ! -d ${INSTALLPATH}.emulationstation/scripts ]]; then #does the ES scripts folder exist, make it if not
    mkdir ${INSTALLPATH}.emulationstation/scripts
fi

#pixelcade core files
echo "${yellow}Installing Pixelcade Core Files...${white}"
cp -f ${INSTALLPATH}ptemp/pixelcade-linux-main/core/* ${INSTALLPATH}pixelcade #the core Pixelcade files, no sub-folders in this copy
#pixelcade system folder
cp -a -f ${INSTALLPATH}ptemp/pixelcade-linux-main/system ${INSTALLPATH}pixelcade #system folder, .initial-date will go in here
#pixelcade scripts for emulationstation events
echo "${yellow}Installing Pixelcade EmulationStation Scripts...${white}"
sudo cp -a -f ${INSTALLPATH}ptemp/pixelcade-linux-main/retropie/scripts ${INSTALLPATH}.emulationstation #note this will overwrite existing scripts
sudo find ${INSTALLPATH}.emulationstation/scripts -type f -iname "*.sh" -exec chmod +x {} \; #make all the scripts executble
#hi2txt for high score scrolling
echo "${yellow}Installing hi2txt for High Scores...${white}"
cp -r -f ${INSTALLPATH}ptemp/pixelcade-linux-main/hi2txt ${INSTALLPATH}pixelcade #for high scores

#now lets check if the user also has attractmode installed
if [[ -d "//home/pi/.attract" ]]; then
  echo "${yellow}Attract Mode front end detected, installing Pixelcade plug-in for Attract Mode...${white}"
  attractmode=true
  cd /home/pi/.attract
  #sudo cp -r /home/pi/pixelcade/attractmode-plugin/Pixelcade /home/pi/.attract/plugins
  cp -r ${INSTALLPATH}ptemp/pixelcade-linux-main/attractmode-plugin/Pixelcade /home/pi/.attract/plugins
    #let's also enable the plug-in saving the user from having to do that
  if cat attract.cfg | grep -q 'Pixelcade'; then
     echo "${yellow}Pixelcade Attract Mode plug-in already in attract.cfg, please ensure it's enabled from the Attract Mode GUI${white}"
  else
     echo "${yellow}Enabling Pixelcade Attract Mode plug-in in attract.cfg...${white}"
     sed -i -e '$a\' attract.cfg
     sed -i -e '$a\' attract.cfg
     sudo sed -i '$ a plugin\tPixelcade' attract.cfg
     sudo sed -i '$ a enabled\tyes' attract.cfg
  fi
  #don't forget to make the scripts executable
  sudo chmod +x /home/pi/.attract/plugins/Pixelcade/scripts/update_pixelcade.sh
  sudo chmod +x /home/pi/.attract/plugins/Pixelcade/scripts/display_marquee_text.sh
else
  attractmode=false
  echo "${yellow}Attract Mode front end is not installed..."
fi
# set the RetroPie logo as the startup marquee
sed -i 's/startupLEDMarqueeName=arcade/startupLEDMarqueeName=retropie/' ${INSTALLPATH}pixelcade/settings.ini
# no longer need these
sed -i '/all,mame/d' ${INSTALLPATH}pixelcade/console.csv
sed -i '/favorites,mame/d' ${INSTALLPATH}pixelcade/console.csv
sed -i '/recent,mame/d' ${INSTALLPATH}pixelcade/console.csv
#add to retropie startup
if [ "$retropie" = true ] ; then

    # for existing users, let's add the -s flag
    if cat /opt/retropie/configs/all/autostart.sh | grep "^[^#;]" | grep -w 'cd /home/pi/pixelcade && java -jar pixelweb.jar -b &'; then
      echo "${yellow}Setting Pixelcade to silent mode...${white}"
      sed -i '/cd \/home\/pi\/pixelcade && java -jar pixelweb.jar -b &/d' /opt/retropie/configs/all/autostart.sh #delete the line
      sudo sed -i '/^emulationstation.*/i cd /home/pi/pixelcade && java -jar pixelweb.jar -b -s &' /opt/retropie/configs/all/autostart.sh #replace it with -s
    fi

    # let's check if the newer pixelweb was installed which means here the user is trying to downgrade
    if cat /opt/retropie/configs/all/autostart.sh | grep "^[^#;]" | grep -q 'pixelweb -image'; then  #ignore any comment line, user has the new pixelweb so we need to commend out this line
        echo "${yellow}Backing up autostart.sh to autostart.bak${white}"
        cd /opt/retropie/configs/all && cp autostart.sh autostart.bak #let's make a backup of autostart.sh since we are modifying it
        echo "${yellow}Commenting out new pixelweb version${white}"
        sed -e '/pixelweb -image/ s/^#*/#/' -i /opt/retropie/configs/all/autostart.sh #comment out the line
    fi

    # let's check if autostart.sh already has pixelcade added and if so, we don't want to add it twice
    if cat /opt/retropie/configs/all/autostart.sh | grep "^[^#;]" | grep -q 'pixelcade'; then
      echo "${yellow}Pixelcade already added to autostart.sh, skipping...${white}"
    else
      echo "${yellow}Adding Pixelcade /opt/retropie/configs/all/autostart.sh...${white}"
      sudo sed -i '/^emulationstation.*/i cd /home/pi/pixelcade && java -jar pixelweb.jar -b -s &' /opt/retropie/configs/all/autostart.sh #insert this line before emulationstation #auto
      if [ "$attractmode" = true ] ; then
          echo "${yellow}Adding Pixelcade for Attract Mode to /opt/retropie/configs/all/autostart.sh...${white}"
          sudo sed -i '/^attract.*/i cd /home/pi/pixelcade && java -jar pixelweb.jar -b -s &' /opt/retropie/configs/all/autostart.sh #insert this line before attract #auto
      fi
    fi

    echo "${yellow}Installing Fonts...${white}"
    cd /home/pi/pixelcade
    mkdir /home/pi/.fonts
    sudo cp /home/pi/pixelcade/fonts/*.ttf /home/pi/.fonts
    sudo apt -y install font-manager
    sudo fc-cache -v -f
else #there is no retropie so we need to add pixelcade using .service instead
  echo "${yellow}Installing Fonts...${white}"
  cd /home/pi/pixelcade
  mkdir /home/pi/.fonts
  sudo cp /home/pi/pixelcade/fonts/*.ttf /home/pi/.fonts
  sudo apt -y install font-manager
  sudo fc-cache -v -f
  echo "${yellow}Adding Pixelcade to Startup...${white}"
  cd /home/pi/pixelcade/system
  sudo chmod +x /home/pi/pixelcade/system/autostart.sh
  sudo cp pixelcade.service /etc/systemd/system/pixelcade.service
  #to do add check if the service is already running
  sudo systemctl start pixelcade.service
  sudo systemctl enable pixelcade.service
fi

if [[ -d "/etc/udev/rules.d" ]]; then #let's create the udev rule for Pixelcade if the rules.d folder is there
  echo "${yellow}Adding udev rule...${white}"
  sudo wget -O /etc/udev/rules.d/50-pixelcade.rules https://raw.githubusercontent.com/alinke/pixelcade-linux-builds/main/install-scripts/50-pixelcade.rules
  sudo /etc/init.d/udev restart #BUT it seems this takes a re-start and does not work immediately
fi

echo "Checking for Pixelcade LCDs..."
java -jar pixelcadelcdfinder.jar -nogui #check for Pixelcade LCDs

cd ${INSTALLPATH}pixelcade
java -jar pixelweb.jar -b & #run pixelweb in the background\

# let's send a test image and see if it displays
sleep 8
cd ${INSTALLPATH}pixelcade
java -jar pixelcade.jar -m stream -c mame -g 1941

#let's write the version so the next time the user can try and know if he/she needs to upgrade
echo $version > ${INSTALLPATH}pixelcade/pixelcade-version

echo "Cleaning Up..."
cd ${INSTALLPATH}
if [[ -d "${INSTALLPATH}pixelcade-master" ]]; then #if the user killed the installer mid-stream,it's possible this file is still there so let's remove it to be sure before downloading, otherwise wget will download and rename to .1
   sudo rm master.zip
fi
sudo rm setup.sh
sudo rm -r ${INSTALLPATH}ptemp

sudo chown -R pi: /home/pi/pixelcade #this is our fail safe in case the user did a sudo ./setup.sh which seems to be needed on some pre-made Pi images
#do we need to do for ES scripts too?

#let's just confirm java is installed
if type -p java ; then
  echo "${yellow}Confirmed Java is installed and working${white}"
else
  echo "${red}[CRITICAL ERROR] Java is not installed. Pixelcade cannot run without Java. Most likely either the Java source download is no longer valid or you ran out of disk space.${white}"
fi

touch ${INSTALLPATH}pixelcade/system/.initial-date #this is for the user artwork backup

echo "INSTALLATION COMPLETE , please now reboot and then the Pixelcade logo should be display on Pixelcade"
install_succesful=true

echo " "
while true; do
    read -p "Is the 1941 Game Logo Displaying on Pixelcade Now? (y/n)" yn
    case $yn in
        [Yy]* ) echo "INSTALLATION COMPLETE , please now reboot and then Pixelcade will be controlled by RetroPie" && install_succesful=true; break;;
        [Nn]* ) echo "It may still be ok and try rebooting, you can also refer to https://pixelcade.org/download-pi/ for troubleshooting steps" && exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

if [ "$install_succesful" = true ] ; then
  while true; do
      read -p "Would you like to reboot now? (y/n)" yn
      case $yn in
          [Yy]* ) sudo reboot; break;;
          [Nn]* ) echo "Please reboot when you get a chance" && exit;;
          * ) echo "Please answer yes or no.";;
      esac
  done
fi
