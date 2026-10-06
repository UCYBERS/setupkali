#!/bin/bash

# setupkali.sh  Author: DARK (UCYBERS)
# git clone https://github.com/UCYBERS/setupkali
# Usage: sudo ./setupkali.sh  (defaults to the menu system)
# Only one command line argument is accepted (see --help)
#
# Full revision history: CHANGELOG.md
# Standard Disclaimer: Author assumes no liability for any damage

# Most functions are invoked indirectly through run_step
# shellcheck disable=SC2317,SC2329

VERSION="2.0.3"

# Answer --version before the root / Kali checks so anyone can run it
if [[ "${1:-}" == "--version" || "${1:-}" == "-v" ]]; then
    echo "setupkali ${VERSION}"
    exit 0
fi


RED='\033[31m'
GREEN='\e[1;32m'
YELLOW='\033[33m'
BLUE='\033[34m'
BOLD='\033[1m'
RESET='\033[0m' 
greenplus='\e[1;33m[++]\e[0m'
greenminus='\e[1;33m[--]\e[0m'
deep_green='\e[38;5;34m'


if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}Error: This script must be run as root.${RESET}"
    echo -e "${YELLOW}Usage: sudo $0${RESET}"
    exit 1
fi

if ! grep -Eq '^ID="?kali"?$' /etc/os-release; then
    echo -e "${RED}This script is intended to be run on Kali Linux only.${RESET}"
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive

INTEGRITY_FAILURE=0

declare -rA ASSET_SHA256=(
    [Vibrancy-Kali.tar.gz]="55ea8978064e6953d65dc4a6fee5e7702def47fe572dbf9c6be8ed11c64143d7"
    [startpage.7z]="1fc5193a07e9cb296ad561c00caa814cce7f432b91773c821ec08e3232b8dc11"
    [hstshijack.zip]="22ce5359e72fff65215cf36ad0dda4e25365bc898d9d04ce85703f257f73dae5"
)

download_verified() {
    local url="$1" dest="$2" expected="$3" actual

    curl --proto '=https' --tlsv1.2 -fsSL --retry 3 -o "$dest" "$url" || {
        echo -e "${RED}Download failed: $url${RESET}"
        rm -f "$dest"
        return 1
    }

    actual=$(sha256sum "$dest" | awk '{print $1}')
    if [[ "$actual" != "$expected" ]]; then
        INTEGRITY_FAILURE=1
        echo -e "${RED}[!!] SHA-256 mismatch for $(basename "$dest") — file deleted${RESET}"
        echo -e "${RED}     expected: $expected${RESET}"
        echo -e "${RED}     actual:   $actual${RESET}"
        rm -f "$dest"
        return 1
    fi

    echo -e "${GREEN}[OK] SHA-256 verified: $(basename "$dest")${RESET}"
}


