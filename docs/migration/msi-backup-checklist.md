# `msi` — pre-reinstall backup checklist

Everything on `msi` that is **not** in this git repo and would be lost by the
Nobara reinstall (PLAN phase 6). Compiled 2026-09-23 from a read-only SSH
inventory; sizes are `du -sh` at that moment.

## Read this first

Two assumptions in the task brief turned out to be false on this host:

- **restic-to-Hetzner is NOT running on `msi`.** `modules/nixos/backup.nix`
  is enabled only by `home-server` (`configurations/nixos/home-server/default.nix:55`,
  backing up `/data/syncthing`, `/data/immich` and *that host's*
  `/home/volodia/Documents`). `msi` never sets `my.backup.enable`, and there
  is no `restic-backups-*.service` or timer on the machine.
  (Corrected: an earlier draft of this file claimed no host enables it at
  all. home-server does; msi does not.)
- **Syncthing is running but shares nothing.**
  `~/.local/state/syncthing/config.xml` has a single placeholder folder with
  empty `id`/`label`/`path`, and exactly one device — `msi` itself. No peers.

So the "already synced elsewhere" column below is **"no" for essentially
everything**. Nothing on this machine is protected today.

## Sizes at a glance

| Area | Size | Verdict |
| --- | --- | --- |
| `/persistent/home/volodia` (all of `$HOME`) | **34 G** | must back up (selectively) |
| `/Games` (`/dev/sdb5`, separate disk) | **120 G** | do **not** back up — see below |
| `/persistent/var` | 3.8 G | flatpak store + systemd state, reinstallable |
| `/var/log` | 192 M | disposable |
| `/persistent/etc` | 44 K | machine identity, back up |
| `/nix` | 69 G | disposable (rebuildable) |

**Recommended copy target: ~5 GB of genuinely irreplaceable data, or ~34 GB
if you take all of `$HOME` verbatim.** The 31 GB in `~/Downloads` is almost
entirely re-downloadable media and dominates the number.

### The `/Games` shortcut

`/Games` is `/dev/sdb5` on a **physically separate disk** (`sdb`, Crucial
BX500). The OS lives entirely on `sda`. If the Nobara installer is pointed at
`sda` only and `sdb` is left alone, 120 GB of Steam content **and the game
saves in `compatdata`** survive untouched with zero copying. This is by far
the highest-value action on this list.

- [ ] **Confirm the Nobara installer targets `sda` only and does not touch
      `sdb`.** `sdb` also holds an old Windows install (`sdb3`, 280 G ntfs)
      and its ESP (`sdb1`) — decide separately whether that stays.
- [ ] If `sdb` *will* be wiped, back up `/Games/SteamLibrary/steamapps/compatdata`
      (2.0 G) and `/Games/default` (340 M) — everything else under `/Games`
      is re-downloadable.

---

## 1. Credentials and identity — small, highest consequence

- [ ] `~/.ssh/id_ed25519` + `~/.ssh/id_ed25519.pub` — 432 B / 113 B.
      **Private key; contents not read.** Not synced anywhere. If lost, every
      `authorized_keys` entry that trusts it must be reissued. Highest-value
      item per byte on the machine.
- [ ] `~/.ssh/known_hosts` (1658 B) and `~/.ssh/known_hosts.old` (922 B) —
      not synced. Cheap to keep, annoying to rebuild.
- [ ] `~/.ssh/agent/` (directory, mode 0700) — ssh-agent socket dir; likely
      runtime-only, verify before assuming it is empty of key material.
      (`~/.ssh/authorized_keys` and `~/.ssh/config` are symlinks into the
      Home-Manager store — already in git, skip.)
- [ ] `~/.local/share/keyrings/login.keyring` (3666 B) +
      `user.keystore` (207 B) — GNOME keyring; holds saved application
      secrets. Not synced. Encrypted with the login password.
- [ ] `~/.gnupg/` — 20 K total. `private-keys-v1.d/` is **empty** and
      `pubring.kbx` is 32 B (no keys). Only `sshcontrol` (676 B) and
      `trustdb.gpg` (1200 B) have content. Low value, copy anyway, it is tiny.
- [ ] `/persistent/etc/ssh/` — 20 K. **SSH host keys**
      (`ssh_host_ed25519_key`, `ssh_host_rsa_key` + `.pub`). Root-readable
      only; not read. Keep these if you want `msi` to present the same host
      identity after reinstall — otherwise every client, including this repo's
      `known_hosts`, must re-trust it. Contents never to be recorded.
- [ ] `/persistent/etc/machine-id` (4 K) — systemd machine ID. Keep only if
      you care about journal continuity / identity-derived state.
- [ ] `~/.config/rtk/` (8 K) — may contain tokens. Inspect before discarding.
- [ ] `~/.claude.json` (161 B) and `~/.claude/settings.json` — small config,
      may reference credentials.

**Not backed up, by design:** `~/.envvars.sh`, `~/.mail.inria.password.txt`,
`~/.python-grid5000.yaml` are symlinks into `/run/user/1000/agenix/` —
decrypted agenix secrets, regenerated from the repo. Nothing to copy.

