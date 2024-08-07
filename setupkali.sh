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

# تعريف الألوان
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
MAGENTA='\033[35m'
CYAN='\033[36m'
WHITE='\033[37m'
RESET='\033[0m' 


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


setup_all() {
    change_to_gnome
    enable_root_login
    install_tools_for_root
    configure_dock_for_root
    configure_dash_apps
    install_icons
}


show_menu() {
    clear
    echo -e "$asciiart"
    echo -e "\n    ${YELLOW}Select an option from menu:${RESET}\n"  # إضافة سطر فارغ هنا
    echo -e " ${GREEN}Key  Menu Option:              Description:${RESET}"
    echo -e " ${GREEN}---  ------------              ------------${RESET}"
    echo -e " ${BLUE}1 - Change to GNOME Desktop   (Installs GNOME and sets it as default)${RESET}"
    echo -e " ${BLUE}2 - Enable Root Login         (Installs root login and sets password)${RESET}"
    echo -e " ${BLUE}3 - Install Tools for Root    (Installs terminator, leafpad, and mousepad for root user)${RESET}"
    echo -e " ${BLUE}4 - Setup All                 (Runs change GNOME, enable root login, install tools for root, configure dock, and install icons)${RESET}"
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
    echo -e "${RED}You must type 'reboot' to restart the system.${RESET}"
fi
