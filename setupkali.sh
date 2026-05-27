#!/bin/bash

# setupkali.sh  Author: DARK (UCYBERS)
# git clone https://github.com/UCYBERS/setupkali
# Usage: sudo ./setupkali.sh  (defaults to the menu system)
# command line arguments are valid, only catching 1 argument
#
# Full Revision history can be found in changelog.txt
# Standard Disclaimer: Author assumes no liability for any damage

# revision var
revision="1.1.4"


RED='\033[31m'
redminus='\e[1;31m[--]\e[0m'
redexclaim='\e[1;31m[!!]\e[0m'
GREEN='\e[1;32m'
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
deep_green='\e[38;5;34m'

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
    
    
    sudo mkdir -p /root/.config/autostart

    
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
    echo -e "${BLUE}Installing GNOME Desktop Environment...${RESET}"

    local available_mb
    available_mb=$(df /usr --output=avail -m | tail -1)
    if (( available_mb < 3072 )); then
        echo -e "${RED}Insufficient disk space: ${available_mb}MB available, 3072MB required${RESET}"
        return 1
    fi

    echo -e "${BLUE}Updating package list...${RESET}"
    apt-get update || {
        echo -e "${RED}apt update failed — aborting GNOME install${RESET}"
        return 1
    }

    echo -e "${BLUE}Installing kali-desktop-gnome...${RESET}"
    apt-get install -y kali-desktop-gnome || {
        echo -e "${RED}Failed to install kali-desktop-gnome${RESET}"
        echo -e "${YELLOW}Run: apt-get install -f to fix broken packages${RESET}"
        return 1
    }

    apt-get install -y gnome-session gdm3 || {
        echo -e "${RED}Failed to install gnome-session or gdm3${RESET}"
        return 1
    }

    echo -e "${BLUE}Configuring gdm3...${RESET}"
    tee /etc/gdm3/daemon.conf > /dev/null << 'EOF'
[daemon]
#WaylandEnable=false

[security]
AllowRoot=true

[xdmcp]

[chooser]

