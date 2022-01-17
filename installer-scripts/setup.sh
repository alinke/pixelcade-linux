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
version=6  #increment this as the script is updated

cat << "EOF"
       _          _               _
 _ __ (_)_  _____| | ___ __ _  __| | ___
| '_ \| \ \/ / _ \ |/ __/ _` |/ _` |/ _ \
| |_) | |>  <  __/ | (_| (_| | (_| |  __/
| .__/|_/_/\_\___|_|\___\__,_|\__,_|\___|
|_|
EOF

echo "       Pixelcade for RetroPie : Installer Version $version    "
echo ""
echo "This script will install Pixelcade in your /home/pi folder"
echo "${red}IMPORTANT:${white} This script will work on Pi 3 and Pi 4 devices"
echo "Plese ensure you have at least 800 MB of free disk space in /home/pi"
echo "Now connect Pixelcade to a free USB port on your device"
echo "Ensure the toggle switch on the Pixelcade board is pointing towards USB and not BT"
echo "Grab a coffee or tea as this installer will take around 15 minutes"

INSTALLPATH="/home/pi/"

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
else
   echo "${red}Sorry, neither Linux Stretch, Linux Buster, or Ubuntu were detected, exiting..."
   exit 1
fi

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
  echo "Backing up your artwork modifications..."

  if [[ -f "${INSTALLPATH}pixelcade/system/.initial-date" ]]; then #our initial date stamp file is there
     cd ${INSTALLPATH}pixelcade
     find . -not -name "*.rgb565" -not -name "pixelcade-version" -not -name "*.txt" -not -name "decoded" -not -name "*.ini" -not -name "*.csv" -not -name "*.log" -not -name "*.sh" -not -name "*.zip" -not -name "*.git" -newer ${INSTALLPATH}pixelcade/system/.initial-date -print0 | sed "s/'/\\\'/" | xargs -0 tar --no-recursion -cf ${INSTALLPATH}user-modified-pixelcade-artwork/changed.tgz
     #unzip the file
     cd "${INSTALLPATH}user-modified-pixelcade-artwork"
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
  rsync -avruh --exclude '*.jar' --exclude '*.csv' --exclude '*.ini' --exclude '*.log' --exclude '*.cfg' --exclude emuelec --exclude batocera --exclude recalbox --progress ${INSTALLPATH}pixelcade-master/. ${INSTALLPATH}pixelcade/ #this is going to reset the last updated date
  # ok so now copy back in here the files from ptemp

  if [[ -f "${INSTALLPATH}pixelcade/system/.initial-date" ]]; then
     echo "Copying your modified artwork..."
     cp -f -r -v "${INSTALLPATH}user-modified-pixelcade-artwork/." "${INSTALLPATH}pixelcade/"
  fi

  echo "Cleaning up, this will take a bit..."
  rm -r ${INSTALLPATH}pixelcade-master
  rm ${INSTALLPATH}master.zip

  cd ${INSTALLPATH}pixelcade
  java -jar pixelweb.jar -b & #run pixelweb in the background\
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
   find . -not -name "*.rgb565" -not -name "pixelcade-version" -not -name "*.txt" -not -name "decoded" -not -name "*.ini" -not -name "*.csv" -not -name "*.log" -not -name "*.sh" -not -name "*.zip" -newer ${INSTALLPATH}pixelcade/system/.initial-date -print0 | sed "s/'/\\\'/" | xargs -0 tar --no-recursion -cf ${INSTALLPATH}user-modified-pixelcade-artwork/changed.tgz
   #unzip the file
   cd "${INSTALLPATH}user-modified-pixelcade-artwork"
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
   cp -f -r -v "${INSTALLPATH}user-modified-pixelcade-artwork/." "${INSTALLPATH}pixelcade/"
fi

echo "Cleaning up, this will take a bit..."
rm -r ${INSTALLPATH}pixelcade-master
rm ${INSTALLPATH}master.zip

cd ${INSTALLPATH}pixelcade
PIXELCADE_PRESENT=true
}

#******************* MAIN SCRIPT START ******************************
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

killall java #need to stop pixelweb.jar if already running

# let's check the version and also prompt user if they want to do an artwork update if pixelcade alreaady there
if [[ -d "${INSTALLPATH}pixelcade" ]]; then
    if [[ -f "${INSTALLPATH}pixelcade/pixelcade-version" ]]; then
      echo "Existing Pixelcade installation detected, checking version..."
      read -r currentVersion<${INSTALLPATH}pixelcade/pixelcade-version
      if [[ $currentVersion -lt $version ]]; then
            echo "Older Pixelcade version detected, now upgrading..."
            while true; do
                read -p "You've got an older version of Pixelcade software, type y to upgrade both your Pixelcade software and get the latest Pixelcade artwork? (y/n) " yn
                case $yn in
                    [Yy]* ) updateartworkandsoftware; break;;
                    [Nn]* ) exit; break;;
                    * ) echo "Please answer y or n";;
                esac
            done
      else
            while true; do
                read -p "Your Pixelcade software vesion is up to date. Type y to get the latest Pixelcade artwork (y/n) " yn
                case $yn in
                    [Yy]* ) updateartwork; break;;
                    [Nn]* ) exit; break;;
                    * ) echo "Please answer y or n";;
                esac
            done
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
        echo "${red}Sorry, neither Linux Stretch or Linux Buster was detected, exiting..."
        exit 1
    fi