asciiart=$(base64 -d <<< "H4sICP9gsmYAA2xvZ28udHh0AH1OMQ4CMQzb+wqPTJcPoA6c+ACIAclSJcTNIBaE1McTJ1cECxnq
xLFTAz/VGvCHmTTpKVqoEgzoalfSm+7MmJBTb60XWDjNpGbcZ+wZSkppMMrF1edPiT3IdH94IL6u
qIq31TiutPBZBqhM8AjKkScgcMYNm5SF2iKnivYNWTLcb8/lsVxjcXkJTvN5tz8ch6i8ASj+YXlX
AQAA" | gunzip)


echo -e "$asciiart"


echo


install_icons() {
    echo -e "${BLUE}Downloading and installing icons...${RESET}"
    local icons_url="https://github.com/UCYBERS/setupkali/releases/download/1.1.5/Vibrancy-Kali.tar.gz"
    local icons_file
    icons_file=$(mktemp /tmp/Vibrancy-Kali_XXXXXX.tar.gz) || return 1

    download_verified "$icons_url" "$icons_file" "${ASSET_SHA256[Vibrancy-Kali.tar.gz]}" || {
        rm -f "$icons_file"
        return 1
    }

    tar -xzf "$icons_file" -C /usr/share/icons/ --no-same-owner || {
        echo -e "${RED}Failed to extract icons${RESET}"
        rm -f "$icons_file"
        return 1
    }
    rm -f "$icons_file"

    sudo -u root gsettings set org.gnome.desktop.interface icon-theme 'Vibrancy-Kali'

    echo -e "${GREEN}Icons installed and set successfully.${RESET}"
}

configure_gnome_terminal() {
    
    echo -e "${BLUE}Setting qterminal as the terminal for menu launchers...${RESET}"

    apt-get install -y qterminal dconf-cli || return 1

    local profile="/etc/dconf/profile/user"
    local keyfile="/etc/dconf/db/local.d/00-setupkali-terminal"

    mkdir -p /etc/dconf/profile /etc/dconf/db/local.d || return 1

    if [[ ! -f "$profile" ]]; then
        printf 'user-db:user\nsystem-db:local\n' > "$profile"
    elif ! grep -qx 'system-db:local' "$profile"; then
        echo 'system-db:local' >> "$profile"
    fi

    cat > "$keyfile" <<'DCONFEOF'
[org/gnome/desktop/applications/terminal]
exec='qterminal'
exec-arg='-e'
DCONFEOF

    dconf update || {
        echo -e "${RED}dconf update failed${RESET}"
        return 1
    }

    echo -e "${GREEN}[OK] Menu launchers will open in qterminal${RESET}"
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
    [[ -f /etc/gdm3/daemon.conf ]] && backup_apt_file /etc/gdm3/daemon.conf > /dev/null
    tee /etc/gdm3/daemon.conf > /dev/null << 'EOF'
[daemon]
#WaylandEnable=false

[security]

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

    configure_gnome_terminal || \
        echo -e "${YELLOW}Warning: menu launchers may not open in a terminal${RESET}"

    echo -e "${GREEN}GNOME installed successfully. Please reboot to apply changes.${RESET}"
}

enable_root_login() {
    echo -e "${BLUE}Enabling root login in GDM...${RESET}"

    local conf_file="/etc/gdm3/daemon.conf"
    local backup_file
    backup_file="${conf_file}.bak.$(date +%Y%m%d_%H%M%S)"

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

    local ssh_conf="/etc/ssh/sshd_config.d/01-setupkali-root.conf"
    mkdir -p /etc/ssh/sshd_config.d
    cat > "$ssh_conf" <<'SSHEOF'
# Added by setupkali: the root password (e.g. 'ucybers') is never accepted over SSH
PermitRootLogin prohibit-password
SSHEOF
    chmod 644 "$ssh_conf"
    if command -v sshd &>/dev/null && ! sshd -t 2>/dev/null; then
        echo -e "${RED}SSH config test failed — removing $ssh_conf${RESET}"
        rm -f "$ssh_conf"
    else
        systemctl is-active --quiet ssh && systemctl reload ssh
        echo -e "${GREEN}[OK] SSH root login with password is disabled${RESET}"
    fi

    echo -e "${BLUE}Setting root password...${RESET}"

    local virt
    virt=$(systemd-detect-virt --vm 2>/dev/null) || virt="none"

    local desktop_vm="no"
    case "$virt" in
        vmware|oracle|microsoft|parallels) desktop_vm="yes" ;;
    esac

    local use_default="no"
    if [[ "$desktop_vm" == "yes" && -t 0 ]]; then
        echo -e "${YELLOW}Default password is: ucybers${RESET}"
        echo -e "${RED}[!] SECURITY NOTICE:${RESET}"
        echo -e "${YELLOW}    The 'ucybers' password is intended ONLY for an isolated local${RESET}"
        echo -e "${YELLOW}    training VM (VMware/VirtualBox using NAT or Host-Only networking).${RESET}"
        echo -e "${YELLOW}    Do NOT use it in bridged mode or on a network you do not control.${RESET}"
        echo -e "${GREEN}Virtual machine detected: ${virt}${RESET}"
        while true; do
            echo -ne "Keep default password 'ucybers'? [Y/n]: "
            read -r use_default || { echo; echo -e "${RED}Input closed — root password NOT changed.${RESET}"; return 1; }
            case "${use_default,,}" in
                y|"") use_default="yes"; break ;;
                n)    use_default="no";  break ;;
                *)    echo -e "${RED}  Invalid input. Please enter Y or N.${RESET}" ;;
            esac
        done
    else
        if [[ ! -t 0 ]]; then
            echo -e "${YELLOW}[!] No interactive terminal — a random root password will be generated.${RESET}"
        elif [[ "$virt" == "none" ]]; then
            echo -e "${YELLOW}[!] Physical machine: the default 'ucybers' password is not offered.${RESET}"
        else
            echo -e "${YELLOW}[!] Server/cloud VM (${virt}): the default 'ucybers' password is not offered.${RESET}"
        fi
    fi

    if [[ "$use_default" == "yes" ]]; then
        printf '%s:%s\n' "root" "ucybers" | chpasswd
        echo -e "${GREEN}Root password set to: ucybers${RESET}"
    else
        local root_pass root_pass2 choice="g"
        if [[ -t 0 ]]; then
            while true; do
                echo -ne "Root password: [G]enerate a random one, or [T]ype your own? [G/t]: "
                read -r choice || { echo; echo -e "${RED}Input closed — root password NOT changed.${RESET}"; return 1; }
                case "${choice,,}" in
                    g|"") choice="g"; break ;;
                    t)    choice="t"; break ;;
                    *)    echo -e "${RED}  Please enter G or T.${RESET}" ;;
                esac
            done
        fi

        if [[ "$choice" == "t" ]]; then
            while true; do
                read -rs -p "  Enter new root password: " root_pass || { echo; return 1; }
                echo ""
                read -rs -p "  Confirm root password: " root_pass2 || { echo; return 1; }
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
            echo -e "${GREEN}Root password updated successfully.${RESET}"
        else
            root_pass=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 20)
            printf '%s:%s\n' "root" "$root_pass" | chpasswd
            if [[ -t 0 ]]; then
                echo -e "${GREEN}Root password set to: ${BOLD}${root_pass}${RESET}"
                echo -e "${YELLOW}Write it down now: it is shown only once.${RESET}"
            else
                local pass_file="/root/setupkali-root-password.txt"
                ( umask 077; printf '%s\n' "$root_pass" > "$pass_file" )
                echo -e "${GREEN}Root password set. It was saved to ${pass_file} (mode 600).${RESET}"
                echo -e "${YELLOW}Read it once, then delete the file.${RESET}"
            fi
        fi
        unset root_pass root_pass2
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

    
    local apps_dir="/usr/local/share/applications"
    mkdir -p "$apps_dir" || return 1

    cat > "$apps_dir/org.gnome.Nautilus.desktop" <<'DESKEOF'
[Desktop Entry]
Name=Files
Comment=Access and organize files
Exec=nemo %U
Icon=system-file-manager
Type=Application
DBusActivatable=false
MimeType=inode/directory;application/x-gnome-saved-search;
Categories=GNOME;GTK;Core;
DESKEOF
    chmod 644 "$apps_dir/org.gnome.Nautilus.desktop"
    update-desktop-database "$apps_dir" || true
    echo -e "${GREEN}Files launcher now opens Nemo.${RESET}"

    local mime_file
    for mime_file in /etc/xdg/gnome-mimeapps.list /etc/xdg/mimeapps.list; do
        [[ -f "$mime_file" ]] && backup_apt_file "$mime_file" > /dev/null
        python3 - "$mime_file" <<'PYEOF' || echo -e "${YELLOW}Warning: could not update $mime_file${RESET}"
import configparser, os, sys, tempfile

path = sys.argv[1]
cp = configparser.RawConfigParser(strict=False, delimiters=("=",), interpolation=None)
cp.optionxform = str                      # keep the case of mime types
if os.path.exists(path):
    cp.read(path, encoding="utf-8")
if not cp.has_section("Default Applications"):
    cp.add_section("Default Applications")