[debug]
#Enable=true
EOF

    echo "/usr/sbin/gdm3" > /etc/X11/default-display-manager
    rm -f /etc/systemd/system/display-manager.service
    DEBIAN_FRONTEND=noninteractive dpkg-reconfigure gdm3 2>/dev/null || \
        echo -e "${YELLOW}Warning: Could not reconfigure gdm3 automatically${RESET}"
    systemctl enable gdm3 || \
        echo -e "${YELLOW}Warning: Could not enable gdm3${RESET}"

    if ! dpkg -l "kali-desktop-gnome" 2>/dev/null | grep -q "^ii"; then
        echo -e "${RED}GNOME installation could not be verified — skipping XFCE removal${RESET}"
        return 1
    fi

    if dpkg -l "kali-desktop-xfce" 2>/dev/null | grep -q "^ii"; then
        echo -e "${BLUE}Removing XFCE...${RESET}"
        apt-get remove --autoremove -y \
            kali-desktop-xfce \
            "xfce4*" || \
            echo -e "${YELLOW}Warning: Could not fully remove XFCE${RESET}"
        apt-get autoremove -y
    else
        echo -e "${YELLOW}XFCE not found — skipping removal${RESET}"
    fi

    echo -e "${GREEN}GNOME installed successfully. Please reboot to apply changes.${RESET}"
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
    echo -e "${BLUE}Enabling root login in GDM...${RESET}"

    local conf_file="/etc/gdm3/daemon.conf"
    local backup_file="${conf_file}.bak.$(date +%Y%m%d_%H%M%S)"

    if [[ ! -f "$conf_file" ]]; then
        echo -e "${RED}GDM config file not found: $conf_file${RESET}"
        echo -e "${YELLOW}Is GDM3 installed? Try: apt-get install -y gdm3${RESET}"
        return 1
    fi

    cp "$conf_file" "$backup_file" || {
        echo -e "${RED}Failed to backup GDM config — aborting${RESET}"
        return 1
    }
    echo -e "${GREEN}Backup saved to: $backup_file${RESET}"

    echo -e "${BLUE}Installing kali-root-login...${RESET}"
    apt-get install -y kali-root-login || {
        echo -e "${RED}Failed to install kali-root-login${RESET}"
        return 1
    }

    if grep -q "^\[security\]" "$conf_file"; then
        sed -i '/^AllowRoot/d' "$conf_file"
        sed -i '/^\[security\]/a AllowRoot=true' "$conf_file"
    else
        printf '\n[security]\nAllowRoot=true\n' >> "$conf_file"
    fi

    if grep -q "^WaylandEnable=false" "$conf_file"; then
        sed -i 's/^WaylandEnable=false/#WaylandEnable=false/' "$conf_file"
        echo -e "${GREEN}WaylandEnable fixed — Wayland restored${RESET}"
    fi

    local count_root
    count_root=$(grep -c "^AllowRoot=true" "$conf_file" || true)
    if [[ "$count_root" -ne 1 ]]; then
        echo -e "${RED}Configuration verification failed — restoring backup${RESET}"
        cp "$backup_file" "$conf_file"
        return 1
    fi

    echo -e "${GREEN}GDM configuration updated successfully.${RESET}"

    echo -e "${BLUE}Setting root password...${RESET}"
    echo -e "${YELLOW}Default password is: ucybers${RESET}"

    local keep_default=""
    while true; do
        echo -ne "Keep default password 'ucybers'? [Y/n]: "
        read -r keep_default || true
        case "${keep_default,,}" in
            y|"") break ;;
            n)    break ;;
            *)    echo -e "${RED}  Invalid input. Please enter Y or N.${RESET}" ;;
        esac
    done

    if [[ "${keep_default,,}" == "n" ]]; then
        local root_pass root_pass2
        while true; do
            read -rs -p "  Enter new root password: " root_pass
            echo ""
            read -rs -p "  Confirm root password: " root_pass2
            echo ""
            if [[ "$root_pass" != "$root_pass2" ]]; then
                echo -e "${RED}  Passwords do not match. Try again.${RESET}"
                continue
            fi
            if [[ -z "$root_pass" ]]; then
                echo -e "${RED}  Password cannot be empty. Try again.${RESET}"
                continue
            fi
            break
        done
        printf '%s:%s\n' "root" "$root_pass" | chpasswd
        unset root_pass root_pass2
        echo -e "${GREEN}Root password updated successfully.${RESET}"
    else
        printf '%s:%s\n' "root" "ucybers" | chpasswd
        echo -e "${GREEN}Root password set to: ucybers${RESET}"
    fi

    echo -e "${GREEN}Root login enabled successfully.${RESET}"
    echo -e "${YELLOW}A system reboot is required to apply GDM changes.${RESET}"
}

install_tools_for_root() {
    echo -e "${BLUE}Installing tools for root user...${RESET}"

    # Check available disk space
    local available_mb
    available_mb=$(df /usr --output=avail -m | tail -1)
    if (( available_mb < 5120 )); then
        echo -e "${RED}Insufficient disk space: ${available_mb}MB available, 5120MB required${RESET}"
        return 1
    fi

    echo -e "${BLUE}Updating package list...${RESET}"
    apt-get update || {
        echo -e "${RED}apt update failed${RESET}"
        return 1
    }

    local -a security_tools=(
        terminator mousepad firefox-esr
        metasploit-framework burpsuite
        maltego beef-xss zaproxy mdk4
        nemo
    )

    local -a utility_tools=(
        ark gwenview
        kate partitionmanager okular vlc
    )

    echo -e "${BLUE}Installing security tools...${RESET}"
    apt-get install -y "${security_tools[@]}" || {
        echo -e "${RED}One or more security tools failed to install${RESET}"
        echo -e "${YELLOW}Run: apt-get install -f to fix broken packages${RESET}"
        return 1
    }

    echo -e "${BLUE}Installing utility tools...${RESET}"
    apt-get install -y "${utility_tools[@]}" || \
        echo -e "${YELLOW}Warning: One or more utility tools failed to install${RESET}"

    echo -e "${GREEN}Tools installed successfully.${RESET}"
    apply_gnome_settings_on_login
    apply_nemo_fix_for_root
}

configure_dock_for_root() {
    echo -e "${BLUE}Configuring dock position for root user...${RESET}"
    sudo -u root gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'LEFT'
}

