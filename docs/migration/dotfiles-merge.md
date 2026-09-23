# Task 0.4 — Reconciliation of the two chezmoi trees

Produced by task 0.4. **Nothing is copied here** — this is the ruling table that
phase 2 executes.

- **A** = `chezmoi/` in this repo (Nix-era, flat, no templates, no
  `.chezmoiignore`, no `run_*`). 58 files.
- **B** = `github.com/VolodiaPG/dotfiles`, read-only clone at `/tmp/dotfiles-vpg`
  (pre-Nix, Arch + KDE + macOS). 400 files, of which 392 are B-only.

| Set | Count |
| --- | --- |
| Paths in **both** trees (byte-comparable, same source path) | 8 |
| Paths only in **A** | 50 |
| Paths only in **B** | 392 |

Of the 8 shared paths: 3 identical or A-superset (**A wins**), 5 **dropped from
both** (`dot_config/opencode/`, §0).

A second class of conflict exists that a path-level `comm` does not see: files
that live at the **same `$HOME` target** but come from Home Manager in A and
from a real file in B (git, tmux, ssh, kanata, lazygit). Those are in §3.

---

## 1. Paths present in BOTH trees (8)

Diffed content, not filenames.

| Path | Diff summary | Decision | Why |
| --- | --- | --- | --- |
| `dot_config/kitty/kitty.conf` | A 63 / B 61 lines. A adds `background_opacity 0.85` + blur, `modify_font cell_height 80%`; A `editor vim`, B `editor nvim`; A `shell /etc/profiles/per-user/volodia/bin/zsh`, B `shell /bin/bash` | **A wins**, with one templating fix | A is the live Nix-era file and strictly richer. The `shell` line is a Nix store-ish path → must become `shell {{ .shell }}` / `/usr/bin/zsh` in phase 2 (task 2.5). `editor vim` kept: HM sets `EDITOR=vim` and `pkgs.vim` is what's installed. |
| `dot_config/private_karabiner/private_karabiner.json` | A 299 / B 293. Only diff: A adds `complex_modifications.parameters` (4 × 20 ms timings). Rules are byte-identical. | **A wins** (strict superset) | Same rule set, A additionally tunes the home-row-mod timings. |
| `dot_config/zathura/zathurarc` | byte-identical (md5 match) | **A wins** (no-op) | Identical; keep A's copy, no merge needed. |
| `dot_config/opencode/opencode.json` | differs (B adds an `lmstudio` provider + hardcoded `/home/volodia/...`; A adds caveman skill permissions) | **Drop both** | §0: `programs.opencode` dropped, "also drop `dot_config/opencode/`". §0.1 repeats it. |
| `dot_config/opencode/oh-my-opencode-slim.json` | differs (A 54 / B 85 lines, different model routing) | **Drop both** | §0 / §0.1. |
| `dot_config/opencode/oh-my-openagent.json` | byte-identical | **Drop both** | §0 / §0.1. |
| `dot_config/opencode/opencode-agents.json` | byte-identical | **Drop both** | §0 / §0.1. |
| `dot_config/opencode/skills/caveman/SKILL.md` | differs (A adds a "Persistence" section) | **Drop both** | §0 / §0.1. Note: if the caveman skill is wanted outside opencode, it is A's copy that is newer — but that is out of scope here. |

