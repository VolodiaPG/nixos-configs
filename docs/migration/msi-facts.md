# `msi` — live system facts (captured 2026-09-23, read-only over SSH)

Snapshot of the running NixOS install on `msi` before the Nobara reinstall
(phase 6). Everything here was read live from the machine; nothing was
changed. Companion files: `msi-units-system.txt`, `msi-units-user.txt`,
`msi-network.txt`, `msi-hardware.txt`, `msi-backup-checklist.md`.

**Reachability note:** `ssh msi.goblin-alewife.ts.net` fails with
*Host key verification failed* — `~/.ssh/known_hosts` on the control node
stores the keys under the bare name `msi` only. The keys returned by
`ssh-keyscan` on the FQDN are byte-identical to the stored `msi` entries, so
`ssh msi` works and was used for all captures. Ansible inventory should
either use `msi` or add the FQDN to `known_hosts`.

## Identity

| Field | Value |
| --- | --- |
| Hostname | `msi` |
| Chassis | MSI MS-7920 rev 1.0 (desktop), BIOS V1.9, 2016-02-16 |
| OS | NixOS 26.05 "Yarara", build `26.05.1e8bc65` |
| Kernel | `7.2.6-cachyos-lto` (CachyOS LTO kernel, `#1-NixOS SMP PREEMPT_DYNAMIC`) |
| Arch | x86_64 |
| Boot | UEFI, systemd-boot-style NixOS entry (`NixOS-boot` EFI var); ESP = `/dev/sda1` mounted at `/boot`, vfat FAT16, 499 MB (199 MB used). Secure Boot: disabled (setup mode). No TPM2. |
| Init | systemd, `dbus-broker` |

## User & session

| Field | Value |
| --- | --- |
| Primary user | `volodia` uid 1000, gid 100 (`users`), GECOS "Volodia P.G." |
| Shell | `zsh` (`/run/current-system/sw/bin/zsh`) |
| Supplementary groups | `wheel`, `disk`, `audio`, `video`, `dialout`, `networkmanager`, `docker`, `render`, `i2c` |
| Other human users | none (only `nixbld1..32` Nix build users) |
| Display manager | **greetd** (`greetd.service`, enabled + running) |
| Greeter | `noctalia-greeter` 1.5.0 running its own Wayland compositor |
| Desktop | Wayland / Hyprland + noctalia shell (`noctalia.service` user unit enabled). **All of this is dropped in the migration — target is KDE Plasma on Nobara.** |
| Lingering | `linger-users.service` enabled (user units run without login) |
| Audio | PipeWire + WirePlumber (user sockets `pipewire.socket`, `pipewire-pulse.socket`, `wireplumber.service`) |
| Polkit agent | `hyprpolkitagent` (user unit) |

Reproduce for Ansible: a normal user `volodia` uid 1000, primary group
`users` (gid 100), in `wheel video audio render dialout i2c` + Nobara's
`docker`/`networkmanager` equivalents, login shell zsh, lingering enabled.

## Locale / time / keyboard (actually in effect)

| Field | Value |
| --- | --- |
| `LANG` | `fr_FR.UTF-8` |
| VC keymap | **unset** (console keymap not configured) |
| X11/Wayland layout | `fr`, model `pc104`, variant `oss` |
| X11 options | `eurosign:e,ctrl:swapcaps` (**caps↔ctrl swap — must be reproduced**) |
| Timezone | `Europe/Paris` (CEST, +0200), RTC in UTC |
| NTP | `systemd-timesyncd`, active, clock synchronised |

Note the keyboard is also remapped in userspace by **kanata**
(`kanata-all.service`, system unit, enabled). The `ctrl:swapcaps` XKB option
and kanata overlap — check which one is load-bearing before porting.

## Hardware

| Field | Value |
| --- | --- |
| GPU | NVIDIA GeForce RTX 4070, 12282 MiB VRAM |
| NVIDIA driver | 595.99.02 (proprietary kernel module, built with clang 21.1.8) |
| NVIDIA extras enabled | `nvidia-frequency.service` (clock lock), `nvidia-suspend/resume/hibernate`, `nvidia-container-toolkit-cdi-generator` |
| Swap | zram0, 7.8 GB, active; plus a 17 GB `/persistent/swapfile` (`mkswap-persistent-swapfile.service`) |
| Firmware | `fwupd` enabled (`fwupd-refresh.timer`) |

Full `lspci` / `lspci -k` / `lsusb` / `/proc/asound/cards` output is in
`msi-hardware.txt`.

## Storage layout

| Device | Size | Contents |
| --- | --- | --- |
| `sda` (Samsung 840 EVO 250 GB) | 232.9 G | `sda1` 499 M vfat → `/boot`; `sda2` LVM PV `root_vg` |
| `root_vg-root` | 16 G ext4 | `/` — 38 MB used (**tmpfs-like: impermanence wipes it**) |
| `root_vg-nix` | 150 G ext4 | `/nix` + `/nix/store`, 69 G used |
| `root_vg-persistent` | 66.4 G ext4 | `/persistent`, 53 G used — the impermanence store, bind-mounted all over `/home` and `/var/lib` |
| `sdb` (Crucial BX500 480 GB) | 447.1 G | `sdb1` 100 M vfat (old Windows ESP), `sdb2` 16 M MSR, `sdb3` 280.5 G ntfs (Windows), `sdb4` 530 M ntfs (recovery), `sdb5` 166 G ext4 label `Games` → `/Games` (120 G used) |
| `sdc` (SanDisk Cruzer Slice 7.5 G) | — | NixOS installer USB stick, still plugged in |

