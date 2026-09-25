# `msi` cutover runbook — PLAN.MD task 6.2

This is the on-the-day procedure for wiping `msi` and reinstalling Nobara
KDE, replacing NixOS. It is written for a human to execute step by step.
**Nothing on `msi` is backed up today** (`docs/migration/msi-facts.md`,
"Backup reality check") — restic does not run there and Syncthing has no
peers. Section 1 is the only safety net. Do not skip it.

Sources cited throughout: `docs/migration/msi-backup-checklist.md`,
`docs/migration/msi-facts.md`, `docs/migration/msi-hardware.txt`,
`ansible/inventory/hosts.yml`, `PLAN.MD` (§6.2, task 2.9, task 0.2).

---

## 0. Before you start

- **STOP and confirm with the user before touching disks** (PLAN.MD 6.2).
  This whole procedure is destructive from step 2 onward.
- Control node is this Mac (`macbook`, `ansible_connection: local` in
  `ansible/inventory/hosts.yml`). All commands below run **from the Mac**,
  over Tailscale, unless stated otherwise.
- `msi`'s Tailscale MagicDNS name is `msi.goblin-alewife.ts.net`; the
  inventory addresses it by the **bare name `msi`**, not the FQDN, because
  this control node's `~/.ssh/known_hosts` only has msi's host key stored
  under the short name (`ansible/inventory/hosts.yml`,
  `docs/migration/msi-facts.md` "Reachability note"). Use `ssh msi` /
  `scp ... msi:...`, not the FQDN, for every command below.

---

## 1. Pre-wipe data capture — blocking checklist

Do not proceed to section 2 until every box here is checked. This is the
last chance to read anything off `msi`'s disk. Run all commands from the
Mac. Destination directory suggestion:

```sh
mkdir -p ~/msi-cutover-backup
```

### 1.1 Highest priority — small, irreplaceable