**Conflict breakdown:** 8 shared paths → 3 A-wins (1 real merge conflict resolved
in A's favour + 1 superset + 1 identical), 5 drop-both. **0 B-wins** among
byte-shared paths.

---

## 2. Paths only in A (50)

(The 5 `dot_config/opencode/` files also exist in B and are ruled on in §1.)

| Path(s) | Count | Decision | Why |
| --- | --- | --- | --- |
| `dot_config/nvim/**` (init.lua, `lua/myLuaConf/**`, `dot_stylua.toml`, `nvim-pack-lock.json`) | 16 | **A wins — keep inline** | §0 ruling, not revisited. B's `.chezmoiexternal.toml` nvim entry is dropped entirely (§1 below). `modules/home/neovim.nix` is packages-only by design and never writes `init.lua`, so this is a straight copy. |
| `dot_config/hypr/hyprland.lua` (500 lines) | 1 | **Drop** | §0: Hyprland dropped, target desktop is KDE Plasma. |
| `dot_config/noctalia/{config.toml,settings.json,plugins.json,plugins/tailscale/settings.json}` | 4 | **Drop** | §0: noctalia dropped with Hyprland. |
| `dot_config/mpv/{mpv.conf,input.conf}` | 2 | **Keep, edited** | §0: keep `mpv.conf`/`input.conf`, drop the RIFE stack. `input.conf` lines 1–3 bind `r`/`t`/`g` to `vf toggle vapoursynth=~~/rife*.py` — **delete those three lines** in phase 2 or mpv errors on every keypress. `mpv.conf` itself has no RIFE reference. |
| `dot_config/mpv/{rife.py,rife25.py,rife_high.py}` | 3 | **Drop** | §0: `mpv-rife`/VapourSynth/TensorRT dropped. `modules/home/mpv.nix` (the only consumer) goes away with it. |
| `dot_config/mpv/script-opts/modernz.conf` | 1 | **Keep** | mpv UI config, no RIFE dependency; `modernz` is a plain mpv script (needs `~/.config/mpv/scripts/modernz.lua`, which neither tree ships — vendor it via `.chezmoiexternal.toml` in phase 2 or the config is inert). |
| `dot_config/starship.toml` | 1 | **Keep** | starship survives (`common-home.nix` installs the binary, `zsh.nix` does `starship init zsh`). HM's `programs.starship` block is commented out, so this file is genuinely chezmoi-owned already. |
| `dot_config/OrcaSlicer/user/default/**` (+ `filament/.keep`) | 15 | **Keep** | User printer profiles, pure `$HOME` data, no Nix dependency. Only meaningful if OrcaSlicer is installed (currently commented out in `gui.nix`) — cheap to carry, costs nothing if absent. |
| `dot_var/app/com.bambulab.BambuStudio/config/BambuStudio/user/default/**` | 7 | **Keep** | Same reasoning; the `dot_var/app/...` path is the **Flatpak** BambuStudio location, which is exactly how it will be installed on Nobara. |

---

## 3. Same `$HOME` target, different source (Home Manager vs B)

These are the real merge decisions the path-level diff hides: A has **no file**
because Home Manager generates it. Each needs task-2.x treatment, not a copy.

| Target | A source (HM) | B source | Decision |
| --- | --- | --- | --- |
| `~/.config/git/config` | `modules/home/git.nix` (`programs.git`: user/email/signingKey from `config.nix`, `core.editor vim`, `alias.lg`, `diff.external difft`, `rebase.autostash`, `init.defaultBranch main`, ssh signing `signByDefault`) | `dot_config/git/config` — same content rendered, **plus** `[tag] gpgSign = true` and `core.editor = "nvim"`; identity hardcoded | **Union, HM base (task 2.2).** Render git.nix to `dot_config/git/config.tmpl` with `{{ .name }}/{{ .email }}/{{ .signingKey }}`; **adopt B's `[tag] gpgSign = true`** (HM's `signByDefault` covers commits only). Keep `core.editor = vim` (HM), not B's `nvim`. |
| `~/.config/tmux/tmux.conf` | `modules/home/tmux.nix` (prefix C-a, vi keys, vim-navigator, resurrect+continuum, catppuccin via HM module with **Nix store plugin paths**) | `dot_config/tmux/tmux.conf` — an earlier copy of the same config, **plus** `run ~/.config/tmux/plugins/catppuccin/tmux/catppuccin.tmux` as line 1, and `run_once_tmux.sh.tmpl` that clones the plugin there | **Union, HM base (task 2.4).** Take HM's body (it is newer: resurrect/continuum/`@resurrect-processes`), and **adopt B's plugin mechanism** — `.chezmoiexternal.toml` (or `run_onchange_`, §0.1 lesson 2) vendoring `catppuccin/tmux` into `~/.config/tmux/plugins/`, since the Nix store paths in `tmux.nix` will not exist. |
| `~/.ssh/config` | `static/config.ssh`, written with `force = true` by `common-home.nix` | `private_dot_ssh/config` | **Union, A base.** A has `Host linux-builder` (dies with nix-darwin → drop) and the `@g5k_login@` placeholder (→ template var). **Adopt from B:** `Host github.com { AddKeysToAgent yes; IdentitiesOnly no }`, `Host home-server` (still a live host, §0), the concrete `User volparolguarino` for g5k. Drop B's `Host dell` (machine no longer in scope). **`Host storagebox` user disagrees: A `u593939`, B `u593939-sub1` — see NEEDS USER below.** Ships as `private_dot_ssh/private_config.tmpl` (task 2.3). |
| `~/.ssh/authorized_keys` | `common-home.nix` from `config.me.keys` | — | **A wins**, becomes an Ansible `users` role task (keys are a root-adjacent concern) or a chezmoi template fed by `.chezmoi.toml.tmpl`; task 2.3 decides. Not B's problem. |
| `~/.config/kanata/config.kbd` | `static/kanata.lisp`, read by `modules/nixos/desktop.nix` | `dot_config/kanata/config.kbd` | **Union: A's content at B's path.** The two files differ by exactly one line — A has `;; (defcfg concurrent-tap-hold yes)` commented out, B has it live. Take **A's content** (it is the one currently running) and put it at B's chezmoi path; the *service* goes to Ansible (§0.1). |
| `~/.zshrc`, `~/.bashrc`, `~/.profile`, `~/.blerc` | `modules/home/zsh.nix` (generated) | `dot_zshrc`, `dot_bashrc`, `dot_profile`, `dot_blerc` | **A/HM wins; do not adopt B** — §0.1 ruling. Captured in task 2.6. B's `dot_blerc`/ble.sh go with `run_once_ble.sh.tmpl` (dropped, §0.1). |
| `~/Library/Application Support/lazygit/config.yml` (macOS) | `catppuccin-theme.nix` writes `~/.config/lazygit/theme.{dark,light}.yml` and sets `LG_CONFIG_FILE`; `interactive.nix` sets the `difft` pager | `private_Library/private_Application Support/lazygit/empty_config.yml` — one static file with the difftastic pager **and a hardcoded Mocha palette** | **Union, B's path + A's split-theme scheme.** Adopt B's file as the macOS-path skeleton, but keep the dark/light split (theme-switcher depends on it) — i.e. ship `theme.dark.yml`/`theme.light.yml` in chezmoi (vendored from `catppuccin/lazygit` via `.chezmoiexternal.toml`) and keep `LG_CONFIG_FILE` pointing at `config.yml,theme.yml`. B's single hardcoded palette would freeze lazygit in dark mode. |