for mime in ("inode/directory", "application/x-gnome-saved-search"):
    cp.set("Default Applications", mime, "nemo.desktop")

os.makedirs(os.path.dirname(path), exist_ok=True)
fd, tmp = tempfile.mkstemp(dir=os.path.dirname(path), suffix=".tmp")
with os.fdopen(fd, "w", encoding="utf-8") as f:
    cp.write(f, space_around_delimiters=False)
os.chmod(tmp, 0o644)
os.replace(tmp, path)
PYEOF
    done
    echo -e "${GREEN}Nemo set as the default file manager for all users.${RESET}"

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

is_desktop_vm() {
    local virt
    virt=$(systemd-detect-virt --vm 2>/dev/null) || return 1
    case "$virt" in
        vmware|oracle|microsoft|parallels) return 0 ;;
        *) return 1 ;;
    esac
}

configure_gnome_defaults() {
    echo -e "${BLUE}Setting GNOME defaults (dash, dock, background, icons)...${RESET}"

    apt-get install -y dconf-cli || return 1

    local profile="/etc/dconf/profile/user"
    local keyfile="/etc/dconf/db/local.d/01-setupkali-desktop"

    mkdir -p /etc/dconf/profile /etc/dconf/db/local.d || return 1

    if [[ ! -f "$profile" ]]; then
        printf 'user-db:user\nsystem-db:local\n' > "$profile"
    elif ! grep -qx 'system-db:local' "$profile"; then
        echo 'system-db:local' >> "$profile"
    fi

    cat > "$keyfile" <<'DCONFEOF'
[org/gnome/shell]
favorite-apps=['terminator.desktop', 'org.gnome.Terminal.desktop', 'firefox-esr.desktop', 'nemo.desktop', 'kali-metasploit-framework.desktop', 'kali-burpsuite.desktop', 'kali-maltego.desktop', 'kali-beef-xss.desktop', 'org.xfce.mousepad.desktop']

[org/gnome/shell/extensions/dash-to-dock]
dock-position='LEFT'

[org/gnome/desktop/interface]
icon-theme='Vibrancy-Kali'

[org/gnome/desktop/background]
picture-uri='file:///usr/share/backgrounds/kali/kali-tiles-16x9.jpg'
picture-uri-dark='file:///usr/share/backgrounds/kali/kali-tiles-16x9.jpg'
DCONFEOF

    if is_desktop_vm; then
        cat >> "$keyfile" <<'DCONFEOF'

[org/gnome/settings-daemon/plugins/power]
sleep-inactive-ac-type='nothing'
sleep-inactive-ac-timeout=0
sleep-inactive-battery-type='nothing'
sleep-inactive-battery-timeout=0
power-button-action='nothing'

[org/gnome/desktop/session]
idle-delay=uint32 0

[org/gnome/desktop/screensaver]
lock-enabled=false
DCONFEOF
        echo -e "${YELLOW}Desktop VM: sleep and screen lock are disabled for all users.${RESET}"
    else
        echo -e "${GREEN}Screen lock and power settings left unchanged (not a desktop VM).${RESET}"
    fi

    dconf update || {
        echo -e "${RED}dconf update failed${RESET}"
        return 1
    }

    echo -e "${GREEN}[OK] GNOME defaults will apply at the next login${RESET}"
}

configure_dash_apps() {
    echo -e "${BLUE}Configuring Dash applications...${RESET}"
    configure_gnome_defaults
}

apply_gnome_settings_on_login() {
    rm -f /root/.config/autostart/setupkali-gnome-settings.desktop
    configure_gnome_defaults
}

change_background() {
    local BACKGROUND_IMAGE="/usr/share/backgrounds/kali/kali-cubes-16x9.jpg"
    
    echo -e "\n  ${GREEN}Changing root user's desktop background...${RESET}"
    
    
    sudo -u root gsettings set org.gnome.desktop.background picture-uri "file://$BACKGROUND_IMAGE"
    sudo -u root gsettings set org.gnome.desktop.background picture-uri-dark "file://$BACKGROUND_IMAGE"
    
    echo -e "\n  ${GREEN}Background changed to ${BACKGROUND_IMAGE}${RESET}"
}
fix_bad_apt_hash() {
    echo -e "\n  ${BLUE}Checking APT package lists...${RESET}"

    if apt-get update; then
        echo -e "\n  ${GREEN}APT lists are healthy - nothing to clean.${RESET}"
        return 0
    fi

    echo -e "\n  ${YELLOW}apt update failed - clearing the package lists and retrying...${RESET}"
    find /var/lib/apt/lists -mindepth 1 -maxdepth 1 ! -name lock ! -name partial -exec rm -rf {} +
    apt-get clean
    apt-get update --fix-missing || true
    echo -e "\n  ${GREEN}APT cache cleaned.${RESET}"
}

backup_apt_file() {
    local src="$1"
    local backup_dir="/var/backups/setupkali" dest
    dest="${backup_dir}/$(basename "$src").bak.$(date +%Y%m%d_%H%M%S)"

    mkdir -p "$backup_dir" || return 1
    cp -p "$src" "$dest" || return 1
    echo "$dest"
}

