# Nix package inventory (Task 0.1)

Generated from `nix eval` on the macOS control node against the `ansible`
branch flake. Raw data: `msi-system-pkgs.json`, `msi-home-pkgs.json`,
`mac-system-pkgs.json`, `mac-home-pkgs.json` in this directory.

Sources evaluated (verbatim attribute paths):

- `.#nixosConfigurations.msi.config.environment.systemPackages`
- `.#nixosConfigurations.msi.config.home-manager.users.volodia.home.packages`
- `.#darwinConfigurations.Volodias-MacBook-Pro.config.environment.systemPackages`
- `.#darwinConfigurations.Volodias-MacBook-Pro.config.home-manager.users.volodia.home.packages`

Names are `pname or name`, i.e. **nixpkgs** names. They still need mapping to
Fedora/Nobara RPM and Homebrew names — that is Task 0.3.

### Caveats

- These lists only cover packages added as *derivations* to
  `environment.systemPackages` / `home.packages`. Tools pulled in via
  `programs.<x>.enable = true` (home-manager modules) do **not** appear here;
  a few show up only because the module also adds a wrapper (e.g. `mpv-with-scripts`).
  Cross-check `modules/` when building the package map.
- Some entries are not real packages but generated helper derivations
  (`hm-session-vars.sh`, `dummy-fc-dir1`, `index.theme`, `ld-library-path`,
  `X11-fonts`). They are marked NIX-ONLY.
- A large share of the msi system list is NixOS's own default
  `environment.systemPackages` (systemd, util-linux, shadow, perl, …). Those
  come from the base distro on Nobara and need no explicit mapping; they are
  kept as rows for completeness.

### Legend

- **NIX-ONLY** — artefact of Nix/NixOS/nix-darwin/home-manager itself; it will
  not be reinstalled on the target (exception: Determinate Nix is kept as a
  package manager, so `determinate-nix*`/`devenv`/`cachix` survive *as Nix*,
  not as RPM/brew).
- **DROPPED** — explicitly out of scope per PLAN.MD §0 (Hyprland, noctalia,
  hyperhdr, caddy, mpv-rife/vsmlrt stack, high-tide).

## msi (NixOS → Nobara KDE)

246 distinct packages (75 also present on macOS).