### Everything else Home Manager currently generates or overwrites (needs task 2.x, never a straight copy)

| HM artifact | Module | Phase-2 treatment |
| --- | --- | --- |
| `~/.config/kitty/kitty-themes` → `${pkgs.kitty-themes}` symlink | `gui.nix:77` | **Blocking for `kitty.conf`**: it does `include ~/.config/kitty/kitty-themes/themes/Catppuccin-Mocha.conf`. Vendor `kovidgoyal/kitty-themes` via `.chezmoiexternal.toml`, or the terminal comes up unthemed. |
| `~/.config/lazygit/theme.{dark,light}.yml` + `LG_CONFIG_FILE` | `catppuccin-theme.nix:48` | see lazygit row above. |
| `~/.config/chezmoi/chezmoi.json` (sets `sourceDir`) | `chezmoi.nix:31` | Replaced by the Ansible `chezmoi` role (`chezmoi init` against this repo) + `.chezmoi.toml.tmpl` (task 2.1). |
| `~/.config/discord/settings.json` | `gui.nix` | Move into chezmoi as a plain file if Discord/legcord is kept; otherwise drop with `gui.nix`. |
| `~/.config/electron-flags.conf`, `~/.config/hypr/xdph.conf` | `hyprland.nix:84,93` | **Drop** — Hyprland (§0). |
| catppuccin tmux `extraConfig` + `pkgs.tmux-session-color`, `pkgs.openrouter-credits`, `pkgs.theme-switcher` | `catppuccin-theme.nix`, `theme-daemon.nix` | These are custom `packages/*` derivations referenced from `zsh.nix` (`theme-switcher -t tmux,kitty`) and tmux. They must come from Nix-as-package-manager or be rewritten; flag for task 2.6/3.4. |
| `services.darkman` (Linux) / `launchd.agents.theme-daemon` (macOS) | `theme-daemon.nix` | Ansible role + B's `dot_local/share/darkman/default.sh` (adopted, §4). Note `theme-switcher` only *reads* `~/.config/kitty/kitty.conf` and writes to a temp file — it does **not** clobber chezmoi-owned files. |

---

## 4. Paths only in B (392)

### 4.1 chezmoi machinery