apply_nemo_fix_for_root() {
    echo -e "${BLUE}Installing and configuring Nemo file manager...${RESET}"

    apt-get install -y nemo || {
        echo -e "${RED}Failed to install nemo${RESET}"
        return 1
    }

    if [[ -f "/usr/share/applications/org.gnome.Nautilus.desktop" ]]; then
        sed -i 's|^Exec=nautilus.*|Exec=nemo %U|' \
            /usr/share/applications/org.gnome.Nautilus.desktop || \
            echo -e "${YELLOW}Warning: Could not modify Nautilus desktop file${RESET}"
        echo -e "${GREEN}Nautilus replaced with Nemo in Places menu.${RESET}"
    fi

    update-desktop-database /usr/share/applications/ || true

    xdg-mime default nemo.desktop inode/directory application/x-gnome-saved-search || true

    local kali_home="/home/kali"
    if [[ -d "$kali_home" ]]; then
        mkdir -p "$kali_home/.config"
        cp /root/.config/mimeapps.list "$kali_home/.config/mimeapps.list" 2>/dev/null || true
        chown kali:kali "$kali_home/.config/mimeapps.list" 2>/dev/null || true
        update-desktop-database "$kali_home/.local/share/applications/" 2>/dev/null || true
        echo -e "${GREEN}Nemo set as default for kali user.${RESET}"
    fi

    local dbus_addr="unix:path=/run/user/0/bus"
    if [[ -S "/run/user/0/bus" ]]; then
        DBUS_SESSION_BUS_ADDRESS="$dbus_addr" \
            gsettings set org.gnome.desktop.background show-desktop-icons false || true
        DBUS_SESSION_BUS_ADDRESS="$dbus_addr" \
            gsettings set org.nemo.desktop show-desktop-icons true || true
    else
        echo -e "${YELLOW}No active DBUS session — desktop icons will apply on next login${RESET}"
    fi

    if pgrep -x nautilus &>/dev/null; then
        pkill -x nautilus || true
        echo -e "${GREEN}Nautilus stopped.${RESET}"
    fi

    echo -e "${GREEN}Nemo configured successfully as default file manager.${RESET}"
}

configure_dash_apps() {
    echo -e "${BLUE}Configuring Dash applications for root user...${RESET}"

    local dconf_dir="/root/.config/dconf"
    local favorite_apps="['terminator.desktop', 'org.gnome.Terminal.desktop', 'firefox-esr.desktop', 'nemo.desktop', 'kali-metasploit-framework.desktop', 'kali-burpsuite.desktop', 'kali-maltego.desktop', 'kali-beef-xss.desktop', 'org.xfce.mousepad.desktop']"

    if [[ -S "/run/user/0/bus" ]]; then
        DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/0/bus" \
            gsettings set org.gnome.shell favorite-apps "$favorite_apps" && {
            echo -e "${GREEN}Dash apps configured via gsettings.${RESET}"
            return 0
        }
    fi

    echo -e "${YELLOW}Writing dash apps directly via dconf...${RESET}"
    mkdir -p "$dconf_dir"

    apt-get install -y dconf-cli &>/dev/null || true

    dconf write /org/gnome/shell/favorite-apps "$favorite_apps" 2>/dev/null || {

        mkdir -p /root/.config/dconf
        cat > /root/.config/dconf/user.d/setupkali.conf << EOF
[org/gnome/shell]
favorite-apps=$favorite_apps
EOF
        echo -e "${YELLOW}Dash apps written to dconf keyfile — will apply on next login.${RESET}"
        return 0
    }

    echo -e "${GREEN}Dash apps configured via dconf.${RESET}"
}