- [ ] **`/etc/NetworkManager/system-connections/` (Wi-Fi PSKs).** PLAN.MD
      step 3 and `msi-backup-checklist.md` §6 both call this out: it was
      **unreadable during the original inventory** because `msi` has no
      passwordless sudo, so this has never actually been captured. Losing
      it means re-entering every saved network by hand. Root read required:

      ```sh
      ssh msi 'sudo tar czf - -C /etc/NetworkManager system-connections' \
        > ~/msi-cutover-backup/nm-system-connections.tar.gz
      ```

      This will prompt for `msi`'s sudo password interactively over the SSH
      session (or use `-t` if it doesn't). Verify the archive is non-empty
      before continuing:
      `tar tzf ~/msi-cutover-backup/nm-system-connections.tar.gz`.

- [ ] **`~/.ssh/id_ed25519` + `.pub`** (432 B / 113 B) — the private key
      itself. `msi-backup-checklist.md` §1 deliberately did not read its
      contents; copy the files, do not print them:

      ```sh
      scp msi:.ssh/id_ed25519 msi:.ssh/id_ed25519.pub ~/msi-cutover-backup/
      chmod 600 ~/msi-cutover-backup/id_ed25519
      ```

      If lost, every `authorized_keys` entry trusting it must be reissued.

- [ ] **`~/.ssh/known_hosts`, `known_hosts.old`**:

      ```sh
      scp msi:.ssh/known_hosts msi:.ssh/known_hosts.old ~/msi-cutover-backup/
      ```

- [ ] **`/persistent/etc/ssh/` (SSH host keys)** — only if you want `msi` to
      keep presenting the same host identity after reinstall (optional; if
      skipped, every client including this Mac's `known_hosts` must
      re-trust the new host key):

      ```sh
      ssh msi 'sudo tar czf - -C /persistent/etc ssh' \
        > ~/msi-cutover-backup/persistent-etc-ssh.tar.gz
      ```

- [ ] **GNOME keyring** — `~/.local/share/keyrings/` (login.keyring,
      user.keystore):

      ```sh
      scp -r msi:.local/share/keyrings ~/msi-cutover-backup/keyrings
      ```

- [ ] **`~/.gnupg/`** (20 K, only `sshcontrol`/`trustdb.gpg` have content,
      low value but tiny):

      ```sh
      scp -r msi:.gnupg ~/msi-cutover-backup/gnupg
      ```

- [ ] **`~/.zsh_history`, `~/.bash_history`** — not synced anywhere,
      unrecoverable, tiny:

      ```sh
      scp msi:.zsh_history msi:.bash_history ~/msi-cutover-backup/
      ```

### 1.2 Config the repo does not own (verify against `chezmoi/` first)

`msi-backup-checklist.md` §2 lists a long tail of `~/.config/*` dirs that
are mostly already chezmoi/Home-Manager output and thus already in git —
only copy what **differs**. At minimum, without diffing:

- [ ] **`~/.config/qBittorrent/` + `~/.local/share/qBittorrent/`**
      (`BT_backup` holds active torrent resume state — losing it loses all
      seeding torrents):

      ```sh
      scp -r msi:.config/qBittorrent ~/msi-cutover-backup/
      scp -r msi:.local/share/qBittorrent ~/msi-cutover-backup/
      ```

- [ ] **`~/.config/OrcaSlicer/`** (173 M — hand-tuned printer/filament
      profiles, genuinely painful to rebuild):

      ```sh
      scp -r msi:.config/OrcaSlicer ~/msi-cutover-backup/
      ```

- [ ] **`~/.config/FreeCAD/`, `~/.local/share/FreeCAD/`, `~/.config/blender/`**:

      ```sh
      scp -r msi:.config/FreeCAD msi:.local/share/FreeCAD msi:.config/blender \
        ~/msi-cutover-backup/
      ```

- [ ] **`~/.config/chezmoi/chezmoistate.boltdb`** — only if you want to
      avoid re-running `run_once_` scripts (optional, low value):

      ```sh
      scp msi:.config/chezmoi/chezmoistate.boltdb ~/msi-cutover-backup/
      ```

- [ ] Diff-check the rest of §2's list (`mpv`, `nvim`, `kitty`, `git`,
      `starship.toml`, `tmux`, `bottom`, `lazygit`, `k9s`, `htop`,
      `zathura`, `fuzzel`, `direnv`, `systemd`) against `chezmoi/` in this
      repo; copy only files that show local drift.

### 1.3 Application data — large, mostly not replaceable

- [ ] **Brave profile** — `~/.config/BraveSoftware/Brave-Origin/` (377 M).
      Close Brave on `msi` first, then:

      ```sh
      ssh msi 'pkill -f Brave-Origin' || true
      rsync -avz msi:.config/BraveSoftware/Brave-Origin/ \
        ~/msi-cutover-backup/Brave-Origin/
      ```

- [ ] **Signal Desktop** — `~/.config/Signal/` (216 M). Copy whole or
      nothing — a partial copy of `sql/db.sqlite` is unrecoverable
      (encryption key lives alongside it in `config.json`):

      ```sh
      rsync -avz msi:.config/Signal/ ~/msi-cutover-backup/Signal/
      ```

      Alternative: skip this and re-link the Signal desktop client from the
      phone, accepting loss of local-only message history.

- [ ] **BambuStudio Flatpak data** — `~/.var/app/com.bambulab.BambuStudio/`
      (200 M):

      ```sh
      rsync -avz msi:.var/app/com.bambulab.BambuStudio/ \
        ~/msi-cutover-backup/BambuStudio/
      ```

- [ ] **Claude / opencode / T3 state** (optional, but cheap):
      `~/.claude/` (14 M, skip `cache/`/`telemetry/`), `~/.config/opencode/`
      (skip `node_modules`), `~/.t3/userdata/` (179 M):

      ```sh
      rsync -avz --exclude=cache --exclude=telemetry msi:.claude/ \
        ~/msi-cutover-backup/claude/
      rsync -avz --exclude=node_modules msi:.config/opencode/ \
        ~/msi-cutover-backup/opencode/
      rsync -avz msi:.t3/userdata/ ~/msi-cutover-backup/t3-userdata/
      ```