| Path | Decision | Why |
| --- | --- | --- |
| `.chezmoiexternal.toml` (single `[".config/nvim"]` git-repo entry → `VolodiaPG/vim`) | **Drop the entry; recreate the file empty-then-repopulated** | §0/§0.1: nvim inline tree wins. The *file* is still needed in phase 2 for the new vendoring the merge creates: kitty-themes, catppuccin/tmux, catppuccin/lazygit, modernz.lua. |
| `.chezmoiignore` (`**/*.src.ini`, `*.kate-swp`) | **Adopt, then extend** | **Load-bearing**: without `**/*.src.ini`, chezmoi writes the `.src.ini` sources into `~/.config/` alongside the real rc files. Extend with the per-OS exclusions task 2.1 needs (macOS ⊖ KDE, Linux ⊖ `private_Library`). |
| `README.MD` (chezmoi + `chezmoi_modify_manager` requirement; the `rm ~/.config/plasma-org.kde.plasma.desktop-appletsrc` first-apply step) | **Adopt the *content*, not the file** | The `rm` instruction is the documented fix for duplicate Plasma containments; it belongs in the merge sequence (§5) and the `kde` role, not in a README in `chezmoi/`. |

### 4.2 KDE — adopt wholesale (§0.1)

| Path(s) | Count | Decision |
| --- | --- | --- |
| `dot_config/modify_{kdeglobals,kwinrc,plasma-org.kde.plasma.desktop-appletsrc,plasmashellrc,private_kglobalshortcutsrc,private_krunnerrc}` | 6 | **Adopt wholesale** (§0.1). Each is a 7–9 line `#!/usr/bin/env chezmoi_modify_manager` + `source auto` shim. |
| `dot_config/{kdeglobals,kwinrc,plasma-org.kde.plasma.desktop-appletsrc,plasmashellrc,private_kglobalshortcutsrc,private_krunnerrc}.src.ini` | 6 | **Adopt wholesale** (§0.1). ~47 KB of live Plasma state; `private_kglobalshortcutsrc.src.ini` alone is 16 KB of keybindings. |
| `dot_config/private_kxkbrc` (`LayoutList=fr`, `VariantList=oss`) | 1 | **Adopt** (§0.1 — satisfies part of task 4.4). |
| `dot_config/private_dolphinrc`, `private_kded5rc`, `private_kwinrulesrc`, `private_plasmanotifyrc` | 4 | **Adopt.** Plain (non-`modify_`) KDE rc files Plasma rarely rewrites; they are the same KDE asset class §0.1 rules on. `private_kded5rc` is Plasma-5 naming — verify it is still read by Plasma 6 on Nobara at task 2.9; if not, drop that one file. |

### 4.3 KDE theming — adopt the Catppuccin set, drop the Itchy/Scratchy legacy

§0.1 adopts `look-and-feel/`, `color-schemes/`, `aurorae/themes/`. Reading the
actual `contents/defaults` shows the directory contains **two generations**: a
Catppuccin set that §0.1 names, and an older Itchy/Scratchy set nothing in the
current setup references.

| Path(s) | Count | Decision | Why |
| --- | --- | --- | --- |
| `dot_local/share/plasma/look-and-feel/Catppuccin-{Mocha,Latte}-Mauve/**` | 18 | **Adopt** | Named by §0.1; they point at the adopted aurorae + color-schemes. |
| `dot_local/share/plasma/look-and-feel/Custom {dark,light}/**` | 10 | **Adopt** | Named by §0.1. These carry `contents/layouts/org.kde.plasma.desktop-layout.js` — the panel layout — and use `ColorScheme=CatppuccinMochaMauve` / `CatppuccinLatteMauve`. |
| `dot_local/share/plasma/look-and-feel/{dark,light}/**` | 6 | **Drop** | Earlier duplicates of `Custom dark`/`Custom light`; `light` still points at `ColorScheme=Itchy`. |
| `dot_local/share/plasma/look-and-feel/Custom latte/`, `Custom latte 2/`, `Custom moccha/` | 15 | **Drop** | Dead iterations: they reference `Itchy`, `BreezeClassic`, `Scratchy` schemes — not the Catppuccin set §0 standardises on. |
| `dot_local/share/plasma/look-and-feel/{Itchy,Scratchy}/**` | 10 | **Drop** | Pre-Catppuccin personal themes, superseded. |
| `dot_local/share/aurorae/themes/Catppuccin{Latte,Mocha}-Modern/**` | 22 | **Adopt** | Referenced by name from the two adopted Catppuccin look-and-feels. |
| `dot_local/share/aurorae/themes/{Itchy,Scratchy}/**` | 22 | **Drop** | Only referenced by the dropped look-and-feels. |
| `dot_local/share/color-schemes/CatppuccinMochaMauve.colors`, `private_CatppuccinLatteFlamingo.colors` | 2 | **Adopt** | The dark/light pair the adopted themes and Plasma day/night switching need. |
| `dot_local/share/color-schemes/Itchy.colors` | 1 | **Drop** | Only used by dropped themes. |
| `dot_local/share/plasma/desktoptheme/{Itchy,Scratchy}/**` | 228 | **Drop** | **58 % of B's file count.** Both adopted Catppuccin look-and-feels set `[plasmarc][Theme] name=default`, i.e. they use Plasma's stock desktop theme — these 228 svgz assets are referenced by nothing that survives. |
| `dot_local/share/darkman/default.sh` (`theme-switcher $1`) | 1 | **Adopt** | Two-line bridge from `darkman` to `theme-switcher`; pairs with `theme-daemon.nix` going away. Keep only if darkman is kept — Plasma's native day/night switching (§0) may replace it; decide at task 4.x, but the file costs nothing. |

