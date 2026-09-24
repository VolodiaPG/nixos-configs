# Migration runbook — NixOS/nix-darwin → Ansible + chezmoi

**Audience: agents executing this migration.** Each task below is a
self-contained ticket: preconditions, steps, deliverable, verification. Work
tasks in order within a phase; phases 2–5 can overlap. Update the
[progress table](#progress) as you go.

Branch: `ansible`. Control node: the macOS host (`Volodias-MacBook-Pro`).

---

## 0. Decisions already made — do not relitigate

| Question | Decision |
| --- | --- |
| Target Linux distro | **Nobara Linux, KDE edition** (Fedora-based). Chosen partly for a later Asahi path. |
| `msi` | Migrates to Nobara KDE. Full reinstall. |
| `m1` | **Retired.** Delete its config; do not port it. |
| `home-server` | **Stays on NixOS.** Out of scope. The flake must keep evaluating for it. |
| Desktop | **KDE Plasma** (Nobara default). Hyprland, noctalia, GNOME/dconf are all dropped. |
| Impermanence | **Dropped** on migrated hosts. (`home-server` keeps it, in the flake.) |
| Nix | **Kept as a package manager only** — Determinate Nix, for `devenv`/direnv/`.envrc` projects. No NixOS, no nix-darwin, no Home Manager on migrated hosts. |
| Deploy model | **Push** (`ansible-playbook` over SSH/Tailscale) now. Pull (`ansible-pull` on a timer) later. |
| Theme switching | Must stay **instantaneous and decoupled from chezmoi**. Use Plasma's native day/night scheme switching. Low priority. |
| `mpv-rife` | **Dropped.** Keep `mpv.conf`/`input.conf` (auto-subs, UI); drop the RIFE/VapourSynth/TensorRT stack. |
| Secrets | **ansible-vault.** Several existing secrets are dead — audit and prune. |
| Syncthing | **Native service**, not a container. Systemd user unit on Linux (per the split rule), launchd agent on macOS. Wanted even though msi's instance currently has no peers/folders. Do not port the old repo's linuxserver.io compose file. |
| Hetzner storagebox users | **Both are live.** `u593939` is the general account (`config.nix` `hetzner-user`, `static/config.ssh`); `u593939-sub1` is the **backup** user. Carry both. |
| Zed | **Install it.** Add to the Linux and macOS package sets; adopt `dot_config/zed/` from the old repo. |
| Container runtime on msi | **Docker** is installed and available today. Use it for throwaway verification containers (task 0.3). Long-term runtime choice for the Ansible `virtualization` role is still podman + distrobox unless a role needs docker. |
| Repo | Migrate on branch `ansible`. |
| Prior dotfiles repo | **`github.com/VolodiaPG/dotfiles` is in scope as source material** — see §0.1. It is a working pre-Nix version of the target architecture. |
| `services.caddy` on msi | **Dropped.** Do not port `modules/nixos/caddy.nix` or `static/services-page/`. |
| `hyperhdr` | **Dropped.** Do not port `modules/nixos/hyperhdr.nix`. |
| `programs.opencode` | **Dropped.** Remove from the tooling list; also drop `dot_config/opencode/` if merging the old dotfiles repo. |
| Browser | **Brave Flatpak `com.brave.Browser`.** Task 0.3 established no `brave-origin` Flatpak exists and that Flathub ships upstream Brave; the user chose the Flatpak anyway (2026-09-23), accepting the different build. nixpkgs `brave-origin` is the fallback. |
| `msi` addressing | Reachable by **Tailscale name**. Use it in the inventory, not a LAN IP. |
| `~/.config/nvim` | **This repo's inline tree wins** (`chezmoi/dot_config/nvim/`). It is up to date; `github.com/VolodiaPG/vim` is not. Drop the old `.chezmoiexternal.toml` nvim entry. |
| macOS app set | **Intersection, plus `steam`, `calibre`, `qbittorrent`** — see §0.2. Where the two sources otherwise disagree, neither side is worth carrying. |
| CPU governor | **Dropped.** Let Nobara's own power-profile handling run. Do not port `run_once_governor.tmpl`. |
| `immich-ml` | **Dead.** Do not port the module or the old repo's user unit. |

### 0.2 macOS app set — resolved to the intersection

The two lists disagree; none of the disputed entries are worth carrying
**except three the user has explicitly kept**. Install what both lists agree
on, plus those three, and drop the rest:

- **Keep** (in both lists): `karabiner-elements`, `tg-pro`, `bettermouse`,
  `betterdisplay`, `tidal`, `signal`, `vlc`, `parsec`.
- **Keep** (explicit rulings, also present in the Linux set): `steam`,
  `calibre` (both nix-darwin-only), `qbittorrent` (old-repo-only).
- **Drop** (nix-darwin only): `hiddenbar`, `alt-tab`.
- **Drop** (old dotfiles repo only): `ghostty`, `mtmr`, `skim`, `bitwarden`,
  `container`, `bambu-studio`, `obsidian`, `zotero`, `unified-remote`, `jan`,
  `drawio`, `helium-chromium`, plus the `nushell`, `carapace`, `aider`,
  `docker`, `skhd` formulae.
- **Brews still needed regardless of the two lists**: the CLI tooling that
  `common-home.nix`/`interactive.nix` provided under Nix (task 3.1). These
  were never cask-level disagreements and this ruling does not touch them.

That is **11 casks** from the intersection, plus `kitty` (in both Nix
lists, so never a disputed entry) and `zed` (§0) — **13 casks** total. `steam`, `calibre` and `qbittorrent` are a
deliberate override of the intersection rule, not an oversight — do not prune
them back out when reconciling.

### 0.1 Prior art — `github.com/VolodiaPG/dotfiles`

**Read this repo before starting phase 2.** It is a chezmoi dotfiles repo the
user ran *before* the Nix setup, targeting Arch + KDE Plasma + macOS. It
already implements much of what this plan describes, and it solves the
hardest open problem (KDE config) properly. Last commit 2026-07-16.

Clone it read-only for reference:
`git clone --depth 1 https://github.com/VolodiaPG/dotfiles`

What it contains and how to treat each part:

| Asset | Disposition |
| --- | --- |
| `dot_config/modify_*` + `*.src.ini` — KDE rc files via **`chezmoi_modify_manager`** | **Adopt wholesale.** This is the correct solution to task 2.9; do not invent another. |
| `dot_local/share/plasma/look-and-feel/` — 11 themes | **Adopt only 4**: `Catppuccin-Mocha-Mauve`, `Catppuccin-Latte-Mauve`, `Custom dark`, `Custom light`. The other 7 (`dark`, `light`, `Custom latte`, `Custom latte 2`, `Custom moccha`, `Itchy`, `Scratchy`) are a legacy generation. |
| `dot_local/share/plasma/desktoptheme/{Itchy,Scratchy}` | **Drop.** All four adopted look-and-feels set `[plasmarc][Theme] name=default`, so nothing references them. Verified. This is 228 of B's 392 files — 58% of the repo. |
| `dot_local/share/color-schemes/`, `dot_local/share/aurorae/themes/` | **Adopt the Catppuccin ones only** (`CatppuccinMochaMauve.colors`, `CatppuccinMocha-Modern`, `CatppuccinLatte-Modern`). Drop `Itchy.colors` and the Itchy/Scratchy aurorae. |
| `dot_config/private_kxkbrc` — already `LayoutList=fr`, `VariantList=oss` | **Adopt.** Satisfies part of task 4.4. |
| `run_once_kanata.sh.tmpl` — uinput group + udev rule + user service | **Adopt the logic, move to Ansible** (needs root). |
| `run_once_packages.sh.tmpl` — `brew bundle` block (macOS) + `paru -S` list (Arch) | **macOS: take the intersection with the nix-darwin block** per §0.2, not this list wholesale. **Linux: translate** the paru list to dnf; it is Arch-only. |
| `run_once_defaults.tmpl` — macOS `defaults write` settings | **Adopt**, translate to `osx_defaults`. More complete than `modules/darwin/common-darwin.nix`. |
| nvidia clock-lock systemd unit (inside `run_once_packages.sh.tmpl`) | **Adopt**, but see task 4.5 — its values disagree with the Nix module. |
| `run_once_{docker,services,udev_usb_chrome}` | **Port to Ansible roles** (all need root). |
| `run_once_mediacontrole.sh.tmpl` | **Drop.** Depends on MTMR + nushell + `/opt/homebrew/bin/media-control`, all dropped by §0.2 — the port would have no consumer. |
| `dot_config/zed/` | **Adopt** (current-era, missed by the first pass). Zed is not in any Nix package list; add it to the package sets (§0). |
| `Documents/docker-services/syncthing/` | **Drop.** Resolved in §0: Syncthing runs as a native service, so `modules/home/syncthing.nix` is the model and this compose file is superseded. |
| `run_once_governor.tmpl` | **Drop** (§0 — Nobara handles power profiles). |
| `dot_config/systemd/user/{kanata,immich-ml}.service` | kanata → Ansible; immich-ml → **drop** (§0, dead). |
| `dot_zshrc`, `dot_bashrc`, `dot_profile`, `dot_blerc` | **Do not adopt.** Oh-my-zsh based, older than the HM-generated zshrc, and carries hardcoded paths (`/Users/volodia/...`, lmstudio). The HM output wins — see task 2.6. |
| `.chezmoiexternal.toml` — pulls `~/.config/nvim` from `github:VolodiaPG/vim` | **Drop the nvim entry.** This repo's inline tree is authoritative (§0). Keep the file only if something else needs vendoring. |
| `dot_config/{yabai,skhd,opencode}/` | **Drop.** yabai/skhd were already disabled in Nix; opencode is dropped per §0. |
| `run_once_yabai.tmpl`, `run_once_ble.sh.tmpl`, `run_once_devenv.sh.tmpl` | Drop (devenv now comes from Determinate Nix, task 3.4). |

**Theme assets have three gaps — resolve them in task 2.7, not at cutover:**

1. **`CatppuccinLatteMauve` is missing.** `Catppuccin-Latte-Mauve` and
   `Custom light` both set `ColorScheme=CatppuccinLatteMauve`, but the tree
   ships only `CatppuccinMochaMauve.colors`, `Itchy.colors` and
   `private_CatppuccinLatteFlamingo.colors`. **Light mode breaks as-is.**
   Either install `catppuccin-kde` or repoint those two themes at the
   Flamingo scheme that is actually present.
2. **Cursor and window-decoration themes are assumed, not shipped.**
   `Catppuccin-{Mocha,Latte}-Mauve-Cursors` and `Fluent-purple-{dark,light}`
   are referenced by the adopted themes but exist in neither tree — they
   become Ansible-installed packages (task 3.1/4.7).
3. **`.chezmoiignore` is load-bearing, not cosmetic.** Without
   `**/*.src.ini`, chezmoi writes the `chezmoi_modify_manager` *source* files
   into `~/.config/` alongside the real ones. It must exist before any KDE
   file is applied.

**Two structural lessons from it, both of which the plan applies:**

1. That repo did *everything* in chezmoi `run_once_` scripts because it had no
   Ansible. We do. Apply the split rule from §2: anything needing root (udev,
   system units, packages, groups) becomes an **Ansible role**; only `$HOME`
   content stays in chezmoi.
2. It used `run_once_` for package installation, which runs exactly once per
   machine — adding a package later never installs it. Where a script *does*
   stay in chezmoi, prefer **`run_onchange_`** so edits re-trigger it.

### Scope

In scope: **`msi`** (→ Nobara KDE) and **`Volodias-MacBook-Pro`** (→ macOS +
Ansible + Homebrew + Determinate Nix).

Out of scope: `home-server` (stays NixOS), `m1` (retired), `installer` ISO
(dropped — a stock Nobara ISO plus `playbooks/bootstrap.yml` replaces it).

---

## 1. Rules for agents

1. **Never break `home-server`.** It stays on NixOS and is deployed from this
   repo. After *any* change touching `flake.nix`, `modules/nixos/`,
   `secrets/`, `config.nix`, `lib/` or `overlays/`, run:
   ```sh
   nix eval --raw .#nixosConfigurations.home-server.config.system.build.toplevel.drvPath
   ```
   It must succeed. If a deletion breaks it, the module is still in use —
   keep it.
2. **Deletions are last.** Nothing under `modules/`, `configurations/nixos/msi/`
   or `configurations/darwin/` is deleted until the corresponding host has
   successfully cut over (phase 6). `configurations/nixos/m1/` is the sole
   exception (retired, task 1.4).
3. **Never run a destructive command on a live host without confirming with
   the user first.** Disk partitioning, `dnf remove`, `rm -rf ~/.config/*`,
   uninstalling Nix. Ask, then act.
4. **`--check --diff` before every real run.** Every Ansible task must be
   idempotent: a second run reports zero changes. If it doesn't, fix the task,
   don't shrug.
5. **Commit per task**, message `ansible: <task id> <what>`, on branch
   `ansible`.
6. **Record what you verify.** Package-name lookups, unit names, config paths
   — write them into `docs/migration/`, don't leave them in a transcript.
7. **Stop and ask** when a task says STOP, or when a decision would be
   irreversible and isn't in §0.

### Nobara-specific gotchas — read before writing any Linux role

- Nobara **must not** be upgraded with a bare `dnf upgrade`. It ships
  `nobara-sync` (CLI: `nobara-sync cli`), which sequences repo/package fixups.
  Ansible roles must never do a blanket `dnf: name='*' state=latest`. Pin
  explicit package names with `state: present`.
- Nobara preconfigures RPM Fusion, multimedia codecs, and (on the NVIDIA
  edition) the NVIDIA driver. **Check before adding** — do not re-add repos
  Nobara already ships, and do not install `akmod-nvidia` by hand if the
  image already did.
- Extra packages frequently come from **COPR** (`community.general.copr`) or
  **Flatpak**, not the main repos. Verify every package name on the target
  with `dnf provides` / `dnf search` before writing it into a var file.
- Use `ansible.builtin.dnf5` (Fedora 41+ / Nobara 41+) — `dnf` module aliases
  work but emit deprecations. Confirm which is present on the target and
  note it in `docs/migration/msi-facts.md`.
- KDE Plasma **rewrites its own config files at runtime**. A file chezmoi
  owns outright will be clobbered by Plasma and produce a permanent diff.
  See task 2.9 for the handling.

---

## 2. Target layout

```
ansible/
  ansible.cfg                 # vault_password_file, inventory, ssh settings
  requirements.yml            # community.general, containers.podman
  inventory/
    hosts.yml                 # msi (ssh), macbook (local) + groups
    group_vars/
      all.yml                 # ← port of config.nix `me`
      all/vault.yml           # ansible-vault encrypted
      nobara.yml              # dnf/copr/flatpak package names
      darwin.yml              # brew formulae + casks
      desktop.yml
    host_vars/{msi,macbook}.yml
  roles/
    base/                     # locale fr_FR, tz Europe/Paris, sysctl, sudo, ssh
    users/                    # user, groups, authorized_keys
    nix/                      # Determinate Nix installer + nix.conf substituters
    pkgs/                     # platform-dispatching package role
    shell/                    # zsh login shell, starship, tooling (pairs w/ chezmoi)
    chezmoi/                  # install chezmoi, init from this repo, apply
    secrets/                  # vault-sourced files into place
    desktop_linux/            # fonts (incl. Comic Code), kanata, flatpak, xkb fr/oss
    kde/                      # Plasma settings that need root or kwriteconfig6
    nvidia/                   # msi only — verify against Nobara's own setup first
    gaming/                   # steam, gamemode, mangohud
    audio/                    # ex-hifi.nix: pipewire, realtime limits
    virtualization/           # podman, distrobox
    networking/               # NetworkManager tweaks, firewalld ports
    vpn/                      # tailscale
    darwin_defaults/          # osx_defaults, TouchID sudo, maxfiles launchd
    homebrew/
  playbooks/
    site.yml  linux.yml  macos.yml  bootstrap.yml
chezmoi/
  .chezmoi.toml.tmpl          # NEW — host/role/flavor data
  .chezmoiignore              # NEW — per-OS exclusions
  .chezmoiexternal.toml       # NEW — vendored assets
  dot_config/ ... dot_zshrc.tmpl ...
docs/migration/               # phase-0 inventory + verified name mappings
```

**Split rule, applied without exception:** chezmoi owns everything under
`$HOME`; Ansible owns anything needing root or a package manager. The one
carve-out is user systemd units, which Ansible writes (it must also enable
them).

---

## PHASE 0 — Inventory

Goal: capture ground truth from the running systems *before* dismantling
anything. Output is `docs/migration/`.

### Task 0.1 — Dump what Nix installs (run on macOS control node)

Cross-platform evaluation works from macOS, so both hosts can be dumped here.

```sh
mkdir -p docs/migration
nix eval --json --apply 'ps: map (p: p.pname or p.name) ps' \
  '.#nixosConfigurations.msi.config.environment.systemPackages' \
  > docs/migration/msi-system-pkgs.json
nix eval --json --apply 'ps: map (p: p.pname or p.name) ps' \
  '.#nixosConfigurations.msi.config.home-manager.users.volodia.home.packages' \
  > docs/migration/msi-home-pkgs.json
nix eval --json --apply 'ps: map (p: p.pname or p.name) ps' \
  '.#darwinConfigurations.Volodias-MacBook-Pro.config.environment.systemPackages' \
  > docs/migration/mac-system-pkgs.json
nix eval --json --apply 'ps: map (p: p.pname or p.name) ps' \
  '.#darwinConfigurations.Volodias-MacBook-Pro.config.home-manager.users.volodia.home.packages' \
  > docs/migration/mac-home-pkgs.json
```

**Done when:** four JSON files exist and are non-empty.

### Task 0.2 — Dump live system state from `msi`

Run **on msi** (SSH from the control node), before it is reinstalled:

```sh
systemctl list-unit-files --state=enabled        > msi-units-system.txt
systemctl --user list-unit-files --state=enabled > msi-units-user.txt
ip -j addr; nmcli -t con show                     # network, for the firewall/NM port
```

Also copy off anything not in git that you'd miss: `~/.ssh/known_hosts`,
browser profiles, `~/.local/share/` app data worth keeping. **This machine
gets wiped in phase 6.**

**Done when:** files are committed under `docs/migration/` and a
`docs/migration/msi-backup-checklist.md` lists what must be preserved
across the reinstall, with each item ticked as backed up.

### Task 0.3 — Build the package-name mapping table

The single most load-bearing artifact of this migration. Create
`docs/migration/package-map.md`: one row per package from 0.1, with columns
`nixpkgs attr | Fedora/Nobara source | exact name | verified?`.

Sources, in order of preference: Nobara/Fedora main repo → RPM Fusion →
COPR (`atim/*` covers many Rust tools) → Flatpak → Nix (`nix profile`) →
`upstream` (a released prebuilt binary, `get_url` + `unarchive` into
`~/.local/bin`) → drop it. `upstream` is a last resort and currently has
exactly one user: **`chezmoi_modify_manager`**, from
`github.com/VorpalBlade/chezmoi_modify_manager` releases (confirmed by the
user, 2026-09-23). It is a hard prerequisite for task 2.9.

**Correction (task 0.3, verified):** an earlier draft of this task claimed
the Task 0.1 lists were incomplete because Home Manager's
`programs.<x>.enable` packages never reach `home.packages`. **That was
wrong.** HM *does* add an enabled program's package to `home.packages` —
`git`, `zsh`, `tmux`, `zoxide`, `keychain`, `fzf`, `lazygit`, `direnv`,
`starship` and `neovim` are all present in both `msi-home-pkgs.json` and
`mac-home-pkgs.json`. `mac-home-pkgs.json` is not implausibly thin; the Mac
simply has no Linux desktop packages. What the JSON genuinely does not
capture is module-generated **config**, not packages — that is phase 2's
problem, not this table's. The one real package gap was `programs.ssh` /
`services.ssh-agent`, which resolve to `openssh-clients` from the base
install.

Also add packages that are in **neither** source but are wanted (§0):
`zed` (Flatpak `dev.zed.Zed` or the upstream COPR — verify which), and
`syncthing` itself, which becomes a native service rather than a container.

Ignore the synthetic helper derivations (`hm-session-vars.sh`,
`dummy-fc-dir*`, `ld-library-path`, `glibc-locales`, `X11-fonts`,
`index.theme`, `home-configuration-reference-manpage`) — already marked
NIX-ONLY in `package-inventory.md`. Likewise skip NixOS's stock base set
(`systemd`, `util-linux`, `shadow`, `procps`, `perl`, `which`, …), which
Nobara supplies from its own base install.

Verify each with `dnf search` / `dnf provides`. **Do not guess.** msi has
**docker** installed, so run the first pass in a throwaway container from the
macOS control node:

```sh
ssh msi -- docker run --rm -i fedora:43 bash -s <<'EOF'
dnf -y install dnf-plugins-core >/dev/null 2>&1
dnf -q search <name>
EOF
```

This is read-only with respect to msi (rule 3): `--rm`, no volume mounts, no
writes outside the container. Verified working from the control node: msi runs Docker 29.8.0 and the
`fedora:{41,42,43,44}` images all pull. Use **`fedora:43`** — Nobara's exact
base release is unconfirmed until the install ISO is picked, so record the
Fedora release you verified against in the table header. A plain `fedora:43`
image has **neither RPM Fusion nor Nobara's own repos**, so enable RPM Fusion inside the container
before searching, and mark anything that only resolves via a Nobara-specific
repo as `verified: on-box-required` rather than guessing.

**Verified name differences** (the rest of the once-suspected list —
`difftastic`, `chezmoi`, `gdu`, `grc`, `mosh`, `zoxide`, `just` — are all in
Fedora main under their nixpkgs name): `fd`→`fd-find`, `cpupower`→
`kernel-tools`, `gnumake`→`make`, `go`→`golang`, `vim`→`vim-enhanced`,
`wget`→`wget2-wget`, `lm-sensors`→`lm_sensors`, `libgtop`→`libgtop2`,
`kdeconnect-kde`→`kde-connect`, `docker`→`moby-engine`, `qttools`→
`qt6-qttools`, `bash-language-server`→`nodejs-bash-language-server`,
`inter`→`rsms-inter-fonts`, `noto-fonts-cjk-*`→`google-noto-{sans,serif}-cjk-fonts`,
`ShellCheck` (Fedora) vs `shellcheck` (brew), and the `NetworkManager` /
`ModemManager` capitalisation. `starship`, `lazygit`, `bottom` are absent
from Fedora main and come from COPR `atim/*`.

Packages with no clean Fedora path go to the **Nix column** — that's what
Determinate Nix is retained for. Prefer Nix over a hand-rolled COPR.

Known drops (do not map): `mpv-rife`, `vsmlrt`, `vstrt`, `miscfilters`,
`high-tide` (→ Flatpak if available), `noctalia*`, `hyprland*`, everything
GNOME-specific, `nixos-*` tooling, `nix-index`/`comma`, `home-manager`.

**Done when:** every entry from 0.1 has a decision and the `verified?`
column is fully populated. **STOP and ask** if more than ~10 desktop
packages have no source.

### Task 0.4 — Reconcile the two chezmoi trees

Produce `docs/migration/dotfiles-merge.md`: for every path present in both
`chezmoi/` (this repo) and the old dotfiles repo, which one wins and why.

Known conflicts to decide explicitly:

- **`~/.config/nvim`** — **resolved** (§0): the inline tree here wins. Drop
  the old repo's `.chezmoiexternal.toml` nvim entry; do not merge anything
  from `VolodiaPG/vim`.
- **zshrc** — HM output wins (see table above).
- **`dot_config/kitty`, `dot_config/tmux`, `dot_config/git`, `dot_config/zathura`**
  — present in both. The Nix-era versions are newer; diff them and take the
  union deliberately, per file.
- **`private_karabiner`** — present in both; diff.

**Done when:** the table is complete and every row has a decision. Nothing is
copied yet — that happens in phase 2.

---

## PHASE 1 — Scaffold

### Task 1.1 — Create the Ansible skeleton

Create `ansible/` per §2 with empty-but-valid roles. `ansible.cfg`:

```ini
[defaults]
inventory = inventory/hosts.yml
roles_path = roles
vault_password_file = ~/.config/ansible/vault-pass
host_key_checking = True
stdout_callback = yaml
[ssh_connection]
pipelining = True
```

`requirements.yml`: `community.general`, `containers.podman`, `ansible.posix`.

**Verify:** `ansible-playbook --syntax-check playbooks/site.yml` passes;
`ansible-lint` is clean.

**DONE.** Four corrections to the spec above, all found by actually running
the verification:

1. **`vault_password_file` is commented out.** Ansible hard-fails *every*
   command, including `--syntax-check`, when it points at a file that does
   not exist — which would make the whole scaffold unverifiable until phase
   4. Re-enable it in phase 4 when the vault has contents.
2. **`stdout_callback = yaml` does not exist any more.** It resolved to
   `community.general.yaml`, removed in community.general 12.0.0. The
   supported replacement is `stdout_callback = default` + `result_format =
   yaml`.
3. **`group_vars/` and `host_vars/` live under `inventory/`**, not beside
   `ansible.cfg` as §2 drew them. Ansible only resolves playbook-adjacent
   `group_vars`, so with playbooks in `playbooks/` the vars silently never
   loaded and every var was undefined at play time. Inventory-adjacent
   resolves from any playbook location.
4. **Roles have no `galaxy_info`** in `meta/main.yml`, just `dependencies`.
   These are not Galaxy roles, and `galaxy_info` drags in required
   `author`/`license` keys that ansible-lint enforces for no benefit.

`ansible/.ansible-lint` pins `profile: basic` and skips `yaml[line-length]`
— SSH public keys and substituter keys are single unbreakable tokens well
past 160 chars. The scaffold currently passes at `production`, two profiles
above the requirement.

**There is no `ansible` on any host yet.** Until the `pkgs` role installs
one, run it from the flake's nixpkgs:

```sh
nix shell --impure --expr '(builtins.getFlake (toString /Users/volodia/Documents/nixos-configs)).inputs.nixpkgs.legacyPackages.aarch64-darwin.ansible' -c ansible-playbook ...
```

### Task 1.2 — Port `config.nix` → `group_vars/all.yml`

`config.nix`'s `me` attrset is the existing single source of truth; keep that
property. Port to snake_case: `username`, `full_name`, `email`,
`signing_key`, `ssh_keys` (list of 3), `tailnet`, `hetzner_user`,
`bot_email`, `bot_smtp_address`.

Drop: `cachixName`, `extra-substituters`, `trusted-public-keys` —
**except** keep the substituter list for the `nix` role (task 3.4), since
Determinate Nix still benefits from them.

`homeDirectory`/`chezmoiDirectory` were stdenv-conditional functions; in
Ansible they become `home_dir: "{{ '/Users/' if ansible_system == 'Darwin' else '/home/' }}{{ username }}"`.

**Verify:** `ansible -m debug -a 'var=ssh_keys' all` prints all three keys on
both hosts.

**DONE.** `inventory/group_vars/all/main.yml` is **generated by `nix eval`
from `config.nix`**, not transcribed — the SSH keys and cache public keys are
exact by construction. Regenerate it the same way if `config.nix` changes
before phase 7 deletes it. Verified: 6 keys across the 2 hosts, and
`home_dir` resolves to `/home/volodia` on msi and `/Users/volodia` on
macbook (needs `gather_facts: true`; an ad-hoc `-m debug` has no facts and
will report `ansible_system` undefined).

`hetzner_backup_user` was added alongside `hetzner_user` — both storagebox
accounts are live (§0).

### Task 1.3 — Inventory

```yaml
all:
  children:
    linux:   { hosts: { msi: { ansible_host: msi } } }   # NOT the FQDN — see below
    nobara:  { hosts: { msi: {} } }
    darwin:  { hosts: { macbook: { ansible_connection: local } } }
    desktop: { hosts: { msi: {}, macbook: {} } }
```

`home-server` is deliberately absent. Do not add it.

**Use the bare name `msi`, not `msi.goblin-alewife.ts.net`.** The control
node's `known_hosts` has msi's keys recorded under the short name only, so
the FQDN fails host-key verification even though `ssh-keyscan` confirms both
names return byte-identical ed25519/RSA keys. Either keep the short name
(simplest) or add the FQDN to `known_hosts` — but do **not** paper over it
with `host_key_checking = False`.

**Verify:** `ansible-inventory --graph`.

**DONE.** Graph matches the spec, and a real `gather_facts` run against
`msi` over SSH succeeded under the bare name — confirming both Tailscale
reachability and the known_hosts caveat above.

### Task 1.4 — Retire `m1`

Delete `configurations/nixos/m1/` and its entry in `flake.nix`'s `nixosHosts`.
Check whether any module becomes unused as a result (`nixos-apple-silicon`
input; `modules/nixos/betterSleep.nix`, `elegant-boot.nix`, `ananicy.nix`,
`hifi.nix`, `home-lab.nix` are referenced by msi too — keep those until
phase 7).

**Verify:** rule 1 (home-server evaluates); `nix flake check` passes;
`nixos-apple-silicon` removed from `flake.lock` after `nix flake update`.

**DONE.** Deleted `configurations/nixos/m1/` (including its ~firmware
blobs), the `nixos-apple-silicon` input, the `m1.system` entry, the README
row and the stale `# - m1` comment in `deploy.yaml`. One non-obvious
knock-on: **`avd-fw` in `overlays/default.nix` existed only for
`nixos-apple-silicon`'s video module** and was removed with it. Verified:
`nixos-apple-silicon` is gone from `flake.lock` (0 matches), and all three
surviving configurations still evaluate — `home-server` (rule 1), `msi`, and
the darwin host.

### Task 1.5 — CI

Replace the nix-building workflows for the *migrated* hosts with
`ansible-lint` + `--syntax-check`. **Leave `deploy.yaml`'s `home-server`
job alone** — that host still deploys from this repo. Remove only the `msi`
build/cachix job, and only in phase 7.

**DONE (the additive half).** `.github/workflows/ansible.yaml` runs
`--syntax-check` on every playbook plus `ansible-lint`, path-filtered to
`ansible/**`. `deploy.yaml` is otherwise untouched: both the `msi` and
`home-server` build jobs still run. Removing the msi job is still phase 7.

---

## PHASE 2 — Dotfiles into chezmoi

The bulk of the work, and fully reversible: for each Home Manager module,
copy what it *generated* into chezmoi. If a later rebuild is a no-op for that
file, the port was exact.

**CORRECTION — do NOT delete any `modules/home/*.nix` in phase 2.** An
earlier draft said "copy it out, delete the module, rebuild". That is unsafe:
`configurations/nixos/home-server/home.nix` imports
`flake.self.nixosModules.home-manager`, which pulls in
`self.homeModules.default` — i.e. **all of `modules/home/`** — and sets
`my.commonHome.enable = true`. Deleting those modules breaks rule 1.
Phase 2 is **copy-out only**; every deletion waits for phase 7, where each
one is checked against home-server individually.

**Also do not run `darwin-rebuild switch`, `nixos-rebuild switch`, or
`chezmoi apply`.** Phase 2 produces files in the repo; it does not mutate a
running machine. Verify with `chezmoi diff`, `chezmoi execute-template`, and
`nix eval` — never with a switch. The cutover is phase 6.

**The core technique:** HM-generated dotfiles are symlinks into the Nix
store, so `cat ~/.zshrc > chezmoi/dot_zshrc` captures exact current
behaviour. Do this **on the macOS host, which is still running HM**, before
that host is cut over. Do not hand-rewrite what you can copy.

Today `chezmoi/` is a **flat tree with no templates, no `.chezmoiignore`, no
`run_*` scripts, and no `.chezmoi.toml.tmpl`** — all host/OS differentiation
currently comes from Home Manager. That machinery must be built, not ported.

### Task 2.1 — chezmoi config scaffolding (do this first)

Create `chezmoi/.chezmoi.toml.tmpl` exposing: `host`, `role`
(`desktop`/`mac`), `flavor` (`mocha`/`latte`), `email`, `signing_key`,
`home_dir`. Source values from prompts on first `chezmoi init`, defaults
derived from `.chezmoi.os` / `.chezmoi.hostname`.

Create `.chezmoiignore`: mac excludes `dot_config/hypr`, `dot_config/noctalia`,
`dot_config/OrcaSlicer`; Linux excludes `private_karabiner`. It must also
carry over `**/*.src.ini` from the old repo's `.chezmoiignore` — those are
inputs to `chezmoi_modify_manager`, not files to apply (task 2.9).

`.chezmoiroot` already points at `chezmoi/` — leave it.

`kitty.conf` `include`s `~/.config/kitty/kitty-themes/...`, which
`modules/home/gui.nix:77` currently symlinks out of `pkgs.kitty-themes`. That
symlink dies with Home Manager, so the themes must be vendored via
`.chezmoiexternal.toml` **before first apply** or kitty starts with a broken
include. Same for the catppuccin tmux/lazygit themes and `modernz.lua`.

Neither `.chezmoi.toml.tmpl` nor `.chezmoiexternal.toml` exists here yet; the
old dotfiles repo has an `.chezmoiexternal.toml` (nvim) and an
`.chezmoiignore` to start from. It has no `.chezmoi.toml.tmpl` either — the
templating data is genuinely new work.

**Verify:** `chezmoi execute-template < .chezmoi.toml.tmpl` renders on both
OSes; `chezmoi diff` on the mac shows no unexpected churn.

**How to render a template for verification — the obvious command does not
work.** `chezmoi execute-template < file` fails on `promptStringOnce` (that
function exists only during `init`), and `--init` only *enables* the prompt
functions — it does **not** populate `.data` from `.chezmoi.toml.tmpl`, so
any template referencing `.email` etc. dies with `map has no entry for key`.
The working recipe:

```sh
chezmoi execute-template --init < chezmoi/.chezmoi.toml.tmpl > /tmp/cfg.toml
# sourceDir MUST be prepended, before [data], or it lands inside that table
sed -i "" "1i\\
sourceDir = \"$PWD/chezmoi\"
" /tmp/cfg.toml
chezmoi --config /tmp/cfg.toml execute-template < chezmoi/dot_config/git/config.tmpl
```

**Expect `chezmoi diff` to be loud, and for that to be correct.** Every
target on the mac is currently a symlink into
`/nix/store/…-home-manager-files/`, so chezmoi reports each as "delete
symlink (120755) → write regular file". That *is* the cutover, not a porting
error. What matters is that no *content* differs unexpectedly.

### Task 2.2 — `git.nix` → `dot_config/git/config.tmpl`

31 lines. Template the signing key and email from chezmoi data.

**DONE.** Two things in this spec described features that do not exist:

- **"the credential helper differs per OS"** — Home Manager set **no**
  credential helper anywhere in the Nix tree (verified by grep across
  `modules/` and `static/`). Adding one would be a behaviour change, not a
  port, so `dot_config/git/config.tmpl` deliberately has no `[credential]`
  section. Add one later if it is actually wanted.
- **"the difftastic/delta pager setup"** — there is no delta. The generated
  config has `diff.external = difft` and nothing else: no `[pager]`, no
  `[delta]`, no `core.pager`. delta is in no package list.

One Nix-ism dropped: `gpg.ssh.program` pointed at a `/nix/store/…-openssh`
`ssh-keygen`; git's built-in default resolves it from `$PATH`.

### Task 2.3 — SSH bits from `common-home.nix`

`~/.ssh/config` is already `static/config.ssh` — move it to
`private_dot_ssh/config`. `authorized_keys` is generated from the key list →
`private_dot_ssh/authorized_keys.tmpl`.

Note `common-home.nix` sets HM's `programs.ssh.settings."*"` defaults
explicitly; fold those into the config file rather than losing them.

**DONE**, with three notes:

- Files are `private_dot_ssh/private_config` and
  `private_dot_ssh/private_authorized_keys.tmpl`. `private_` on the
  *directory* alone gives `~/.ssh` 0700 but leaves the files 0644 — the
  prefix is needed on each file too. Verified: `.ssh` → 40700, both files →
  100600.
- Equivalence was checked with `ssh -G -F <file> <host>`, byte-identical for
  `storagebox`, `github.com`, `access.grid5000.fr`, `foo.grid5000.fr` and an
  unmatched host.
- **There is no `u593939-sub1` stanza to port.** `static/config.ssh` has only
  `Host storagebox` → `u593939`; the backup sub-account exists solely as
  `hetzner_backup_user` in the Ansible vars. Adding a stanza is new work, not
  a port — do it in phase 4 if the backup role needs it.
- `static/config.ssh` is **not deleted**: `modules/home/common-home.nix:106`
  still `readFile`s it, so removing it breaks rule 1. Phase 7.
- Two pre-existing warts carried over verbatim, to be fixed in phase 4, not
  hidden now: the literal unsubstituted `User @g5k_login@` placeholder, and
  the `Host linux-builder` block (127.0.0.1:31022) which dies with
  nix-darwin.

### Task 2.4 — `tmux.nix` (94 lines) → `dot_config/tmux/tmux.conf`

`cat ~/.config/tmux/tmux.conf` from the live mac. The `tmux-session-color`
helper it calls becomes a script (task 4.1).

### Task 2.5 — `interactive.nix` (101 lines) → per-tool configs

fzf, direnv (`direnv.toml` with the silent/`DIRENV_LOG_FORMAT` stdlib),
lazygit (`lazygit/config.yml`, incl. the `useExternalDiffGitConfig` pager),
zoxide (`--cmd cd`). Shell integration hooks move into the zshrc (2.6).

Dropped here: `nix-index`/`comma` (Nix-specific) and `programs.opencode`
(dropped per §0 — also delete `dot_config/opencode/` if it arrives from the
old dotfiles repo).

**DONE.** `dot_config/opencode/` deleted. **fzf and zoxide write no config
file at all** under this setup — they are pure shell-hook, so task 2.6 is
their entire port. lazygit, `direnv.toml` and `direnvrc` were copied
verbatim.

**Two gaps this opens, neither owned by 2.5:**

1. **`~/.config/lazygit/theme.yml` has no owner post-migration.**
   `LG_CONFIG_FILE` lists it, but it is a *symlink* created at runtime by
   `packages/theme-switcher/theme-switcher.sh:158`, which §0 drops.
   `.chezmoiexternal.toml` vendors only `theme.{dark,light}.yml`. On a fresh
   host lazygit fails to start until something seeds that symlink — task 2.7
   or a `run_once_` script must do it. Confirmed live: `theme.yml ->
   theme.light.yml`.
2. **`~/.config/direnv/lib/hm-nix-direnv.sh` is not portable** — it is a
   resholved script hardcoding a `/nix/store/…/bin/nix`. direnv still works
   without it, but loses nix-direnv's flake caching until the `nix` role
   (task 3.4) installs nix-direnv and sources its `direnvrc`. Since §0 keeps
   Determinate Nix precisely for devenv/direnv projects, this one matters.

### Task 2.6 — `zsh.nix` (225 lines) → `dot_zshrc.tmpl` + fragments

The gnarliest one. Notes:
- It embeds a `date_since_last_nixpkgs` script built on `nixos-version`.
  **Dead post-migration — drop it**, don't port it.
- It has tmux session-name refresh hooks and `zle_application_mode` handling
  — keep those.
- Starship init, zoxide init, direnv hook, keychain, fzf bindings all land
  here.
- Nobara ships zsh but bash is the default shell; the `users` role must set
  the login shell (task 4.2).

Split into `dot_config/zsh/` fragments sourced by `dot_zshrc.tmpl` if the
single file exceeds ~150 lines.

### Task 2.7 — `catppuccin-theme.nix` + `theme-daemon.nix` → **drop, replace with Plasma native**

Per §0, switching must stay instantaneous and chezmoi-independent. Plasma 6
switches color schemes on a day/night schedule natively, so the custom
daemon, the dual-flavor generation and the `theme-switcher` package all go
away. Install a Catppuccin Plasma global theme and configure the native
switch (task 4.7).

Mind the three theme-asset gaps in §0.1 — the missing `CatppuccinLatteMauve`
scheme in particular, which breaks light mode.

The Catppuccin Plasma assets are **already vendored** in the old dotfiles
repo — `dot_local/share/plasma/look-and-feel/` (Mocha/Latte plus `Custom
dark`/`Custom light`), `dot_local/share/color-schemes/`, and
`dot_local/share/aurorae/themes/`. Copy them across rather than re-sourcing
from the KDE store; they are plain files chezmoi handles fine.

Keep only per-app themes that Plasma can't drive — kitty, tmux, starship,
bat — as static chezmoi files in the dark flavor. **STOP and ask** before
investing in live per-app switching; §0 marks it low priority.

### Task 2.8 — `mpv.nix` → chezmoi only

`chezmoi/dot_config/mpv/{mpv.conf,input.conf}` already exist and stay.
**Delete** `rife_high.py` and `rife25.py` (RIFE is dropped) and strip
`mpv.conf` of RIFE/vapoursynth lines. Keep the auto-subtitle and UI
settings, cache settings, and `ytdl-format`.

Package: plain `mpv` from Nobara's repos (RPM Fusion), not `mpv-rife`.

### Task 2.9 — KDE Plasma config — **already solved upstream, adopt it**

`modules/home/gnome.nix` (424 lines of dconf) and `hyprland.nix` are both
**dropped**, not ported.

Plasma rewrites its own `~/.config/*rc` files at runtime, so chezmoi must not
own them outright — it produces permanent diffs and silently lost settings.
The old dotfiles repo already solves this with
**[`chezmoi_modify_manager`](https://github.com/VorpalBlade/chezmoi_modify_manager)**:
a `modify_<file>` script paired with a `<file>.src.ini` of the desired values,
merged into whatever Plasma currently has. Adopt this pattern as-is — do not
invent a `kwriteconfig6` alternative.

Copy across from the old repo, then re-capture current values:

```
dot_config/modify_kdeglobals                           + kdeglobals.src.ini
dot_config/modify_kwinrc                               + kwinrc.src.ini
dot_config/modify_plasmashellrc                        + plasmashellrc.src.ini
dot_config/modify_plasma-org.kde.plasma.desktop-appletsrc + .src.ini
dot_config/modify_private_kglobalshortcutsrc           + .src.ini
dot_config/modify_private_krunnerrc                    + .src.ini
dot_config/private_kxkbrc      # fr/oss — already correct
dot_config/private_{dolphinrc,kwinrulesrc,plasmanotifyrc,kded5rc}
```

Note the existing ignore rules — they matter and were clearly learned the hard
way. `modify_private_kglobalshortcutsrc` ignores
`ActivityManager/switch-to-activity-.*` (per-machine UUIDs) and the
`org.chromium.Chromium` section (auto-generated). Expect to add more as
per-machine keys surface; the symptom is a `chezmoi diff` that never goes
quiet.

**Two hard requirements:**

1. `chezmoi_modify_manager` must be installed **before first apply** — add it
   to the package lists (task 3.1; Fedora source needs verifying, it may be
   `cargo install` or a COPR).
2. Per the old repo's README, before the *first* apply on a new machine:
   ```sh
   rm ~/.config/plasma-org.kde.plasma.desktop-appletsrc
   chezmoi apply
   ```
   Otherwise the merge creates duplicate containments, because panel
   containment/applet IDs are auto-generated per machine. Put this in
   `playbooks/bootstrap.yml` and in the msi cutover checklist (task 6.2).

`private_kded5rc` is Plasma 5 era — verify the Plasma 6 equivalent on Nobara
before copying it forward.

### Task 2.10 — Remaining home modules

`browser.nix` (46), `claude.nix` (129), `gui.nix` (95), `syncthing.nix` (17).

`browser.nix` is **brave-origin**, confirmed current (§0). The old repo's
`helium-chromium` is superseded — ignore it. Two things to resolve:
- **Packaging**: verify whether a `brave-origin` Flatpak exists. Flathub's
  `com.brave.Browser` is upstream Brave, **not** the same build — do not
  silently substitute it. Order of preference: Flatpak of brave-origin →
  Brave's RPM repo → Nix. If only upstream Brave is obtainable, **stop and
  ask**; that is a different browser, not a packaging detail.
  **Resolved: the Brave Flatpak, `com.brave.Browser`.** Task 0.3 confirmed
  no `brave-origin` Flatpak exists and that both Flathub and Brave's RPM
  repo ship upstream Brave; the user chose it regardless, so the stop-and-ask
  above is discharged and the build change is accepted, not an oversight.
  nixpkgs `brave-origin` (1.95.102, verified by eval) stays the documented
  fallback. Note the extension policy path is the **Flatpak-scoped** one,
  `/var/lib/flatpak/extension/` overrides via
  `flatpak override --filesystem=`, not `/etc/brave/policies/managed/`.
- **Extensions**: HM declared them via `programs.chromium.extensions`
  (bitwarden `nngceckbapebfimnlniiiahkandclblb`, sponsorblock
  `mnjggcdmjocbbbhaepdhchncahnbgone`, Quedelix `phaodiidhofhdmfkjiacigibgikhfafn`).
  The Ansible equivalent is a managed-policy JSON with `ExtensionInstallForcelist`
  dropped into the browser's policies directory (`/etc/brave/policies/managed/`
  or the Flatpak-scoped path). Preserve the three IDs exactly.

`claude.nix` is worth reading closely: it deliberately does *not* own
`~/.claude/settings.json` or `~/.claude.json` (Claude Code writes to them at
runtime) and instead runs idempotent merge installers for the rtk hook and
codegraph MCP entry. That pattern maps cleanly onto a chezmoi
`run_onchange_` script — keep the merge semantics, don't switch to owning
the files. The headroom wrapper becomes a script in `dot_local/bin/`.

`syncthing.nix` becomes a systemd user unit written by Ansible (per the
split rule) on Linux, and a `brew services` / launchd agent on macOS.
Task 0.2 found msi's Syncthing running with **no peers and no configured
folders**. It is still wanted (§0) — port the unit, and expect to configure
peers and folders by hand afterwards. Do not port the old repo's
linuxserver.io container.

### Task 2.11 — `neovim.nix` → packages only

No dotfile work: the lua config already lives in `chezmoi/dot_config/nvim/`,
and the module already avoids `programs.neovim` precisely to stay out of
chezmoi's way. Only the package set moves (task 3.x): plain `neovim`, the
LSPs/formatters/treesitter toolchain, and `nvim-pack-lock.json` continues to
drive plugins. `wrapNeovimUnstable`/`wrapRc = false` has no successor —
plain `nvim` reads `~/.config/nvim` directly.

---

### PHASE 2 — what it leaves behind

Phase 2 is finished, but it did not resolve everything it touched. These are
owned by later phases; none of them is optional.

**Hard blockers — a fresh host is broken until these are done:**

1. **`chezmoi/dot_config/nvim/init.lua` has its whole `vim.pack.add` block
   commented out** (lines 1–49), because Home Manager supplied the 43 plugins
   through `wrapNeovimUnstable`. Line 53 `vim.cmd.packadd 'lze'` is live, so
   with plain `neovim` nvim fails on startup. The commented list matches the
   43 entries in `nvim-pack-lock.json`, so uncommenting it is the fix. Owner:
   phase 6, before the first nvim launch.
2. **`~/.config/lazygit/theme.yml` has no owner.** It was a symlink created by
   `theme-switcher.sh:158` to `theme.{dark,light}.yml`. Both targets are
   vendored as externals, but nothing creates the symlink, and `LG_CONFIG_FILE`
   names it — lazygit will not start on a fresh host. Owner: phase 4 (task
   4.1, with theme-switcher).
3. **`chezmoi_modify_manager` must be on the `PATH` of whatever runs the first
   `chezmoi apply`**, or all six `modify_*` scripts fail the apply outright.
   Not in nixpkgs, not in Fedora. Owner: phase 4. See
   `docs/migration/kde-cutover.md`.

**Degradations — working, but worse than before:**

4. `~/.config/direnv/lib/hm-nix-direnv.sh` was resholved with a hardcoded
   store path, so nix-direnv's flake caching is lost until the `nix` role
   reinstalls it. Owner: phase 3 (task 3.4).
5. `~/.config/mpv/{input.conf,rife*.py,rife*.vpy}` still exist on the live mac
   as unmanaged leftovers. chezmoi will not remove what it never owned; delete
   them by hand at cutover.

**Unverifiable from here — decide at first boot, do not guess now:**

6. **Nothing in the KDE work has been tested against a running Plasma.** The
   macOS host has none, and `msi` is still NixOS/Hyprland until its reinstall.
   All 17 files are byte-identical copies of the old dotfiles repo, which is
   the best available source, but that is provenance, not verification.
7. `private_kded5rc` is a Plasma 5 filename and Nobara 43 ships Plasma 6
   (`kded6rc`). Kept under the original name; rename at first boot if Plasma
   ignores it.
8. The Brave Flatpak policy path is read from the Flathub manifest
   (`--filesystem=host-etc` plus a launcher symlink, so the same
   `/etc/brave/policies/managed` as the RPM), not confirmed on msi. Confirm
   with `flatpak info --show-permissions com.brave.Browser` after install.

## PHASE 3 — Packages

### Task 3.1 — `roles/pkgs`

Platform-dispatching role consuming plain lists:

```yaml
# group_vars/nobara.yml
pkgs_dnf:     [ripgrep, fd-find, jq, ...]      # names VERIFIED in task 0.3
pkgs_copr:    { "atim/starship": [starship], ... }
pkgs_flatpak: [com.brave.Browser, ...]
pkgs_nix:     [devenv, ...]                     # only where no RPM exists
# group_vars/darwin.yml
brew_formulae: [ripgrep, fd, ...]
brew_casks:    [hiddenbar, karabiner-elements, tg-pro, bettermouse, alt-tab,
                tidal, parsec, signal, vlc, calibre, steam, betterdisplay]
```

macOS is nearly a 1:1 port of the `homebrew` block already sitting in
`modules/darwin/common-darwin.nix` (currently `enable = false`) — it just
gets turned on under Ansible instead.

`chezmoi` and **`chezmoi_modify_manager`** must both land here — the latter
is a hard prerequisite for task 2.9 and is unlikely to be in Fedora's main
repos (expect COPR, the upstream release binary, or `cargo install`).
Verify and record the source.

Remember rule: `state: present`, never `state: latest` on Nobara.

**Verify:** second run reports zero changes on both hosts.

### Task 3.2 — Flatpak

`community.general.flatpak` + `flatpak_remote` for Flathub. Nobara ships
Flathub already — check before adding. Port the GTK-config override
(`flatpak override --user --filesystem=xdg-config/gtk-4.0:ro`) from
`modules/nixos/desktop.nix`.

### Task 3.3 — Fonts

`modules/nixos/desktop.nix` sets fontconfig defaults: monospace = *Comic Code
Ligatures* (licensed, in `persistent/.../fonts/comicode/`, transcrypt-encrypted),
sans = Inter, serif = IBM Plex Serif. Port: install `inter-fonts`,
`ibm-plex-fonts-all`, Noto CJK from dnf; ship Comic Code from the repo into
`~/.local/share/fonts` (chezmoi, since it's per-user); write the fontconfig
defaults as a chezmoi `dot_config/fontconfig/fonts.conf`.

`joypixels` requires license acceptance — drop unless the user asks.

### Task 3.4 — `roles/nix` — Determinate Nix

Both hosts. Install via the Determinate installer
(`curl -fsSL https://install.determinate.systems/nix | sh -s -- install --determinate`),
guarded by a `creates:`/`command -v nix` check so it's idempotent.

Carry the substituter list from `config.nix` (`me.extra-substituters` +
`trusted-public-keys`) into `/etc/nix/nix.conf`. This keeps `devenv`, `.envrc`
and direnv projects working, which is the whole reason Nix is retained.

**On macOS this is a replacement, not a fresh install** — nix-darwin is
currently managing the Nix installation there. See task 6.1; do not run the
installer on the mac before nix-darwin is removed.

---

### PHASE 3 — what it leaves behind

Hard blockers (each must be closed before the phase named):

1. ~~Comic Code Ligatures~~ — **RESOLVED 2026-09-24, option (a).** The font
   stays parked under transcrypt at
   `persistent/home/volodia/.local/share/fonts/comicode/`; Ansible copies it
   to `~/.local/share/fonts` at apply time
   (`roles/desktop_linux/tasks/fonts.yml`). It is never placed in the chezmoi
   source tree. The copy reads from the **control node**, so that checkout
   must be transcrypt-unlocked or the target gets ciphertext — an assert on
   the OpenType magic (`OTTO`) fails the play loudly rather than installing
   five unusable files. macOS already has them in `~/Library/Fonts`,
   hand-installed and untouched by Nix, so it needs nothing.
2. **`chezmoi_modify_manager` PATH wiring is not done.** `roles/pkgs` installs
   the binary to `~/.local/bin` and exports the location as
   `chezmoi_modify_manager_install_dir`, but the `modify_` scripts' shebang
   resolves from `PATH` at `chezmoi apply` time, and `roles/chezmoi` is still
   a scaffold. Consume that variable there. **Owner: task 4.7 / `roles/chezmoi`.**
3. **`~/.config/direnv/lib/hm-nix-direnv.sh` is still the resholved store
   path.** `roles/nix` now installs `nix-direnv` into the user profile, but
   nothing repoints direnv at `~/.nix-profile/share/nix-direnv/direnvrc`.
   That file is in the chezmoi tree, outside `roles/nix`. **Owner: phase 6.**

Degradations accepted for now:

4. **`/etc/nix/nix.custom.conf` loses ~17 settings. Accepted — do not port
   (user decision, 2026-09-24).** `roles/nix` templates only
   `extra-substituters`, `trusted-public-keys` and `trusted-users`. The live
   nix-darwin file also sets `sandbox = false`, `fallback`,
   `keep-derivations`, `keep-env-derivations`, `accept-flake-config`,
   `warn-dirty`, `nix-path`, `connect-timeout`, `http-connections`, the
   narinfo TTLs, and a `post-build-hook` pointing at a `/nix/store` cachix
   push hook. Consequence knowingly accepted: after cutover, local builds are
   no longer pushed to `volodiapg.cachix.org`, though it is still read from.
   Revisit if a build starts failing for want of `sandbox = false`.
5. ~~`FREETYPE_PROPERTIES`~~ — **ABANDONED (user decision, 2026-09-24).**
   The `cff:no-stem-darkening=0 autofitter:no-stem-darkening=0` tweak in
   `modules/nixos/desktop.nix` was for noctalia and is reportedly already
   Nobara's default. Do not port it. If font rendering looks wrong after the
   Nobara install, this is the first thing to re-check.
6. **`corefonts` is dropped.** No Fedora or RPM Fusion package exists; it
   would need `cabextract` plus the Microsoft installer. Web pages specifying
   Arial/Times New Roman will substitute.

Unverified / needs a real machine:

7. **Nothing in phase 3 has run anywhere.** `msi` is still NixOS/Hyprland, so
   no `dnf`, `flatpak`, `copr` or `fc-cache` call has ever executed. Package
   names come from a `fedora:43` container, not Nobara. The stated acceptance
   bar — "second run reports zero changes on both hosts" — is unmet and
   untestable until the Nobara install.
8. **`nix profile list` parsing is a guess.** `roles/pkgs`' nix step decides
   idempotency by substring-matching that command's output; its exact format
   was never checked against a live Determinate Nix profile. This is the most
   likely task to report spurious changes on a second run.
9. ~~`vmnet-helper` + the `nirs/vmnet-helper` tap~~ — **DROPPED (user
   decision, 2026-09-24).** Present in `modules/darwin/common-darwin.nix`
   (lines 43, 60) and absent from `docs/migration/package-map.md` entirely —
   a genuine gap in task 0.3, not a deliberate omission. The original reason
   for installing it is no longer remembered, so it is not carried over. If
   `podman machine` networking misbehaves on macOS after cutover, this is the
   likely cause.

Corrections to this plan found while executing phase 3 (the plan text above
has NOT been rewritten; these are the facts):

- Task 3.3's Inter RPM is `rsms-inter-fonts`, not `inter-fonts` (no such
  package).
- Task 3.4's installer command omits `--no-confirm` and would hang forever
  under Ansible waiting on a TTY prompt.
- Task 3.1's `brew_casks` example is stale: it omits `qbittorrent` and lists
  `hiddenbar` and `alt-tab`, both retired by §0.2. The real set is 13.
- `package-map.md` files `com.brave.Browser` under §5 `nix` although its own
  source column says `flatpak`; its §10a header says 12 casks while its table
  and Counts say 13. The source column and Counts were followed.
- Task 3.2 was accurate — `modules/nixos/desktop.nix` has exactly the one
  `flatpak override --user --filesystem=xdg-config/gtk-4.0:ro` it describes.

---

## PHASE 4 — System roles

### Task 4.1 — In-repo scripts → `dot_local/bin/`

| Package | Disposition |
| --- | --- |
| `tmux-session-color` | script → `chezmoi/dot_local/bin/` |
| `openrouter-credits` | script → `chezmoi/dot_local/bin/` |
| `claude-code-headroom`, `headroom` | scripts → `dot_local/bin/` |
| `theme-switcher` | **dropped** (Plasma native, task 2.7) |
| `xinstall`, `xmount` | installer helpers → `scripts/`, run by hand |
| `high-tide` | Flatpak if available, else drop |
| `mpv-rife` + `_vsmlrt`/`_vstrt`/`_miscfilters` | **dropped** |

Each script currently gets its runtime deps from Nix. Add an explicit
dependency check at the top, and add those deps to the package lists.

### Task 4.2 — `roles/base` + `roles/users`

From `modules/nixos/base.nix` (180 lines): locale `fr_FR.UTF-8` (all the
`LC_*`), timezone `Europe/Paris`, console keymap `fr`, sysctl
(`vm.max_map_count=6000000`, `fs.file-max`, `kernel.threads-max`), sshd
(`PermitRootLogin prohibit-password`, SFTP), fail2ban (maxretry 5, the
ignoreIP list), earlyoom (thresholds 5/5, and the `--prefer`/`--avoid`
process lists — update them: `Hyprland`/`noctalia` are gone, `plasmashell`
and `kwin_wayland` take their place), journald caps (200M/50M), user +
groups + authorized_keys, zsh as login shell.

Dropped from that module: `documentation.enable=false`, `nix.optimise`,
`nix-ld`, `envfs` (all Nix-isms), `mutableUsers` (no analogue).

### Task 4.3 — `roles/audio` (ex `hifi.nix`, 190 lines)

Pipewire + realtime limits. Nobara ships Pipewire configured; port only the
deltas (realtime group/limits, any custom config). Verify what's already
there before writing anything.

### Task 4.4 — `roles/desktop_linux`

From `modules/nixos/desktop.nix`: kanata (unit + `static/kanata.lisp`, with
`concurrent-tap-hold yes` and `Restart=always`/`RestartSec=1s`), XKB
`fr`/`oss` with `eurosign:e,ctrl:swapcaps`, the i2c udev rule
(`KERNEL=="i2c-[0-9]*", GROUP="i2c", MODE="0660"`) + `i2c-dev` module +
`i2c` group for ddcutil, `FREETYPE_PROPERTIES` env.

Firewall: NixOS's `networking.firewall` → `firewalld`. Ports to carry over:
TCP 22, 3389; TCP+UDP 1714–1764 (KDE Connect — now actually apt, on KDE);
TCP 6881–6999 (torrents); UDP 3389, 5353 (mDNS).

kanata under KDE/Wayland needs uinput access. The old dotfiles repo's
`run_once_kanata.sh.tmpl` already works out the full recipe — create the
`uinput` group, add the user to `input` and `uinput`, write
`/etc/udev/rules.d/99-input.rules` with
`KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"`,
reload udev, then enable the **user** unit
(`dot_config/systemd/user/kanata.service`). Port that logic into this role
(it needs root, so it belongs in Ansible, not chezmoi). Note the script has a
typo — `--sysname-match=uniput` — fix it rather than copying it.

The XKB layout is set twice on Plasma: `private_kxkbrc` (task 2.9) covers the
desktop session; this role covers the console/TTY keymap.

### Task 4.5 — `roles/nvidia` (msi)

**Check what Nobara already did first.** Nobara's NVIDIA edition ships the
proprietary driver. Likely all that remains is the msi-specific bits from
`configurations/nixos/msi/configuration.nix`: blacklist `nouveau` and
`iTCO_wdt`, and the `nvidia-frequency` oneshot unit
(`nvidia-smi -lmc 1620,2100`, `-lgc 210,3105`) that works around slow clock
ramping.

The old dotfiles repo has the same unit as `nvidia-clock-lock.service`, but
with `-lmc 1620,21002` — note the trailing `2`. The two disagree and one is
a typo. **Use the Nix module's `1620,2100`** (it is the value currently
running on msi); do not copy the old repo's number.