move_stray_apt_backups() {
    local stray
    for stray in /etc/apt/sources.list.d/*.bak*; do
        [[ -e "$stray" ]] || continue
        mkdir -p /var/backups/setupkali || return 1
        mv -- "$stray" /var/backups/setupkali/ && \
            echo -e "  ${YELLOW}Moved old backup out of sources.list.d: $(basename "$stray")${RESET}"
    done
    return 0
}


fix_sources() {
    fix_bad_apt_hash

    local new_sources="/etc/apt/sources.list.d/kali.sources"
    local old_sources="/etc/apt/sources.list"

    echo -e "\n  ${BLUE}Fixing APT sources...${RESET}"

    if [[ -f "$new_sources" ]]; then
        echo -e "\n  ${GREEN}Detected Kali 2026.2+ deb822 format${RESET}"

        local backup_file
        backup_file=$(backup_apt_file "$new_sources") || {
            echo -e "\n  ${RED}Failed to backup kali.sources — aborting${RESET}"
            return 1
        }
        move_stray_apt_backups
        echo -e "\n  ${GREEN}Backup saved to: $backup_file${RESET}"

        # Add deb-src if missing
        if ! grep -q "^Types:.*deb-src" "$new_sources"; then
            sed -i 's/^Types: deb$/Types: deb deb-src/' "$new_sources"
            echo -e "\n  $greenplus deb-src enabled in kali.sources"
        else
            echo -e "\n  $greenminus deb-src already enabled — skipping"
        fi

        # Ensure non-free-firmware is present
        if ! grep -q "non-free-firmware" "$new_sources"; then
            sed -i 's/non-free$/non-free non-free-firmware/' "$new_sources"
            echo -e "\n  $greenplus non-free-firmware added"
        fi

        echo -e "\n  ${GREEN}APT sources fixed successfully (deb822 format).${RESET}"
        return 0
    fi

    # Fallback — legacy sources.list format (Kali 2026.1 and older)
    if [[ -f "$old_sources" ]]; then
        echo -e "\n  ${BLUE}Detected legacy sources.list format${RESET}"

        local backup_file
        backup_file=$(backup_apt_file "$old_sources") || {
            echo -e "\n  ${RED}Failed to backup sources.list — aborting${RESET}"
            return 1
        }
        move_stray_apt_backups
        echo -e "\n  ${GREEN}Backup saved to: $backup_file${RESET}"

        local current_mirror
        current_mirror=$(grep -m1 "^deb http" "$old_sources" | cut -d'/' -f3 || true)

        if [[ -z "$current_mirror" ]]; then
            echo -e "\n  ${RED}Could not detect current mirror — aborting${RESET}"
            return 1
        fi

        echo -e "\n  ${BLUE}Detected mirror: $current_mirror${RESET}"

        local check_space check_nospace
        check_space=$(grep -c "^# deb-src http.*/kali kali-rolling" "$old_sources" || true)
        check_nospace=$(grep -c "^#deb-src http.*/kali kali-rolling" "$old_sources" || true)

        if [[ "$check_space" -eq 0 && "$check_nospace" -eq 0 ]]; then
            echo -e "\n  $greenminus deb-src not found — skipping"
        elif [[ "$check_space" -ge 1 ]]; then
            sed -i "s|^# deb-src http.*/kali kali-rolling.*|deb-src http://${current_mirror}/kali kali-rolling main contrib non-free|" \
                "$old_sources"
            echo -e "\n  $greenplus deb-src enabled"
        elif [[ "$check_nospace" -ge 1 ]]; then
            sed -i "s|^#deb-src http.*/kali kali-rolling.*|deb-src http://${current_mirror}/kali kali-rolling main contrib non-free|" \
                "$old_sources"
            echo -e "\n  $greenplus deb-src enabled"
        fi

        if grep -q "non-free$" "$old_sources"; then
            sed -i 's/non-free$/non-free non-free-firmware/' "$old_sources"
            echo -e "\n  $greenplus non-free-firmware added"
        fi

        echo -e "\n  ${GREEN}APT sources fixed successfully (legacy format).${RESET}"
        return 0
    fi

    echo -e "\n  ${RED}No APT sources file found — skipping${RESET}"
}

apt_update() {
    echo -e "\n  ${GREEN}running: apt update${RESET}"
    apt-get -y update -o Dpkg::Progress-Fancy="1" || {
        echo -e "\n  ${RED}apt update failed${RESET}"
        return 1
    }
}

disable_power_checkde() {
        echo -e "\n  ${GREEN}GNOME is installed on the system${RESET}"
        disable_power_gnome
}


disable_power_gnome() {
    if ! is_desktop_vm; then
        echo -e "\n  ${GREEN}Not a desktop VM - power and screen lock settings left unchanged${RESET}"
        return 0
    fi
    echo -e "\n  ${GREEN}GNOME detected - Disabling Power Savings${RESET}"
    sudo -u root gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type nothing
    echo -e "  ${GREEN}org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type nothing${RESET}"
    sudo -u root gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 0
    echo -e "  ${GREEN}org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 0${RESET}"
    sudo -u root gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type nothing
    echo -e "  ${GREEN}org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type nothing${RESET}"
    sudo -u root gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout 0
    echo -e "  ${GREEN}org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout 0${RESET}"
    sudo -u root gsettings set org.gnome.settings-daemon.plugins.power power-button-action nothing
    echo -e "  ${GREEN}org.gnome.settings-daemon.plugins.power power-button-action nothing${RESET}"
    sudo -u root gsettings set org.gnome.settings-daemon.plugins.power idle-brightness 0
    echo -e "  ${GREEN}org.gnome.settings-daemon.plugins.power idle-brightness 0${RESET}"
    sudo -u root gsettings set org.gnome.desktop.session idle-delay 0
    echo -e "  ${GREEN}org.gnome.desktop.session idle-delay 0${RESET}"
    sudo -u root gsettings set org.gnome.desktop.screensaver lock-enabled false
    echo -e "  ${GREEN}org.gnome.desktop.screensaver lock-enabled false${RESET}\n"
}

apt_update_complete() {
        echo -e "\n  ${GREEN}apt update - complete${RESET}"
    }