### 1.4 User documents — highest-value original work

- [ ] **`~/Documents/Stand/`** (1.1 G) — 3D print project files, **original
      work, nowhere else. Highest-value data on the machine after the SSH
      key** (`msi-backup-checklist.md` §4):

      ```sh
      rsync -avz msi:Documents/Stand/ ~/msi-cutover-backup/Stand/
      ```

- [ ] **Verify `~/Documents/nixos-configs` is clean and pushed before
      wiping.** The checklist notes this repo was at `ff247b8` == origin/main
      at inventory time but **uncommitted working-tree changes were never
      checked** (no `git` commands were run to produce that inventory):

      ```sh
      ssh msi 'cd ~/Documents/nixos-configs && git status --porcelain'
      ```

      If that prints anything, `git stash`/commit/push it from `msi` before
      continuing, or `rsync` the working tree over as a fallback:

      ```sh
      rsync -avz msi:Documents/nixos-configs/ \
        ~/msi-cutover-backup/nixos-configs-worktree/
      ```

- [ ] **`~/Documents/old-nix/`** (54 M) — prior-art Nix config tree, keep at
      least until migration is signed off:

      ```sh
      rsync -avz msi:Documents/old-nix/ ~/msi-cutover-backup/old-nix/
      ```

- [ ] **`~/Documents/fixed.sql.gz`, `CV2/`, `test.FCStd`* , `randonnees aude/`,
      `printer-slowdown/`, `k3s.yaml`** — provenance/ownership unclear per
      the checklist; sweep them all rather than triage under time pressure:

      ```sh
      rsync -avz --exclude=Stand --exclude=nixos-configs --exclude=old-nix \
        msi:Documents/ ~/msi-cutover-backup/Documents-rest/
      ```

- [ ] **`~/Pictures/Wallpapers/`** (11 M):

      ```sh
      rsync -avz msi:Pictures/Wallpapers/ ~/msi-cutover-backup/Wallpapers/
      ```

- [ ] **`~/Downloads/` — needs a human triage pass, not a blanket copy.**
      31 G total; the checklist judges most of it (TV/film `.mkv`, RIFE
      models — `mpv-rife` is dropped per PLAN §0) re-acquirable, but flags
      the 3D-printing assets (`3D/`, `Spirit*`, `toto/`,
      `Sweeping_Name_Plate_VZZM*`, `*.3mf`) as possibly-original project
      work mixed with downloaded models. If in doubt, copy the whole 31 G —
      it is cheap Mac-side disk, and this is the last chance:

      ```sh
      rsync -avz msi:Downloads/ ~/msi-cutover-backup/Downloads/
      ```

### 1.5 Confirmed nothing else to capture

Per `msi-facts.md`/`msi-backup-checklist.md` §5: Docker (0 images/containers/
volumes), Podman/libvirt/VirtualBox/Boxes (not installed), k3s (not
running, only `~/Documents/k3s.yaml` which §1.4 already covers),
`/nix` (rebuildable), `/persistent/swapfile` (swap). Nothing to do for
these.

### 1.6 `/Games` — do not touch, see section 2

Do **not** back up `/Games` (the 166 G ext4 `Games` partition on the
Crucial `ata-CT480BX500SSD1_2512E9B1E868`, 120 G used). It is on a
physically separate
disk from the one being wiped; section 2 explains why it survives with zero
copying as long as the installer is pointed at the right disk.

---

## 2. Disk identification

> **The device letters in `msi-hardware.txt` are STALE AND REVERSED.**
> That file (captured 2026-09-23) records `sda` = Samsung = install target
> and `sdb5` = `/Games`. A `ls -l /dev/disk/by-id` taken on 2026-09-25
> shows the opposite: the Crucial is `sda` and the Samsung is `sdb`.
> **Following "install to `sda`" would erase the 120 G Steam library and
> leave NixOS untouched.** Ignore letters entirely. Use the serials below.