CUDA (`msi` was built with a cuda nixpkgs variant) — was only for
`immich-ml`, which is `false` on msi. Confirm nothing else needs it, then
drop.

### Task 4.6 — `roles/gaming`, `roles/virtualization`, `roles/vpn`, `roles/networking`

- gaming: Nobara is gaming-oriented and ships Steam/gamemode/mangohud —
  verify, then port only gaps from `modules/nixos/gaming.nix` (33 lines).
- virtualization: podman + distrobox (`libvirt.enable = false` on msi, so
  skip libvirt).
- vpn: tailscale (`modules/nixos/vpn.nix`, 63 lines) — repo + `tailscale up`
  with an authkey from vault.
- networking: NetworkManager is Nobara's default; port only the deltas
  (`NetworkManager-wait-online` disabled, etc.).

Dropped entirely: `kernel.nix` (CachyOS-kernel-specific — Nobara ships its
own patched kernel), `impermanence.nix`, `hyperhdr.nix` (dropped per §0),
`backlight-off.nix`,
`betterSleep.nix` (verify Plasma/Nobara defaults suffice),
`elegant-boot.nix` (was `false` on msi), `ananicy.nix` (Nobara ships
ananicy-cpp — verify, then port the 410-line ruleset only if it isn't
already covered), `home-lab.nix` (`false` on msi), `immich-ml.nix`
(`false`), and `caddy.nix` (dropped per §0 — also drop
`static/services-page/`).

