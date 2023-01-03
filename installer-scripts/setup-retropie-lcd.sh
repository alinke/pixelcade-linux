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
version=8  #increment this as the script is updated
es_minimum_version=2.11.0
es_version=default

cat << "EOF"
       _          _               _
 _ __ (_)_  _____| | ___ __ _  __| | ___
| '_ \| \ \/ / _ \ |/ __/ _` |/ _` |/ _ \
| |_) | |>  <  __/ | (_| (_| | (_| |  __/
| .__/|_/_/\_\___|_|\___\__,_|\__,_|\___|
|_|
EOF

echo "       Pixelcade LCD for RetroPie : Installer Version $version    "
echo ""
echo "This script will install Pixelcade in your /home/pi folder"
echo "${red}IMPORTANT:${white} This script will work on Pi 3 and Pi 4 devices"

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
        read -p "${red}[IMPORTANT] Pixelcade needs EmulationStation version $es_minimum_version or higher, type y to upgrade your RetroPie and EmulationStation now and then choose "Update" from the RetroPie GUI menu(y/n)${white}" yn
        case $yn in
          [Yy]* ) sudo ~/RetroPie-Setup/retropie_setup.sh; break;;
          [Nn]* ) echo "${yellow}Continuing Pixelcade installation without RetroPie update, NOT RECOMMENDED${white}"; break;;
            * ) echo "Please answer y or n";;
        esac
    done
else
  echo "${green}Your EmulationStation version $es_version is good & meets the minimum EmulationStation version $es_minimum_version that is required for Pixelcade${white}"
fi

#******************* MAIN SCRIPT START ******************************

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

if [[ -d ${INSTALLPATH}ptemp ]]; then
    rm -r ${INSTALLPATH}ptemp
fi

mkdir ${INSTALLPATH}ptemp
cd ${INSTALLPATH}ptemp

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
#copy over the patched emulationstation and resources folder to /usr/bin, in the future add a check here if the RetroPie team ever incorporates the patch

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
sed -i 's/port=COM99/port=COM89/' ${INSTALLPATH}pixelcade/settings.ini
sed -i 's/CYCLEMODE=yes/CYCLEMODE=no/' ${INSTALLPATH}.emulationstation/scripts/game-start/01-pixelcade.sh #cycle mode won't work with LCD

# no longer need these
sed -i '/all,mame/d' ${INSTALLPATH}pixelcade/console.csv
sed -i '/favorites,mame/d' ${INSTALLPATH}pixelcade/console.csv
sed -i '/recent,mame/d' ${INSTALLPATH}pixelcade/console.csv
#add to retropie startup
if [ "$retropie" = true ] ; then
    # let's check if autostart.sh already has pixelcade added and if so, we don't want to add it twice

    # for existing users, let's add the -s flag
    if cat /opt/retropie/configs/all/autostart.sh | grep -w 'cd /home/pi/pixelcade && java -jar pixelweb.jar -b &'; then
      echo "${yellow}Setting Pixelcade to silent mode...${white}"
      sed -i '/cd \/home\/pi\/pixelcade && java -jar pixelweb.jar -b &/d' /opt/retropie/configs/all/autostart.sh #delete the line
      sudo sed -i '/^emulationstation.*/i cd /home/pi/pixelcade && java -jar pixelweb.jar -b -s &' /opt/retropie/configs/all/autostart.sh #replace it with -s
    fi

    if cat /opt/retropie/configs/all/autostart.sh | grep -q 'pixelcade'; then
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
   rm master.zip
fi
rm setup.sh
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
