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
NC='\033[0m'

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
    ICONS_URL="https://dl.dropbox.com/scl/fi/d8o2oor98iiq54y3uf006/Vibrancy-Kali.tar.gz?rlkey=nj8w51w5oljddqsjs0e5wmffm&st=tx97epgh"
    ICONS_FILE="/tmp/Vibrancy-Kali.tar.gz"
    
   
    wget -O "$ICONS_FILE" "$ICONS_URL"
    
    
    sudo tar -xzf "$ICONS_FILE" -C /usr/share/icons/
    
   
   sudo -u root gsettings set org.gnome.desktop.interface icon-theme 'Vibrancy-Kali'
    
    echo -e "${GREEN}Icons installed and set successfully.${RESET}"
    # enable_icon_theme_autostart_root
}

enable_icon_theme_autostart_root() {
    echo -e "${BLUE}Setting up autostart to change icon theme to Vibrancy-Kali for root...${RESET}"
    
    # إنشاء مجلد autostart لمستخدم الرووت إذا لم يكن موجودًا
    sudo mkdir -p /root/.config/autostart

    # إنشاء ملف desktop لتغيير ثيم الأيقونات عند بدء التشغيل لمستخدم الرووت
    sudo tee /root/.config/autostart/change_icon_theme.desktop > /dev/null <<EOF
[Desktop Entry]
Type=Application
Exec=gsettings set org.gnome.desktop.interface icon-theme 'Vibrancy-Kali'
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Change Icon Theme
EOF

    echo -e "${GREEN}Autostart setup completed to change the icon theme for root.${RESET}"
}


change_to_gnome() {
    switch_to_snapshot
    echo -e "${BLUE}Updating system and installing GNOME...${RESET}"
    sudo apt update -y
    sudo apt install -y kali-desktop-gnome

    echo -e "${BLUE}Setting GNOME as default session...${RESET}"

    echo "1" | sudo update-alternatives --config x-session-manager
    sudo apt purge --autoremove --allow-remove-essential kali-desktop-xfce
    echo -e "${GREEN}GNOME has been set as the default environment and XFCE has been removed.${RESET}"
    switch_to_rolling
    

}
switch_to_snapshot() {
  local sources_file="/etc/apt/sources.list"

  # Backup the original file
  cp "$sources_file" "${sources_file}.bak"

  # Comment out kali-rolling if it exists
  sed -i 's|^deb http://http.kali.org/kali kali-rolling|# deb http://http.kali.org/kali kali-rolling|' "$sources_file"

  # Add kali-last-snapshot if not already present
  if ! grep -q "^deb http://http.kali.org/kali kali-last-snapshot" "$sources_file"; then
    echo "deb http://http.kali.org/kali kali-last-snapshot main contrib non-free non-free-firmware" >> "$sources_file"
  fi

  echo "[✔] Switched to kali-last-snapshot"
}

switch_to_rolling() {
  local sources_file="/etc/apt/sources.list"

  # Backup the original file
  cp "$sources_file" "${sources_file}.bak"

  # Remove kali-last-snapshot line
  sed -i '/^deb http:\/\/http.kali.org\/kali kali-last-snapshot/d' "$sources_file"

  # Uncomment kali-rolling line if it was commented
  sed -i 's|^# deb http://http.kali.org/kali kali-rolling|deb http://http.kali.org/kali kali-rolling|' "$sources_file"

  echo "[✔] Switched to kali-rolling"
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
    sudo apt install -y terminator mousepad firefox-esr metasploit-framework burpsuite maltego beef-xss
    sudo apt install -y ark dolphin gwenview mdk3 kate partitionmanager okular vlc zaproxy
}


configure_dock_for_root() {
    echo -e "${BLUE}Configuring dock position for root user...${RESET}"
    sudo -u root gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'LEFT'
}


configure_dash_apps() {
    echo -e "${BLUE}Configuring Dash applications for root user...${RESET}"
    sudo -u root gsettings set org.gnome.shell favorite-apps "['terminator.desktop', 'firefox-esr.desktop', 'org.gnome.Nautilus.desktop', 'kali-metasploit-framework.desktop', 'kali-burpsuite.desktop', 'kali-maltego.desktop', 'kali-beef-xss.desktop', 'org.xfce.mousepad.desktop']"
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
    configure_dash_apps
    disable_power_gnome
}

apt_upgrade_complete() {
    echo -e "\n  $greenplus apt upgrade - complete"
    configure_dash_apps
}