Also portable from the old dotfiles repo: `run_once_docker.sh.tmpl` (docker
group) — needs root, so it becomes an Ansible role. `run_once_governor.tmpl`
is **dropped** per §0.

### Task 4.7 — `roles/kde`

Plasma-level settings needing root, plus the Catppuccin global theme and the
native day/night color scheme switch (the replacement for the theme daemon,
task 2.7). SDDM config if needed.

---

## PHASE 5 — Secrets

### Task 5.1 — Audit and prune

The 13 agenix secrets, with a first-pass read of who uses them:

| Secret | Used by | Likely disposition |
| --- | --- | --- |
| `hashed-password` | `base.nix` users | **msi**: not needed (Nobara sets the password at install) |
| `tailscale-authkey` | vpn | keep → vault |
| `access-token`, `envvars`, `pythong5k`, `mail.inria.password` | user scope | keep → vault, deployed to `$HOME` |
| `cachix-token` | cachix push hook | **drop** (no more Nix builds to push) |
| `hetzner-token`, `hetzner-data-encryption-key` | backup (home-server) | **home-server only — leave in agenix** |
| `samba-user-password`, `tailscale-k8s-operator`, `fizzy-env`, `rss-password`, `ssh-remote-builder{,-pub}` | home-server services | **home-server only — leave in agenix** |