apply_gnome_settings_on_login() {
    echo -e "${BLUE}Setting up GNOME settings autostart...${RESET}"

    mkdir -p /root/.config/autostart

    cat > /root/.config/autostart/setupkali-gnome-settings.desktop << EOF
[Desktop Entry]
Type=Application
Name=SetupKali GNOME Settings
Exec=/bin/bash -c 'gsettings set org.gnome.shell favorite-apps "[\"terminator.desktop\", \"org.gnome.Terminal.desktop\", \"firefox-esr.desktop\", \"nemo.desktop\", \"kali-metasploit-framework.desktop\", \"kali-burpsuite.desktop\", \"kali-maltego.desktop\", \"kali-beef-xss.desktop\", \"org.xfce.mousepad.desktop\"]"; gsettings set org.gnome.shell.extensions.dash-to-dock dock-position LEFT; gsettings set org.gnome.desktop.background picture-uri "file:///usr/share/backgrounds/kali/kali-tiles-16x9.jpg"; gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type nothing; gsettings set org.gnome.desktop.session idle-delay 0; gsettings set org.gnome.desktop.screensaver lock-enabled false; mkdir -p /root/.local/share/applications; printf "[Desktop Entry]\nType=Application\nName=Files\nExec=nemo %%U\nIcon=system-file-manager\nNoDisplay=false\nMimeType=inode/directory;\n" > /root/.local/share/applications/org.gnome.Nautilus.desktop; xdg-mime default nemo.desktop inode/directory; update-desktop-database /root/.local/share/applications/; rm -f /root/.config/autostart/setupkali-gnome-settings.desktop'
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF

    echo -e "${GREEN}GNOME settings will be applied on next login automatically.${RESET}"
}

change_background() {
    local BACKGROUND_IMAGE="/usr/share/backgrounds/kali/kali-net-16x9.jpg"
    
    echo -e "\n  ${GREEN}Changing root user's desktop background...${RESET}"
    
    
    sudo -u root gsettings set org.gnome.desktop.background picture-uri "file://$BACKGROUND_IMAGE"
    sudo -u root gsettings set org.gnome.desktop.background picture-uri-dark "file://$BACKGROUND_IMAGE"
    
    echo -e "\n  ${GREEN}Background changed to ${BACKGROUND_IMAGE}${RESET}"
}
fix_bad_apt_hash() {
    echo -e "\n  ${BLUE}Fixing APT hash issues...${RESET}"
    # Remove cached package lists that may have bad hashes
    rm -rf /var/lib/apt/lists/*
    apt-get clean
    apt-get update --fix-missing || true
    echo -e "\n  ${GREEN}APT cache cleaned.${RESET}"
}

fix_sources() {
    fix_bad_apt_hash
    local sources_file="/etc/apt/sources.list"
    local backup_file="${sources_file}.bak.$(date +%Y%m%d_%H%M%S)"

    echo -e "\n  ${BLUE}Fixing APT sources...${RESET}"

    cp "$sources_file" "$backup_file" || {
        echo -e "\n  ${RED}Failed to backup sources.list — aborting${RESET}"
        return 1
    }
    echo -e "\n  ${GREEN}Backup saved to: $backup_file${RESET}"

    local current_mirror
    current_mirror=$(grep -m1 "^deb http" "$sources_file" | cut -d'/' -f3 || true)

    if [[ -z "$current_mirror" ]]; then
        echo -e "\n  ${RED}Could not detect current mirror — aborting${RESET}"
        return 1
    fi

    echo -e "\n  ${BLUE}Detected mirror: $current_mirror${RESET}"

    local check_space check_nospace
    check_space=$(grep -c "^# deb-src http.*/kali kali-rolling" "$sources_file" || true)
    check_nospace=$(grep -c "^#deb-src http.*/kali kali-rolling" "$sources_file" || true)

    if [[ "$check_space" -eq 0 && "$check_nospace" -eq 0 ]]; then
        echo -e "\n  $greenminus deb-src not found — skipping"
    elif [[ "$check_space" -ge 1 ]]; then
        echo -e "\n  $greenplus Enabling deb-src (with space)..."
        sed -i "s|^# deb-src http.*/kali kali-rolling.*|deb-src http://${current_mirror}/kali kali-rolling main contrib non-free|" \
            "$sources_file"
        echo -e "\n  $greenplus deb-src enabled"
    elif [[ "$check_nospace" -ge 1 ]]; then
        echo -e "\n  $greenplus Enabling deb-src (without space)..."
        sed -i "s|^#deb-src http.*/kali kali-rolling.*|deb-src http://${current_mirror}/kali kali-rolling main contrib non-free|" \
            "$sources_file"
        echo -e "\n  $greenplus deb-src enabled"
    fi

    if grep -q "non-free$" "$sources_file"; then
        sed -i 's/non-free$/non-free non-free-firmware/' "$sources_file"
        echo -e "\n  $greenplus non-free-firmware added"
    fi

    echo -e "\n  ${GREEN}APT sources fixed successfully.${RESET}"
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
    echo -e "\n  ${BLUE}Fixing nmap scripts...${RESET}"

    local clamav_url="https://raw.githubusercontent.com/nmap/nmap/master/scripts/clamav-exec.nse"
    local shellshock_url="https://raw.githubusercontent.com/UCYBERS/setupkali/master/fixed-http-shellshock.nse"
    local tmp_clamav="/tmp/clamav-exec.nse"
    local tmp_shellshock="/tmp/http-shellshock.nse"

    echo -e "\n  ${BLUE}Downloading clamav-exec.nse...${RESET}"
    wget --https-only -q "$clamav_url" -O "$tmp_clamav" || {
        echo -e "\n  ${RED}Failed to download clamav-exec.nse${RESET}"
        return 1
    }

    echo -e "\n  ${BLUE}Downloading http-shellshock.nse...${RESET}"
    wget --https-only -q "$shellshock_url" -O "$tmp_shellshock" || {
        echo -e "\n  ${RED}Failed to download http-shellshock.nse${RESET}"
        rm -f "$tmp_clamav"
        return 1
    }

    rm -f /usr/share/nmap/scripts/clamav-exec.nse
    mv "$tmp_clamav"     /usr/share/nmap/scripts/clamav-exec.nse
    mv "$tmp_shellshock" /usr/share/nmap/scripts/http-shellshock.nse
    chmod 644 /usr/share/nmap/scripts/clamav-exec.nse
    chmod 644 /usr/share/nmap/scripts/http-shellshock.nse

    echo -e "\n  ${GREEN}Nmap scripts updated successfully.${RESET}"
}