## 2. Config the repo does not own

- [ ] `/persistent/etc/NetworkManager/system-connections/` (8 K) — saved
      Wi-Fi/Ethernet connections **including PSKs**. Directory is root-only;
      **could not be read during this inventory**. Not in git, not synced.
      Needs a root read (or manual re-entry of Wi-Fi passwords after install).
- [ ] `~/.config/chezmoi/chezmoistate.boltdb` (128 K) — chezmoi's
      `run_once_` bookkeeping. Deleting it just re-runs the scripts; keep only
      if you want to avoid that.
- [ ] `~/.config/qBittorrent/` (32 K) + `~/.local/share/qBittorrent/` (8.6 M,
      of which `BT_backup` holds the active torrent/resume state). Not in git,
      not synced. Losing `BT_backup` loses all seeding torrents.
- [ ] `~/.config/mpv/` (60 K), `~/.config/nvim/` (124 K), `~/.config/kitty/`,
      `~/.config/git/`, `~/.config/starship.toml`, `~/.config/tmux/`,
      `~/.config/bottom/`, `~/.config/lazygit/`, `~/.config/k9s/`,
      `~/.config/htop/`, `~/.config/zathura/`, `~/.config/fuzzel/`,
      `~/.config/direnv/` — **verify each against `chezmoi/` in this repo
      before copying.** Most are Home-Manager/chezmoi output and are already
      in git; any that differ are local drift worth capturing.
- [ ] `~/.config/hypr/` (28 K), `~/.config/noctalia/` (52 K),
      `~/.local/state/noctalia/` (20 M), `~/.config/darkman/` (8 K) —
      Hyprland/noctalia. **Dropped per PLAN §0** (target is KDE Plasma).
      Archive only if you want the theming as reference material.
- [ ] `~/.config/FreeCAD/` (72 K) + `~/.local/share/FreeCAD/` (40 K),
      `~/.config/blender/` (964 K), `~/.config/OrcaSlicer/` (**173 M** —
      printer profiles, filament presets, print history). OrcaSlicer profiles
      are hand-tuned and genuinely painful to rebuild. Not synced.
- [ ] `~/.local/share/orca-slicer/` (76 K), `~/.local/share/SVP4/` (88 K),
      `~/.local/share/fonts/comicode` (476 K), `~/.local/share/pki/` (76 K).
- [ ] `~/.config/karabiner/` (20 K) — macOS-oriented; probably dead on this
      host, confirm before copying.
- [ ] `~/.hyperhdr/` (40 K) — HyperHDR LED config. **`hyperhdr` is dropped per
      PLAN §0**; archive only.
- [ ] `~/.local/state/theme-switcher/` (212 K), `~/.local/state/headroom/`
      (268 K), `~/.local/state/k9s/` (84 K), `~/.local/state/syncthing/`
      (116 K — device ID/certs; keep if you want the same Syncthing identity).
- [ ] `~/.zsh_history` (52 K) and `~/.bash_history` (703 B) — not synced,
      unrecoverable, tiny. Easy win.
- [ ] `~/.config/systemd/` (84 K) — user units not managed by HM; diff against
      the repo.

## 3. Application data — large, mostly not replaceable

- [ ] `~/.config/BraveSoftware/Brave-Origin/` — **377 M**. The Brave profile:
      history, cookies, logins, extensions, session. Not synced. PLAN §0 keeps
      `brave-origin`, so this profile should come across. Copy while Brave is
      **closed**.
- [ ] `~/.config/Signal/` — **216 M**. Signal Desktop. `sql/db.sqlite` is
      encrypted with a key in `config.json` — **copy the whole directory or
      nothing**; a partial copy is unrecoverable. Not synced. Alternatively
      just re-link the desktop client from the phone and skip it, accepting
      loss of local message history not on the phone.
- [ ] `~/.var/app/com.bambulab.BambuStudio/` — **200 M**. The only Flatpak
      app's data (printer presets, projects). Not synced.
- [ ] `~/.t3/userdata/` — **179 M** (of `~/.t3` = 179 M total). Not synced.
- [ ] `~/.config/opencode/` — 63 M, but **63 M of it is `node_modules`**.
      Real content is `skills/` (168 K), `tui.json`,
      `oh-my-openagent.json`, `package-lock.json` — copy those, drop
      `node_modules`.
- [ ] `~/.config/T3 Code (Alpha)/` — 20 M.
- [ ] `~/.claude/` — 14 M. `projects/` (8.5 M, conversation history),
      `skills/` (4.2 M), `backups/`, `settings.json`. `cache/` and
      `telemetry/` are disposable.
- [ ] `~/.local/share/supermaven/` (14 M), `~/.local/share/opencode/` (17 M),
      `~/.local/share/opentui/` (1.7 M) — mostly caches; check before copying.