**STOP and confirm the disposition column with the user before deleting
anything.** Deleting an `.age` file that `home-server` still references
breaks rule 1.

Note the split: `secrets/` keeps serving `home-server` via agenix, while the
migrated hosts get ansible-vault. Both coexist until phase 7.

### Task 5.2 — ansible-vault

Vault password at `~/.config/ansible/vault-pass` (mode 0600, **never
committed**; store it in Bitwarden). `ansible/inventory/group_vars/all/vault.yml`
encrypted with `ansible-vault`. Decrypt each surviving secret with
`ragenix`/`agenix` once, re-encrypt into vault.

`roles/secrets` writes user-scope secrets to their existing paths so nothing
downstream changes: `~/.envvars.sh`, `~/.python-grid5000.yaml`,
`~/.mail.inria.password.txt` (all mode 0400).

transcrypt stays as-is for in-tree binaries (SSH keys, Comic Code fonts) —
it's orthogonal to Nix and needs no migration.

**Verify:** `git grep -n 'BEGIN.*PRIVATE\|password' ansible/` finds nothing
in plaintext; a fresh clone + vault password reproduces every secret file.

---

## PHASE 6 — Cutover

### Task 6.1 — macOS first (lowest risk, proves the stack)

No bootloader, no reinstall, and nix-darwin uninstalls cleanly. Order:

1. Ansible + chezmoi run **alongside** the existing nix-darwin setup;
   resolve every conflict (chezmoi and HM both wanting a file) until
   `chezmoi diff` is empty and `darwin-rebuild` is a no-op.
2. **STOP — confirm with the user before this step.** Uninstall nix-darwin
   and Home Manager. Preserve `/opt/homebrew`: it is currently owned by
   `nix-homebrew`, and Homebrew must survive and be adopted by
   `roles/homebrew`.
3. Reinstall Nix via the Determinate installer (task 3.4).
4. Port `modules/darwin/common-darwin.nix` (210 lines): TouchID sudo
   (`security.pam.services.sudo_local` → `/etc/pam.d/sudo_local`),
   `limit-maxfiles` launchd daemon (524288) + the `ulimit -n` shell init,
   `NSWindowResizeTime` via `osx_defaults`, Rosetta install check.
   Most of the file is commented-out yabai/skhd — do not port it.
5. Port the old dotfiles repo's `run_once_defaults.tmpl` to `osx_defaults`
   tasks — it is **more complete than the Nix module** (Finder hidden files
   and sort order, instant Dock autohide, dated screenshots to `~/Downloads`,
   `LSQuarantine` off, trackpad `FirstClickThreshold`, CMD-drag windows,
   linear mouse). Remember the `killall Finder/Dock/SystemUIServer` those
   need to take effect.