| package | system or home | also on other host? | notes |
| --- | --- | --- | --- |
| `accountsservice` | system | no |  |
| `acl` | system | no |  |
| `alsa-utils` | system | no |  |
| `ananicy-cpp` | system | no |  |
| `attr` | system | no |  |
| `avahi` | system | no |  |
| `bash-interactive` | system | yes (system) |  |
| `bash-language-server` | home | yes (home) |  |
| `bc` | home | yes (home) |  |
| `bcache-tools` | system | no |  |
| `bind` | system | no |  |
| `bluez` | system | no |  |
| `bottom` | home | yes (home) |  |
| `brave-origin` | home | no |  |
| `brightnessctl` | home | no |  |
| `bzip2` | system | no |  |
| `cachix` | home | yes (home) | **NIX-ONLY** – does not survive migration |
| `cargo` | home | yes (home) |  |
| `catppuccin-papirus-folders` | home | no |  |
| `chezmoi` | home | yes (home) |  |
| `claude` | home | yes (home) |  |
| `cliphist` | system + home | no | **DROPPED** per PLAN §0 (Hyprland/noctalia/mpv-rife/caddy stack) |
| `codegraph` | home | yes (home) |  |
| `comma-with-db-2.4.1` | home | yes (home) | **NIX-ONLY** – does not survive migration |
| `coreutils-full` | system | no |  |
| `cpio` | system | no |  |
| `cpupower` | system | no |  |
| `curl` | system | no |  |
| `darkman` | home | no |  |
| `dbus` | system | no |  |
| `dbus-broker` | system | no |  |
| `dconf` | system | no |  |
| `ddcutil` | system | no |  |
| `determinate-nix` | system | no | **NIX-ONLY** – does not survive migration |
| `determinate-nixd` | system | no | **NIX-ONLY** – does not survive migration |
| `devenv` | home | yes (home) | **NIX-ONLY** – does not survive migration |
| `difftastic` | home | yes (home) |  |
| `diffutils` | system | no |  |
| `direnv` | home | yes (home) |  |
| `distrobox` | home | no |  |
| `distrobox-tui` | home | no |  |
| `docker` | system | no |  |
| `docker-compose` | system | no |  |
| `dosfstools` | system | no |  |
| `dummy-fc-dir1` | home | no | **NIX-ONLY** – does not survive migration |
| `dummy-fc-dir2` | home | no | **NIX-ONLY** – does not survive migration |
| `dummy-xdg-mime-dirs1` | home | no | **NIX-ONLY** – does not survive migration |
| `dummy-xdg-mime-dirs2` | home | no | **NIX-ONLY** – does not survive migration |
| `e2fsprogs` | system | no |  |
| `easyeffects` | system | no |  |
| `envfs` | system | no |  |
| `fail2ban` | system | no |  |
| `faugus-launcher` | system | no |  |
| `filezilla` | home | no |  |
| `findutils` | system + home | yes (home) |  |
| `flatpak` | system | no |  |
| `fontconfig` | system + home | no |  |
| `fscrypt` | system | no |  |
| `fuse` | system | no |  |
| `fuzzel` | home | no |  |
| `fwupd` | system | no |  |
| `fzf` | home | yes (home) |  |
| `gamemode` | system | no |  |
| `gawk` | system | no |  |
| `gcc-wrapper` | home | yes (home) |  |
| `gdu` | home | yes (home) |  |
| `geoclue` | system | no |  |
| `gimp` | home | no |  |
| `git` | home | yes (home) |  |
| `git-crypt` | home | yes (home) |  |
| `glibc` | system | no |  |
| `glibc-locales` | system | no | **NIX-ONLY** – does not survive migration |
| `gnome-calculator` | system | no |  |
| `gnome-characters` | system | no |  |
| `gnome-clocks` | system | no |  |
| `gnome-font-viewer` | system | no |  |
| `gnome-keyring` | system | no |  |
| `gnome-obfuscate` | system | no |  |
| `gnome-system-monitor` | system | no |  |
| `gnugrep` | system | no |  |
| `gnumake` | home | yes (home) |  |
| `gnupg` | system | no |  |
| `gnused` | system | no |  |
| `gnutar` | system | no |  |
| `go` | home | yes (home) |  |
| `gopls` | home | yes (home) |  |
| `gparted` | home | no |  |
| `graphite-cursors` | home | no |  |
| `grc` | home | yes (home) |  |
| `grim` | system + home | no | **DROPPED** per PLAN §0 (Hyprland/noctalia/mpv-rife/caddy stack) |
| `gvfs` | system | no |  |
| `gzip` | system | no |  |
| `headroom` | home | yes (home) |  |
| `hicolor-icon-theme` | system | no |  |
| `high-tide` | home | no | **DROPPED** per PLAN §0 (Hyprland/noctalia/mpv-rife/caddy stack) |
| `hm-session-vars.sh` | home | yes (home) | **NIX-ONLY** – does not survive migration |
| `home-configuration-reference-manpage` | home | yes (home) | **NIX-ONLY** – does not survive migration |
| `hostname-debian` | system | no |  |
| `htop` | home | yes (home) |  |
| `hyperhdr` | system | no | **DROPPED** per PLAN §0 (Hyprland/noctalia/mpv-rife/caddy stack) |
| `hyprland` | system + home | no | **DROPPED** per PLAN §0 (Hyprland/noctalia/mpv-rife/caddy stack) |
| `index.theme` | home | no | **NIX-ONLY** – does not survive migration |
| `inkscape` | home | no |  |
| `iproute2` | system | no |  |
| `iptables` | system | no |  |
| `iputils` | system | no |  |
| `jack-libs` | system | no |  |
| `jq` | system | no |  |
| `just` | home | yes (home) |  |
| `kbd` | system | no |  |
| `kdeconnect-kde` | home | no |  |
| `kexec-tools` | system | no |  |
| `keychain` | home | yes (home) |  |
| `kitty` | home | yes (system + home) |  |
| `kitty-themes` | home | yes (home) |  |
| `kmod` | system | no |  |
| `lazygit` | home | yes (home) |  |
| `ld-library-path` | system | no | **NIX-ONLY** – does not survive migration |
| `legcord` | home | no |  |
| `less` | system | no |  |
| `libcap` | system | no |  |
| `libgtop` | home | yes (home) |  |
| `libnotify` | home | no |  |
| `libressl` | system | no |  |
| `linux-pam` | system | no |  |
| `lm-sensors` | system | no |  |
| `loupe` | system | no |  |
| `lsof` | home | yes (home) |  |
| `lua-language-server` | home | yes (home) |  |
| `lvm2` | system | no |  |
| `man-db` | system + home | yes (home) |  |
| `mdadm` | system | no |  |
| `mkpasswd` | system | no |  |
| `modemmanager` | system | no |  |
| `moreutils` | home | yes (home) |  |
| `mosh` | system + home | yes (home) |  |
| `mpv-with-scripts` | home | yes (home) |  |
| `mtools` | system | no |  |
| `nano` | system | no |  |
| `nautilus` | system | no |  |
| `ncurses` | system | no |  |
| `neovim` | home | yes (home) |  |
| `networkmanager` | system | no |  |
| `nix-bash-completions` | system | no | **NIX-ONLY** – does not survive migration |
| `nix-index-with-full-db-0.1.10` | home | yes (home) | **NIX-ONLY** – does not survive migration |
| `nix-info` | system | no | **NIX-ONLY** – does not survive migration |
| `nix-zsh-completions` | system + home | yes (system + home) | **NIX-ONLY** – does not survive migration |
| `nixd` | home | yes (home) | **NIX-ONLY** – does not survive migration |
| `nixfmt` | home | yes (home) | **NIX-ONLY** – does not survive migration |
| `nixos-build-vms` | system | no | **NIX-ONLY** – does not survive migration |
| `nixos-enter` | system | no | **NIX-ONLY** – does not survive migration |
| `nixos-firewall-tool` | system | no | **NIX-ONLY** – does not survive migration |
| `nixos-generate-config` | system | no | **NIX-ONLY** – does not survive migration |
| `nixos-icons` | system | no | **NIX-ONLY** – does not survive migration |
| `nixos-install` | system | no | **NIX-ONLY** – does not survive migration |
| `nixos-option` | system | no | **NIX-ONLY** – does not survive migration |
| `nixos-rebuild-ng` | system | no | **NIX-ONLY** – does not survive migration |
| `nixos-version` | system | no | **NIX-ONLY** – does not survive migration |
| `nmap` | home | yes (home) |  |
| `noctalia` | system | no | **DROPPED** per PLAN §0 (Hyprland/noctalia/mpv-rife/caddy stack) |
| `noctalia-greeter` | system | no | **DROPPED** per PLAN §0 (Hyprland/noctalia/mpv-rife/caddy stack) |
| `notify-desktop` | home | no |  |
| `nvidia-settings` | system | no |  |
| `nvidia-x11` | system | no |  |
| `opencode` | home | yes (home) |  |
| `openresolv` | system | no |  |
| `openrouter-credits` | home | yes (home) |  |
| `openssh` | system | no |  |
| `parallel` | home | yes (home) |  |
| `patch` | system | no |  |
| `pavucontrol` | system | no |  |
| `pcsclite-with-polkit` | system | no |  |
| `perl` | system | no |  |
| `pipewire` | system | no |  |
| `polkit` | system | no |  |
| `polkit-gnome` | system + home | no |  |
| `power-profiles-daemon` | system | no |  |
| `prettierd` | home | yes (home) |  |
| `procps` | system | no |  |
| `pulseaudio` | system | no |  |
| `python3` | home | yes (home) |  |
| `qbittorrent` | home | yes (system + home) |  |
| `qpwgraph` | system | no |  |
| `qttools` | home | no |  |
| `ripgrep` | home | yes (home) |  |
| `rsync` | system | no |  |
| `rtk` | home | yes (home) |  |
| `rtkit` | system | no |  |
| `ruff` | home | yes (home) |  |
| `rustfmt` | home | yes (home) |  |
| `satty` | home | no |  |
| `shadow` | system | no |  |
| `shared-mime-info` | system + home | no |  |
| `ShellCheck` | home | yes (home) |  |
| `shellharden` | home | yes (home) |  |
| `shfmt` | home | yes (home) |  |
| `signal-desktop` | home | yes (home) |  |
| `slurp` | system + home | no | **DROPPED** per PLAN §0 (Hyprland/noctalia/mpv-rife/caddy stack) |
| `snapshot` | system | no |  |
| `sound-theme-freedesktop` | system | no |  |
| `speech-dispatcher` | system | no |  |
| `starship` | home | yes (home) |  |
| `steam` | system | no |  |
| `steam-run` | system | no |  |
| `strace` | system | no |  |
| `stylua` | home | yes (home) |  |
| `sudo` | system | no |  |
| `swaybg` | home | no |  |
| `swayidle` | system | no | **DROPPED** per PLAN §0 (Hyprland/noctalia/mpv-rife/caddy stack) |
| `syncthing` | home | yes (home) |  |
| `systemd` | system | no |  |
| `t3code` | home | yes (home) |  |
| `tailscale` | system | no |  |
| `texlab` | home | yes (home) |  |
| `theme-switcher` | home | yes (home) |  |
| `time` | system | no |  |
| `tinymist` | home | yes (home) |  |
| `tmux` | home | yes (home) |  |
| `tmux-session-color` | home | yes (home) |  |
| `typstyle` | home | yes (home) |  |
| `udisks` | system | no |  |
| `unzip` | home | yes (home) |  |
| `upower` | system | no |  |
| `util-linux` | system | no |  |
| `uwsm` | system | no | **DROPPED** per PLAN §0 (Hyprland/noctalia/mpv-rife/caddy stack) |
| `vim` | home | yes (home) |  |
| `wget` | home | yes (home) |  |
| `which` | system | no |  |
| `wireplumber` | system | no |  |
| `wl-clipboard` | system + home | no |  |
| `wlogout` | home | no |  |
| `wpa_supplicant` | system | no |  |
| `wpaperd` | home | no |  |
| `X11-fonts` | system | no | **NIX-ONLY** – does not survive migration |
| `xdg-desktop-portal` | system + home | no |  |
| `xdg-desktop-portal-gtk` | system + home | no |  |
| `xdg-desktop-portal-hyprland` | system + home | no | **DROPPED** per PLAN §0 (Hyprland/noctalia/mpv-rife/caddy stack) |
| `xdg-terminal-exec` | home | no | **DROPPED** per PLAN §0 (Hyprland/noctalia/mpv-rife/caddy stack) |
| `xdg-utils` | system | no |  |
| `xwayland` | system | no | **DROPPED** per PLAN §0 (Hyprland/noctalia/mpv-rife/caddy stack) |
| `xz` | system | no |  |
| `zathura-with-plugins` | home | no |  |
| `zip` | home | yes (home) |  |
| `zoxide` | home | yes (home) |  |
| `zsh` | system + home | yes (system + home) |  |
| `zstd` | system | no |  |