fix_nmap() {
    echo -e "\n  ${BLUE}Fixing nmap scripts...${RESET}"

    local nmap_commit="1bb2586a85ae41dc6824a8405e44d17309e9288c"
    local clamav_sha256="34c7b72531cc6aa6b073c2a23c17903a2ff6b1e96d9419cc6536bdf91da020c9"
    local clamav_url="https://raw.githubusercontent.com/nmap/nmap/${nmap_commit}/scripts/clamav-exec.nse"

    local shellshock_sha256="db5f4d608c1e2ec103526cb5b20f3ad464ebef1a529a626caedbfce707f6075e"
    local script_dir local_shellshock actual
    script_dir="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
    local_shellshock="${script_dir}/fixed-http-shellshock.nse"

    local nse_dir="/usr/share/nmap/scripts"
    local tmp_dir

    if [[ ! -d "$nse_dir" ]]; then
        echo -e "\n  ${RED}nmap scripts directory not found — is nmap installed?${RESET}"
        return 1
    fi

    if [[ ! -f "$local_shellshock" ]]; then
        echo -e "\n  ${RED}Missing $local_shellshock — run the script from the setupkali folder${RESET}"
        return 1
    fi

    actual=$(sha256sum "$local_shellshock" | awk '{print $1}')
    if [[ "$actual" != "$shellshock_sha256" ]]; then
        INTEGRITY_FAILURE=1
        echo -e "${RED}[!!] SHA-256 mismatch for fixed-http-shellshock.nse${RESET}"
        echo -e "${RED}     expected: $shellshock_sha256${RESET}"
        echo -e "${RED}     actual:   $actual${RESET}"
        return 1
    fi
    echo -e "${GREEN}[OK] SHA-256 verified: fixed-http-shellshock.nse${RESET}"

    tmp_dir=$(mktemp -d /tmp/nmap_fix_XXXXXX)

    echo -e "\n  ${BLUE}Downloading clamav-exec.nse (nmap v7.991)...${RESET}"
    download_verified "$clamav_url" "$tmp_dir/clamav-exec.nse" "$clamav_sha256" || {
        rm -rf "$tmp_dir"
        return 1
    }

    if ! install -m 0644 -o root -g root "$tmp_dir/clamav-exec.nse" "$nse_dir/clamav-exec.nse" ||
       ! install -m 0644 -o root -g root "$local_shellshock" "$nse_dir/http-shellshock.nse"; then
        echo -e "\n  ${RED}Failed to install nmap scripts${RESET}"
        rm -rf "$tmp_dir"
        return 1
    fi

    rm -rf "$tmp_dir"
    nmap --script-updatedb &>/dev/null || true

    echo -e "\n  ${GREEN}Nmap scripts updated successfully.${RESET}"
}

apt_upgrade() {
    echo -e "\n  $greenplus Running full system upgrade...\n"

    apt-get update || {
        echo -e "\n  ${RED}apt update failed${RESET}"
        return 1
    }

    apt-get -y upgrade -o Dpkg::Progress-Fancy="1" -o Dpkg::Options::="--force-confold" || {
        echo -e "\n  ${RED}apt upgrade failed${RESET}"
        return 1
    }

    apt-get -y dist-upgrade -o Dpkg::Progress-Fancy="1" -o Dpkg::Options::="--force-confold" || {
        echo -e "\n  ${RED}dist-upgrade failed${RESET}"
        return 1
    }

    apt-get -y autoremove
    apt-get -y autoclean

    apt_upgrade_complete
}

apt_upgrade_complete() {
    echo -e "\n  $greenplus apt upgrade complete"
    echo -e "\n  ${GREEN}System upgrade finished successfully.${RESET}"
}

install_wifi_hotspot() {
    echo -e "${BLUE}Installing linux-wifi-hotspot...${RESET}"

    local hotspot_repo="https://github.com/lakinduakash/linux-wifi-hotspot"
    local hotspot_commit="63c2168626a0b13015913d52d5dbd5e1d91a7fb6"

    apt-get install -y build-essential libgtk-3-dev hostapd libqrencode-dev libpng-dev pkg-config || return 1

    local build_user="nobody"
    if [[ -n "${SUDO_USER:-}" && "$SUDO_USER" != "root" ]] && id "$SUDO_USER" &>/dev/null; then
        build_user="$SUDO_USER"
    fi

    local tmp_dir head_commit
    tmp_dir=$(mktemp -d /tmp/wifi_hotspot_XXXXXX)

    echo -e "${BLUE}Fetching linux-wifi-hotspot v5.0.0 (commit ${hotspot_commit:0:7})...${RESET}"
    if ! git -C "$tmp_dir" init -q ||
       ! git -C "$tmp_dir" fetch -q --depth=1 "$hotspot_repo" "$hotspot_commit" ||
       ! git -C "$tmp_dir" -c advice.detachedHead=false checkout -q FETCH_HEAD; then
        echo -e "${RED}Failed to fetch pinned linux-wifi-hotspot commit${RESET}"
        rm -rf "$tmp_dir"
        return 1
    fi

    head_commit=$(git -C "$tmp_dir" rev-parse HEAD)
    if [[ "$head_commit" != "$hotspot_commit" ]]; then
        INTEGRITY_FAILURE=1
        echo -e "${RED}[!!] Commit mismatch for linux-wifi-hotspot${RESET}"
        echo -e "${RED}     expected: $hotspot_commit${RESET}"
        echo -e "${RED}     actual:   $head_commit${RESET}"
        rm -rf "$tmp_dir"
        return 1
    fi
    echo -e "${GREEN}[OK] Commit verified: linux-wifi-hotspot ${hotspot_commit:0:7}${RESET}"

    chown -R "$build_user": "$tmp_dir"

    echo -e "${BLUE}Building as user: ${build_user}${RESET}"
    runuser -u "$build_user" -- env HOME="$tmp_dir" make -C "$tmp_dir" || {
        echo -e "${RED}linux-wifi-hotspot build failed${RESET}"
        rm -rf "$tmp_dir"
        return 1
    }

    chown -R root:root "$tmp_dir"

    make -C "$tmp_dir" install || {
        echo -e "${RED}linux-wifi-hotspot install failed${RESET}"
        rm -rf "$tmp_dir"
        return 1
    }

    rm -rf "$tmp_dir"
    echo -e "${GREEN}linux-wifi-hotspot installed successfully.${RESET}"
}