**Two gaps §0.1's table does not mention** (fix while adopting, do not discover at apply time):

1. **`CatppuccinLatteMauve` does not exist in the tree.** `Catppuccin-Latte-Mauve/contents/defaults` and `Custom light/contents/private_defaults` both set `ColorScheme=CatppuccinLatteMauve`, but the only Latte scheme shipped is `private_CatppuccinLatteFlamingo.colors` (Name=`Catppuccin Latte Flamingo`). Either install `catppuccin-kde` via Ansible or repoint the two `defaults` files at the Flamingo scheme.
2. **External icon/cursor themes are assumed present.** The adopted look-and-feels reference `Fluent-purple-{dark,light}` icons and `Catppuccin-{Mocha,Latte}-Mauve-Cursors` / `breeze_cursors`. None ship in either tree → they become Ansible `kde`/`desktop_linux` role packages, or Plasma silently falls back to Breeze.

### 4.4 `run_once_*` scripts (14) — all leave chezmoi

| Script | Decision | Why |
| --- | --- | --- |
| `run_once_kanata.sh.tmpl` | **Adopt logic → Ansible** | §0.1. uinput group + `/etc/udev/rules.d/99-input.rules` + user unit; needs root. |
| `run_once_docker.sh.tmpl` | **Port → Ansible** (§0.1) | `groupadd docker` + `usermod -aG`. Retarget to **podman** per §2's `virtualization` role, or keep docker only if the compose files below survive. |
| `run_once_services.sh.tmpl` | **Port → Ansible** (§0.1) | Enables tailscaled/containerd/docker **and** writes the nvidia clock-lock unit (`-lmc 1620,21002`, `-lgc 210,3105`) — §0.1 routes that to task 4.5, values disagree with the Nix module. |
| `run_once_udev_usb_chrome.sh.tmpl` | **Port → Ansible** (§0.1) | plugdev group + hidraw/tty udev rules. |
| `run_once_mediacontrole.sh.tmpl` | **Port → Ansible** (§0.1) — but see note | 99 lines that generate a launchd agent running a **nushell** script against `/opt/homebrew/bin/media-control`, feeding **MTMR**. §0.2 drops both `mtmr` and the `nushell` formula, so as written this port has no consumer. Not a NEEDS USER (§0.1 rules "port"), but resolve the mtmr dependency at task time — most likely it becomes a no-op. |
| `run_once_defaults.tmpl` | **Adopt → `osx_defaults`** (§0.1) | More complete than `modules/darwin/common-darwin.nix`. 39 lines. |
| `run_once_packages.sh.tmpl` | **macOS: intersection per §0.2; Linux: translate paru→dnf** (§0.1) | Feeds task 0.3 / 3.x, not chezmoi. |
| `run_once_packages_vim.sh.tmpl` | **Drop** | Installs `nvim` + language servers via brew and calls `~/.config/nvim/install.sh` — a file of the *external* `VolodiaPG/vim` repo that §0 drops. LSP packages are task 3.1's job. |
| `run_once_tmux.sh.tmpl`, `run_once_tmux.tmpl` | **Adopt the idea, not the script** | Two near-duplicates that clone `catppuccin/tmux`. Becomes a `.chezmoiexternal.toml` entry (see §3, tmux row). |
| `run_once_governor.tmpl` | **Drop** | §0 / §0.1 — Nobara handles power profiles. |
| `run_once_yabai.tmpl` | **Drop** | §0.1. |
| `run_once_ble.sh.tmpl` | **Drop** | §0.1 (ble.sh is bash-only, and `dot_bashrc`/`dot_blerc` are dropped). |
| `run_once_devenv.sh.tmpl` | **Drop** | §0.1 — devenv comes from Determinate Nix (task 3.4). |