- [ ] `~/.local/state/nvim/` (6.8 M) — shada, undo history, sessions.
- [ ] `~/.tmux/resurrect/` (928 K) — tmux session snapshots. Disposable.
- [ ] `~/.config/chromium/External Extensions/` (20 K) — trivial.
- [ ] `~/.config/kdeconnect/` (16 K) — device pairings; re-pairing is easy.

## 4. User documents

- [ ] `~/Documents/` — **1.6 G total.** Breakdown:
  - `Stand/` **1.1 G** — 3D print project (3MF/STL, FDM + photopolymer
    variants). **Original work, nowhere else. Highest-value data on the
    machine after the SSH key.**
  - `nixos-configs/` 171 M — **this repo.** Local `main` is at `ff247b8`,
    identical to `origin/main`, so it is pushed. *Uncommitted working-tree
    changes were not checked* (no `git` commands were run per instructions) —
    **verify `git status` is clean on msi before wiping.**
  - `fixed.sql.gz` 138 M — a database dump. Provenance unknown; check whether
    it still matters.
  - `old-nix/` 54 M — a previous copy of the Nix config tree (`flake.nix`,
    `modules/`, `chezmoi/`, `persistent/`). Likely superseded by the repo but
    is exactly the kind of §0.1 prior-art source material this migration
    references. Keep at least until the migration is done.
  - `CV2/` 39 M, `test.FCStd` 36 M + `test.20260902-145522.FCBak` 1.2 M,
    `randonnees aude/` 18 M, `printer-slowdown/` 1.7 M, `k3s.yaml` 4 K
    (kubeconfig — may contain a cluster token).
- [ ] `~/Pictures/Wallpapers/` — 11 M. Not synced.
- [ ] `~/Music/`, `~/Videos/`, `~/.zotero/`, `~/.nixops/`, `~/.docker/`,
      `~/.supermaven/` — all empty or 4–8 K. Nothing to do.
- [ ] `~/Downloads/` — **31 G**, and the single biggest line item in `$HOME`.
      Overwhelmingly re-acquirable:
  - ~15 G of TV/film `.mkv` (Silo S03E09/E10 2.8 G each, Slow Horses S06E01
    3.6 G, Widows Bay S01 5.4 G, etc.) — **drop.**
  - `rife_v2_v4/` 321 M + `rife_v2_v4.7z` 190 M — RIFE models. **`mpv-rife`
    is dropped per PLAN §0. Drop.**
  - `3D/` 816 M, `Spirit/` 921 M + `Spirit.zip` 103 M, `toto/` 953 M,
    `Sweeping_Name_Plate_VZZM*` (~370 M across duplicated `.3mf`/`.stl`),
    `A1+HQ+PRESET.3mf` 137 M, `Spirit_HQ.3mf` 67 M — 3D printing assets.
    **Triage: some of this is likely project work worth keeping, the rest is
    downloaded models. Needs a human pass.**
  - `Les chroniques de Narnia …epub` 72 M, `Inter.zip` 20 M,
    `StudioBridge-2.1.3-x86_64.AppImage` 43 M — re-downloadable.

## 5. Confirmed nothing to back up

Checked and empty / irrelevant:

- Docker: **0 images, 0 containers, 0 volumes.** `/persistent/var/lib/docker`
  is 4 K.
- Podman / libvirt / VirtualBox / GNOME Boxes: **not installed**, no VM
  images anywhere on the system.
- k3s: `/persistent/var/lib/rancher` 16 K, `/run/k3s/containerd` empty, no
  `k3s.service` enabled. Only `~/Documents/k3s.yaml` (4 K) remains.
- PostgreSQL, Redis (`redis-immich`), fail2ban, colord, bluetooth,
  tailscale state: all 4 K stubs under `/persistent/var/lib/`. (Re-authing
  Tailscale after reinstall is a 30-second job.)
- `/persistent/var/lib/flatpak` 3.5 G — the Flatpak *runtime store*.
  Reinstallable; only the `~/.var/app/` data above matters.
- `/persistent/var/lib/systemd` 128 M, `/var/log` 192 M — journals and
  systemd state. Disposable.
- `/nix` 69 G — rebuildable from the flake. Disposable.
- `/persistent/swapfile` 17 G — swap. Disposable.
- `/home/volodia/~/.cache/vsmlrt` — empty; artefact of an unexpanded `~` in
  the impermanence config. Do not recreate.
- `~/.nix-profile` → `~/.local/state/nix/profiles/profile`: `nix profile
  list` is empty.

## 6. Could not read

- [ ] `/etc/NetworkManager/system-connections/` — permission denied as
      `volodia`; passwordless sudo is not configured on `msi`. **Needs a root
      read before the wipe** (Wi-Fi PSKs live here).
- [ ] Live `nft list ruleset` / `iptables-save` — same reason. Worked around
      by capturing the generated `firewall-start` script instead; see
      `msi-network.txt`.
- [ ] `~/.ssh/id_ed25519`, `/persistent/etc/ssh/ssh_host_*_key` — private key
      material, deliberately not read. Paths recorded only.
- [ ] Working-tree cleanliness of `~/Documents/nixos-configs` — no `git`
      commands were run. Verify manually.
