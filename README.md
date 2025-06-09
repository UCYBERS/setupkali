

![setupkali](https://github.com/user-attachments/assets/98faac4b-9dec-40d4-ba58-1a498719de21)
<p align="center">
  <img src="https://img.shields.io/badge/Author-UCYBERS-red?style=flat-square">
  <img src="https://img.shields.io/badge/Open%20Source-Yes-darkgreen?style=flat-square">
  <img src="https://img.shields.io/badge/Maintained%3F-Yes-lightblue?style=flat-square">
  <img src="https://img.shields.io/badge/Written%20In-Bash-darkcyan?style=flat-square">
  <img src="https://img.shields.io/github/last-commit/ucybers/setupkali">
  <img src="https://img.shields.io/github/repo-size/ucybers/setupkali">
  <a href="https://discord.gg/FXgT8fdGyY">
        <img src="https://img.shields.io/discord/308323056592486420?logo=discord&logoColor=white"
            alt="Chat on Discord"></a>
  <a href="https://ucybers.com">
        <img src="https://img.shields.io/static/v1?label=Website&message=UCYBERS&color=blue&style=flat-square"
            alt="Visit UCYBERS"></a>
  <a href="https://x.com/UCybersX">
        <img src="https://img.shields.io/twitter/url/https/twitter.com/ucybers.svg?style=social&label=Update%20%40ucybers"
            alt="Twitter"></a>
</p>


# setupkali.sh
# Fixes and Enhancements for Kali Linux


   


- **Author**: UCYBERS
- **GitHub Repository**: [setupkali](https://github.com/UCYBERS/setupkali)
- **Usage**: `sudo ./setupkali.sh` (defaults to the menu system)
- **Command Line Arguments**: Valid arguments can be used; only one argument is supported


# 👤🔑 Enabled root login.

- **Username**: root
- **Password**: ucybers

# ✨ Fixes and Features for Kali Linux Setup
- Author assumes zero liability for any data loss or misuse of setupkali
- Menu breakdown added below revision history

# 🪶 Revision History

## Revision 1.0.0 - Initial Release
- Added features for Kali Linux setup
- Included options for package installation and configuration

## Revision 1.1.0 - Feature Enhancements and Improvements

### New Functions Added:
- Introduced the `fix_hushlogin` function to manage `.hushlogin` for root user sessions.
- Added the `fix_sources` function to update and validate APT sources, including enabling `deb-src` and ensuring `non-free-firmware` inclusion.
- Implemented the `apt_autoremove` function for system cleanup post-upgrade.

### Customization Updates:
- Added support for setting a custom Firefox homepage for the root user.
- Improved menu layout and descriptions for better usability.

### Wi-Fi Hotspot Installation:
- Streamlined the installation process for `linux-wifi-hotspot`, ensuring proper package verification and minimal dependencies.

### Kernel Update Integration:
- Included commands for installing kernel headers alongside kernel updates.

### Power Management Tweaks:
- Added `disable_power_gnome` function to optimize GNOME power settings for better performance.

### General Enhancements:
- Optimized the script to ensure functions run under the correct user contexts (e.g., root or kali user as needed).
- Various bug fixes and performance improvements.


# ☰ Menu Breakdown of setupkali

- **Menu Option 1** - Change to GNOME Desktop
  - Installs GNOME and sets it as default
  - Updates the system to remove XFCE and configure GNOME as the primary session

- **Menu Option 2** - Enable Root Login
  - Installs root login and sets the password
  - Sets the root password to 'ucybers'

- **Menu Option 3** - Install Tools for Root
  - Installs a comprehensive list of tools and utilities including:
    - Terminator
    - Leafpad
    - Mousepad
    - Firefox ESR
    - Metasploit Framework
    - Burpsuite
    - Maltego
    - Beef-xss
    - Additional tools like ark, dolphin, gwenview, mdk3, kate, partitionmanager, okular, unix-privesc-check, vlc, zaproxy

- **Menu Option 4** - Install Pen Tools
  - Improved wireless compatibility
      - Atheros AR9271 drivers.
      - Correct RTL8812AU drivers.
      - Realtek RT5370 drivers.
      - Improved Monitor mode, packet injection and AP mode support.

  - Bug fixes:
      - Fixed netdiscover range issue.
      - Fixed Zenmap discovery bugs.
      - Fixed wash and reaver issues with RTL8812AU chipset.
      - Fixed bettercap hstshijack caplet issues.
      - Added modified hstshijack caplet that works properly with HSTS websites.
      - Patched XZ Utils package.
   
  - Additional software:
      - Install WiFi Hotspot
      - Install system monitoring tool
      - Setup Firefox Custom Homepage
      - Add Firefox Bookmarks
      - Install Zenmap
      - Install Network Driver
      - Install MDK4
      - Install Python2 Pip


- **Menu Option 5** - Upgrade System
  - System Upgrade
    - Update package list
    - Upgrade installed packages
    - Perform a full distribution upgrade
    - Clean up unnecessary packages
    - Clean up package cache
  

- **Menu Option 6** - Setup All
  - Executes a series of setup tasks including:
    - Changing to GNOME
    - Enabling root login
    - Installing tools for root
    - Installing and configuring icons
    - Changing the root user's desktop background
    - Fixing APT sources and updating system
    - Installing and configuring WiFi hotspot utilities
    - Configuring GNOME dock and Dash applications
    - Running Python package installations
    - Updating and upgrading system packages
    - Fixing broken packages
    - Fix Nmap
    - Remove Kali Undercover
    - Improved performance
    - Darker theme
    - Darker icons


- **Menu Option 0** - Exit
  - Exits the script



# 🛠️ Installation
```bash
# Remove existing setupkali folder
rm -rf setupkali/

# Clone setupkali repository & enter the folder
sudo git clone https://github.com/UCYBERS/setupkali
cd setupkali

# Execute the script - Run menu options as needed
sudo chmod +x setupkali.sh
# (The script must be run with root privileges)
sudo ./setupkali.sh
```
# TODO
- Improve error handling
- Add more customization options