### 4.5 Services, containers, macOS-only, editors

| Path(s) | Count | Decision | Why |
| --- | --- | --- | --- |
| `dot_config/systemd/user/kanata.service` | 1 | **Adopt → Ansible** | §0.1 + §2 carve-out: user units are written by Ansible (it must enable them). Note it hardcodes `/usr/bin/kanata` and `Environment=PATH=/usr/local/...`. |
| `dot_config/systemd/user/immich-ml.service` + `default.target.wants/`, `multi-user.target.wants/` symlink units | 3 | **Drop** | §0/§0.1 — immich-ml is dead. |
| `dot_config/immich-ml/{docker-compose.yml,hwaccel.ml.yml}` | 2 | **Drop** | §0 — dead. |
| `Documents/docker-services/immich-ml/{docker-compose.yml,hwaccel.ml.yml}` | 2 | **Drop** | Same stack, second copy (differs only by `ports: 3003` vs `0.0.0.0:8080` + `network_mode: host`). §0. |
| `Documents/docker-services/docker-compose.yml` (an `include:` of syncthing + immich-ml) | 1 | **Adopt, reduced** | Only meaningful for the syncthing half once immich-ml is dropped — see below. |
| `Documents/docker-services/syncthing/docker-compose.yml` | 1 | **NEEDS USER** — see §6 | Not in §0.1's table at all. `modules/home/syncthing.nix` exists in this repo, so syncthing is live, but the two implementations (HM service vs a linuxserver.io container under `~/Documents`) are mutually exclusive. Ruling needed: keep the container (→ Ansible `virtualization` + chezmoi-owned compose file) or run syncthing as a native user unit. |
| `dot_config/zed/{keymap.json,private_settings.json}` | 2 | **Adopt** | Not in §0.1's table. Current-era config (Catppuccin system light/dark, Comic Code, vim mode, Elixir LSP pinning). Chezmoi-only cost is zero. **Caveat:** Zed appears in no package list — §0.2's 11 casks do not include it — so nothing installs it; add it in task 3.x or the config is inert. |
| `dot_config/skhd/empty_skhdrc`, `dot_config/yabai/yabairc` | 2 | **Drop** | §0.1 — already disabled under Nix. |
| `private_Library/private_Application Support/lazygit/empty_config.yml` | 1 | **Union** | see §3 lazygit row. |
| `private_dot_ssh/config` | 1 | **Union, A base** | see §3 ssh row. |
| `dot_config/kanata/config.kbd` | 1 | **Union: B's path, A's content** | see §3 kanata row. |
| `dot_config/git/config` | 1 | **Union, HM base** | see §3 git row. |
| `dot_config/tmux/tmux.conf` | 1 | **Union, HM base** | see §3 tmux row. |
| `dot_zshrc`, `dot_bashrc`, `dot_profile`, `dot_blerc` | 4 | **Drop** | §0.1 — oh-my-zsh, stale, hardcoded `/Users/volodia/...`. HM output wins (task 2.6). |

---

## 5. Merge sequence for phase 2

Prerequisites, in this order, before the first `chezmoi apply` on a target host:

- **P1.** `chezmoi_modify_manager` installed and on `$PATH` (Ansible `chezmoi`
  role). The `modify_*` scripts are `#!/usr/bin/env chezmoi_modify_manager`
  shebangs — without it, apply fails on the KDE files.
- **P2.** `.chezmoiignore` in place containing `**/*.src.ini` **before** any KDE
  file is added, or chezmoi litters `~/.config/` with `.src.ini` files.