apt_upgrade() {
    echo -e "\n  $greenplus Running full system upgrade...\n"

    apt-get update || {
        echo -e "\n  ${RED}apt update failed${RESET}"
        return 1
    }

    apt-get -y upgrade -o Dpkg::Progress-Fancy="1" || {
        echo -e "\n  ${RED}apt upgrade failed${RESET}"
        return 1
    }

    apt-get -y dist-upgrade -o Dpkg::Progress-Fancy="1" || {
        echo -e "\n  ${RED}dist-upgrade failed${RESET}"
        return 1
    }

    apt-get -y autoremove
    apt-get -y autoclean

    apt_upgrade_complete
}

apt_upgrade_complete() {
    echo -e "\n  $greenplus apt upgrade complete"
    configure_dash_apps || \
        echo -e "\n  ${YELLOW}Warning: Could not configure dash apps${RESET}"
    disable_power_gnome || \
        echo -e "\n  ${YELLOW}Warning: Could not configure power settings${RESET}"
    echo -e "\n  ${GREEN}System upgrade finished successfully.${RESET}"
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



add_firefox_bookmarks() {
    echo -e "${BLUE}Configuring Firefox bookmarks...${RESET}"

    local policies_dir="/etc/firefox-esr/policies"
    local policies_file="$policies_dir/policies.json"
    local kali_policies="/usr/share/firefox-esr/distribution/policies.json"

    mkdir -p "$policies_dir" || {
        echo -e "${RED}Failed to create Firefox policies directory${RESET}"
        return 1
    }

    # Merge with Kali's system policies to avoid being overridden
    local target_file="$kali_policies"
    [[ ! -f "$kali_policies" ]] && target_file="$policies_file"

    python3 -c "
import json, sys
try:
    with open('$target_file', 'r') as f:
        data = json.load(f)
except:
    data = {'policies': {}}
data.setdefault('policies', {})['Bookmarks'] = [
    {'Title': 'UCYBERS',                'URL': 'https://ucybers.com',                       'Toolbar': True},
    {'Title': 'UCYBERS Certifications', 'URL': 'https://certifications.ucybers.com',         'Toolbar': True},
    {'Title': 'UCYBERS Academy',        'URL': 'https://academy.ucybers.com',                'Toolbar': True},
    {'Title': 'UCYBERS YouTube',        'URL': 'https://www.youtube.com/@ucybers',           'Toolbar': True},
    {'Title': 'UCYBERS FB',             'URL': 'https://www.facebook.com/ucybersx',          'Toolbar': True},
    {'Title': 'UCYBERS Twitter',        'URL': 'https://x.com/ucybersx',                    'Toolbar': True},
    {'Title': 'UCYBERS Linkedin',       'URL': 'https://www.linkedin.com/company/ucybersx', 'Toolbar': True}
]
with open('$target_file', 'w') as f:
    json.dump(data, f, indent=2)
" && echo -e "${GREEN}Firefox bookmarks configured successfully.${RESET}" || {
        echo -e "${RED}Failed to configure bookmarks${RESET}"
        return 1
    }
}