firefox_set_policy() {
    python3 - "$1" "$2" <<'PYEOF'
import json, os, sys, tempfile

name, value = sys.argv[1], json.loads(sys.argv[2])
etc_file  = "/etc/firefox/policies/policies.json"
kali_file = "/usr/share/firefox-esr/distribution/policies.json"

# Start from our file if it exists, otherwise from Kali's policies
source = etc_file if os.path.exists(etc_file) else kali_file
if os.path.exists(source):
    try:
        with open(source) as f:
            data = json.load(f)
    except (OSError, ValueError) as e:
        sys.exit(f"Cannot read {source}: {e} — nothing changed")
else:
    data = {}

if not isinstance(data.get("policies", {}), dict):
    sys.exit(f"Unexpected format in {source} — nothing changed")

data.setdefault("policies", {})[name] = value

# Write to a temp file first, then replace in one step
os.makedirs(os.path.dirname(etc_file), exist_ok=True)
fd, tmp = tempfile.mkstemp(dir=os.path.dirname(etc_file), suffix=".tmp")
with os.fdopen(fd, "w") as f:
    json.dump(data, f, indent=2)
os.chmod(tmp, 0o644)
os.replace(tmp, etc_file)
PYEOF
}

add_firefox_bookmarks() {
    echo -e "${BLUE}Configuring Firefox bookmarks...${RESET}"

    firefox_set_policy "Bookmarks" '[
        {"Title": "UCYBERS",                "URL": "https://ucybers.com",                       "Toolbar": true},
        {"Title": "UCYBERS Certifications", "URL": "https://certifications.ucybers.com",         "Toolbar": true},
        {"Title": "UCYBERS Academy",        "URL": "https://academy.ucybers.com",                "Toolbar": true},
        {"Title": "UCYBERS YouTube",        "URL": "https://www.youtube.com/@ucybers",           "Toolbar": true},
        {"Title": "UCYBERS FB",             "URL": "https://www.facebook.com/ucybersx",          "Toolbar": true},
        {"Title": "UCYBERS Twitter",        "URL": "https://x.com/ucybersx",                     "Toolbar": true},
        {"Title": "UCYBERS Linkedin",       "URL": "https://www.linkedin.com/company/ucybersx", "Toolbar": true}
    ]' || {
        echo -e "${RED}Failed to configure bookmarks${RESET}"
        return 1
    }

    echo -e "${GREEN}Firefox bookmarks configured successfully.${RESET}"
}

setup_firefox_custom_homepage() {
    echo -e "${BLUE}Setting up custom Firefox homepage...${RESET}"

    local startpage_url="https://github.com/UCYBERS/setupkali/releases/download/1.1.6/startpage.7z"
    local startpage_dir="/var/startpage"
    local startpage_file
    startpage_file=$(mktemp /tmp/startpage_XXXXXX.7z) || return 1
    local homepage_path="file://${startpage_dir}/startpage/ucybers.html"

    if ! command -v 7z &>/dev/null; then
        apt-get install -y 7zip || {
            echo -e "${RED}Failed to install 7zip${RESET}"
            rm -f "$startpage_file"
            return 1
        }
    fi

    echo -e "${BLUE}Downloading startpage...${RESET}"
    download_verified "$startpage_url" "$startpage_file" "${ASSET_SHA256[startpage.7z]}" || {
        rm -f "$startpage_file"
        return 1
    }

    mkdir -p "$startpage_dir"
    7z x "$startpage_file" -o"${startpage_dir}/" -y || {
        echo -e "${RED}Failed to extract startpage${RESET}"
        rm -f "$startpage_file"
        return 1
    }
    rm -f "$startpage_file"

    if [[ ! -f "${startpage_dir}/startpage/ucybers.html" ]]; then
        echo -e "${RED}ucybers.html not found after extraction${RESET}"
        return 1
    fi

    firefox_set_policy "Homepage" "{
        \"URL\": \"${homepage_path}\",
        \"Locked\": false,
        \"StartPage\": \"homepage\"
    }" || {
        echo -e "${RED}Failed to set homepage in policies${RESET}"
        return 1
    }

    echo -e "${GREEN}Firefox homepage set to local startpage.${RESET}"
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
    echo -e "${BLUE}Installing Zenmap...${RESET}"

    if apt-cache show zenmap &>/dev/null; then
    apt-get install -y zenmap || return 1
    echo -e "${GREEN}Zenmap installed via apt.${RESET}"
    return 0
    fi
    echo -e "${YELLOW}zenmap-kbx not found in repo — trying Flatpak...${RESET}"

    if ! command -v flatpak &>/dev/null; then
        apt-get install -y flatpak || {
            echo -e "${RED}Failed to install flatpak${RESET}"
            return 1
        }
        flatpak remote-add --if-not-exists flathub \
            https://flathub.org/repo/flathub.flatpakrepo || true
    fi

    flatpak install -y flathub org.nmap.Zenmap || {
        echo -e "${RED}Failed to install Zenmap via Flatpak${RESET}"
        return 1
    }

    echo -e "${GREEN}Zenmap installed via Flatpak.${RESET}"
}

install_network_driver() {
    echo -e "${BLUE}Checking wireless drivers...${RESET}"

    local -a drivers=(
        "rtw88_8812au"
        "rtw88_8814au"
        "rtw88_8821au"
        "ath9k_htc"
        "mt76x2u"
        "mt7921u"
    )

    for driver in "${drivers[@]}"; do
        if modinfo "$driver" &>/dev/null; then
            modprobe "$driver" 2>/dev/null || true
            echo -e "${GREEN}✔ $driver loaded${RESET}"
        else
            echo -e "${YELLOW}! $driver not available${RESET}"
        fi
    done

    apt-get install -y aircrack-ng iw wireless-tools rfkill || \
        echo -e "${YELLOW}Warning: Some wireless tools failed to install${RESET}"

    echo -e "${GREEN}Wireless drivers configured successfully.${RESET}"
}