## Volodias-MacBook-Pro (nix-darwin → Ansible + Homebrew)

88 distinct packages (75 also present on msi).

| package | system or home | also on other host? | notes |
| --- | --- | --- | --- |
| `bash-interactive` | system | yes (system) |  |
| `bash-language-server` | home | yes (home) |  |
| `bc` | home | yes (home) |  |
| `bottom` | home | yes (home) |  |
| `brew` | system | no | **NIX-ONLY** – does not survive migration |
| `cachix` | home | yes (home) | **NIX-ONLY** – does not survive migration |
| `cargo` | home | yes (home) |  |
| `chezmoi` | home | yes (home) |  |
| `claude` | home | yes (home) |  |
| `codegraph` | home | yes (home) |  |
| `comma-with-db-2.4.1` | home | yes (home) | **NIX-ONLY** – does not survive migration |
| `darwin-help` | system | no | **NIX-ONLY** – does not survive migration |
| `darwin-manpages` | system | no | **NIX-ONLY** – does not survive migration |
| `darwin-manual-html` | system | no | **NIX-ONLY** – does not survive migration |
| `darwin-option` | system | no | **NIX-ONLY** – does not survive migration |
| `darwin-rebuild` | system | no | **NIX-ONLY** – does not survive migration |
| `darwin-uninstaller` | system | no | **NIX-ONLY** – does not survive migration |
| `darwin-version` | system | no | **NIX-ONLY** – does not survive migration |
| `devenv` | home | yes (home) | **NIX-ONLY** – does not survive migration |
| `difftastic` | home | yes (home) |  |
| `direnv` | home | yes (home) |  |
| `findutils` | home | yes (system + home) |  |
| `fswatch` | system | no |  |
| `fzf` | home | yes (home) |  |
| `gcc-wrapper` | home | yes (home) |  |
| `gdu` | home | yes (home) |  |
| `git` | home | yes (home) |  |
| `git-crypt` | home | yes (home) |  |
| `gnumake` | home | yes (home) |  |
| `go` | home | yes (home) |  |
| `gopls` | home | yes (home) |  |
| `grc` | home | yes (home) |  |
| `headroom` | home | yes (home) |  |
| `hm-session-vars.sh` | home | yes (home) | **NIX-ONLY** – does not survive migration |
| `home-configuration-reference-manpage` | home | yes (home) | **NIX-ONLY** – does not survive migration |
| `htop` | home | yes (home) |  |
| `just` | home | yes (home) |  |
| `keychain` | home | yes (home) |  |
| `kitty` | system + home | yes (home) |  |
| `kitty-themes` | home | yes (home) |  |
| `lazygit` | home | yes (home) |  |
| `libgtop` | home | yes (home) |  |
| `lsof` | home | yes (home) |  |
| `lua-language-server` | home | yes (home) |  |
| `man-db` | home | yes (system + home) |  |
| `moreutils` | home | yes (home) |  |
| `mosh` | home | yes (system + home) |  |
| `mpv-with-scripts` | home | yes (home) |  |
| `neovim` | home | yes (home) |  |
| `nix-index-with-full-db-0.1.10` | home | yes (home) | **NIX-ONLY** – does not survive migration |
| `nix-zsh-completions` | system + home | yes (system + home) | **NIX-ONLY** – does not survive migration |
| `nixd` | home | yes (home) | **NIX-ONLY** – does not survive migration |
| `nixfmt` | home | yes (home) | **NIX-ONLY** – does not survive migration |
| `nmap` | home | yes (home) |  |
| `opencode` | home | yes (home) |  |
| `openrouter-credits` | home | yes (home) |  |
| `parallel` | home | yes (home) |  |
| `podman` | system | no |  |
| `podman-compose` | system | no |  |
| `prettierd` | home | yes (home) |  |
| `python3` | home | yes (home) |  |
| `qbittorrent` | system + home | yes (home) |  |
| `ripgrep` | home | yes (home) |  |
| `rtk` | home | yes (home) |  |
| `ruff` | home | yes (home) |  |
| `rustfmt` | home | yes (home) |  |
| `ShellCheck` | home | yes (home) |  |
| `shellharden` | home | yes (home) |  |
| `shfmt` | home | yes (home) |  |
| `signal-desktop` | home | yes (home) |  |
| `starship` | home | yes (home) |  |
| `stylua` | home | yes (home) |  |
| `syncthing` | home | yes (home) |  |
| `t3code` | home | yes (home) |  |
| `terminal-notifier` | system | no |  |
| `texinfo-interactive` | system | no |  |
| `texlab` | home | yes (home) |  |
| `theme-switcher` | home | yes (home) |  |
| `tinymist` | home | yes (home) |  |
| `tmux` | home | yes (home) |  |
| `tmux-session-color` | home | yes (home) |  |
| `typstyle` | home | yes (home) |  |
| `unzip` | home | yes (home) |  |
| `vim` | home | yes (home) |  |
| `wget` | home | yes (home) |  |
| `zip` | home | yes (home) |  |
| `zoxide` | home | yes (home) |  |
| `zsh` | system + home | yes (system + home) |  |

## Summary counts

| host | system | home | distinct total | shared with other host |
| --- | --- | --- | --- | --- |
| msi | 148 | 114 | 246 | 75 |
| Volodias-MacBook-Pro | 18 | 74 | 88 | 75 |

Union across both hosts: **259** distinct nixpkgs names.
