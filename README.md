# setupkali.sh
![SetupKali](https://github.com/user-attachments/assets/4159ae20-d7a0-45aa-80f1-b8534f60686a)
<p align="center">
  <img src="https://img.shields.io/badge/version-2.0.1-b5003c">
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

# Fixes and Enhancements for Kali Linux

Setup script for a fresh, up-to-date **Kali Linux** install (GNOME desktop, root login, tools, icons and
UCYBERS start page). Current version: **2.0.1** (`sudo ./setupkali.sh --version`).

- **Author**: UCYBERS
- **GitHub Repository**: [setupkali](https://github.com/UCYBERS/setupkali)
- **Usage**: `sudo ./setupkali.sh` (opens the menu) or `sudo ./setupkali.sh --all`
- **Arguments**: only one argument is accepted per run
- **Changes**: see [CHANGELOG.md](CHANGELOG.md)

> The script is meant for current Kali installs. It refuses to run on anything else and it must be run as root.

# 🛠️ Installation
```console
# Remove an existing copy (if any)
rm -rf setupkali/

# Clone the repository (no sudo needed) and enter the folder
git clone https://github.com/UCYBERS/setupkali
cd setupkali

# Run it with root privileges
sudo ./setupkali.sh
```
The file is already executable, so `chmod +x` is not needed.

To keep a log of a full run:
```console
script -q -c "sudo ./setupkali.sh --all" ~/run.log
```

# 👤🔑 Root login

- **Username**: root
- **Default password**: `ucybers`

> ⚠️ **Security notice - read before using outside a lab.**
> The `ucybers` password is intended **only** for an isolated local training VM
> (VMware/VirtualBox using **NAT** or **Host-Only** networking). **Do not** use it on a machine on a
> public network, on a VPS, or in **bridged** mode.

How the password is set:

- On a **desktop virtual machine** (VMware, VirtualBox, Hyper-V, Parallels) pressing Enter keeps `ucybers`;
  answering `n` lets you choose your own password.
- On a **physical machine or a server/cloud VM**, the default password is **not offered**: you can
  generate a random root password (shown once) or type your own. Without a terminal a random
  password is generated and saved to `/root/setupkali-root-password.txt` (mode 600).
- **SSH password login for root is disabled** (`PermitRootLogin prohibit-password`, set in
  `/etc/ssh/sshd_config.d/01-setupkali-root.conf`), so the default password works for the GNOME login only.

# ⌨️ Command Line Arguments

| Argument         | Shortcut(s) | Description                                              |
| ---------------- | ----------- | -------------------------------------------------------- |
| `--gnome`        | `-g`        | Install GNOME and make it the default desktop             |
| `--root`         | `-r`        | Enable root login and set the root password               |
| `--enable-root`  | `-R`        | Enable root login only                                    |
| `--tools`        | `-t`        | Install tools for the root user                           |
| `--hacking`      | `-H`        | Install additional hacking tools                          |
| `--upgrade`      | `-u`        | Update and upgrade the system                             |
| `--all`          | `-a`, `-A`  | Run the full setup (all steps)                            |
| `--fix-sources`  | `-f`        | Fix and update the APT sources                            |
| `--nmap`         | `-n`        | Fix nmap scripts                                          |
| `--style`        | `-s`        | Configure dock, dash and icons                            |
| `--wifi`         | `-w`        | Install linux-wifi-hotspot                                |
| `--firefox`      | `-F`        | Firefox bookmarks and UCYBERS homepage                    |
| `--version`      | `-v`        | Show the version                                          |
| `--help`         | `-h`, `-?`  | Show the help message (an unknown option exits with 1)    |

```console
sudo ./setupkali.sh --all
sudo ./setupkali.sh -g
sudo ./setupkali.sh --fix-sources
sudo ./setupkali.sh --help
```

# ☰ Menu

| Key | Option | What it does |
| --- | ------ | ------------ |
| 1 | Change to GNOME Desktop | Installs `kali-desktop-gnome` and GDM3, makes GDM the default display manager, removes XFCE if present, and sets qterminal as the default terminal for menu launchers (fixes tools such as Metasploit) |
| 2 | Enable Root Login | Installs `kali-root-login`, allows root in GDM (with a backup of the config), disables SSH password login for root and sets the root password (see above) |
| 3 | Install Tools for Root | terminator, mousepad, firefox-esr, metasploit-framework, burpsuite, maltego, beef-xss, zaproxy, mdk4, nemo, plus ark, gwenview, kate, partitionmanager, okular, vlc. Also applies the GNOME defaults and makes **Nemo** the default file manager |
| 4 | Install Pen Tools | htop, Firefox bookmarks and UCYBERS homepage, zenmap, bettercap with caplets, the patched `hstshijack` caplet, Python 2 pip |
| 5 | Upgrade System | update, upgrade, dist-upgrade, autoremove, autoclean |
| 6 | Setup All | Everything below, in order |
| 0 | Exit | Leaves the script |

**Setup All** runs: fix APT sources, update, GNOME, root login, basic build packages, tools for root,
hacking tools, nmap fix, WiFi hotspot, wireless drivers/tools, icons, desktop background, dock, dash apps,
GNOME defaults and power settings.

## Notable behaviour

- **Downloads are verified.** Release assets are checked against a pinned SHA-256, and git sources are
  pinned to fixed commits (get-pip, bettercap caplets, linux-wifi-hotspot v5.0.0, clamav-exec).
  A mismatch stops that step.
- **Steps retry and repair.** A failed step is retried up to 3 times, repairing APT in between. At the end a
  summary lists failed steps and the exit code is non-zero if any step failed.
- **APT sources.** `fix_sources` enables `deb-src` and `non-free-firmware`, and keeps backups in
  `/var/backups/setupkali/`. It only clears the APT lists when `apt update` fails.
- **Firefox.** Bookmarks and homepage are set through enterprise policies in `/etc/firefox/policies/`
  (Kali's own policies are preserved). Check them at `about:policies`.
- **Desktop.** Icons (Vibrancy-Kali), dock on the left and the Kali background are applied system-wide through
  dconf defaults. Nemo replaces Files through an override launcher in `/usr/local/share/applications`;
  no package file is edited.
- **Wireless.** Known wireless kernel modules are loaded when available, and `aircrack-ng`, `iw`,
  `wireless-tools` and `rfkill` are installed.
- **Screen lock and sleep.** They are disabled for all users only on desktop virtual machines (VMware, VirtualBox, Hyper-V, Parallels); on any other machine these settings are left unchanged.

# 🪶 Revision History
The full history is in [CHANGELOG.md](CHANGELOG.md).

- **2.0.1** - the default root password, sleep/screen lock and graphical root login are limited to where they are needed (desktop VMs, explicit root login).
- **2.0.0** - supply-chain pinning, retry/repair and failure summary, safer root and SSH handling,
  system-wide desktop defaults, new UCYBERS start page, code cleanup, `--version`.
- **1.1.5** - Kali 2026.2 compatibility, Nemo as the file manager for root, idempotent GDM configuration.
- **1.1.4** - short and long arguments, improved help and menu confirmation.
- **1.1.0** - `fix_sources`, autoremove, custom Firefox homepage.
- **1.0.0** - initial release.

# ⚖️ Disclaimer
The author assumes no liability for any data loss or misuse of setupkali. Use it on systems you own.