6. Build `group_vars/darwin.yml` per §0.2 — the 8-cask intersection plus the
   3 explicit keeps (`steam`, `calibre`, `qbittorrent`), plus the CLI tooling
   from task 3.1. Carry nothing else that appears in only one source.

**Rollback:** the nix-darwin generation is still in `/nix/var/nix/profiles`
until step 2. Take a Time Machine snapshot before step 2 regardless.

### Task 6.2 — msi: Nobara install

**Destructive. STOP and confirm with the user before touching disks.**

1. Verify task 0.2's backup checklist is fully ticked. **Nothing on msi is
   backed up today** — restic is enabled only on `home-server`, and msi's
   Syncthing has no peers and no configured folders. There is no safety net
   but the checklist. Treat it as the gate it is.
2. **Install to `sda` only.** `/Games` lives on a physically separate disk
   (`sdb5`, 120 G of Steam content plus ~2 G of Proton saves in
   `compatdata`); the OS is entirely on `sda`. Pointing the Nobara installer
   at `sda` preserves all of it with zero copying. Confirm the disk
   identifiers against `docs/migration/msi-hardware.txt` on the day — device
   names are not stable.
3. **Read `/etc/NetworkManager/system-connections/` as root before the wipe.**
   It holds the Wi-Fi PSKs and was unreadable during task 0.2 (msi has no
   passwordless sudo). Losing it means re-entering every network by hand.