Proof the letters moved, not the disks: the LVM physical-volume UUID
`vmyRUe-qCC1-UJh1-bNUT-OKlm-nxWL-VHG6fa` is recorded against `sda2` in
`msi-hardware.txt` line 5, and resolves to `sdb2` in the 2026-09-25
`by-id` listing. Same partition, same UUID, different letter. This is
exactly the hazard this section was written to guard against, and it has
already materialised once.

### The only identifiers to trust

| Role | Serial (`/dev/disk/by-id`) | `wwn` alias | Model / size |
| --- | --- | --- | --- |
| **INSTALL TARGET — erase this one** | `ata-Samsung_SSD_840_EVO_250GB_S1DBNSCFA01973D` | `wwn-0x50025388a07a2321` | Samsung SSD 840 EVO 250GB, 232.9 G |
| **DO NOT TOUCH — this is `/Games`** | `ata-CT480BX500SSD1_2512E9B1E868` | `wwn-0x500a0751e9b1e868` | Crucial CT480BX500SSD1, 447.1 G |

The install target is the disk whose `-part2` carries LVM PV
`vmyRUe-qCC1-UJh1-bNUT-OKlm-nxWL-VHG6fa`, feeding
`root_vg-{root,nix,persistent}` — i.e. the current NixOS root. The disk
to preserve is the one with five partitions, whose `-part5` is the
166 G ext4 volume labelled `Games` (120 G used), alongside old Windows
partitions on `-part1`..`-part4`.

A SanDisk Cruzer Slice USB stick
(`usb-SanDisk_Cruzer_Slice_4C532010051109104472-0:0`) was also present.
Expect the Nobara installer stick to appear similarly — never select a
`usb-*` device as the target either.

### Re-verify on the day, before partitioning

```sh
# Authoritative. Letters on the right-hand side WILL differ; ignore them.
ls -l /dev/disk/by-id/ | grep -v part

# Confirm which disk currently holds the NixOS LVM PV:
sudo pvs -o +uuid

# Confirm which disk currently holds /Games:
lsblk -o NAME,SIZE,MODEL,SERIAL,LABEL,MOUNTPOINTS
```

- [ ] `ata-Samsung_SSD_840_EVO_250GB_S1DBNSCFA01973D` is the **only**
      disk selected in the installer.
- [ ] `ata-CT480BX500SSD1_2512E9B1E868` is **not** selected, not
      initialised, not reformatted, not assigned a mount point.
- [ ] The installer's summary screen names the Samsung serial (or its
      current letter, cross-checked against `by-id` in the same session)
      before you confirm.
- [ ] If the installer shows only letters and no serials, drop to a
      terminal and re-run `ls -l /dev/disk/by-id` **in that same boot** —
      letters are stable within a boot, just not across boots.
- [ ] If anything is ambiguous, **stop** and run
      `sudo smartctl -i /dev/sdX` to read the serial directly. Do not
      guess.

Old Windows partitions live on the Crucial (`-part1`..`-part4`);
keeping or dropping them is out of scope, but the installer must not
touch that disk at all either way.

---

## 3. The install itself

1. Boot the official **Nobara KDE** ISO (the old `installer` ISO and
   `disko` config are **not ported** to this migration — PLAN.MD 6.2 step 4
   — partitioning here is manual/guided through the stock Nobara installer).
2. Partition **the Samsung** (`ata-Samsung_SSD_840_EVO_250GB_S1DBNSCFA01973D`)
   manually/guided. Suggested layout, cheapest rollback
   first:
   - **If space allows, keep the existing NixOS install bootable on a
     separate partition** (PLAN.MD 6.2 step 5) — the cheapest possible
     rollback path, cheaper than reinstalling NixOS from the flake. This
     means *not* wiping the whole of the Samsung outright; shrink/repartition
     instead of a full-disk erase if the installer supports it. If the
     installer only supports full-disk erase, skip this and rely on the
     flake-reinstall rollback in section 6 instead — do not fight the
     installer for it.
   - Otherwise, straightforward guided partitioning of the Samsung for Nobara KDE
     (ESP + root, no separate `/home` needed — Ansible/chezmoi will recreate
     `$HOME` structure).
   - Do **not** touch the Crucial `ata-CT480BX500SSD1_2512E9B1E868`
     (section 2) or any `usb-*` device.
