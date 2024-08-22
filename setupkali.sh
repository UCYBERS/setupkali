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
greenplus='\e[1;33m[++]\e[0m'
greenminus='\e[1;33m[--]\e[0m'

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
    sudo apt install -y ark dolphin gwenview mdk3 kate partitionmanager okular vlc zaproxy zenmap-kbx htop
}


configure_dock_for_root() {
    echo -e "${BLUE}Configuring dock position for root user...${RESET}"
    sudo -u root gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'LEFT'
}


configure_dash_apps() {
    echo -e "${BLUE}Configuring Dash applications for root user...${RESET}"
    sudo -u root gsettings set org.gnome.shell favorite-apps "['terminator.desktop', 'firefox-esr.desktop', 'org.gnome.Nautilus.desktop', 'kali-msfconsole.desktop', 'kali-burpsuite.desktop', 'kali-maltego.desktop', 'kali-beef-start.desktop', 'leafpad.desktop']"
}

change_background() {
    local BACKGROUND_IMAGE="/usr/share/backgrounds/kali/kali-metal-dark-16x9.png"
    
    echo -e "\n  ${GREEN}Changing root user's desktop background...${RESET}"
    
    
    sudo -u root gsettings set org.gnome.desktop.background picture-uri "file://$BACKGROUND_IMAGE"
    sudo -u root gsettings set org.gnome.desktop.background picture-uri-dark "file://$BACKGROUND_IMAGE"
    
    echo -e "\n  ${GREEN}Background changed to ${BACKGROUND_IMAGE}${RESET}"
}

fix_sources() {
    check_space=$(cat /etc/apt/sources.list | grep -c "# deb-src http://.*/kali kali-rolling.*")
    check_nospace=$(cat /etc/apt/sources.list | grep -c "#deb-src http://.*/kali kali-rolling.*")
    get_current_mirror=$(cat /etc/apt/sources.list | grep "deb-src http://.*/kali kali-rolling.*" | cut -d "/" -f3)
    if [[ $check_space = 0 && $check_nospace = 0 ]]; then
    	echo -e "\n  $greenminus # deb-src or #deb-sec not found - skipping"
    elif [ $check_space = 1 ]; then
      echo -e "\n  $greenplus # deb-src with space found in sources.list uncommenting and enabling deb-src"
      # relaxed sed
      sudo sed 's/\# deb-src http\:\/\/.*\/kali kali-rolling.*/\deb-src http\:\/\/'$get_current_mirror'\/kali kali-rolling main contrib non\-free''/' -i /etc/apt/sources.list
      echo -e "\n  $greenplus new /etc/apt/sources.list written with deb-src enabled"
    elif [ $check_nospace = 1 ]; then
      echo -e "\n  $greenplus #deb-src without space found in sources.list uncommenting and enabling deb-src"
      # relaxed sed
      sudo sed 's/\#deb-src http\:\/\/.*\/kali kali-rolling.*/\deb-src http\:\/\/'$get_current_mirror'\/kali kali-rolling main contrib non\-free''/' -i /etc/apt/sources.list
      echo -e "\n  $greenplus new /etc/apt/sources.list written with deb-src enabled"
    fi
    sudo sed -i 's/non-free$/non-free non-free-firmware/' /etc/apt/sources.list
    }

apt_update() {
        echo -e "\n  ${GREEN}running: apt update${RESET}"
        eval sudo apt -y update -o Dpkg::Progress-Fancy="1"
    }