install_bettercap() {
    echo -e "${YELLOW}Installing bettercap...${RESET}"

    local caplets_repo="https://github.com/bettercap/caplets.git"
    local caplets_commit="eb626871ad99ea8c4f9771f216caa2290e06a058"

    apt-get install -y bettercap || {
        echo -e "${RED}Failed to install bettercap${RESET}"
        return 1
    }

    if ! command -v bettercap &>/dev/null; then
        echo -e "${RED}bettercap installation could not be verified${RESET}"
        return 1
    fi

    echo -e "${GREEN}bettercap installed successfully!${RESET}"

    local caplets_tmp head_commit
    caplets_tmp=$(mktemp -d /tmp/caplets_XXXXXX)

    echo -e "${YELLOW}Fetching bettercap caplets (commit ${caplets_commit:0:7})...${RESET}"
    if ! git -C "$caplets_tmp" init -q ||
       ! git -C "$caplets_tmp" fetch -q --depth=1 "$caplets_repo" "$caplets_commit" ||
       ! git -C "$caplets_tmp" -c advice.detachedHead=false checkout -q FETCH_HEAD; then
        echo -e "${RED}Failed to fetch pinned caplets commit${RESET}"
        rm -rf "$caplets_tmp"
        return 1
    fi

    head_commit=$(git -C "$caplets_tmp" rev-parse HEAD)
    if [[ "$head_commit" != "$caplets_commit" ]]; then
        INTEGRITY_FAILURE=1
        echo -e "${RED}[!!] Commit mismatch for caplets${RESET}"
        echo -e "${RED}     expected: $caplets_commit${RESET}"
        echo -e "${RED}     actual:   $head_commit${RESET}"
        rm -rf "$caplets_tmp"
        return 1
    fi
    echo -e "${GREEN}[OK] Commit verified: caplets ${caplets_commit:0:7}${RESET}"

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
    local url="https://github.com/UCYBERS/setupkali/releases/download/1.1.5/hstshijack.zip"
    local dest_dir="/usr/local/share/bettercap/caplets/hstshijack"
    local tmp_zip tmp_dir

    tmp_zip=$(mktemp /tmp/hstshijack_XXXXXX.zip)
    tmp_dir=$(mktemp -d /tmp/hstshijack_dir_XXXXXX)

    echo -e "${YELLOW}Downloading hstshijack...${RESET}"
    download_verified "$url" "$tmp_zip" "${ASSET_SHA256[hstshijack.zip]}" || {
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
    local old_dir=""
    if [[ -d "$dest_dir" ]]; then
        old_dir="${dest_dir}.old.$$"
        mv "$dest_dir" "$old_dir" || {
            echo -e "${RED}Could not move the existing hstshijack aside${RESET}"
            rm -f "$tmp_zip"
            rm -rf "$tmp_dir"
            return 1
        }
    fi
    mv "$tmp_dir/hstshijack" "$dest_dir" || {
        echo -e "${RED}Failed to move hstshijack to destination${RESET}"
        [[ -n "$old_dir" ]] && mv "$old_dir" "$dest_dir"
        rm -f "$tmp_zip"
        rm -rf "$tmp_dir"
        return 1
    }
    [[ -n "$old_dir" ]] && rm -rf "$old_dir"

    rm -f "$tmp_zip"
    rm -rf "$tmp_dir"
    echo -e "${GREEN}hstshijack replaced successfully.${RESET}"
}
install_python2_pip() {
    echo -e "${BLUE}Installing pip for Python 2...${RESET}"

    local getpip_commit="831b5dd0bec03caf24aa6d736a28dc2ba80f91cc"
    local getpip_sha256="40ee07eac6674b8d60fce2bbabc148cf0e2f1408c167683f110fd608b8d6f416"
    local getpip_url="https://raw.githubusercontent.com/pypa/get-pip/${getpip_commit}/public/2.7/get-pip.py"
    local tmp_dir

    if ! command -v python2 &>/dev/null; then
        echo -e "${YELLOW}python2 not installed — skipping${RESET}"
        return 0
    fi

    if python2 -m pip --version &>/dev/null; then
        echo -e "${GREEN}pip2 already installed${RESET}"
        return 0
    fi

    tmp_dir=$(mktemp -d /tmp/get_pip2_XXXXXX)

    download_verified "$getpip_url" "$tmp_dir/get-pip.py" "$getpip_sha256" || {
        rm -rf "$tmp_dir"
        return 1
    }

    python2 "$tmp_dir/get-pip.py" || {
        echo -e "${RED}get-pip.py failed${RESET}"
        rm -rf "$tmp_dir"
        return 1
    }

    rm -rf "$tmp_dir"
    echo -e "${GREEN}pip2 installed successfully${RESET}"
}

install_hacking_tools() {
    echo -e "${YELLOW}Starting installation of hacking tools...${RESET}"

    apt-get update || {
        echo -e "${RED}apt update failed${RESET}"
        return 1
    }

    apt-get install -y htop python3 python3-pip python3-venv || \
        echo -e "${YELLOW}Warning: Some packages failed to install${RESET}"

    local part
    local -a failed_parts=()
    for part in add_firefox_bookmarks setup_firefox_custom_homepage install_zenmap \
                install_bettercap replace_hstshijack install_python2_pip; do
        "$part" || failed_parts+=("$part")
    done

    if (( ${#failed_parts[@]} > 0 )); then
        echo -e "${RED}Hacking tools finished with failures: ${failed_parts[*]}${RESET}"
        return 1
    fi

    echo -e "${GREEN}Hacking tools installation complete.${RESET}"
}




FAILED_STEPS=()
STEP_MAX_ATTEMPTS=3

repair_apt() {
    echo -e "${YELLOW}  Repairing APT before retrying...${RESET}"
    dpkg --configure -a &>/dev/null
    apt-get -f install -y &>/dev/null
    apt-get update &>/dev/null
}

run_step() {
    local step="$1" attempt=1 answer
    while true; do
        INTEGRITY_FAILURE=0
        "$@" && return 0

        if (( INTEGRITY_FAILURE )); then
            echo -e "\n${RED}[FAILED] ${step}: integrity check failed - not retrying.${RESET}"
            FAILED_STEPS+=("$step")
            return 1
        fi

        if (( attempt < STEP_MAX_ATTEMPTS )); then
            echo -e "\n${YELLOW}[RETRY] ${step} failed (attempt ${attempt}/${STEP_MAX_ATTEMPTS}) — retrying in 5 seconds...${RESET}"
            repair_apt
            sleep 5
            attempt=$((attempt + 1))
            continue
        fi

        echo -e "\n${RED}[FAILED] ${step} failed ${STEP_MAX_ATTEMPTS} times.${RESET}"

        if [[ ! -t 0 ]]; then
            FAILED_STEPS+=("$step")
            return 1
        fi

        while true; do
            read -r -p "  Press Enter to retry ${step} again, or type 's' to skip it: " answer || answer="s"
            case "${answer,,}" in
                "") attempt=1; continue 2 ;;
                s)  FAILED_STEPS+=("$step")
                    echo -e "${YELLOW}  Skipped: ${step}${RESET}"
                    return 1 ;;
                *)  echo -e "${RED}  Press Enter to retry, or type 's' to skip.${RESET}" ;;
            esac
        done
    done
}

setup_all() {
    echo -e "${BLUE}Starting full system setup...${RESET}"

    run_step fix_sources
    run_step apt_update && apt_update_complete

    run_step change_to_gnome || {
        echo -e "${RED}GNOME installation failed — aborting setup${RESET}"
        return 1
    }

    run_step enable_root_login

    run_step install_basic_packages
    run_step install_tools_for_root
    run_step install_hacking_tools
    run_step fix_nmap
    run_step install_wifi_hotspot
    run_step install_network_driver

    run_step install_icons
    run_step change_background
    run_step configure_dock_for_root
    run_step configure_dash_apps
    run_step apply_gnome_settings_on_login
    run_step disable_power_checkde

    if (( ${#FAILED_STEPS[@]} > 0 )); then
        echo -e "${YELLOW}Full setup finished with errors — see the summary below.${RESET}"
        return 1
    fi
    echo -e "${GREEN}Full setup complete. Please reboot to apply all changes.${RESET}"
}



confirm_menu_choice() {
    case "$menuinput" in
        0|1|2|3|4|5|6) ;;
        *)
            echo -e "\n${RED}  Invalid option: '${menuinput}'. Please try again.${RESET}"
            return 1
            ;;
    esac

    if [ "$menuinput" == "0" ]; then
        clear
        echo -e "${BOLD}${deep_green}$asciiart${RESET}"
        echo -e "\n${RED}Happy Hacking!${RESET} ${GREEN}Setup completed! ${RESET}\n"
        
        exit 0
    fi

    echo -e ""
    echo -ne " Menu selection is ${deep_green}${menuinput}${RESET} Press ${GREEN}Y${RESET} to confirm or ${RED}N${RESET} to cancel: "
    read -r -n1 selectinput


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
        echo -e "\n    ${YELLOW}Select an option from the menu (v${VERSION}):${RESET}\n"  
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
        
        
        read -r -n1 -p " Press key for menu selection or press 0 to exit: " menuinput
        echo
        
        if confirm_menu_choice "$menuinput"; then
            case $menuinput in
                1) run_step change_to_gnome; break ;;
                2) run_step enable_root_login; break ;;
                3) run_step install_tools_for_root; break ;;
                4) run_step install_hacking_tools; break ;;
                5) run_step apt_upgrade; break ;;
                6) setup_all; break ;;
            esac
        fi
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
    "  -v, --version         - Show the version"
    "  -h, -?, --help        - Show this help message"
    )

    for option in "${options[@]}"; do
        echo -e "$option"
    done
    echo
    exit "${1:-0}"
}