4. Install Nobara KDE from the official ISO (the `installer` ISO and `disko`
   config are not ported; partitioning is manual/guided).
5. Keep the NixOS install bootable on a separate partition if space allows —
   cheapest possible rollback.
6. Bootstrap: `playbooks/bootstrap.yml` (user, SSH keys, vault password,
   tailscale, and the `rm ~/.config/plasma-org.kde.plasma.desktop-appletsrc`
   from task 2.9) then `playbooks/site.yml`.
7. Work through a functional checklist before declaring done: boots to
   Plasma, NVIDIA driver active + `nvidia-frequency` applied, audio, kanata
   remapping, fr/oss keyboard with swapped caps, tailscale up, syncthing
   syncing, mpv plays HDR, Steam runs a game, `nix develop` works in a
   devenv project, `chezmoi diff` clean, second `site.yml` run reports zero
   changes.

**Rollback:** reinstall NixOS from the flake — `configurations/nixos/msi/`
is still in the repo at this point. Do not delete it until 6.2 is signed off.

---

## PHASE 7 — Decommission

Only after both hosts are signed off. **Rule 1 still applies throughout:
`home-server` stays on NixOS and must keep evaluating.**

Delete: `configurations/nixos/msi/`, `configurations/darwin/`,
`modules/darwin/`, `modules/home/`, and the `modules/nixos/*` files
home-server does not import. Prune `flake.nix` (`darwinHosts`, msi from
`nixosHosts`, and the inputs that become unused: `nix-darwin`, `nix-homebrew`,
`home-manager` — *check*, home-server has a `home.nix`; `catppuccin`,
`nix-index-database`, `nix-cachyos-kernel`, `high-tide`, `noctalia-greeter`).
Drop `packages/mpv-rife/`. Prune the `overlays/` entries that lose consumers.