**Impermanence:** `/` is effectively disposable; every path that must survive
a reboot is a bind mount from `/persistent`. Full list of bind mounts is the
`*.mount` block at the top of `msi-units-system.txt`. Impermanence is
**dropped** on the migrated host, so all of these become ordinary
directories on Nobara.

Known wart: a literal directory named `~` exists in `$HOME`
(`/home/volodia/~/.cache/vsmlrt`) — the result of an unexpanded `~` in the
vsmlrt impermanence entry. It is empty and should not be recreated.

`/etc/fstab`, `findmnt`, `df -hT` output: see `msi-hardware.txt`.

## Networking

| Field | Value |
| --- | --- |
| Manager | NetworkManager (`NetworkManager.service`, `NetworkManager-dispatcher.service`, `ModemManager`, `wpa_supplicant`) |
| `enp3s0` | onboard NIC, **NO-CARRIER / unused** |
| `enp0s20u2` | USB Ethernet, active — DHCP `192.168.1.22/24`, IPv6 `2a04:800:25e9:7b01::/64` (SLAAC + privacy addr) |
| `tailscale0` | `100.86.139.105`, `fd7a:115c:a1e0::e29:8b6a`, MagicDNS name `msi.goblin-alewife.ts.net` |
| `docker0` | `192.168.234.1/24` (non-default subnet — set explicitly somewhere) |
| mDNS | `avahi-daemon` enabled |
| Resolver | see `msi-network.txt` |

Firewall is the NixOS iptables firewall (`firewall.service`, enabled and
active). Live `nft`/`iptables-save` needs root and passwordless sudo is not
available, so `msi-network.txt` instead contains the full generated
`firewall-start` script from the Nix store, which is the authoritative source
of the rules. Open ports include TCP 22 (ssh), 8384 (syncthing GUI), 22000
(syncthing), 19400/19444/8090/8092 (hyperhdr); UDP 3389, 5353 (mDNS), 6001,
6002, 41641 (tailscale), 1714-1764 (KDE Connect), 60000-61000 (mosh).

Listening processes at capture time: sshd, syncthing, hyperhdr, mosh-server,
tailscaled, caddy admin API on `127.0.0.1:2019`.

## Services worth knowing about

Enabled system units of interest (full list in `msi-units-system.txt`):

- **Keep / port:** `sshd`, `tailscaled`, `docker`, `NetworkManager`,
  `bluetooth`, `avahi-daemon`, `fail2ban`, `greetd`→(replaced by SDDM on
  Nobara), `kanata-all`, `nvidia-frequency`, `earlyoom`, `ananicy-cpp`,
  `acpid`, `fwupd`, `logrotate`, `fstrim`, `docker-prune.timer`.
- **Dropped per PLAN §0:** `caddy.service`, `hyperhdr.service`,
  `cpufreq.service`/`powertop.service` (Nobara handles power profiles),
  `noctalia.service` + Hyprland stack, `home-manager-volodia.service`,
  all `persist-persistent-*` impermanence units.
- **k3s remnants:** `run-k3s-containerd.mount`,
  `persist-persistent-etc-rancher-k3s-k3s.yaml.service`,
  `/persistent/var/lib/rancher` (16 K, effectively empty). No `k3s.service`
  enabled — k3s is not actually running.

Enabled *user* units: `agenix`, `darkman`, `dbus-broker`,
`flatpak-override-gtk`, `gcr-ssh-agent`, `geoclue-agent`,
`hyprpolkitagent`, `kdeconnect` + `kdeconnect-indicator`, `noctalia`,
`ssh-agent`, `syncthing` + `syncthing-init`, `systembus-notify`,
`wireplumber`. (`msi-units-user.txt`)

## Package / runtime environment

- Nix: multi-user daemon + **Determinate Nix** (`determinate-nixd.socket`).
  Survives the migration as a package manager only.
- Docker: engine enabled, **zero images, zero containers, zero volumes** at
  capture time.
- Podman: not installed.
- Flatpak: one app installed — `com.bambulab.BambuStudio` 2.8.2.61.
- libvirt / VirtualBox / GNOME Boxes: **not installed, no VM images anywhere.**
- Steam: `steam` on PATH; library at `/Games/SteamLibrary` (see checklist).
- `nix profile`: empty (all packages come from the system/HM closures).

## Backup reality check

- **restic is not running on `msi`.** `modules/nixos/backup.nix` defines
  `my.backup` but no host sets `my.backup.enable`; there is no
  `restic-backups-*.service` or timer on the machine.
- **Syncthing is running but syncing nothing.** `~/.local/state/syncthing/config.xml`
  contains one placeholder folder with empty `id`/`label`/`path` and a single
  device (`msi` itself, `UZLCBNP…`). No peers, no shared folders.

Therefore **nothing on `msi` is currently backed up anywhere.** Treat every
item in `msi-backup-checklist.md` as unprotected.
