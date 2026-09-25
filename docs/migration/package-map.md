# Package-name mapping table (Task 0.3)

**Verification target: `fedora:43`** (docker image, pulled on `msi`, run as
`docker run --rm` with no volume mounts — msi's own state was never touched).
**Date verified: 2026-09-23.**

Nobara's exact base release is unconfirmed until the install ISO is picked, so
every `fedora`/`rpmfusion` row is a Fedora 43 fact, not a Nobara fact. Nobara
tracks Fedora closely, so these names should hold, but anything marked
`on-box-required` genuinely cannot be resolved without the real machine.

## How each cell in `verified?` was produced

| marker | meaning |
| --- | --- |
| `dnf repoquery @fedora:43` | `docker run --rm -i fedora:43` → `dnf repoquery --qf '%{repoid}' <name>` returned `fedora`/`updates`. RPM Fusion free+nonfree release RPMs were installed in the container first, so `fedora` vs `rpmfusion-*` is distinguishable. |
| `dnf repoquery @fedora:43 +rpmfusion` | same, resolved from `rpmfusion-nonfree` / `rpmfusion-free`. |
| `dnf repoquery @fedora:43 +copr:<repo>` | same, after `dnf -y copr enable <repo>` in the container. |
| `flathub API 200` | `GET https://flathub.org/api/v2/appstream/<app-id>` returned 200 and the expected app name. |
| `nix eval → <version>` | `nix eval --raw '.#nixosConfigurations.msi.pkgs.<attr>.name'` on the control node. This is the exact attribute that is installed today, so the Determinate-Nix path is a guaranteed like-for-like replacement. |
| `brew info` | `brew info --formula/--cask <name>` on the macOS control node (`/opt/homebrew`). |
| `on-box-required` | not in Fedora 43 + RPM Fusion; plausibly in a Nobara-only repo. **Do not guess — check on the installed box.** |
| `upstream release` | verified against the project's GitHub releases API (asset names quoted). |
| `n/a — dropped` | §0 decision or NixOS/Nix artefact; nothing to install. |

Sources in the `source` column: `fedora`, `rpmfusion`, `copr:<repo>`,
`flatpak`, `nix`, `homebrew`, `upstream`, `drop`, `already-in-base`.

> **One source value beyond the agreed set:** `upstream`. It is used for
> exactly one package — `chezmoi_modify_manager` — which exists in no RPM
> repo, no COPR, and no nixpkgs attribute, but is a hard prerequisite for
> task 2.9. See the `upstream` section.

---

## 1. `fedora` — Fedora main repo (`dnf`, `state: present`)

| nixpkgs attr | host(s) | source | exact name / app id | verified? | notes |
| --- | --- | --- | --- | --- | --- |
| `ShellCheck` | msi + mac | fedora | `ShellCheck` | `dnf repoquery @fedora:43` | capital S, as in nixpkgs |
| `alsa-utils` | msi | fedora | `alsa-utils` | `dnf repoquery @fedora:43` | |
| `bash-language-server` | msi + mac | fedora | `nodejs-bash-language-server` | `dnf repoquery @fedora:43` | **name differs** |
| `bc` | mac | fedora | `bc` | `dnf repoquery @fedora:43` | also in Fedora base install |
| `brightnessctl` | msi | fedora | `brightnessctl` | `dnf repoquery @fedora:43` | |
| `cargo` | msi + mac | fedora | `cargo` (or `rust`) | `dnf repoquery @fedora:43` | `rust` also present |
| `chezmoi` | msi + mac | fedora | `chezmoi` | `dnf repoquery @fedora:43` | in main repo — no COPR needed |
| `cpupower` | msi | fedora | `kernel-tools` | `dnf repoquery @fedora:43` | **name differs**; `cpupower` ships in `kernel-tools` |
| `ddcutil` | msi | fedora | `ddcutil` | `dnf repoquery @fedora:43` | pair with `i2c-tools` (task 4.4) |
| `difftastic` | msi + mac | fedora | `difftastic` | `dnf repoquery @fedora:43` | listed in PLAN as "known to differ" — it does **not**; main repo has it |
| `direnv` | msi + mac | fedora | `direnv` | `dnf repoquery @fedora:43` | |
| `distrobox` | msi | fedora | `distrobox` | `dnf repoquery @fedora:43` | |
| `docker` | msi | fedora | `moby-engine` | `dnf repoquery @fedora:43` | **name differs**. §0 keeps docker on msi today; long-term runtime is podman (task 4.6) |
| `docker-compose` | msi | fedora | `docker-compose` | `dnf repoquery @fedora:43` | |
| `easyeffects` | msi | fedora | `easyeffects` | `dnf repoquery @fedora:43` | commented out in `gui.nix`, still in the system list |
| `fail2ban` | msi | fedora | `fail2ban` | `dnf repoquery @fedora:43` | task 4.2 |
| `filezilla` | msi | fedora | `filezilla` | `dnf repoquery @fedora:43` | |
| `fzf` | msi + mac | fedora | `fzf` | `dnf repoquery @fedora:43` | |
| `gamemode` | msi | fedora | `gamemode` | `dnf repoquery @fedora:43` | Nobara likely ships it — check before adding (task 4.6) |
| `gcc-wrapper` | msi + mac | fedora | `gcc` | `dnf repoquery @fedora:43` | macOS: Xcode CLT, no brew formula needed |
| `gdu` | msi + mac | fedora | `gdu` | `dnf repoquery @fedora:43` | listed in PLAN as "known to differ" — it does not |
| `gimp` | msi | fedora | `gimp` | `dnf repoquery @fedora:43` | |
| `git` | msi + mac | fedora | `git` | `dnf repoquery @fedora:43` | HM `programs.git.enable` |
| `git-crypt` | msi + mac | fedora | `git-crypt` | `dnf repoquery @fedora:43` | |
| `gnumake` | msi + mac | fedora | `make` | `dnf repoquery @fedora:43` | **name differs** |
| `go` | mac (+msi dev) | fedora | `golang` | `dnf repoquery @fedora:43` | **name differs** |
| `gopls` | mac | fedora | `gopls` | `dnf repoquery @fedora:43` | standalone package, not part of `golang-x-tools` |
| `gparted` | msi | fedora | `gparted` | `dnf repoquery @fedora:43` | |
| `grc` | msi + mac | fedora | `grc` | `dnf repoquery @fedora:43` | listed in PLAN as "known to differ" — it does not |
| `htop` | msi + mac | fedora | `htop` | `dnf repoquery @fedora:43` | |
| `inkscape` | msi | fedora | `inkscape` | `dnf repoquery @fedora:43` | |
| `jq` | msi | fedora | `jq` | `dnf repoquery @fedora:43` | |
| `just` | msi + mac | fedora | `just` | `dnf repoquery @fedora:43` | listed in PLAN as "known to differ" — it does not |
| `kdeconnect-kde` | msi | fedora | `kde-connect` | `dnf repoquery @fedora:43` | **name differs**; firewall ports 1714–1764 (task 4.4) |
| `keychain` | msi + mac | fedora | `keychain` | `dnf repoquery @fedora:43` | HM `programs.keychain.enable` |
| `kitty` | msi + mac | fedora | `kitty` | `dnf repoquery @fedora:43` | macOS: cask |
| `libgtop` | msi + mac | fedora | `libgtop2` | `dnf repoquery @fedora:43` | **name differs** |
| `libnotify` | msi | fedora | `libnotify` | `dnf repoquery @fedora:43` | provides `notify-send` |
| `lm-sensors` | msi | fedora | `lm_sensors` | `dnf repoquery @fedora:43` | **underscore, not hyphen** |
| `lsof` | msi + mac | fedora | `lsof` | `dnf repoquery @fedora:43` | |
| `mkpasswd` | msi | fedora | `mkpasswd` | `dnf repoquery @fedora:43` | may be unneeded (task 5.1 drops `hashed-password`) |
| `moreutils` | msi + mac | fedora | `moreutils` | `dnf repoquery @fedora:43` | |
| `mosh` | msi + mac | fedora | `mosh` | `dnf repoquery @fedora:43` | listed in PLAN as "known to differ" — it does not. The Nix overlay patches mosh; the patch is not carried over |
| `neovim` | msi + mac | fedora | `neovim` | `dnf repoquery @fedora:43` | plain `nvim` reads `~/.config/nvim` (task 2.11) |
| `nmap` | msi + mac | fedora | `nmap` | `dnf repoquery @fedora:43` | |
| `parallel` | msi + mac | fedora | `parallel` | `dnf repoquery @fedora:43` | |
| `pavucontrol` | msi | fedora | `pavucontrol-qt` | `dnf repoquery @fedora:43` | Qt build for KDE; plain `pavucontrol` also exists |
| `podman` | mac (+msi 4.6) | fedora | `podman` | `dnf repoquery @fedora:43` | |
| `podman-compose` | mac (+msi 4.6) | fedora | `podman-compose` | `dnf repoquery @fedora:43` | |
| `python3` | msi + mac | fedora | `python3` | `dnf repoquery @fedora:43` | |
| `qbittorrent` | msi + mac | fedora | `qbittorrent` | `dnf repoquery @fedora:43` | Flathub `org.qbittorrent.qBittorrent` also verified if a Flatpak is preferred; macOS: cask |
| `qpwgraph` | msi | fedora | `qpwgraph` | `dnf repoquery @fedora:43` | |
| `qttools` | msi | fedora | `qt6-qttools` | `dnf repoquery @fedora:43` | **name differs** |
| `ripgrep` | msi + mac | fedora | `ripgrep` | `dnf repoquery @fedora:43` | |
| `ruff` | mac | fedora | `ruff` | `dnf repoquery @fedora:43` | |
| `rustfmt` | mac | fedora | `rustfmt` | `dnf repoquery @fedora:43` | |
| `shfmt` | msi + mac | fedora | `shfmt` | `dnf repoquery @fedora:43` | |
| `syncthing` | msi + mac | fedora | `syncthing` | `dnf repoquery @fedora:43` | §0: native service. Ansible writes the **user** unit (task 2.10) |
| `tailscale` | msi | fedora | `tailscale` | `dnf repoquery @fedora:43` | in Fedora main; Tailscale's own repo is not required |
| `tmux` | msi + mac | fedora | `tmux` | `dnf repoquery @fedora:43` | HM `programs.tmux.enable` |
| `vim` | msi + mac | fedora | `vim-enhanced` | `dnf repoquery @fedora:43` (`repoquery --whatprovides /usr/bin/vim`) | **name differs** |
| `wget` | msi + mac | fedora | `wget2-wget` | `dnf repoquery @fedora:43` (`--whatprovides /usr/bin/wget`) | **name differs**. Fedora 43 default is wget2; `wget1-wget` is the classic build |
| `wl-clipboard` | msi | fedora | `wl-clipboard` | `dnf repoquery @fedora:43` | inventory files it under the Hyprland stack, but it is a generic Wayland tool and KDE benefits — **keep** |
| `zathura-with-plugins` | msi | fedora | `zathura` + `zathura-plugins-all` | `dnf repoquery @fedora:43` | two packages; `zathura-pdf-mupdf` also present |
| `zoxide` | msi + mac | fedora | `zoxide` | `dnf repoquery @fedora:43` | listed in PLAN as "known to differ" — it does not |
| `zsh` | msi + mac | fedora | `zsh` | `dnf repoquery @fedora:43` | login shell set by `roles/users` (task 4.2) |

### 1b. New rows — in neither Nix list, required by the plan

| nixpkgs attr | host(s) | source | exact name / app id | verified? | notes |
| --- | --- | --- | --- | --- | --- |
| *(n/a)* `earlyoom` | msi | fedora | `earlyoom` | `dnf repoquery @fedora:43` | `base.nix` enabled it as a NixOS service (task 4.2) |
| *(n/a)* `firewalld` | msi | fedora | `firewalld` | `dnf repoquery @fedora:43` | replaces `networking.firewall` (task 4.4) |
| `zsh-autosuggestions` | msi | fedora | `zsh-autosuggestions` | mdapi f43 (0.7.1), 2026-09-25 | **Added phase 6.1.** A `programs.zsh` plugin, not a `home.packages` entry, so the original inventory never saw it. `chezmoi/dot_config/zsh/20-completion.zsh` sources it. `zsh-completions` has **no** Fedora 43 package (mdapi: not found); zsh's bundled completions stand in. |
| *(n/a)* `i2c-tools` | msi | fedora | `i2c-tools` | `dnf repoquery @fedora:43` | ddcutil prerequisite + `i2c` group/udev rule (task 4.4) |
| *(n/a)* `glibc-langpack-fr` | msi | fedora | `glibc-langpack-fr` | `dnf repoquery @fedora:43` | replaces `glibc-locales` for `fr_FR.UTF-8` (task 4.2) |
| `gnupg` | msi | fedora | `gnupg2` + `pinentry-tty` | `dnf repoquery @fedora:43` | `desktop.nix` ran the gpg agent with `pinentry-tty` |
| *(n/a)* `mangohud` | msi | fedora | `mangohud` | `dnf repoquery @fedora:43` | Nobara likely ships it — verify before adding (task 4.6) |
| `pkgs.inter` | msi | fedora | `rsms-inter-fonts` | `dnf repoquery @fedora:43` | **name differs**; fontconfig sans default (task 3.3) |
| `pkgs.ibm-plex` | msi | fedora | `ibm-plex-fonts-all` | `dnf repoquery @fedora:43` | fontconfig serif default (task 3.3) |
| `pkgs.noto-fonts-cjk-sans` | msi | fedora | `google-noto-sans-cjk-fonts` | `dnf repoquery @fedora:43` | **name differs** |
| `pkgs.noto-fonts-cjk-serif` | msi | fedora | `google-noto-serif-cjk-fonts` | `dnf repoquery @fedora:43` | **name differs** |
| `catppuccin-papirus-folders`\* | msi | fedora | `papirus-icon-theme` | `dnf repoquery @fedora:43` | base icon theme only; the Catppuccin folder recolour is **not** packaged — see the `nix` section |

---

## 2. `rpmfusion`

| nixpkgs attr | host(s) | source | exact name / app id | verified? | notes |
| --- | --- | --- | --- | --- | --- |
| `mpv-with-scripts` | msi + mac | rpmfusion | `mpv` | `dnf repoquery @fedora:43 +rpmfusion` (repo `rpmfusion-free`) | **plain `mpv`**, RIFE/VapourSynth stack dropped per §0 (task 2.8). macOS: brew formula `mpv` |
| `steam` | msi | rpmfusion | `steam` | `dnf repoquery @fedora:43 +rpmfusion` (repo `rpmfusion-nonfree`, `rpmfusion-nonfree-updates`) | Nobara ships Steam — check before adding (task 4.6). macOS: cask |

---

## 3. `copr:<repo>`

Only three packages genuinely need a COPR. All three come from `atim/*`,
which is a long-standing, well-known Fedora packager. COPRs were enabled in
the container and the package resolved from
`copr:copr.fedorainfracloud.org:atim:<repo>`.

| nixpkgs attr | host(s) | source | exact name / app id | verified? | notes |
| --- | --- | --- | --- | --- | --- |
| `starship` | msi + mac | copr:`atim/starship` | `starship` | `dnf repoquery @fedora:43 +copr:atim/starship` | **not** in Fedora main. macOS: brew |
| `lazygit` | msi + mac | copr:`atim/lazygit` | `lazygit` | `dnf repoquery @fedora:43 +copr:atim/lazygit` | **not** in Fedora main. HM `programs.lazygit.enable` (task 2.5). macOS: brew |
| `bottom` | msi + mac | copr:`atim/bottom` | `bottom` | `dnf repoquery @fedora:43 +copr:atim/bottom` | **not** in Fedora main; binary is `btm`. macOS: brew |

Rejected COPRs (searched via the Copr API, then not used): `atim/kanata`,
`atim/difftastic`, `atim/lua-language-server` do **not exist** (`copr enable`
failed). The only Copr hits for `kanata`, `stylua`, `texlab`,
`lua-language-server`, `zed`, `faugus-launcher` are single-user personal
projects; per PLAN §0.3 ("prefer nix over hand-rolling a COPR") those go to
the `nix` column instead.

---

## 4. `flatpak`

All app IDs confirmed against the Flathub API (HTTP 200 + matching app name).

| nixpkgs attr | host(s) | source | exact name / app id | verified? | notes |
| --- | --- | --- | --- | --- | --- |
| `signal-desktop` | msi | flatpak | `org.signal.Signal` | `flathub API 200` ("Signal Desktop") | no Fedora/RPM Fusion package exists. macOS: cask `signal` |
| `legcord` | msi | flatpak | `app.legcord.Legcord` | `flathub API 200` ("Legcord") | **not** `io.github.legcord.LegCord` — that ID 404s. Found via Flathub search |
| `high-tide` | msi | flatpak | `io.github.nokse22.high-tide` | `flathub API 200` ("High Tide") | PLAN said "Flatpak if available, else drop" — it **is** available, so keep |
| `faugus-launcher` | msi | flatpak | `io.github.Faugus.faugus-launcher` | `flathub API 200` ("Faugus") | not in Fedora/RPM Fusion; nixpkgs also has it if Flatpak proves awkward |
| *(n/a)* `zed` | msi | flatpak | `dev.zed.Zed` | `flathub API 200` ("Zed") | §0 wants Zed installed. **No Fedora package and no credible COPR** — Flathub is the answer on Linux. macOS: cask `zed` (`brew info`) |

Flathub is already configured on Nobara — check before adding the remote
(task 3.2).

---

## 5. `nix` — Determinate Nix (`nix profile install`)

Everything here was verified by evaluating the **exact attribute currently
installed**, so these are guaranteed like-for-like.

| nixpkgs attr | host(s) | source | exact name / app id | verified? | notes |
| --- | --- | --- | --- | --- | --- |
| `brave-origin` | msi | flatpak | `com.brave.Browser` | `flathub API 200` | **User decision (2026-09-23): use the Brave Flatpak.** This is upstream Brave, not the `brave-origin` build installed today — a deliberate, accepted substitution. Extensions become a managed-policy JSON (task 2.10). nixpkgs `brave-origin` 1.95.102 remains the fallback if the upstream build proves unacceptable |
| `devenv` | msi + mac | nix | `devenv` | `nix eval → devenv-2.1.2` | the whole reason Nix is retained (§0) |
| `determinate-nix` / `determinate-nixd` | msi + mac | nix | Determinate installer | n/a — installer, task 3.4 | `curl -fsSL https://install.determinate.systems/nix \| sh -s -- install --determinate` |
| `claude` | msi + mac | nix | `claude-code` | `nix eval → claude-code-2.1.278` | npm is the alternative; nix keeps the pinned version |
| `codegraph` | msi + mac | nix | `codegraph` | `nix eval → codegraph-1.6.0` | overlay, from nixpkgs-unstable |
| `rtk` | mac (+msi) | nix | `rtk` | `nix eval → rtk-0.49.0` | overlay, from nixpkgs-unstable |
| `t3code` | msi + mac | nix | `t3code` | `nix eval → t3code-0.0.40` | overlay, from nixpkgs-unstable |
| `lua-language-server` | msi + mac | nix | `lua-language-server` | `nix eval → lua-language-server-3.18.1` | not in Fedora 43; no trustworthy COPR. macOS: brew |
| `stylua` | msi + mac | nix | `stylua` | `nix eval → stylua-2.5.2` | not in Fedora. macOS: brew |
| `typstyle` | msi + mac | nix | `typstyle` | `nix eval → typstyle-0.14.4` | not in Fedora. macOS: brew |
| `tinymist` | msi + mac | nix | `tinymist` | `nix eval → tinymist-0.14.18` | not in Fedora. macOS: brew |
| `texlab` | msi + mac | nix | `texlab` | `nix eval → texlab-5.25.1` | not in Fedora. macOS: brew |
| `shellharden` | msi + mac | nix | `shellharden` | `nix eval → shellharden-4.3.1` | not in Fedora. macOS: brew |
| `prettierd` | msi + mac | nix | `prettierd` | `nix eval → prettierd-0.27.0` | not in Fedora. macOS: brew |
| *(n/a)* `kanata` | msi | nix | `kanata` | `nix eval → kanata-1.11.0` | **not in Fedora, no real COPR.** Needed by task 4.4. The binary is all that is needed; the uinput group/udev rule/user unit are Ansible's job |
| `distrobox-tui` | msi | nix | `distrobox-tui` | `nix eval → distrobox-tui-0.2.0` | not in Fedora |
| `notify-desktop` | msi | nix | `notify-desktop` | `nix eval → notify-desktop-0.2.0` | not in Fedora. **Consider dropping** — `libnotify`'s `notify-send` covers the same ground and is a Fedora package |
| `catppuccin-papirus-folders` | msi | nix | `catppuccin-papirus-folders` | `nix eval → catppuccin-papirus-folders-0-unstable-2024-08-06` | Fedora has `papirus-icon-theme` but not the Catppuccin folder recolour. It is a shell script over the icon theme — could also be run from `~` by chezmoi |
| `graphite-cursors` | msi | nix | `graphite-cursors` | `nix eval → graphite-cursors-2021-11-26` | not in Fedora |
| *(n/a)* `catppuccin-cursors` | msi | nix | `catppuccin-cursors` | `nix eval → catppuccin-cursors-2.0.0` | fills theme-asset gap 2 of PLAN §0.1 (`Catppuccin-{Mocha,Latte}-Mauve-Cursors`). Not in Fedora (`catppuccin-cursors-mocha` → NONE) |
| *(n/a)* `catppuccin-kde` | msi | nix | `catppuccin-kde` | `nix eval → kde-0.2.6` | fills theme-asset gap 1 (`CatppuccinLatteMauve` colour scheme, which breaks light mode). Not in Fedora |
| `nixd` | msi + mac | nix | `nixd` | `nix eval → nixd-2.9.1` | optional: only useful while any Nix code is still edited (`home-server` stays on NixOS, so **keep**) |
| `nixfmt` | msi + mac | nix | `nixfmt-rfc-style` | in the current closure as `nixfmt` | same rationale as `nixd` |

---

## 6. `upstream` — no packaged source anywhere

| nixpkgs attr | host(s) | source | exact name / app id | verified? | notes |
| --- | --- | --- | --- | --- | --- |
| *(n/a)* `chezmoi_modify_manager` | msi (+mac) | upstream | `chezmoi_modify_manager-v3.7.1-x86_64-unknown-linux-gnu.tar.gz` | `upstream release` (GitHub releases API, `VorpalBlade/chezmoi_modify_manager` tag `v3.7.1`; darwin `aarch64-apple-darwin` asset also present) | **Hard prerequisite for task 2.9.** Not in Fedora, not in any COPR (Copr API search returns zero projects), **not in nixpkgs** (`chezmoi-modify-manager` and `chezmoi_modify_manager` both absent), not in Homebrew. Install with `get_url` + `unarchive` into `~/.local/bin`, or `cargo install chezmoi_modify_manager` (`cargo` is a Fedora package). Prefer the release tarball — it is reproducible and needs no Rust toolchain |

---

## 7. `on-box-required` — cannot be resolved without a real Nobara install

| nixpkgs attr | host(s) | source | exact name / app id | verified? | notes |
| --- | --- | --- | --- | --- | --- |
| `nvidia-x11` | msi | on-box-required | (Nobara NVIDIA edition) | `on-box-required` | §0/task 4.5: Nobara's NVIDIA edition ships the proprietary driver. **Do not install `akmod-nvidia` by hand.** Only the msi-specific bits remain (nouveau/iTCO_wdt blacklist, `nvidia-frequency` unit) |
| `nvidia-settings` | msi | on-box-required | (ships with the driver) | `on-box-required` | same |
| `ananicy-cpp` | msi | on-box-required | `ananicy-cpp` | `on-box-required` — absent from Fedora 43 + RPM Fusion | Nobara ships ananicy-cpp per PLAN §4.6. Verify on-box; the 410-line ruleset is ported only if not already covered |

---

## 8. `already-in-base` — Nobara/Fedora base install supplies these

These are almost all NixOS's own stock `environment.systemPackages` and
service-pulled dependencies. **No Ansible task should install them.** Names
below were still checked so the mapping is not a guess; all resolved from
`fedora`/`updates` in the container.

| nixpkgs attr | Fedora name | verified? |
| --- | --- | --- |
| `accountsservice` | `accountsservice` | `dnf repoquery @fedora:43` |
| `acl` | `acl` | `dnf repoquery @fedora:43` |
| `attr` | `attr` | `dnf repoquery @fedora:43` |
| `avahi` | `avahi` | `dnf repoquery @fedora:43` |
| `bash-interactive` | `bash` | base install |
| `bcache-tools` | `bcache-tools` | `dnf repoquery @fedora:43` |
| `bind` | `bind-utils` | `dnf repoquery @fedora:43` |
| `bluez` | `bluez` | `dnf repoquery @fedora:43` |
| `bzip2` | `bzip2` | `dnf repoquery @fedora:43` |
| `coreutils-full` | `coreutils` | `dnf repoquery @fedora:43` |
| `cpio` | `cpio` | `dnf repoquery @fedora:43` |
| `curl` | `curl` | `dnf repoquery @fedora:43` |
| `dbus` | `dbus` | `dnf repoquery @fedora:43` |
| `dbus-broker` | `dbus-broker` | `dnf repoquery @fedora:43` |
| `dconf` | `dconf` | base install (GTK apps still need it under KDE) |
| `diffutils` | `diffutils` | `dnf repoquery @fedora:43` |
| `dosfstools` | `dosfstools` | `dnf repoquery @fedora:43` |
| `e2fsprogs` | `e2fsprogs` | base install |
| `findutils` | `findutils` | `dnf repoquery @fedora:43` |
| `flatpak` | `flatpak` | `dnf repoquery @fedora:43` — Nobara preconfigures it + Flathub |
| `fontconfig` | `fontconfig` | base install |
| `fscrypt` | `fscrypt` | `dnf repoquery @fedora:43` |
| `fuse` | `fuse3` | `dnf repoquery @fedora:43` |
| `fwupd` | `fwupd` | `dnf repoquery @fedora:43` |
| `gawk` | `gawk` | `dnf repoquery @fedora:43` |
| `geoclue` | `geoclue2` | `dnf repoquery @fedora:43` |
| `glibc` | `glibc` | base install |
| `gnome-keyring` | `gnome-keyring` | `dnf repoquery @fedora:43` — KDE uses kwallet; keep only if a GTK app needs it |
| `gnugrep` | `grep` | `dnf repoquery @fedora:43` |
| `gnused` | `sed` | `dnf repoquery @fedora:43` |
| `gnutar` | `tar` | `dnf repoquery @fedora:43` |
| `gvfs` | `gvfs` | `dnf repoquery @fedora:43` |
| `gzip` | `gzip` | `dnf repoquery @fedora:43` |
| `hicolor-icon-theme` | `hicolor-icon-theme` | `dnf repoquery @fedora:43` |
| `hostname-debian` | `hostname` | base install |
| `iproute2` | `iproute` | `dnf repoquery @fedora:43` |
| `iptables` | `iptables-nft` | `dnf repoquery @fedora:43` — superseded by `firewalld` (task 4.4) |
| `iputils` | `iputils` | `dnf repoquery @fedora:43` |
| `jack-libs` | `pipewire-jack-audio-connection-kit` | pipewire sub-package, base install |
| `kbd` | `kbd` | `dnf repoquery @fedora:43` |
| `kexec-tools` | `kexec-tools` | `dnf repoquery @fedora:43` |
| `kmod` | `kmod` | `dnf repoquery @fedora:43` |
| `less` | `less` | `dnf repoquery @fedora:43` |
| `libcap` | `libcap` | `dnf repoquery @fedora:43` |
| `libressl` | `openssl` | `dnf repoquery @fedora:43` — NixOS artefact, Fedora uses openssl |
| `linux-pam` | `pam` | `dnf repoquery @fedora:43` |
| `lvm2` | `lvm2` | `dnf repoquery @fedora:43` |
| `man-db` | `man-db` | `dnf repoquery @fedora:43` |
| `mdadm` | `mdadm` | `dnf repoquery @fedora:43` |
| `modemmanager` | `ModemManager` | `dnf repoquery @fedora:43` — **capitalisation matters** |
| `mtools` | `mtools` | `dnf repoquery @fedora:43` |
| `nano` | `nano` | base install |
| `ncurses` | `ncurses` | `dnf repoquery @fedora:43` |
| `networkmanager` | `NetworkManager` | `dnf repoquery @fedora:43` — **capitalisation matters** |
| `openresolv` | (systemd-resolved) | NetworkManager handles resolv.conf on Fedora |
| `openssh` | `openssh-server` / `openssh-clients` | `dnf repoquery @fedora:43` |
| `patch` | `patch` | `dnf repoquery @fedora:43` |
| `pcsclite-with-polkit` | `pcsc-lite` | `dnf repoquery @fedora:43` |
| `perl` | `perl` | base install |
| `pipewire` | `pipewire` | `dnf repoquery @fedora:43` — Nobara ships it configured (task 4.3) |
| `polkit` | `polkit` | `dnf repoquery @fedora:43` |
| `power-profiles-daemon` | `power-profiles-daemon` | `dnf repoquery @fedora:43` — §0 drops the CPU-governor script, this handles it |
| `procps` | `procps-ng` | `dnf repoquery @fedora:43` |
| `pulseaudio` | `pipewire-pulseaudio` | `dnf repoquery @fedora:43` |
| `rsync` | `rsync` | `dnf repoquery @fedora:43` |
| `rtkit` | `rtkit` | `dnf repoquery @fedora:43` — realtime audio (task 4.3) |
| `shadow` | `shadow-utils` | `dnf repoquery @fedora:43` |
| `shared-mime-info` | `shared-mime-info` | `dnf repoquery @fedora:43` |
| `sound-theme-freedesktop` | `sound-theme-freedesktop` | `dnf repoquery @fedora:43` |
| `speech-dispatcher` | `speech-dispatcher` | `dnf repoquery @fedora:43` |
| `strace` | `strace` | `dnf repoquery @fedora:43` |
| `sudo` | `sudo` | `dnf repoquery @fedora:43` |
| `systemd` | `systemd` | `dnf repoquery @fedora:43` |
| `time` | `time` | `dnf repoquery @fedora:43` |
| `udisks` | `udisks2` | `dnf repoquery @fedora:43` |
| `unzip` | `unzip` | `dnf repoquery @fedora:43` |
| `upower` | `upower` | `dnf repoquery @fedora:43` |
| `util-linux` | `util-linux` | `dnf repoquery @fedora:43` |
| `which` | `which` | `dnf repoquery @fedora:43` |
| `wireplumber` | `wireplumber` | `dnf repoquery @fedora:43` |
| `wpa_supplicant` | `wpa_supplicant` | base install (NetworkManager dependency) |
| `xdg-desktop-portal` | `xdg-desktop-portal` | base install |
| `xdg-desktop-portal-gtk` | `xdg-desktop-portal-gtk` | base install |
| `xdg-utils` | `xdg-utils` | base install |
| `xz` | `xz` | `dnf repoquery @fedora:43` |
| `zip` | `zip` | `dnf repoquery @fedora:43` |
| `zstd` | `zstd` | `dnf repoquery @fedora:43` |

KDE equivalents that Nobara KDE supplies and that replace dropped GNOME apps
(all verified present in Fedora 43: `kcalc`, `ark`, `dolphin`, `konsole`,
`sddm`, `plasma-workspace`, `xdg-desktop-portal-kde`). No Ansible task needs
to install them on a Nobara **KDE** image; verify on-box.

---

## 9. `drop`

| nixpkgs attr | host(s) | why | verified? |
| --- | --- | --- | --- |
| `hyprland`, `xdg-desktop-portal-hyprland`, `uwsm`, `xwayland`, `fuzzel`, `wlogout`, `swaybg`, `swayidle`, `wpaperd`, `cliphist`, `grim`, `slurp`, `satty`, `xdg-terminal-exec` | msi | §0 — Hyprland stack dropped, KDE Plasma instead | `n/a — dropped` |
| `noctalia`, `noctalia-greeter` | msi | §0 | `n/a — dropped` |
| `gnome-calculator`, `gnome-characters`, `gnome-clocks`, `gnome-font-viewer`, `gnome-system-monitor`, `gnome-obfuscate`, `loupe`, `snapshot`, `nautilus` | msi | §0 — GNOME-specific; Plasma equivalents (`kcalc`, `plasma-systemmonitor`, `gwenview`, `dolphin`) ship with Nobara KDE | `n/a — dropped` |
| `polkit-gnome` | msi | KDE uses `polkit-kde-authentication-agent-1` (ships with Plasma) | `n/a — dropped` |
| `hyperhdr` | msi | §0 | `n/a — dropped` |
| `darkman` | msi | §0/task 2.7 — Plasma's native day/night switch replaces it | `n/a — dropped` |
| `theme-switcher` | msi + mac | §0/task 2.7 — in-repo package, superseded by Plasma native | `n/a — dropped` |
| `tmux-session-color`, `openrouter-credits`, `headroom`, `claude-code-headroom` | msi + mac | task 4.1 — in-repo derivations become plain scripts in `chezmoi/dot_local/bin/`. Their runtime deps must be added to the package lists | `n/a — becomes a script` |
| `xinstall`, `xmount` | msi | task 4.1 — installer helpers move to `scripts/`, run by hand | `n/a — becomes a script` |
| `kitty-themes` | msi + mac | task 2.1 — vendored via `.chezmoiexternal.toml`, not a package | `n/a — dropped` |
| `steam-run` | msi | NixOS-only FHS wrapper; meaningless on Fedora | `n/a — dropped` |
| `envfs` | msi | Nix-ism (`/usr/bin/env` shim); Fedora has a real `/usr/bin` | `n/a — dropped` |
| `opencode` | msi + mac | §0 — dropped, also drop `dot_config/opencode/` | `n/a — dropped` |
| `nix-index-with-full-db-0.1.10`, `comma-with-db-2.4.1`, `nix-bash-completions`, `nix-zsh-completions`, `nix-info`, `cachix`, `home-manager` | msi + mac | §0.3 known drops | `n/a — dropped` |
| `nixos-build-vms`, `nixos-enter`, `nixos-firewall-tool`, `nixos-generate-config`, `nixos-icons`, `nixos-install`, `nixos-option`, `nixos-rebuild-ng`, `nixos-version` | msi | NixOS tooling | `n/a — dropped` |
| `darwin-help`, `darwin-manpages`, `darwin-manual-html`, `darwin-option`, `darwin-rebuild`, `darwin-uninstaller`, `darwin-version`, `brew` (nix-homebrew) | mac | nix-darwin tooling; `/opt/homebrew` survives and is adopted by `roles/homebrew` (task 6.1) | `n/a — dropped` |
| `mpv-rife`, `vsmlrt`, `vstrt`, `miscfilters` | msi | §0 | `n/a — dropped` |
| `pkgs.corefonts` | msi | no Fedora/RPM Fusion package (`msttcore-fonts-installer` → NONE). Would need `cabextract` + the MS installer. **Drop unless the user asks** | `dnf repoquery @fedora:43` → NONE |
| `pkgs.joypixels` | msi | PLAN §3.3 — licence acceptance required, drop unless asked. `google-noto-emoji-fonts` is the Fedora substitute if emoji are missed | `dnf repoquery @fedora:43` (substitute verified) |
| synthetic HM derivations: `hm-session-vars.sh`, `dummy-fc-dir1/2`, `dummy-xdg-mime-dirs1/2`, `ld-library-path`, `glibc-locales`, `X11-fonts`, `index.theme`, `home-configuration-reference-manpage` | both | NIX-ONLY build artefacts | `n/a — dropped` |

---

## 10. macOS — Homebrew (`Volodias-MacBook-Pro`)

Every name below was checked with `brew info --formula` / `brew info --cask`
on the control node (`/opt/homebrew`, 2026-09-23). `OK` = formula/cask
resolves.

### 10a. Casks — §0.2's fixed set, 12 entries

§0.2 fixes the set at the 8-way intersection plus `steam`, `calibre`,
`qbittorrent`. `kitty` is the one addition: it is a **cask** on macOS while it
is a formula-equivalent (`dnf` package) on Linux, and it is in the Nix list
for both hosts, so it is not a §0.2 "disputed entry" — it is carried
regardless, exactly as the CLI tooling is. `zed` is added by §0 and is listed
separately below.

| nixpkgs attr | host | source | cask | verified? | notes |
| --- | --- | --- | --- | --- | --- |
| *(nix-darwin homebrew block)* | mac | homebrew | `karabiner-elements` | `brew info` OK | intersection |
| *(nix-darwin homebrew block)* | mac | homebrew | `tg-pro` | `brew info` OK | intersection |
| *(nix-darwin homebrew block)* | mac | homebrew | `bettermouse` | `brew info` OK | intersection |
| *(nix-darwin homebrew block)* | mac | homebrew | `betterdisplay` | `brew info` OK | intersection |
| *(nix-darwin homebrew block)* | mac | homebrew | `tidal` | `brew info` OK | intersection |
| `signal-desktop` | mac | homebrew | `signal` | `brew info` OK | intersection |
| *(nix-darwin homebrew block)* | mac | homebrew | `vlc` | `brew info` OK | intersection |
| *(nix-darwin homebrew block)* | mac | homebrew | `parsec` | `brew info` OK | intersection. No Flathub ID for Parsec (`tv.parsec.www` 404s) — macOS only |
| `steam` | mac | homebrew | `steam` | `brew info` OK | §0.2 explicit keep |
| *(nix-darwin only)* | mac | homebrew | `calibre` | `brew info` OK | §0.2 explicit keep |
| `qbittorrent` | mac | ~~homebrew~~ **none** | *(dropped on macOS)* | **CORRECTED phase 6.1** | `brew info` passed on 2026-09-23, but Homebrew disabled the cask on 2026-09-01 for failing the macOS Gatekeeper check, and a disabled cask is a hard error that aborts every cask after it. Decided: left out on macOS with no replacement and no fork cask. The §0.2 keep still holds on msi, which installs it from Fedora. |
| `kitty` | mac | homebrew | `kitty` | `brew info` OK (cask; **not** a formula) | in both Nix lists, not a §0.2 dispute |
| *(n/a)* `zed` | mac | homebrew | `zed` | `brew info` OK | §0 — install Zed on both hosts |

**Dropped casks** (§0.2, do not reinstate): `hiddenbar`, `alt-tab`,
`ghostty`, `mtmr`, `skim`, `bitwarden`, `container`, `bambu-studio`,
`obsidian`, `zotero`, `unified-remote`, `jan`, `drawio`, `helium-chromium`;
and the formulae `nushell`, `carapace`, `aider`, `docker`, `skhd`.

### 10b. Formulae — the CLI tooling HM provided

| nixpkgs attr | source | formula | verified? |
| --- | --- | --- | --- |
| `ripgrep` | homebrew | `ripgrep` | `brew info` OK |
| `fzf` | homebrew | `fzf` | `brew info` OK |
| `direnv` | homebrew | `direnv` | `brew info` OK |
| `zoxide` | homebrew | `zoxide` | `brew info` OK |
| `starship` | homebrew | `starship` | `brew info` OK |
| `lazygit` | homebrew | `lazygit` | `brew info` OK |
| `difftastic` | homebrew | `difftastic` | `brew info` OK |
| `chezmoi` | homebrew | `chezmoi` | `brew info` OK |
| `gdu` | homebrew | `gdu` | `brew info` OK |
| `grc` | homebrew | `grc` | `brew info` OK |
| `mosh` | homebrew | `mosh` | `brew info` OK |
| `just` | homebrew | `just` | `brew info` OK |
| `keychain` | homebrew | `keychain` | `brew info` OK |
| `tmux` | homebrew | `tmux` | `brew info` OK |
| `neovim` | homebrew | `neovim` | `brew info` OK |
| `git` | homebrew | `git` | `brew info` OK |
| `git-crypt` | homebrew | `git-crypt` | `brew info` OK |
| `gnumake` | homebrew | `make` | `brew info` OK |
| `go` | homebrew | `go` | `brew info` OK |
| `gopls` | homebrew | `gopls` | `brew info` OK |
| `cargo` | homebrew | `rust` | `brew info` OK |
| `ruff` | homebrew | `ruff` | `brew info` OK |
| `rustfmt` | homebrew | *(none — use `rust`)* | **CORRECTED phase 6.1:** `brew info rustfmt` succeeds but resolves to the `rust` formula, for which `rustfmt` is an `oldnames` entry, not a formula of its own. Declaring both `rust` and `rustfmt` makes `community.general.homebrew` fail with "Package names for rust are missing or ambiguous". Dropped from `brew_formulae`; `rust` provides the binary. |
| `stylua` | homebrew | `stylua` | `brew info` OK |
| `shfmt` | homebrew | `shfmt` | `brew info` OK |
| `ShellCheck` | homebrew | `shellcheck` | `brew info` OK (**lowercase on brew**, capital on Fedora) |
| `shellharden` | homebrew | `shellharden` | `brew info` OK |
| `prettierd` | homebrew | `prettierd` | `brew info` OK |
| `bash-language-server` | homebrew | `bash-language-server` | `brew info` OK |
| `lua-language-server` | homebrew | `lua-language-server` | `brew info` OK |
| `texlab` | homebrew | `texlab` | `brew info` OK |
| `tinymist` | homebrew | `tinymist` | `brew info` OK |
| `typstyle` | homebrew | `typstyle` | `brew info` OK |
| `jq` | homebrew | `jq` | `brew info` OK |
| `htop` | homebrew | `htop` | `brew info` OK |
| `nmap` | homebrew | `nmap` | `brew info` OK |
| `parallel` | homebrew | *(none on macOS — conflicts with `moreutils`)* | **CORRECTED phase 6.1:** `brew info parallel` succeeds, but Homebrew declares `Conflicts with: moreutils (because both install a `parallel` executable)`. `brew info` alone cannot surface that. moreutils is kept (tmux.nix needs `sponge`); GNU parallel is dropped on macOS only. Linux is unaffected — Fedora ships moreutils' copy as `parallel-moreutils`. |
| `wget` | homebrew | `wget` | `brew info` OK |
| `moreutils` | homebrew | `moreutils` | `brew info` OK |
| `bottom` | homebrew | `bottom` | `brew info` OK |
| `libgtop` | homebrew | `libgtop` | `brew info` OK |
| `lsof` | homebrew | `lsof` | `brew info` OK |
| `python3` | homebrew | `python@3.13` | `brew info` OK |
| `mpv-with-scripts` | homebrew | `mpv` | `brew info` OK |
| `syncthing` | homebrew | `syncthing` | `brew info` OK — §0: launchd agent / `brew services` |
| `terminal-notifier` | homebrew | `terminal-notifier` | `brew info` OK |
| `fswatch` | homebrew | `fswatch` | `brew info` OK |
| `zsh-autosuggestions` | homebrew | `zsh-autosuggestions` | `brew info` OK (0.7.1) — **added phase 6.1**: HM `programs.zsh` plugin, missed because plugins are not `home.packages` |
| `coreutils` | homebrew | `coreutils` | `brew info` OK (9.12) — **added phase 6.1**: transcrypt's commit hook needs `nproc`. Came implicitly from nix-darwin's system profile before; declared nowhere. Unprefixed only for commands macOS lacks, so BSD tools are not shadowed |
| `zsh-completions` | homebrew | `zsh-completions` | `brew info` OK (0.36.0) — **added phase 6.1**, same reason |
| `podman` | homebrew | `podman` | `brew info` OK |
| `podman-compose` | homebrew | `podman-compose` | `brew info` OK |
| `texinfo-interactive` | homebrew | `texinfo` | `brew info` OK |
| `bc` | homebrew | `bc` | `brew info` OK |
| `findutils` | homebrew | `findutils` | `brew info` OK |
| `zip`, `unzip`, `man-db`, `vim`, `zsh` | already-in-base | — | macOS ships all five |

macOS packages that stay on **nix** (same attrs as §5): `devenv`,
`claude-code`, `codegraph`, `rtk`, `t3code`, `nixd`, `nixfmt`. macOS
`chezmoi_modify_manager` uses the `aarch64-apple-darwin` release tarball
(§6) — but note KDE config is Linux-only, so it is optional there.

---

## 11. Assets that are not packages

| item | disposition | verified? |
| --- | --- | --- |
| Comic Code Ligatures (monospace fontconfig default) | licensed font, transcrypt-encrypted in-repo → chezmoi into `~/.local/share/fonts` (task 3.3) | n/a — in-repo asset |
| `Catppuccin-{Mocha,Latte}-Mauve` global themes, colour schemes, aurorae | adopted from the old dotfiles repo (§0.1) as plain files via chezmoi | n/a — in-repo asset |
| `Fluent-purple-{dark,light}` window decorations | referenced by the adopted look-and-feels, **shipped by neither tree and not packaged in Fedora** | `dnf repoquery @fedora:43` → NONE. Install from the KDE Store or drop the reference (theme gap 3, task 2.7) |
| `kitty-themes`, catppuccin tmux/lazygit themes, `modernz.lua` | vendored via `.chezmoiexternal.toml` before first apply (task 2.1) | n/a — vendored |

---

## Counts

| source | rows |
| --- | --- |
| fedora | 68 + 11 new = **79** |
| rpmfusion | **2** |
| copr | **3** |
| flatpak | **5** |
| nix | **24** |
| upstream | **1** |
| on-box-required | **3** |
| already-in-base | **86** |
| drop | **62** (grouped) |
| homebrew (macOS) | **13 casks + 52 formulae** |

Union of the four Task 0.1 JSON files: **259** distinct nixpkgs names, all
accounted for above, plus 18 rows the Nix lists do not contain (`zed`,
`chezmoi_modify_manager`, `kanata`, `earlyoom`, `firewalld`, `i2c-tools`,
`glibc-langpack-fr`, `catppuccin-cursors`, `catppuccin-kde`, `mangohud`, and
the font packages).

## Corrections to the Task 0.1 inventory

1. **`package-inventory.md`'s caveat about `programs.<x>.enable` is wrong in
   practice.** Home Manager *does* add the package of an enabled program to
   `home.packages`, so `git`, `zsh`, `tmux`, `zoxide`, `keychain`, `fzf`,
   `lazygit`, `direnv`, `starship` and `neovim` all appear in **both**
   `msi-home-pkgs.json` and `mac-home-pkgs.json`. `mac-home-pkgs.json` is not
   "implausibly thin" — the mac simply has no GUI/desktop Linux packages.
   The only genuinely invisible entries are module-generated *config* (ssh
   defaults, direnv stdlib, lazygit settings), not packages.
2. **`ssh` / `ssh-agent`** are the one real gap: `programs.ssh.enable` and
   `services.ssh-agent.enable` add no package. On Fedora these are
   `openssh-clients` (base) + the `ssh-agent` shipped with it.
3. **PLAN §0.3's "names known to differ" list is over-cautious.** Of
   `fd`/`bottom`/`starship`/`lazygit`/`difftastic`/`chezmoi`/`gdu`/`grc`/`mosh`/`zoxide`/`just`,
   only `fd` (→ `fd-find`, verified present), `bottom`, `starship` and
   `lazygit` actually differ or are missing. The rest are in Fedora main
   under their nixpkgs name. (`fd` is not in either Nix list — it is not
   installed today; `fd-find` recorded here for reference only.)
4. **`wl-clipboard` is mis-filed** in `package-inventory.md` as part of the
   dropped Hyprland stack. It is a generic Wayland clipboard tool and is
   useful under KDE — kept as `fedora`/`wl-clipboard`.