check_arg() {
    if [ "$1" == "--help" ] || [ "$1" == "-h" ] || [ "$1" == "-?" ]; then
        setupkali_help
    elif [ -z "$1" ]; then
        show_menu
    else
        case "$1" in
            --gnome|-g)
                run_step change_to_gnome ;;
            --root|-r)
                run_step enable_root_login ;;
            --tools|-t)
                run_step install_tools_for_root ;;
            --hacking|-H)
                run_step install_hacking_tools ;;
            --upgrade|-u)
                run_step apt_update
                run_step apt_upgrade ;;
            --all|-a|-A)
                setup_all ;;
            --fix-sources|-f)
                run_step fix_sources ;;
            --nmap|-n)
                run_step fix_nmap ;;
            --style|-s)
                run_step configure_dock_for_root
                run_step configure_dash_apps
                run_step install_icons ;;
            --wifi|-w)
                run_step install_wifi_hotspot ;;
            --firefox|-F)
                run_step add_firefox_bookmarks
                run_step setup_firefox_custom_homepage ;;
            --enable-root|-R)
                run_step enable_root_login ;;
            *)
                setupkali_help 1 ;;
        esac
    fi
}



acquire_lock() {
    exec 9> /var/lock/setupkali.lock
    if ! flock -n 9; then
        echo -e "${RED}Another setupkali is already running.${RESET}"
        exit 1
    fi
}

case "${1:-}" in
    -h|--help|"-?") ;;
    *) acquire_lock ;;
esac

check_arg "$1"

clear
echo -e "${BOLD}${deep_green}$asciiart${RESET}"
exit_code=0
if (( ${#FAILED_STEPS[@]} > 0 )); then
    exit_code=1
    echo -e "\n${RED}[!!] Finished with ${#FAILED_STEPS[@]} failed step(s):${RESET}"
    for step in "${FAILED_STEPS[@]}"; do
        echo -e "${RED}     - ${step}${RESET}"
    done
    echo -e "${YELLOW}Run the tool again to retry the failed step(s).${RESET}"
else
    echo -e "\n${RED}Happy Hacking!${RESET}"
    echo -e "${GREEN}Setup completed successfully!${RESET}"
fi

echo -e "${GREEN}Please type 'reboot' to apply the changes and restart the system.${RESET}"
read -r -p "Type 'reboot' to restart: " user_input

if [ "$user_input" == "reboot" ]; then
    sudo reboot
else
    echo -e "\n  ${RED}You must type 'reboot' to restart the system.${RESET}"
fi

exit "$exit_code"