disable_power_checkde() {
        echo -e "\n  ${GREEN}GNOME is installed on the system${RESET}"
        disable_power_gnome
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

apt_update_complete() {
        echo -e "\n  ${GREEN}apt update - complete${RESET}"
    }


remove_kali_undercover() {
        echo -e "\n  ${BLUE}Removing kali-undercover package${RESET}"
        sudo apt -y remove kali-undercover
        echo -e "\n  ${GREEN}kali-undercover package removed${RESET}"
}

fix_nmap() {
    echo -e "\n  ${BLUE}Removing old clamav-exec.nse script...${RESET}"
    sudo -u root rm -f /usr/share/nmap/scripts/clamav-exec.nse
    echo -e "\n  ${RED}Removed /usr/share/nmap/scripts/clamav-exec.nse${RESET}"

    echo -e "\n  ${BLUE}Downloading updated clamav-exec.nse and http-shellshock.nse scripts...${RESET}"
    sudo -u root wget https://raw.githubusercontent.com/nmap/nmap/master/scripts/clamav-exec.nse -O /usr/share/nmap/scripts/clamav-exec.nse
    sudo -u root wget https://raw.githubusercontent.com/UCYBERS/setupkali/master/fixed-http-shellshock.nse -O /usr/share/nmap/scripts/http-shellshock.nse

    echo -e "\n  ${GREEN}Scripts updated successfully.${RESET}"
}

apt_upgrade() {
    echo -e "\n  $greenplus running: apt upgrade \n"
    sudo -u root bash -c "
      apt update &&
      apt -y upgrade -o Dpkg::Progress-Fancy='1' &&
      apt -y dist-upgrade -o Dpkg::Progress-Fancy='1' &&
      apt -y autoremove &&
      apt -y autoclean
    "
    apt_upgrade_complete
}

apt_upgrade_complete() {
    echo -e "\n  $greenplus apt upgrade - complete"
}

install_wifi_hotspot() {
    echo "Installing dependencies..."
    sudo apt update
    sudo apt install -y libgtk-3-dev hostapd libqrencode-dev libpng-dev pkg-config

    echo "Cloning and installing linux-wifi-hotspot..."
    
    # Clone and install linux-wifi-hotspot as root
    if [ -d "/opt/linux-wifi-hotspot" ]; then
        echo "linux-wifi-hotspot directory already exists."
    else
        sudo -u root git clone https://github.com/lakinduakash/linux-wifi-hotspot /opt/linux-wifi-hotspot
        sudo -u root bash -c "cd /opt/linux-wifi-hotspot && make && sudo make install"
        
        # Remove the directory after installation
        echo "Removing linux-wifi-hotspot directory..."
        sudo -u root rm -rf /opt/linux-wifi-hotspot
    fi
    
    echo "linux-wifi-hotspot has been successfully installed. You can now run the tool as the kali user."

    setup_firefox_custom_homepage
    add_firefox_bookmarks
}



setup_firefox_custom_homepage() {
    sudo mkdir -p /var/startpage
    cd /var/startpage || exit
    sudo wget -O startpage.7z "https://dl.dropbox.com/scl/fi/flp1oet82gkssjbgggk0n/startpage.7z?rlkey=t0x63e4yhnub1gnf160tp0b7b&st=woz1sg2u"
    sudo 7z x startpage.7z -o/var/startpage/
    sudo rm startpage.7z

    FIREFOX_PROFILE_DIR=$(sudo -u root bash -c 'ls -d /root/.mozilla/firefox/*.default-esr 2>/dev/null || true')

    if [ -z "$FIREFOX_PROFILE_DIR" ]; then
        echo "Firefox profile for root not found. Creating it by running Firefox."
        sudo -u root bash -c "firefox -headless & sleep 5; pkill firefox"
        FIREFOX_PROFILE_DIR=$(sudo -u root bash -c 'ls -d /root/.mozilla/firefox/*.default-esr 2>/dev/null')
    fi

    if [ -n "$FIREFOX_PROFILE_DIR" ]; then
        sudo -u root bash -c "echo 'user_pref(\"browser.startup.homepage\", \"file:///var/startpage/ucybers.html\");' >> $FIREFOX_PROFILE_DIR/user.js"
        echo "Custom homepage set successfully."
    else
        echo "Failed to find or create the Firefox profile."
    fi
}

add_firefox_bookmarks() {
    # Path to Firefox's places.sqlite
    local DB_PATH="/root/.mozilla/firefox/*.default-esr/places.sqlite"

    # Check if the database file exists
    if [ ! -f $DB_PATH ]; then
        echo "Error: Database file not found at $DB_PATH"
        return 1
    fi

    # Open SQLite and display table structures
    echo "Checking table structure in $DB_PATH..."
    sqlite3 $DB_PATH <<EOF
    PRAGMA table_info(moz_bookmarks);
    PRAGMA table_info(moz_places);
EOF

    # Begin the SQLite transaction
    echo "Adding bookmarks to 'Bookmarks Toolbar'..."

    sqlite3 $DB_PATH <<EOF
    BEGIN;

    -- Insert the URLs into moz_places if they don't already exist
    INSERT OR IGNORE INTO moz_places (url, title) VALUES 
    ('https://ucybers.com', 'UCYBERS'),
    ('https://certifications.ucybers.com', 'UCYBERS Certifications'),
    ('https://academy.ucybers.com', 'UCYBERS Academy'),
    ('https://www.youtube.com/@ucybers', 'UCYBERS YouTube'),
    ('https://www.facebook.com/ucybersx', 'UCYBERS FB'),
    ('https://x.com/ucybersx', 'UCYBERS Twitter'),
    ('https://www.linkedin.com/company/ucybersx', 'UCYBERS Linkedin');

    -- Add the bookmarks to the Bookmarks Toolbar
    INSERT INTO moz_bookmarks (fk, parent, title, type) VALUES
        ((SELECT id FROM moz_places WHERE url='https://ucybers.com'), (SELECT id FROM moz_bookmarks WHERE title='toolbar'), 'UCYBERS', 1),
        ((SELECT id FROM moz_places WHERE url='https://certifications.ucybers.com'), (SELECT id FROM moz_bookmarks WHERE title='toolbar'), 'UCYBERS Certifications', 1),
        ((SELECT id FROM moz_places WHERE url='https://academy.ucybers.com'), (SELECT id FROM moz_bookmarks WHERE title='toolbar'), 'UCYBERS Academy', 1),
        ((SELECT id FROM moz_places WHERE url='https://www.youtube.com/@ucybers'), (SELECT id FROM moz_bookmarks WHERE title='toolbar'), 'UCYBERS YouTube', 1),
        ((SELECT id FROM moz_places WHERE url='https://www.facebook.com/ucybersx'), (SELECT id FROM moz_bookmarks WHERE title='toolbar'), 'UCYBERS FB', 1),
        ((SELECT id FROM moz_places WHERE url='https://x.com/ucybersx'), (SELECT id FROM moz_bookmarks WHERE title='toolbar'), 'UCYBERS Twitter', 1),
        ((SELECT id FROM moz_places WHERE url='https://www.linkedin.com/company/ucybersx'), (SELECT id FROM moz_bookmarks WHERE title='toolbar'), 'UCYBERS Linkedin', 1);

    COMMIT;
EOF

    echo "Bookmarks added to the 'Bookmarks Toolbar'."
}




setup_all() {
    change_to_gnome
    enable_root_login
    install_tools_for_root
    configure_dock_for_root
    configure_dash_apps
    install_icons
    change_background
    disable_power_checkde
    fix_sources
    apt_update && apt_update_complete
    remove_kali_undercover
    fix_nmap
    
    
}



show_menu() {
    clear
    echo -e "$asciiart"
    echo -e "\n    ${YELLOW}Select an option from menu:${RESET}\n"  
    echo -e " ${GREEN}Key  Menu Option:              Description:${RESET}"
    echo -e " ${GREEN}---  ------------              ------------${RESET}"
    echo -e " ${BLUE}1 - Change to GNOME Desktop   (Installs GNOME and sets it as default)${RESET}"
    echo -e " ${BLUE}2 - Enable Root Login         (Installs root login and sets password)${RESET}"
    echo -e " ${BLUE}3 - Install Tools for Root    (Installs Hacking tools for root user)${RESET}"
    echo -e " ${BLUE}4 - Install WiFi Hotspot      (Installs and sets up WiFi hotspot)${RESET}"
    echo -e " ${BLUE}5 - Upgrade System            (Updates and upgrades the system)${RESET}"
    echo -e " ${BLUE}6 - ${BOLD}Setup All${RESET}${BLUE}                 (Runs all setup steps)${RESET}"
    echo -e " ${BLUE}0 - Exit                      (Exit the script)${RESET}\n"
    read -n1 -p "  Press key for menu item selection or press X to exit: " menuinput

    
    echo

    case $menuinput in
        1) change_to_gnome;;
        2) enable_root_login;;
        3) install_tools_for_root;;
        4) install_wifi_hotspot;;
        5) apt_upgrade;;
        6) setup_all;;
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