setup_firefox_custom_homepage() {
    echo -e "${BLUE}Setting up custom Firefox homepage...${RESET}"

    local startpage_url="https://dl.dropbox.com/scl/fi/flp1oet82gkssjbgggk0n/startpage.7z?rlkey=t0x63e4yhnub1gnf160tp0b7b&st=woz1sg2u"
    local startpage_dir="/var/startpage"
    local startpage_file="/tmp/startpage.7z"
    local homepage_path="file://${startpage_dir}/startpage/ucybers.html"
    local kali_policies="/usr/share/firefox-esr/distribution/policies.json"

    # Install 7zip if missing
    if ! command -v 7z &>/dev/null; then
        apt-get install -y 7zip || {
            echo -e "${RED}Failed to install 7zip${RESET}"
            return 1
        }
    fi

    # Download startpage
    echo -e "${BLUE}Downloading startpage...${RESET}"
    wget --https-only -O "$startpage_file" "$startpage_url" || {
        echo -e "${RED}Failed to download startpage${RESET}"
        rm -f "$startpage_file"
        return 1
    }

    # Extract startpage
    mkdir -p "$startpage_dir"
    7z x "$startpage_file" -o"${startpage_dir}/" -y || {
        echo -e "${RED}Failed to extract startpage${RESET}"
        rm -f "$startpage_file"
        return 1
    }
    rm -f "$startpage_file"

    # Verify startpage exists
    if [[ ! -f "${startpage_dir}/startpage/ucybers.html" ]]; then
        echo -e "${RED}ucybers.html not found after extraction${RESET}"
        return 1
    fi

    # Set homepage via Firefox policies
    python3 -c "
import json
try:
    with open('$kali_policies', 'r') as f:
        data = json.load(f)
except:
    data = {'policies': {}}
data.setdefault('policies', {})['Homepage'] = {
    'URL': '$homepage_path',
    'Locked': False,
    'StartPage': 'homepage'
}
with open('$kali_policies', 'w') as f:
    json.dump(data, f, indent=2)
" && echo -e "${GREEN}Firefox homepage set to local startpage.${RESET}" || {
        echo -e "${RED}Failed to set homepage in policies${RESET}"
        return 1
    }
}

install_basic_packages() {
    echo -e "${BLUE}Installing essential packages...${RESET}"

    local -a basic_packages=(
        build-essential
        python3-pip
        python3-venv
        python3-setuptools
    )

    apt-get install -y "${basic_packages[@]}" || {
        echo -e "${RED}Failed to install essential packages${RESET}"
        return 1
    }

    echo -e "${GREEN}Essential packages installed successfully.${RESET}"
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
    echo -e "${YELLOW}Installing bettercap...${RESET}"

    apt-get install -y bettercap || {
        echo -e "${RED}Failed to install bettercap${RESET}"
        return 1
    }

    if ! command -v bettercap &>/dev/null; then
        echo -e "${RED}bettercap installation could not be verified${RESET}"
        return 1
    fi

    echo -e "${GREEN}bettercap installed successfully!${RESET}"

    local caplets_tmp
    caplets_tmp=$(mktemp -d /tmp/caplets_XXXXXX)

    echo -e "${YELLOW}Cloning bettercap caplets...${RESET}"
    git clone --depth=1 https://github.com/bettercap/caplets.git "$caplets_tmp" || {
        echo -e "${RED}Failed to clone caplets repository${RESET}"
        rm -rf "$caplets_tmp"
        return 1
    }

    echo -e "${YELLOW}Installing caplets...${RESET}"
    make -C "$caplets_tmp" install || {
        echo -e "${RED}Failed to install caplets${RESET}"
        rm -rf "$caplets_tmp"
        return 1
    }

    rm -rf "$caplets_tmp"
    echo -e "${GREEN}bettercap and caplets installed successfully.${RESET}"
}