Keep: `flake.nix` (slimmer), `modules/nixos/` for home-server, `secrets/`
(agenix, home-server's), `kubernetes/`, `.gitattributes`/transcrypt.

Rewrite `justfile` around Ansible (`just apply`, `just check`,
`just deploy msi`, `just dots`) while keeping the home-server recipes
(`just deploy home-server`, `just eval`). Rewrite `README.md`. Rename the
repo (`nixos-configs` → e.g. `system-configs`) — note `config.nix`'s
`chezmoiDirectory` hardcodes the path `~/Documents/nixos-configs` and
`.chezmoi.toml.tmpl` will too.

---

## What this migration gives up

State these to the user if they come up; do not pretend otherwise.

1. **Atomic rollback.** No `nixos-rebuild --rollback`. Mitigate with btrfs
   snapshots (`snapper`) configured in `roles/base`.
2. **Idempotence is aspirational.** Ansible converges *toward* a state; it
   never removes what you stopped declaring. Dropping a package from a list
   leaves it installed. Budget for periodic drift audits.
3. **Reproducible pins.** `flake.lock` → whatever Nobara ships today.
4. **Cross-host evaluation.** `just eval-all` catching breakage on a host you
   aren't sitting at is gone; `--check --diff` needs a reachable host.
5. **Weaker CI.** Building a host's closure in CI → lint + syntax check.

---

## Progress

| # | Task | Status | Notes |
| --- | --- | --- | --- |
| 0.1 | Dump Nix package sets | ☐ | |
| 0.2 | Dump msi live state + backup checklist | ☐ | |
| 0.3 | Package-name mapping table | ☑ | `docs/migration/package-map.md`, 277 rows, verified against `fedora:43` |
| 0.4 | Reconcile the two chezmoi trees | ☐ | blocks phase 2; STOP on nvim |
| 1.1 | Ansible skeleton | ☑ | `ansible/`, 17 roles, ansible-lint clean at `production` |
| 1.2 | `config.nix` → `group_vars/all.yml` | ☑ | at `inventory/group_vars/all/main.yml`, generated by `nix eval` |
| 1.3 | Inventory | ☑ | msi reached over SSH by bare name |
| 1.4 | Retire `m1` | ☑ | rule 1 re-verified; `avd-fw` overlay went with it |
| 1.5 | CI | ◐ | `ansible.yaml` added; msi job removal deferred to phase 7 |
| 2.1 | chezmoi templating scaffold | ☑ | `.chezmoi.toml.tmpl` renders on both hosts; 8 externals, all URLs 200 |
| 2.2 | git config | ☑ | no credential helper and no delta — my spec invented both |
| 2.3 | ssh config + authorized_keys | ☑ | |
| 2.4 | tmux | ☑ | resurrect + continuum externals were missing; added |
| 2.5 | interactive tools | ☑ | two gaps carried forward, see §2.5 |
| 2.6 | zshrc | ☑ | split into `.zshenv` + 8 `~/.config/zsh` fragments |
| 2.7 | theme → Plasma native | ☑ | 4 live look-and-feels only; latte colour scheme now an external |
| 2.8 | mpv (strip RIFE) | ☑ | spec wrong twice — see commit cf72736 |
| 2.9 | KDE Plasma config | ☑ | all 17 files byte-identical to old repo; **untested — no host runs Plasma yet**, see `docs/migration/kde-cutover.md` |
| 2.10 | browser/claude/gui/syncthing | ☑ | Flatpak policy path corrected; specs in `docs/migration/` |
| 2.11 | neovim packages | ☑ | **blocker found**: `init.lua` plugin list is commented out |
| 3.1 | `roles/pkgs` | ☑ | dnf 71 / rpmfusion 2 / copr 3 / nix 21; brew 13 casks + 52 formulae |
| 3.2 | flatpak | ☑ | 6 app IDs, GTK override ported |
| 3.3 | fonts | ☑ | fontconfig, 4 font RPMs, Comic Code via Ansible (option a) |
| 3.4 | Determinate Nix | ☑ | extra nix.conf settings deliberately not ported |
| 4.1 | scripts → `dot_local/bin` | ☐ | |
| 4.2 | base + users | ☐ | |
| 4.3 | audio | ☐ | |
| 4.4 | desktop_linux | ☐ | |
| 4.5 | nvidia | ☐ | |
| 4.6 | gaming/virt/vpn/net | ☐ | |
| 4.7 | kde | ☐ | |
| 5.1 | secret audit | ☐ | STOP before deleting |
| 5.2 | ansible-vault | ☐ | |
| 6.1 | macOS cutover | ☐ | STOP before uninstalling nix-darwin |
| 6.2 | msi Nobara install | ☐ | STOP before touching disks |
| 7 | Decommission | ☐ | |

---

## Open questions for the user

None outstanding. The four questions raised by task 0.4 and my task 0.3
blocker are all resolved into §0:

- Hetzner storagebox — both users live, `u593939-sub1` is the backup user.
- Syncthing — native service, kept.
- Zed — install it.
- Fedora/Nobara verification target for 0.3 — a `fedora:43` docker container
  on msi.

Raise new ones here as phases progress.