3. Create the initial Nobara admin account through the installer's own
   user-setup screen — this account (with sudo) is what bootstrap.yml
   connects as for the very first run, before `volodia` exists (see
   `ansible/roles/users/tasks/main.yml`'s own header comment: it explicitly
   does not assume any specific connection user, only `become: true`).
   Record its username and password.
4. Complete the install, reboot into Nobara KDE, and note the LAN IP shown
   by NetworkManager (`ip a` in a terminal, or the Nobara welcome screen) —
   `msi` will not be reachable by its Tailscale name yet (see section 4).

---

## 4. Post-install bootstrap order

### 4.1 Control-node prerequisites (on this Mac, before running anything)

- [ ] **Vault password file exists.** `~/.config/ansible/vault-pass` — this
      lives on the control node only, never on `msi`, and there is
      deliberately no Ansible task that could create it there (see
      `ansible/playbooks/bootstrap.yml`'s header comment and
      `docs/migration/vault-setup.md`). If missing, it was supposed to be
      set up in phase 5.2 — recover the value from Bitwarden
      ("ansible-vault password — nixos-configs") rather than regenerating
      it, or every secret in `ansible/inventory/group_vars/all/vault.yml`
      becomes undecryptable.
- [ ] **`vault_password_file` is uncommented in `ansible/ansible.cfg`.** At
      the time this doc was written it is still commented out
      (`# vault_password_file = ~/.config/ansible/vault-pass`) with a
      now-stale comment about the vault being empty — it is not empty
      anymore (`ansible/inventory/group_vars/all/vault.yml` has content as
      of commit `427949c`). Uncomment that line before running bootstrap.yml
      or site.yml, or every `vault_*` variable (tailscale authkey,
      envvars, access-token) resolves as undefined and those roles silently
      skip with a debug message instead of doing their job.
- [ ] **SSH reachable.** From the Mac: `ssh <installer-admin-user>@<msi-LAN-IP>`
      (the IP noted in section 3 step 4) succeeds interactively first, to
      accept the new host key and confirm connectivity, before asking
      Ansible to do it non-interactively.
- [ ] **Inventory hostname/IP is correct for this run.** `msi`'s Tailscale
      identity is about to be recreated from scratch (fresh install =
      fresh Tailscale node key), so `ansible_host: msi` in
      `ansible/inventory/hosts.yml` will not resolve until *after*
      `tailscale up` has run once against the new install (see 4.2). For
      the very first bootstrap + first site.yml run, override the target
      instead of editing the inventory:

      ```sh
      cd ansible
      ansible-playbook -i inventory/hosts.yml playbooks/bootstrap.yml \
        --limit msi -e ansible_host=<msi-LAN-IP> \
        -u <installer-admin-user> -K
      ```

      `-K` prompts for the installer admin's sudo password (`become`).
      Once `tailscale up` has succeeded (during the site.yml run below) and
      `msi` shows up on the tailnet, subsequent runs can drop the
      `-e ansible_host=...` override and go back to plain
      `ansible-playbook playbooks/site.yml --limit msi`.

### 4.2 Run order

1. **`playbooks/bootstrap.yml`** — creates the `volodia` user, groups,
   lingering, and `authorized_keys` (`roles/users`); starts `tailscaled`
   and attempts `tailscale up` if the package happens to already be present
   (`roles/vpn` — it will not be, on a stock Nobara install, so this step
   legitimately no-ops here and that's fine, see bootstrap.yml's header
   comment); and does the one-shot
   `rm ~/.config/plasma-org.kde.plasma.desktop-appletsrc` (PLAN.MD task 2.9)
   before chezmoi ever touches the host.

   ```sh
   cd ansible
   ansible-playbook playbooks/bootstrap.yml --limit msi \
     -e ansible_host=<msi-LAN-IP> -u <installer-admin-user> -K
   ```

