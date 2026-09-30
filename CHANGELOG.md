# Changelog

## 2.0.1

### Security
- The public default root password `ucybers` is offered only on desktop virtual machines; on physical machines, server/cloud VMs and non-interactive runs a random or user-chosen password is used.
- Sleep and screen lock are disabled only on desktop virtual machines; other machines keep their settings.
- `--gnome` no longer enables graphical root login; `AllowRoot` is written only when root login is requested (`--root`, `--all`, menu option 2).

## 2.0.0

### Security
- Every download is pinned: SHA-256 for release assets, fixed commits for git sources
  (get-pip, bettercap caplets, wifi-hotspot v5.0.0, clamav-exec).
- HTTPS is enforced for all downloads (`download_verified`).
- wifi-hotspot is built as a non-root user.
- Root SSH password login is disabled through a drop-in
  (`/etc/ssh/sshd_config.d/01-setupkali-root.conf`, `PermitRootLogin prohibit-password`).
- The default root password `ucybers` is kept, but only set after the user types `ucybers` to confirm.
  Desktop virtual machines (VMware, VirtualBox, Hyper-V, Parallels) are handled separately.

### Reliability
- `run_step` retries failed steps and repairs APT between attempts.
- A final summary lists failed steps and the script exits with a proper exit code.
- `fix_sources` keeps its backups in `/var/backups/setupkali/`, so stray `.bak` files no longer
  stay in `sources.list.d/`.
- `fix_bad_apt_hash` no longer wipes the APT lists on every run: it runs `apt-get update` first and clears the lists only when that fails (the `lock` file and `partial` directory are kept).

### Desktop
- Firefox policies are written to `/etc/firefox/policies/` (Kali's own policies are kept).
- qterminal is the default terminal, which fixes launching Metasploit from the menu.
- GNOME defaults (dock, icons, background, power) are applied system-wide through dconf.
- Nemo is the default file manager through an override launcher and `/etc/xdg` mimeapps.
- New UCYBERS start page.

### Cleanup
- One version source: `VERSION`. New `-v` / `--version` option, shown in the menu title.
- Removed 4 unused functions: `enable_icon_theme_autostart_root`, `switch_to_snapshot`,
  `switch_to_rolling`, `remove_kali_undercover`.
- Removed unused variables: `revision`, `redminus`, `redexclaim`, `MAGENTA`, `CYAN`, `WHITE`, `NC`.
- Fixed: an unknown option now prints the help and exits with 1 (it used to exit 0).
- Menu validation uses `case`, `read -r` everywhere, and the unreachable menu branches are gone.
- ShellCheck passes with no warnings.
- Added a ShellCheck workflow (GitHub Actions) that runs on every change to `.sh` files.
