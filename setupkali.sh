#!/bin/bash

# setupkali.sh  Author: DARK (UCYBERS)
# git clone https://github.com/UCYBERS/setupkali
# Usage: sudo ./setupkali.sh  (defaults to the menu system)
# command line arguments are valid, only catching 1 argument
#
# Full Revision history can be found in changelog.txt
# Standard Disclaimer: Author assumes no liability for any damage

# revision var
revision="1.0.0"


RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
MAGENTA='\033[35m'
CYAN='\033[36m'
WHITE='\033[37m'
BOLD='\033[1m'
RESET='\033[0m' 

finduser="root"
force=0
silent=""
pyver="3.8"


if ! grep -q "Kali" /etc/os-release; then
    echo -e "${RED}This script is intended to be run on Kali Linux only.${RESET}"
    exit 1
fi


asciiart=$(base64 -d <<< "H4sICP9gsmYAA2xvZ28udHh0AH1OMQ4CMQzb+wqPTJcPoA6c+ACIAclSJcTNIBaE1McTJ1cECxnq
xLFTAz/VGvCHmTTpKVqoEgzoalfSm+7MmJBTb60XWDjNpGbcZ+wZSkppMMrF1edPiT3IdH94IL6u
qIq31TiutPBZBqhM8AjKkScgcMYNm5SF2iKnivYNWTLcb8/lsVxjcXkJTvN5tz8ch6i8ASj+YXlX
AQAA" | gunzip)


echo -e "$asciiart"


echo


install_icons() {
    echo -e "${BLUE}Downloading and installing icons...${RESET}"
    ICONS_URL="https://dl.dropboxusercontent.com/scl/fi/lyshbicrin0i9t76f2h3r/Vibrancy-Kali.tar.gz?rlkey=yg31ho4orsbizb3qw3vbxizlb&st=sv8om9xs"
    ICONS_FILE="/tmp/Vibrancy-Kali.tar.gz"
    
   
    wget -O "$ICONS_FILE" "$ICONS_URL"
    
    
    sudo tar -xzf "$ICONS_FILE" -C /usr/share/icons/
    
   
    sudo -u root gsettings set org.gnome.desktop.interface icon-theme 'Vibrancy-Kali'
    
    echo -e "${GREEN}Icons installed and set successfully.${RESET}"
}


change_to_gnome() {
    echo -e "${BLUE}Updating system and installing GNOME...${RESET}"
    sudo apt update -y
    sudo apt install -y kali-desktop-gnome
    echo -e "${BLUE}Setting GNOME as default session...${RESET}"
   
    echo "1" | sudo update-alternatives --config x-session-manager
    sudo apt purge --autoremove -y kali-desktop-xfce
}


enable_root_login() {
    echo -e "${BLUE}Allowing root login in GDM...${RESET}"
    sudo apt update -y
    sudo apt install -y kali-root-login
    echo -e "${BLUE}Setting root password...${RESET}"
    echo "root:ucybers" | sudo chpasswd
    echo -e "${GREEN}Root login enabled and root password set to 'ucybers'.${RESET}"
}


install_tools_for_root() {
    echo -e "${BLUE}Installing tools for root user...${RESET}"
    sudo apt update -y
    sudo apt install -y terminator leafpad mousepad firefox-esr metasploit-framework burpsuite maltego beef-xss
}


configure_dock_for_root() {
    echo -e "${BLUE}Configuring dock position for root user...${RESET}"
    sudo -u root dbus-launch gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'LEFT'
}


configure_dash_apps() {
    echo -e "${BLUE}Configuring Dash applications for root user...${RESET}"
    sudo -u root dbus-launch gsettings set org.gnome.shell favorite-apps "['terminator.desktop', 'firefox-esr.desktop', 'org.gnome.Nautilus.desktop', 'kali-msfconsole.desktop', 'kali-burpsuite.desktop', 'kali-maltego.desktop', 'kali-beef-start.desktop', 'leafpad.desktop']"
}

change_background() {
    local BACKGROUND_IMAGE="/usr/share/backgrounds/kali/kali-metal-dark-16x9.png"
    
    echo -e "\n  ${GREEN}Changing root user's desktop background...${RESET}"
    
    # تغيير الخلفية لجلسة GNOME للمستخدم الجذر
    sudo -u root gsettings set org.gnome.desktop.background picture-uri "file://$BACKGROUND_IMAGE"
    sudo -u root gsettings set org.gnome.desktop.background picture-uri-dark "file://$BACKGROUND_IMAGE"
    
    echo -e "\n  ${GREEN}Background changed to ${BACKGROUND_IMAGE}${RESET}"
}

fix_sources() {
    echo -e "\n  ${GREEN}Updating APT sources...${RESET}"
    
    # Use sudo to ensure changes are made as the root user
    sudo bash -c 'cat > /etc/apt/sources.list <<EOF
# See https://www.kali.org/docs/general-use/kali-linux-sources-list-repositories/
deb http://http.kali.org/kali kali-last-snapshot main contrib non-free non-free-firmware

# Additional line for source packages
# deb-src http://http.kali.org/kali kali-rolling main contrib non-free non-free-firmware
EOF'
    
    echo -e "\n  ${GREEN}APT sources updated successfully.${RESET}"
}



apt_update() {
    if [ "$(id -u)" -eq 0 ]; then
        echo -e "\n  ${GREEN}running: apt update${RESET}"
        eval apt -y update -o Dpkg::Progress-Fancy="1"
    else
        echo -e "\n  ${RED}Not running as root, skipping apt update.${RESET}"
    fi
}

apt_update_complete() {
    if [ "$(id -u)" -eq 0 ]; then
        echo -e "\n  ${GREEN}apt update - complete${RESET}"
    fi
}

apt_autoremove() {
    if [ "$(id -u)" -eq 0 ]; then
        echo -e "\n  ${GREEN}running: apt autoremove${RESET}"
        eval apt -y autoremove -o Dpkg::Progress-Fancy="1"
    else
        echo -e "\n  ${RED}Not running as root, skipping apt autoremove.${RESET}"
    fi
}

apt_autoremove_complete() {
    if [ "$(id -u)" -eq 0 ]; then
        echo -e "\n  ${GREEN}apt autoremove - complete${RESET}"
    fi
}


remove_kali_undercover() {
    if [ "$(id -u)" -eq 0 ]; then
        echo -e "\n  ${BLUE}Removing kali-undercover package${RESET}"
        apt -y remove kali-undercover
        echo -e "\n  ${GREEN}kali-undercover package removed${RESET}"
    else
        echo -e "\n  ${RED}Not running as root, skipping package removal.${RESET}"
    fi
}

install_packages() {
    echo -e "${BLUE}Installing packages...${RESET}"
    sudo apt -o Dpkg::Progress-Fancy="1" -y install \
        libu2f-udev \
        virt-what \
        neo4j \
        dkms \
        build-essential \
        autogen \
        automake \
        python3-setuptools \
        python3-venv \
        python3-distutils \
        libguestfs-tools \
        cifs-utils \
        dbus-x11
    echo -e "${GREEN}Packages installed successfully.${RESET}"
}


install_python_pip() {
    echo -e "${BLUE}Installing Python pip...${RESET}"
    sudo apt -y install python3-pip
    echo -e "${GREEN}Python pip installed successfully.${RESET}"

    echo -e "${BLUE}Installing Python packages...${RESET}"
    sudo pip3 install pycurl
    echo -e "${GREEN}Python packages installed successfully.${RESET}"
}


update_python3_pip() {
    if [ "$(id -u)" -eq 0 ]; then
        echo -e "\n  ${BLUE}Updating or installing python3 pip...${RESET}"
        apt-get remove --purge -y python3-pip
        apt-get autoremove -y
        wget https://bootstrap.pypa.io/get-pip.py
        python3 get-pip.py
        pip3 install --upgrade pip
        echo -e "\n  ${GREEN}python3 pip updated successfully.${RESET}"
    else
        echo -e "\n  ${RED}Not running as root, skipping python3 pip update.${RESET}"
    fi
}

fix_gedit() {
    section="gedit"
    check=$(whereis gedit | grep -i -c "gedit: /usr/bin/gedit")
    force=1 
    fix_section $section $check $force
    fix_root_connectionrefused
}

fix_section() {
    local section=$1
    local check=$2
    local force=$3

    if [ $check -ne 1 ]; then
        echo -e "\n  ${BLUE}Installing: $section${RESET}"
        sudo -u root apt -o Dpkg::Progress-Fancy="1" -y install $section $silent
    elif [ $force -eq 1 ]; then
        echo -e "\n  ${RED}Reinstalling: $section${RESET}"
        sudo -u root apt -o Dpkg::Progress-Fancy="1" -y reinstall $section $silent
    else
        echo -e "\n  ${GREEN}$section already installed${RESET}"
        echo -e "       Use --force to reinstall"
    fi
}


fix_root_connectionrefused() {
    echo -e "\n  ${BLUE}Adding root to xhost for $finduser display: xhost +SI:localuser:root${RESET}\n"
    sudo -u $finduser xhost +SI:localuser:root
    xhost +SI:localuser:root
    echo -e "\n  ${GREEN}Root added to xhost${RESET}"
}

fix_nmap() {
    echo -e "\n  ${BLUE}Removing old clamav-exec.nse script...${RESET}"
    sudo -u root rm -f /usr/share/nmap/scripts/clamav-exec.nse
    echo -e "\n  ${RED}Removed /usr/share/nmap/scripts/clamav-exec.nse${RESET}"
    
    echo -e "\n  ${BLUE}Downloading updated clamav-exec.nse and http-shellshock.nse scripts...${RESET}"
    sudo -u root wget https://raw.githubusercontent.com/nmap/nmap/master/scripts/clamav-exec.nse -O /usr/share/nmap/scripts/clamav-exec.nse
    sudo -u root wget https://raw.githubusercontent.com/Dewalt-arch/pimpmykali/master/fixed-http-shellshock.nse -O /usr/share/nmap/scripts/http-shellshock.nse
    
    echo -e "\n  ${GREEN}Scripts updated successfully.${RESET}"
}

fix_rockyou() {
    if [ "$(id -u)" -eq 0 ]; then
        echo -e "${BLUE}Fixing rockyou wordlist...${RESET}"
        cd /usr/share/wordlists
        gzip -dqf rockyou.txt.gz
        echo -e "\n  ${GREEN}gunzip /usr/share/wordlists/rockyou.txt.gz completed${RESET}"
    else
        echo -e "${RED}Not running as root, skipping rockyou fix.${RESET}"
    fi
}

fix_theharvester() {
    if [ "$(id -u)" -eq 0 ]; then
        section="theharvester"
        check=$(whereis theharvester | grep -i -c "/usr/bin/theharvester")
        
        if [ $check -ne 1 ]; then
            echo -e "\n  ${BLUE}Installing: $section${RESET}"
            apt -o Dpkg::Progress-Fancy="1" -y install $section
        else
            echo -e "\n  ${GREEN}$section already installed${RESET}"
        fi
    else
        echo -e "${RED}Not running as root, skipping theharvester installation.${RESET}"
    fi
}

disable_power_checkde() {
    if dpkg-query -W -f='${Status}' gnome-shell 2>/dev/null | grep -q "install ok installed"; then
        echo -e "\n  ${GREEN}GNOME is installed on the system${RESET}"
        disable_power_gnome
    else
        echo -e "\n  ${RED}GNOME environment not detected${RESET}"
    fi
}


disable_power_gnome() {
    echo -e "\n  ${GREEN}GNOME detected - Disabling Power Savings${RESET}"
    # ac power
    sudo -u root gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type nothing
    echo -e "  ${GREEN}org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type nothing${RESET}"
    sudo -u root gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 0
    echo -e "  ${GREEN}org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 0${RESET}"
    # battery power
    sudo -u root gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type nothing
    echo -e "  ${GREEN}org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type nothing${RESET}"
    sudo -u root gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout 0
    echo -e "  ${GREEN}org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout 0${RESET}"
    # power button
    sudo -u root gsettings set org.gnome.settings-daemon.plugins.power power-button-action nothing
    echo -e "  ${GREEN}org.gnome.settings-daemon.plugins.power power-button-action nothing${RESET}"
    # idle brightness
    sudo -u root gsettings set org.gnome.settings-daemon.plugins.power idle-brightness 0
    echo -e "  ${GREEN}org.gnome.settings-daemon.plugins.power idle-brightness 0${RESET}"
    # screensaver activation
    sudo -u root gsettings set org.gnome.desktop.session idle-delay 0
    echo -e "  ${GREEN}org.gnome.desktop.session idle-delay 0${RESET}"
    # screensaver lock
    sudo -u root gsettings set org.gnome.desktop.screensaver lock-enabled false
    echo -e "  ${GREEN}org.gnome.desktop.screensaver lock-enabled false${RESET}\n"
}

fix_python_requests() {
    echo -e "\n  ${GREEN}Determining and installing compatible Python modules for root user...${RESET}"

    # Define the required packages and their versions
    declare -A packages
    packages=(
        ["colorama"]="0.4.6"
        ["termcolor"]="2.4.0"
        ["service_identity"]="24.1.0"
        ["requests"]="2.31.0"
    )

    # Create a temporary requirements file
    temp_requirements="requirements.txt"
    for pkg in "${!packages[@]}"; do
        echo "$pkg==${packages[$pkg]}" >> "$temp_requirements"
    done

    # Install the packages
    sudo -u root pip install --upgrade -r "$temp_requirements"

    # Clean up
    rm "$temp_requirements"

    # List installed packages
    echo -e "\n  ${GREEN}Installed Python modules:${RESET}"
    for pkg in "${!packages[@]}"; do
        installed_version=$(sudo -u root pip show "$pkg" | grep Version | awk '{print $2}')
        echo -e "  ${GREEN}Installed ${pkg}: ${installed_version}${RESET}"
    done
}



fix_pipxlrd() {
    echo -e "\n  ${GREEN}Fixing Python package installations...${RESET}"

    # Install or upgrade xlrd
    echo -e "\n  ${GREEN}Installing or upgrading xlrd...${RESET}"
    sudo -u root pip install --upgrade xlrd==1.2.0

    # Try removing scapy via apt if installed by Debian package
    echo -e "\n  ${GREEN}Trying to remove scapy via apt...${RESET}"
    sudo apt remove --purge -y python3-scapy

    # Remove scapy if it exists via pip
    echo -e "\n  ${GREEN}Removing existing scapy installation if any...${RESET}"
    sudo -u root pip uninstall -y scapy

    # Install specific version of scapy
    echo -e "\n  ${GREEN}Installing scapy version 2.4.4...${RESET}"
    sudo -u root pip install --ignore-installed scapy==2.4.4

    echo -e "\n  ${GREEN}Python modules updated:${RESET}"
    echo -e "  ${GREEN}xlrd version:$(sudo -u root pip show xlrd | grep Version | awk '{print $2}')${RESET}"
    echo -e "  ${GREEN}scapy version:$(sudo -u root pip show scapy | grep Version | awk '{print $2}')${RESET}"
}


fix_set() {
    if [ "$(id -u)" -eq 0 ]; then
        echo -e "${BLUE}Installing packages: libssl-dev, set, gcc-mingw-w64-x86-64-win32${RESET}"
        apt -y install libssl-dev set gcc-mingw-w64-x86-64-win32
        echo -e "${GREEN}Packages installed successfully.${RESET}"
    else
        echo -e "${RED}Not running as root, skipping package installation.${RESET}"
    fi
}

install_kernel() {
    echo -e "\n  ${GREEN}Updating package list...${RESET}"
    sudo apt update
    
    echo -e "\n  ${GREEN}Installing new kernel and headers...${RESET}"
    sudo apt install -y linux-image-6.8.11-amd64 linux-headers-6.8.11-amd64
    
    echo -e "\n  ${GREEN}Updating GRUB...${RESET}"
    sudo update-grub
    
    echo -e "\n  ${GREEN}Kernel installation complete. Please reboot to apply the changes.${RESET}"
}


setup_all() {
    change_to_gnome
    enable_root_login
    install_tools_for_root
    configure_dock_for_root
    configure_dash_apps
    install_icons
    change_background
    fix_sources
    install_kernel
    apt_update && apt_update_complete
    apt_autoremove && apt_autoremove_complete
    remove_kali_undercover
    install_packages
    install_python_pip_curl
    update_python3_pip
    fix_gedit
    fix_root_connectionrefused
    fix_nmap
    fix_rockyou
    fix_theharvester
    disable_power_checkde
    fix_python_requests
    fix_pipxlrd
    fix_set
}


show_menu() {
    clear
    echo -e "$asciiart"
    echo -e "\n    ${YELLOW}Select an option from menu:${RESET}\n"  
    echo -e " ${GREEN}Key  Menu Option:              Description:${RESET}"
    echo -e " ${GREEN}---  ------------              ------------${RESET}"
    echo -e " ${BLUE}1 - Change to GNOME Desktop   (Installs GNOME and sets it as default)${RESET}"
    echo -e " ${BLUE}2 - Enable Root Login         (Installs root login and sets password)${RESET}"
    echo -e " ${BLUE}3 - Install Tools for Root    (Installs terminator, leafpad, and mousepad for root user)${RESET}"
    echo -e " ${BLUE}4 - ${BOLD}Setup All${RESET}${BLUE}                 (Runs all setup steps)${RESET}"
    echo -e " ${BLUE}0 - Exit                      (Exit the script)${RESET}\n"
    read -n1 -p "  Press key for menu item selection or press X to exit: " menuinput

    
    echo

    case $menuinput in
        1) change_to_gnome;;
        2) enable_root_login;;
        3) install_tools_for_root;;
        4) setup_all;;
        0|X) echo -e "\n\n ${RED}Exiting script - Happy Hacking!${RESET} \n" ;;
        *) show_menu ;;
    esac
}


show_menu


clear
echo -e "$asciiart"
echo -e "\n${RED}Happy Hacking!${RESET}"
echo -e "${GREEN}Setup completed! Please type 'reboot' to apply the changes and restart the system.${RESET}"


read -p "Type 'reboot' to restart: " user_input


if [ "$user_input" == "reboot" ]; then
    sudo reboot
else
    echo -e "\n  ${RED}You must type 'reboot' to restart the system.${RESET}"
fi