2. **`playbooks/site.yml`** — everything else: `roles/pkgs` installs
   tailscale (among everything else) via dnf, `roles/vpn` runs again and
   this time actually authenticates via `vault_tailscale_authkey`, then
   `base`, `users` (idempotent re-run), `shell`, `networking`, `audio`,
   `virtualization`, `desktop_linux`, `kde`, `nvidia`, `gaming`, `secrets`,
   `chezmoi` (first real `chezmoi apply`, now safe because of step 1's
   appletsrc removal). This first run still needs the LAN-IP override,
   since `tailscale up` only happens partway through it:

   ```sh
   ansible-playbook playbooks/site.yml --limit msi \
     -e ansible_host=<msi-LAN-IP>
   ```

   By now `volodia`'s key is authorized (step 1), so this run should not
   need `-u`/`-K` unless something in `roles/pkgs`/etc. needs interactive
   sudo — it shouldn't, per those roles' own `become: true` + key-based
   auth design.

3. From here on, `msi` should be reachable by its Tailscale name. Confirm,
   then switch back to the plain inventory form for every later
   verification run in section 5:

   ```sh
   tailscale status | grep msi
   ansible-playbook playbooks/site.yml --limit msi   # no more -e ansible_host
   ```

---

## 5. Functional checklist (PLAN.MD 6.2 step 7)

Run each command from the Mac (over SSH/Tailscale) unless noted as
"on msi" (console/local session required). Check the box only once the
command's output actually confirms it — not on the claim alone.

- [ ] **Boots to Plasma.** On msi: reboot, confirm SDDM → Plasma session
      loads (visual check; no remote command substitutes for this one).
- [ ] **NVIDIA driver active.**
      `ssh msi nvidia-smi` — must list the RTX 4070, not
      "No devices were found." If it fails, see the first-boot item in
      section 7 about `nvidia-frequency` ordering.
- [ ] **`nvidia-frequency` applied.**
      `ssh msi systemctl status nvidia-frequency` — `active (exited)`, no
      failure; then `ssh msi nvidia-smi -q -d CLOCK | grep -A3 "Applications Clocks"`
      to confirm the locked memory/graphics clocks
      (`1620,2100` / `210,3105` per `ansible/roles/nvidia/defaults/main.yml`)
      took.
- [ ] **Audio.** `ssh msi 'wpctl status'` shows PipeWire sinks/sources; play
      a sound on msi and confirm audibly (remote check can't confirm sound
      actually comes out of the speakers).
- [ ] **Kanata remapping.**
      `ssh msi systemctl --user status kanata.service` — `active (running)`;
      then type on msi's physical keyboard and confirm caps↔ctrl swap and
      any other kanata-defined remaps behave.
- [ ] **fr/oss keyboard with swapped caps.**
      `ssh msi 'cat ~/.config/kxkbrc'` — confirm `LayoutList=fr`,
      `VariantList=oss` (`chezmoi/dot_config/private_kxkbrc`); confirm the
      caps/ctrl swap by typing (this is also partially kanata's job — see
      section 7 item 6 on the overlap that was never resolved from here).
- [ ] **Tailscale up.**
      `ssh msi 'tailscale status --json' | jq -r .BackendState` — `Running`.
- [ ] **Syncthing syncing.**
      `ssh msi systemctl --user status syncthing.service` — active; then
      open the Syncthing GUI (`http://msi:8384` over Tailscale, or
      `ssh -L 8384:localhost:8384 msi` and browse locally) and confirm
      configured folders/peers are set up and syncing — msi's Syncthing had
      **no peers and no folders configured** before the reinstall
      (`msi-facts.md`), so this needs fresh configuration, not just a
      service-up check.
- [ ] **mpv plays HDR.** On msi, play a known-HDR file (one of the ones
      captured in section 1.4/1.3's Downloads sweep, if any, or any local
      HDR sample) and visually confirm tone-mapping looks right — no remote
      command substitutes for this.