replace_hstshijack() {
    local url="https://dl.dropbox.com/scl/fi/qtgpkeinbi6ihngiasx8p/hstshijack.zip?rlkey=4dlfpbuz5kddo8x8guzvvvcrh&st=ot44833o"
    local dest_dir="/usr/local/share/bettercap/caplets/hstshijack"
    local tmp_zip tmp_dir

    tmp_zip=$(mktemp /tmp/hstshijack_XXXXXX.zip)
    tmp_dir=$(mktemp -d /tmp/hstshijack_dir_XXXXXX)

    echo -e "${YELLOW}Downloading hstshijack...${RESET}"
    wget --https-only -qO "$tmp_zip" "$url" || {
        echo -e "${RED}Failed to download hstshijack${RESET}"
        rm -f "$tmp_zip"
        rm -rf "$tmp_dir"
        return 1
    }

    echo -e "${YELLOW}Extracting hstshijack...${RESET}"
    unzip -q "$tmp_zip" -d "$tmp_dir" || {
        echo -e "${RED}Failed to extract hstshijack.zip${RESET}"
        rm -f "$tmp_zip"
        rm -rf "$tmp_dir"
        return 1
    }

    if [[ ! -d "$tmp_dir/hstshijack" ]]; then
        echo -e "${RED}Expected 'hstshijack' folder not found in archive${RESET}"
        rm -f "$tmp_zip"
        rm -rf "$tmp_dir"
        return 1
    fi

    echo -e "${YELLOW}Replacing hstshijack directory...${RESET}"
    rm -rf "$dest_dir"
    mv "$tmp_dir/hstshijack" "$dest_dir" || {
        echo -e "${RED}Failed to move hstshijack to destination${RESET}"
        rm -f "$tmp_zip"
        rm -rf "$tmp_dir"
        return 1
    }

    rm -f "$tmp_zip"
    rm -rf "$tmp_dir"
    echo -e "${GREEN}hstshijack replaced successfully.${RESET}"
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
    echo -e "${YELLOW}Starting installation of hacking tools...${RESET}"

    apt-get update || {
        echo -e "${RED}apt update failed${RESET}"
        return 1
    }

    apt-get install -y htop python3 python3-pip python3-venv || \
        echo -e "${YELLOW}Warning: Some packages failed to install${RESET}"

    add_firefox_bookmarks
    setup_firefox_custom_homepage
    install_zenmap
    install_bettercap
    replace_hstshijack

    echo -e "${GREEN}Hacking tools installation complete.${RESET}"
}




setup_all() {
    echo -e "${BLUE}Starting full system setup...${RESET}"

    fix_sources
    apt_update && apt_update_complete

    change_to_gnome || {
        echo -e "${RED}GNOME installation failed — aborting setup${RESET}"
        return 1
    }

    enable_root_login

    install_basic_packages
    install_tools_for_root
    install_hacking_tools
    fix_nmap
    install_wifi_hotspot
    install_network_driver

    install_icons
    change_background
    configure_dock_for_root
    configure_dash_apps
    apply_gnome_settings_on_login
    disable_power_checkde

    echo -e "${GREEN}Full setup complete. Please reboot to apply all changes.${RESET}"
}

confirm_menu_choice() {
    valid_options=("1" "2" "3" "4" "5" "6" "0")

    if [[ ! " ${valid_options[@]} " =~ " ${menuinput} " ]]; then
        echo -e "\n${RED}  Invalid option: '${menuinput}'. Please try again.${RESET}"
        return 1
    fi

    if [ "$menuinput" == "0" ]; then
        clear
        echo -e "${BOLD}${deep_green}$asciiart${RESET}"
        echo -e "\n${RED}Happy Hacking!${RESET} ${GREEN}Setup completed! ${RESET}\n"
        
        exit 0
    fi

    echo -e ""
    echo -ne " Menu selection is ${deep_green}${menuinput}${RESET} Press ${GREEN}Y${RESET} to confirm or ${RED}N${RESET} to cancel: "
    read -n1 selectinput


    case "$selectinput" in
        Y|y)
            echo -e "\n\n ${GREEN}✔ Executing menu option ${menuinput}${RESET}"
            return 0
            ;;
        N|n)
            echo -e "\n\n  ${YELLOW}↺ Returning to menu...${RESET}"
            return 1
            ;;
        *)
            echo -e "\n\n  ${RED}Invalid input. Please enter Y or N only.${RESET}"
            return 1
            ;;
    esac
}