- **P3.** On the KDE host only, before the first apply:
  `rm ~/.config/plasma-org.kde.plasma.desktop-appletsrc` — otherwise
  `chezmoi_modify_manager` merges into machine-generated containment/applet IDs
  and duplicates every panel widget (B's README).
- **P4.** Plasma **stopped or fresh-logged-out** when applying the KDE rc files
  (§1 gotcha: Plasma rewrites its own config at runtime).

Then, in order — each step is independently verifiable, so commit per step:

1. **`.chezmoi.toml.tmpl` + `.chezmoiignore` + empty `.chezmoiexternal.toml`**
   (task 2.1). Nothing else can be templated or per-OS until these exist.
   `.chezmoiexternal.toml` is created **without** B's nvim entry.
2. **A-only keepers, verbatim** — zero-risk, gets the tree moving:
   `dot_config/nvim/**`, `dot_config/starship.toml`,
   `dot_config/zathura/zathurarc`,
   `dot_config/private_karabiner/private_karabiner.json`,
   `dot_config/OrcaSlicer/**`, `dot_var/app/com.bambulab.BambuStudio/**`.
3. **Deletions from A** — `dot_config/opencode/**`, `dot_config/hypr/`,
   `dot_config/noctalia/`, `dot_config/mpv/rife*.py`, and the three RIFE bindings
   at the top of `dot_config/mpv/input.conf`.
4. **`.chezmoiexternal.toml` vendoring** — `kitty-themes`, `catppuccin/tmux`,
   `catppuccin/lazygit`, `modernz.lua`. Must land before step 5, because
   `kitty.conf` and `tmux.conf` reference these paths.
5. **The §3 unions**, in dependency order:
   `kitty.conf` (A + templated `shell`) → `git/config.tmpl` (HM + B's
   `tag.gpgSign`, task 2.2) → `tmux/tmux.conf` (HM + B's plugin `run` line,
   task 2.4) → `private_dot_ssh/private_config.tmpl` (A + B's github/home-server
   blocks, task 2.3) → lazygit (B's macOS path + split themes) →
   `dot_config/kanata/config.kbd` (A's `static/kanata.lisp` content).
6. **`dot_zshrc.tmpl`** — capture the HM-generated `~/.zshrc` (task 2.6). Last of
   the shell work, because it references `starship`, `theme-switcher`, `zoxide`
   and `direnv`, all of which must be installable by then.
7. **B's KDE machinery** (Linux host only, after P1–P4): the 6 `modify_*`
   scripts + 6 `.src.ini` sources, then `private_kxkbrc`, `private_dolphinrc`,
   `private_kded5rc`, `private_kwinrulesrc`, `private_plasmanotifyrc`.
8. **B's KDE theming**: `color-schemes` (2 files) → `aurorae/themes/Catppuccin*`
   (22) → `look-and-feel/{Catppuccin-Mocha-Mauve,Catppuccin-Latte-Mauve,Custom dark,Custom light}`
   (28). Color schemes first: the look-and-feels reference them by name. Fix the
   `CatppuccinLatteMauve` reference (§4.3 gap 1) in the same commit.
   `dot_local/share/darkman/default.sh` last.
9. **B's editor/misc adoptions**: `dot_config/zed/**`.
10. **Nothing else from B enters `chezmoi/`.** The `run_once_*` scripts, the
    systemd units and the compose files become Ansible roles in phases 3–4;
    the 228 Itchy/Scratchy desktoptheme files and the 7 dead look-and-feels are
    never copied.

---

## 6. NEEDS USER

Two rows, both genuine factual conflicts that no §0/§0.1 ruling covers:

1. **`Host storagebox` SSH user.** `static/config.ssh` says `User u593939` with
   an explicit `IdentityFile ~/.ssh/id_ed25519`; B says `User u593939-sub1` and
   no IdentityFile. These are different Hetzner storage-box sub-accounts, not a
   formatting difference. *Question: which sub-account is current — `u593939` or
   `u593939-sub1`?*
2. **Syncthing deployment model.** B ships
   `Documents/docker-services/syncthing/docker-compose.yml`
   (linuxserver.io container, `./config` + `./data` bind mounts, ports
   8384/22000/21027); this repo has `modules/home/syncthing.nix` (native user
   service). §0.1's table does not mention `Documents/docker-services/` at all.
   *Question: after migration, does syncthing run as a container (Ansible
   `virtualization` role + chezmoi-owned compose file under `~/Documents`) or as
   a native user unit (Ansible `users`/systemd)?* Everything else under
   `Documents/docker-services/` is immich-ml and is dropped.