- [ ] **Steam runs a game.** On msi: launch Steam, confirm
      `/Games/SteamLibrary` is recognized as a library
      (Steam → Settings → Storage), launch any installed title, confirm it
      runs. This is the payoff of section 2's "erase the Samsung only."
- [ ] **`nix develop` works in a devenv project.**
      `ssh msi 'cd <some-devenv-project> && nix develop --command echo ok'`
      — prints `ok`. (This agent did not run `nix develop` anywhere per its
      own constraints; this is purely a check for whoever executes this
      runbook.)
- [ ] **`chezmoi diff` clean.**
      `ssh msi 'chezmoi diff'` — empty output.
- [ ] **Second `site.yml` run reports zero changes.**
      `ansible-playbook playbooks/site.yml --limit msi` a second time (no
      LAN-IP override needed by now) — every task reports `ok`, none
      `changed`. This is the acceptance bar PLAN.MD phase 3/4 repeatedly
      defers to "unverified until a real Nobara install exists"; this is
      that install.

---

## 6. Rollback

- If section 3's partitioning kept the old NixOS install bootable on a
  separate partition, boot into it directly from the bootloader — that is
  the cheapest rollback, and requires nothing further from this repo.
- Otherwise: reinstall NixOS from the flake. `configurations/nixos/msi/`
  **must stay in this repo and must not be deleted until task 6.2 is
  formally signed off** (PLAN.MD 6.2 "Rollback"). Do not delete it as part
  of any cleanup pass tied to this cutover, even after the functional
  checklist above passes — sign-off is a separate, explicit step.

---

## 7. Known first-boot unknowns

Every item below was flagged by an earlier phase as **unverifiable without
a real Nobara install running Plasma** — `msi` was still NixOS/Hyprland (or
in the fedora:43 container used for package-name checks) at the time each
role/template was written. Check all of them during or after section 5;
none of them are guesses that were silently resolved, they are open
questions carried forward on purpose.

1. **`nvidia-frequency.service` ordering vs. the driver**
   (`ansible/roles/nvidia/templates/nvidia-frequency.service.j2`). On NixOS
   the kernel module is guaranteed loaded before `multi-user.target`; on
   Nobara `akmod-nvidia`/dracut own that timing instead, and the unit only
   declares `After=multi-user.target`. If `nvidia-smi` reports "No devices
   were found" in `systemctl status nvidia-frequency`, add
   `After=nvidia-persistenced.service` (or similar) and re-test.
2. **WirePlumber Bluetooth codec properties key name**
   (`ansible/roles/audio/templates/wireplumber-20-bluetooth-quality.conf.j2`).
   Ported as a bare top-level `properties = {...}` block from the NixOS
   module, not `monitor.bluez.properties` (the key upstream WirePlumber's
   own shipped `50-bluez-config.conf` uses). If `bluetoothctl`/`wpctl` show
   the codec preferences (SBC-XQ, mSBC, hw-volume) not taking effect, rename
   the top-level key and re-test.
3. **WirePlumber ALSA headroom conf syntax**
   (`ansible/roles/audio/templates/wireplumber-10-alsa-headroom.conf.j2`) —
   ported verbatim as WirePlumber 0.5 SPA-JSON conf.d syntax, never checked
   against Nobara's actual shipped WirePlumber version/schema. Verify with
   `wpctl status` and `pw-metadata -n settings | grep xrun`.
4. **Catppuccin theme/cursor `XDG_DATA_DIRS` discovery**
   (`ansible/roles/kde/tasks/xdg_data_dirs.yml`,
   `ansible/roles/kde/defaults/main.yml`). The `90-nix-profile-xdg-data-dirs.conf`
   environment.d drop-in is expected to win over any distro-shipped
   `/usr/lib/environment.d/*.conf` by sort order, but this was never
   confirmed against a live Nobara install. If Catppuccin themes/cursors
   don't appear in System Settings after login, check
   `systemctl --user show-environment | grep XDG_DATA_DIRS`.