show_menu() {
    while true; do
        clear
        echo -e "${BOLD}${deep_green}$asciiart"
        echo -e "\n    ${YELLOW}Select an option from the menu:${RESET}\n"  
        echo -e " ${deep_green}Key  Menu Option:              Description:${RESET}"
        echo -e " ${deep_green}---  ------------              ------------${RESET}"
        echo -e " ${BLUE}1 - Change to GNOME Desktop   (Installs GNOME and sets it as default)${RESET}"
        echo -e " ${BLUE}2 - Enable Root Login         (Installs root login and sets password)${RESET}"
        echo -e " ${BLUE}3 - Install Tools for Root    (Installs hacking tools for root user)${RESET}"
        echo -e " ${BLUE}4 - Install Pen Tools         (Installs additional penetration testing tools)${RESET}"
        echo -e " ${BLUE}5 - Upgrade System            (Updates and upgrades the system)${RESET}"
        echo -e " ${BLUE}6 - ${BOLD}Setup All${RESET}${BLUE}                 (Runs all setup steps)${RESET}"
        echo -e " ${BLUE}0 - Exit                      (Exit the script)${RESET}\n"
        echo -e " ${deep_green}Please use sudo ./setupkali.sh --help for additional installations/fixes${RESET}\n"
        
        
        read -n1 -p " Press key for menu selection or press 0 to exit: " menuinput
        echo
        
        # Confirm the selection
        confirm_menu_choice $menuinput
        if [ $? -eq 0 ]; then
            case $menuinput in
                1) change_to_gnome; break ;;
                2) enable_root_login; break ;;
                3) install_tools_for_root; break ;;
                4) install_hacking_tools; break ;;
                5) apt_upgrade; break ;;
                6) setup_all; break ;;
                0) 
                    clear
                    echo -e "$asciiart"
                    echo -e "\n${RED}Happy Hacking!${RESET}"
                    echo -e "${GREEN}Setup completed! ${RESET}\n"
                    exit 0
                    ;;
                *)
                    # Should not reach here because confirm_menu_choice handles invalid input
                    ;;
            esac
        fi
        # If not confirmed, the loop repeats to show the menu again
    done
}


setupkali_help() {
    echo -e "\n  ${YELLOW}Command line arguments:${RESET}\n"
    options=(
    "  -g, --gnome           - Install and switch to GNOME desktop environment"
    "  -r, --root            - Enable root login and prompt for password"
    "  -t, --tools           - Install hacking tools for root user"
    "  -H, --hacking         - Install additional hacking tools"
    "  -u, --upgrade         - Run apt update and upgrade"
    "  -a, -A, --all         - Perform full system setup"
    "  -f, --fix-sources     - Fix and update APT sources list"
    "  -n, --nmap            - Fix nmap configuration/issues"
    "  -s, --style           - Configure dock, dash, and icons for root user"
    "  -w, --wifi            - Install linux-wifi-hotspot tool"
    "  -F, --firefox         - Set custom Firefox homepage"
    "  -R, --enable-root     - Enable root login only"
    "  -h, -?, --help        - Show this help message"
    )

    for option in "${options[@]}"; do
        echo -e "$option"
    done
    echo
    exit 0
}

check_arg() {
    if [ "$1" == "--help" ] || [ "$1" == "-h" ] || [ "$1" == "-?" ]; then
        setupkali_help
    elif [ -z "$1" ]; then
        show_menu
    else
        case "$1" in
            --gnome|-g)
                change_to_gnome ;;
            --root|-r)
                enable_root_login ;;
            --tools|-t)
                install_tools_for_root ;;
            --hacking|-H)
                install_hacking_tools ;;
            --upgrade|-u)
                apt_update
                apt_upgrade ;;
            --all|-a|-A)
                setup_all ;;
            --fix-sources|-f)
                fix_sources ;;
            --nmap|-n)
                fix_nmap ;;
            --style|-s)
                configure_dock_for_root
                configure_dash_apps
                install_icons ;;
            --wifi|-w)
                install_wifi_hotspot ;;
            --firefox|-F)
            	add_firefox_bookmarks
                setup_firefox_custom_homepage ;;
            --enable-root|-R)
                enable_root_login ;;
            *)
                setupkali_help
                exit 1 ;;
        esac
    fi
}



check_arg "$1"


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
