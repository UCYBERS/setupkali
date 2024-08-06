# setupkali


# Fixes and Enhancements for Kali Linux
![setupkali](https://github.com/user-attachments/assets/1e438a29-1217-46c9-8278-bcc7e8d55a4a)


- **Author**: UCYBERS
- **GitHub Repository**: [setupkali](https://github.com/UCYBERS/setupkali)
- **Usage**: `sudo ./setupkali.sh` (defaults to the menu system)
- **Command Line Arguments**: Valid arguments can be used; only one argument is supported
# Revision History

# Fixes and Features for Kali Linux Setup
- Author assumes zero liability for any data loss or misuse of setupkali
- Menu breakdown added below revision history

# Revision History

## Revision 1.0.0 - Initial Release
- Added features for Kali Linux setup
- Included options for package installation and configuration

# Menu Breakdown of setupkali

- **Menu Option 1** - Change to GNOME Desktop
  - Installs GNOME and sets it as default

- **Menu Option 2** - Enable Root Login
  - Installs root login and sets the password

- **Menu Option 3** - Install Tools for Root
  - Installs terminator, leafpad, and mousepad for the root user

- **Menu Option 4** - Setup All
  - Runs change GNOME, enable root login, and install tools for root

- **Menu Option 0** - Exit
  - Exits the script

# TODO
- Improve error handling
- Add more customization options

# Installation
```bash
# Remove existing setupkali folder
rm -rf setupkali/

# Clone setupkali repository & enter the folder
git clone https://github.com/UCYBERS/setupkali
cd setupkali

# Execute the script - Run menu options as needed
# (The script must be run with root privileges)
sudo ./setupkali.sh