5. **`private_kded5rc` vs. Plasma 6's `kded6rc`.** Kept under the Plasma-5
   filename from the old dotfiles repo because `roles/kde` runs before
   `roles/chezmoi` in `playbooks/linux.yml`, so there was nothing on disk
   yet to detect/rename when that role ran. Nobara ships Plasma 6 — after
   `chezmoi apply`, check whether Plasma actually reads `kded5rc` or
   ignores it in favor of `kded6rc`, and rename the chezmoi source file if
   needed.
6. **XKB `ctrl:swapcaps` vs. kanata overlap** (`msi-facts.md` "Locale / time
   / keyboard"). Both the X11/Wayland `ctrl:swapcaps` option
   (`private_kxkbrc`) and kanata's own remapping cover caps↔ctrl; which one
   is actually load-bearing on a live session was never determined. If caps
   behaves unexpectedly (double-swapped, or not swapped), check both layers.
7. **`kanata_bin_path` (`%h/.nix-profile/bin/kanata`)**
   (`ansible/roles/desktop_linux/defaults/main.yml`) — assumes
   `nix profile install nixpkgs#kanata` symlinks the binary exactly there.
   Never confirmed against a real `nix profile install`. If
   `kanata.service` fails with "command not found", check
   `~/.nix-profile/bin/` directly.
8. **`NetworkManager-wait-online.service` unit name**
   (`ansible/roles/networking/tasks/main.yml`) — the mask task is guarded
   `failed_when: false` specifically because the unit name was guessed, not
   confirmed present on Nobara. Check the play's own output for the
   "needs first-boot confirmation" debug message it emits if masking
   failed.
9. **firewalld's `kdeconnect` built-in service** — assumed to cover the
   full KDE Connect port range (1714-1764/tcp+udp) as a shipped firewalld
   service file from the `kde-connect` RPM, never verified live
   (`ansible/roles/desktop_linux/tasks/firewall.yml`). Confirm with
   `firewall-cmd --info-service=kdeconnect`; if the name or range is wrong,
   fall back to explicit ports (commented alternative in that same file).
10. **Brave Flatpak managed-policy path.** Assumed to be the same
    `/etc/brave/policies/managed/` as the RPM build (per the Flathub
    manifest's `--filesystem=host-etc` + launcher symlink), never confirmed
    on msi. Confirm with
    `flatpak info --show-permissions com.brave.Browser` after install, and
    check the three forced extension IDs (bitwarden, sponsorblock,
    Quedelix — PLAN.MD task 2.10) actually get force-installed.
11. **KDE config merge, wholesale.** All 17 chezmoi-managed KDE files
    (`kdeglobals`, `kwinrc`, `plasmashellrc`, the appletsrc this doc's
    bootstrap step resets, etc.) are byte-identical copies of the old
    dotfiles repo — the best available source, but **never tested against a
    running Plasma session anywhere** (PLAN.MD phase 2 report, item 6).
    Watch `chezmoi apply -v` output during the first site.yml run for merge
    errors, not just the post-hoc `chezmoi diff` check in section 5.
12. **Package names verified against a `fedora:43` container, not real
    Nobara** (PLAN.MD phase 3 report, item 7). `dnf_packages`,
    `pkgs_copr`, `pkgs_flatpak` in `ansible/inventory/group_vars/nobara.yml`
    have never actually resolved against Nobara's repos. The first
    `roles/pkgs` run in section 4.2 step 2 is the actual test; if any
    package name 404s, that's expected to be the first real breakage, not a
    sign something else is wrong.

Two adjacent items from the chezmoi tree are not msi-specific but will
surface the first time these apps launch on msi too, so it's worth
rechecking they're still open: `chezmoi/dot_config/nvim/init.lua`'s
`vim.pack.add` block is still commented out as of this writing (grep the
file to confirm before the first `nvim` launch — if still commented, nvim
starts with zero plugins), and `~/.config/lazygit/theme.yml` still has no
task creating the day/night symlink `theme-switcher.sh` used to provide
(grep `ansible/roles` and `chezmoi/` for `lazygit` to confirm before the
first `lazygit` launch).