install_wifi_hotspot() {
    echo "Installing dependencies..."
    sudo apt update
    sudo apt install -y libgtk-3-dev hostapd libqrencode-dev libpng-dev pkg-config

    echo "Cloning and installing linux-wifi-hotspot..."
    
    if [ -d "/opt/linux-wifi-hotspot" ]; then
        echo "linux-wifi-hotspot directory already exists."
    else
        sudo -u root git clone https://github.com/lakinduakash/linux-wifi-hotspot /opt/linux-wifi-hotspot
        sudo -u root bash -c "cd /opt/linux-wifi-hotspot && make && sudo make install"
        
        echo "Removing linux-wifi-hotspot directory..."
        sudo -u root rm -rf /opt/linux-wifi-hotspot
    fi
    
    echo "linux-wifi-hotspot has been successfully installed. You can now run the tool as the kali user."

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
        sudo -u root bash -c "echo 'user_pref(\"browser.startup.homepage\", \"file:///var/startpage/startpage/ucybers.html\");' >> $FIREFOX_PROFILE_DIR/user.js"
        echo "Custom homepage set successfully."
    else
        echo "Failed to find or create the Firefox profile."
    fi
}

add_firefox_bookmarks() {
    local DB_PATH="/root/.mozilla/firefox/*.default-esr/places.sqlite"

    if [ ! -f $DB_PATH ]; then
        echo "Error: Database file not found at $DB_PATH"
        return 1
    fi

    echo "Checking table structure in $DB_PATH..."
    sqlite3 $DB_PATH <<EOF
    PRAGMA table_info(moz_bookmarks);
    PRAGMA table_info(moz_places);
EOF

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

install_basic_packages() {
    echo -e "${BLUE}Installing essential packages...${NC}"
    sudo apt update
    sudo apt install -y build-essential python3-pip python3-venv
}

install_zenmap() {
    local ZENMAP_RPM="zenmap-7.94-1.noarch.rpm"
    local ZENMAP_DEB="zenmap_7.94-2_all.deb"
    local ZENMAP_URL="https://nmap.org/dist/$ZENMAP_RPM"

    if [ "$(id -u)" -ne "0" ]; then
        echo -e "${RED}This script must be run as root.${NC}"
        exit 1
    fi

    echo -e "${BLUE}Updating system...${NC}"
    sudo apt update

    echo -e "${BLUE}Installing alien...${NC}"
    sudo apt install -y alien wget

    echo -e "${BLUE}Downloading Zenmap...${NC}"
    wget $ZENMAP_URL

    echo -e "${BLUE}Converting RPM package to DEB...${NC}"
    sudo alien -d $ZENMAP_RPM

    echo -e "${BLUE}Installing Zenmap...${NC}"
    sudo dpkg -i $ZENMAP_DEB

    echo -e "${BLUE}Fixing missing dependencies...${NC}"
    sudo apt --fix-broken install -y

    echo -e "${BLUE}Cleaning up temporary files...${NC}"
    rm $ZENMAP_RPM $ZENMAP_DEB

    echo -e "${GREEN}Zenmap installation complete. You can now run Zenmap using the command: zenmap${NC}"
}

install_network_driver() {
    echo -e "${BLUE}Updating package list...${RESET}"
    sudo apt update

    echo -e "${BLUE}Installing required packages...${RESET}"
    sudo apt install -y linux-headers-$(uname -r) build-essential bc dkms git libelf-dev rfkill iw

    echo -e "${BLUE}Creating source directory...${RESET}"
    mkdir -p ~/src

    cd ~/src

    echo -e "${BLUE}Cloning the driver repository...${RESET}"
    git clone https://github.com/morrownr/8821au-20210708.git

    cd 8821au-20210708

    echo -e "${BLUE}Installing the driver...${RESET}"
    yes n | sudo ./install-driver.sh

    echo -e "${GREEN}Driver installation complete!${RESET}"
}

install_bettercap() {
    # Update package list
    echo -e "${YELLOW}Updating package list...${NC}"
    sudo apt update

    # Install bettercap
    echo -e "${YELLOW}Installing bettercap...${NC}"
    sudo apt install -y bettercap

    # Check if bettercap is installed
    if command -v bettercap &> /dev/null; then
        echo -e "${GREEN}bettercap installed successfully!${NC}"
    else
        echo -e "${RED}Error occurred while installing bettercap.${NC}"
        return 1
    fi

    git clone https://github.com/bettercap/caplets.git
    cd caplets
    sudo make install

    # Remove caplets directory if it exists in the home directory
    if [ -d "/root/caplets/" ]; then
        echo -e "${YELLOW}Removing caplets directory from the home directory...${NC}"
        rm -rf /root/caplets/
        echo -e "${GREEN}caplets directory removed from the home directory.${NC}"
    else
        echo -e "${YELLOW}No caplets directory found in the home directory.${NC}"
    fi
}

replace_hstshijack() {
    # Set variables
    URL="https://dl.dropbox.com/scl/fi/qtgpkeinbi6ihngiasx8p/hstshijack.zip?rlkey=4dlfpbuz5kddo8x8guzvvvcrh&st=ot44833o"
    DEST_DIR="/usr/local/share/bettercap/caplets/hstshijack"
    TEMP_DIR="/tmp/hstshijack_temp"

    # Download the ZIP file
    echo -e "${YELLOW}Downloading the ZIP file from Dropbox...${NC}"
    wget -qO /tmp/hstshijack.zip "$URL"
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to download the file. Please check the URL and try again.${NC}"
        exit 1
    fi

    # Remove existing destination directory
    echo -e "${YELLOW}Removing existing hstshijack directory...${NC}"
    sudo rm -rf "$DEST_DIR"

    # Create temporary directory
    echo -e "${YELLOW}Creating a temporary directory...${NC}"
    mkdir -p "$TEMP_DIR"

    # Extract the ZIP file to the temporary directory
    echo -e "${YELLOW}Extracting the ZIP file...${NC}"
    unzip -q /tmp/hstshijack.zip -d "$TEMP_DIR"

    # Move the extracted folder to the destination
    echo -e "${YELLOW}Replacing the existing hstshijack directory...${NC}"
    sudo mv "$TEMP_DIR/hstshijack" "$DEST_DIR"

    # Check if replacement was successful
    if [ -d "$DEST_DIR" ]; then
        echo -e "${GREEN}hstshijack directory replaced successfully!${NC}"
    else
        echo -e "${RED}Error occurred while replacing the hstshijack directory.${NC}"
    fi

    # Clean up temporary files
    echo -e "${YELLOW}Cleaning up temporary files...${NC}"
    rm -rf /tmp/hstshijack.zip "$TEMP_DIR"

    echo -e "${GREEN}Temporary files cleaned up successfully.${NC}"
}

python-pip-curl() {
  
    check_pip=$(whereis pip | grep -i -c "/usr/local/bin/pip2.7")
    if [ $check_pip -ne 1 ]
     then
      echo -e "\n  $greenplus installing pip"
      eval curl https://raw.githubusercontent.com/pypa/get-pip/3843bff3a0a61da5b63ea0b7d34794c5c51a2f11/2.7/get-pip.py -o /tmp/get-pip.py $silent
      echo -e "\n  $greenplus Symlinking /bin/python2.7 to /bin/python\n"
      [[ -f /bin/python2.7 ]] && ln -sf /bin/python2.7 /bin/python
      eval python /tmp/get-pip.py $silent
      rm -f /tmp/get-pip.py
      eval pip --no-python-version-warning install setuptools
      [[ ! -f /usr/bin/pip3 ]] && echo -e "\n  $greenplus installing python3-pip"; apt -y reinstall python3-pip || echo -e "\n  $greenplus python3-pip exists in /usr/bin/pip3"
      echo -e "\n  $greenplus python-pip installed"
    else
      echo -e "\n  $greenminus python-pip already installed"
    fi

    python2 -m pip install setuptools
    python2 -m pip install cryptography
    python2 -m pip install python-xlib
    }

install_hacking_tools() {
    echo -e "${YELLOW}Starting installation of Hacking tools...${NC}"

    # install_wifi_hotspot
    # sudo apt install -y htop
    setup_firefox_custom_homepage
    add_firefox_bookmarks
    # install_basic_packages
    install_zenmap
    # install_network_driver
    install_bettercap
    replace_hstshijack
    apt-get update
    # apt-get install realtek-rtl88xxau-dkms -y
    sudo apt install mdk4
    python-pip-curl
    sudo apt-get install python3-venv 
    sudo apt install python3 python3-pip

    echo -e "${GREEN}Installation of Hacking tools complete.${NC}"
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
    # fix_sources
    apt_update && apt_update_complete
    # remove_kali_undercover
    fix_nmap
    install_wifi_hotspot
    sudo apt install -y htop
    install_basic_packages
    install_network_driver
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
    echo -e " ${BLUE}4 - Install Pen Tools         (Installs additional penetration testing tools)${RESET}"
    echo -e " ${BLUE}5 - Upgrade System            (Updates and upgrades the system)${RESET}"
    echo -e " ${BLUE}6 - ${BOLD}Setup All${RESET}${BLUE}                 (Runs all setup steps)${RESET}"
    echo -e " ${BLUE}0 - Exit                      (Exit the script)${RESET}\n"
    read -n1 -p "  Press key for menu item selection or press X to exit: " menuinput

    
    echo

    case $menuinput in
        1) change_to_gnome;;
        2) enable_root_login;;
        3) install_tools_for_root;;
        4) install_hacking_tools;;
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