fi

echo "${yellow}Installing Git...${white}"
sudo apt -y install git

# this is where pixelcade will live

echo "${yellow}Installing Pixelcade from GitHub Repo...${white}"
cd /home/pi
git clone --depth 1 https://github.com/alinke/pixelcade.git
cd /home/pi/pixelcade
git config user.email "sample@sample.com"
git config user.name "sample"

mkdir ${INSTALLPATH}ptemp
cd ${INSTALLPATH}ptemp
if [[ ! -d ${INSTALLPATH}ptemp/pixelcade-linux ]]; then
    sudo rm -r ${INSTALLPATH}ptemp/pixelcade-linux
fi
git clone --depth 1 https://github.com/alinke/pixelcade-linux.git

if [[ ! -d ${INSTALLPATH}.emulationstation/scripts ]]; then #does the ES scripts folder exist, make it if not
    mkdir ${INSTALLPATH}.emulationstation/scripts
fi

cp -a -f ${INSTALLPATH}ptemp/pixelcade-linux/retropie/scripts ${INSTALLPATH}.emulationstation #note this will overwrite existing scripts
find ${INSTALLPATH}.emulationstation/scripts -type f -iname "*.sh" -exec chmod +x {} \; #make all the scripts executble

#copy over hi2txt, this is for high score scrolling
cp -r -f ${INSTALLPATH}ptemp/pixelcade-linux/hi2txt ${INSTALLPATH} #for high scores

#copy over the patched emulationstation and resources folder to /usr/bin, in the future add a check here if the RetroPie team ever incorporates the patch
if [ "$pi4" = true ] ; then
  sudo cp -a -f ${INSTALLPATH}ptemp/pixelcade-linux/retropie/pi4/emulationstation /usr/bin
  sudo cp -a -f ${INSTALLPATH}ptemp/pixelcade-linux/retropie/pi4/resources /usr/bin
  sudo chmod +x /usr/bin/emulationstation
fi

if [ "$pi3" = true ] ; then
  sudo cp -a -f ${INSTALLPATH}ptemp/pixelcade-linux/retropie/pi3/emulationstation /usr/bin
  sudo cp -a -f ${INSTALLPATH}ptemp/pixelcade-linux/retropie/pi3/resources /usr/bin
  sudo chmod +x /usr/bin/emulationstation
fi

# set the RetroPie logo as the startup marquee
sed -i 's/startupLEDMarqueeName=arcade/startupLEDMarqueeName=retropie/' ${INSTALLPATH}pixelcade/settings.ini
# need to remove a few lines in console.csv
sed -i '/all,mame/d' ${INSTALLPATH}pixelcade/console.csv
sed -i '/favorites,mame/d' ${INSTALLPATH}pixelcade/console.csv
sed -i '/recent,mame/d' ${INSTALLPATH}pixelcade/console.csv

if [ "$retropie" = true ] ; then
    # let's check if autostart.sh already has pixelcade added and if so, we don't want to add it twice
    #cd /opt/retropie/configs/all/
    if cat /opt/retropie/configs/all/autostart.sh | grep -q 'pixelcade'; then
      echo "${yellow}Pixelcade already added to autostart.sh, skipping...${white}"
    else
      echo "${yellow}Adding Pixelcade /opt/retropie/configs/all/autostart.sh...${white}"
      sudo sed -i '/^emulationstation.*/i cd /home/pi/pixelcade && java -jar pixelweb.jar -b &' /opt/retropie/configs/all/autostart.sh #insert this line before emulationstation #auto
      #sudo sed -i '/^emulationstation.*/i sleep 10 && cd /home/pi/pixelcade/system && ./pixelcade-startup.sh' /opt/retropie/configs/all/autostart.sh #insert this line before emulationstation #auto
      if [ "$attractmode" = true ] ; then
          echo "${yellow}Adding Pixelcade for Attract Mode to /opt/retropie/configs/all/autostart.sh...${white}"
          sudo sed -i '/^attract.*/i cd /home/pi/pixelcade && java -jar pixelweb.jar -b &' /opt/retropie/configs/all/autostart.sh #insert this line before attract #auto
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
   rm master.zip
fi
rm setup.sh
sudo rm -r ${INSTALLPATH}ptemp

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
      read -p "Reboot Now? (y/n)" yn
      case $yn in
          [Yy]* ) reboot; break;;
          [Nn]* ) echo "Please reboot when you get a chance" && exit;;
          * ) echo "Please answer yes or no.";;
      esac
  done
fi
