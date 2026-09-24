# KDE Plasma cutover

Companion to PLAN.MD tasks 2.7 and 2.9. Everything here concerns `msi` only;
`.chezmoiignore` excludes every path below on macOS.

## Provenance, and why none of it is verified

All 17 Plasma files in `chezmoi/dot_config/` were copied **byte-for-byte**
from the old chezmoi dotfiles repo (clone at `/tmp/dotfiles-vpg`), which is
the config of the user's previous real Nobara/Plasma install. A full
`diff` of every file against that source was run on 2026-09-23 and every one
is identical:

```
kdeglobals.src.ini  modify_kdeglobals
kwinrc.src.ini      modify_kwinrc
plasmashellrc.src.ini  modify_plasmashellrc
plasma-org.kde.plasma.desktop-appletsrc.src.ini  modify_plasma-org.kde.plasma.desktop-appletsrc
private_kglobalshortcutsrc.src.ini  modify_private_kglobalshortcutsrc
private_krunnerrc.src.ini  modify_private_krunnerrc
private_dolphinrc  private_kded5rc  private_kwinrulesrc
private_kxkbrc     private_plasmanotifyrc
```

**Nothing in this section has been tested against a running Plasma**, and it
cannot be until `msi` is reinstalled:

- the macOS host obviously has no Plasma;
- `msi` today is still **NixOS 26.05 running Hyprland**, not Nobara KDE — it
  has no `~/.config/kdeglobals`, no `kded*rc`, and no `plasmashell` at all.
  PLAN.MD line 17 ("`msi` | Migrates to Nobara KDE. Full reinstall.") is
  still pending.

Treat this file as a spec to execute at first boot of the new install, and
expect to correct it there.

## What needs to exist before the first `chezmoi apply`

### 1. `chezmoi_modify_manager` on `PATH`

The six `modify_*` scripts start with:

```
#!/usr/bin/env chezmoi_modify_manager
```

That is cmm's `path` style: chezmoi executes the script, and the kernel
resolves the interpreter **from the `PATH` of the process running
`chezmoi apply`**. If cmm is missing, chezmoi does not skip those files — the
script fails and the apply errors out.

cmm is **not in nixpkgs and not in Fedora/Nobara repos** (both checked). It is
installed from a GitHub release tarball by the Ansible `chezmoi` role in
phase 4:

- version **3.7.1** (verified working on darwin during migration)
- asset for msi: `chezmoi_modify_manager-v3.7.1-x86_64-unknown-linux-gnu.tar.gz`
- install to `~/.local/bin/chezmoi_modify_manager`, mode `0755`

`~/.local/bin` is prepended to `PATH` by `chezmoi/dot_zshrc.tmpl`, but that
only helps an interactive zsh. **If the first `chezmoi apply` is run from the
Ansible bootstrap playbook, the role must put `~/.local/bin` on `PATH`
explicitly** (task 4.x), not rely on the shell.

Sanity check before applying:

```sh
chezmoi_modify_manager --version   # expect 3.7.1
chezmoi_modify_manager --doctor
```

Do **not** use cmm's `-u/--upgrade` self-updater: it would silently drift the
version away from what Ansible pins.

### 2. Vendored theme assets

`.chezmoiexternal.toml` fetches `CatppuccinLatteMauve.colors` from
`catppuccin/kde` @ `6606b517`, while `CatppuccinMochaMauve.colors` is
in-tree under `chezmoi/dot_local/share/color-schemes/`. That asymmetry is
deliberate — the in-tree dark scheme is a hand-tweaked/older variant that
differs from upstream in `ChangeSelectionColor`, `DecorationHover` and the
whole `[Colors:Selection]` block, and it is the one the user actually ran, so
it is preserved verbatim rather than re-fetched.

The four look-and-feel packages under
`chezmoi/dot_local/share/plasma/look-and-feel/` are the only ones copied;
`desktoptheme/` from the old repo was deliberately dropped as dead weight.

## Applying, without Plasma fighting back

Plasma keeps its config in memory and **rewrites these files on session exit**,
which will silently revert a `chezmoi apply` made from inside a running
session. Run the first apply with the Plasma session **not running** — from a
TTY (`Ctrl-Alt-F3`) or over SSH after logging out:

```sh
chezmoi apply
```

`plasma-org.kde.plasma.desktop-appletsrc` is the one to watch. cmm merges the
live file with `.src.ini`, and `modify_plasma-org.kde.plasma.desktop-appletsrc`
already ignores the host-specific keys so they survive the merge:

```
ignore section "ScreenMapping"
ignore regex ".*" "activityId"
ignore regex ".*" "lastScreen"
ignore regex ".*" "ItemGeometries.*"
```

If the merged panel layout still comes out wrong — duplicated or orphaned
applets, which happens when the fresh install's applet IDs do not line up with
the captured ones — delete the live file and apply onto nothing:

```sh
rm ~/.config/plasma-org.kde.plasma.desktop-appletsrc
chezmoi apply ~/.config/plasma-org.kde.plasma.desktop-appletsrc
```

`modify_private_kglobalshortcutsrc` carries three ignore rules from the old
repo (activity switching UUIDs and Chromium's auto-generated extension
shortcuts); these are preserved verbatim and should not be edited.

## Phase 6: re-capture after the first real session

The `.src.ini` files are snapshots of a machine that no longer exists. Once
Plasma has been configured to taste on the new install, refresh them rather
than hand-editing:

```sh
# re-add an already-tracked file; updates the .src.ini, keeps the modify_ script
chezmoi_modify_manager -a ~/.config/kwinrc
```

Re-run for each of the six managed files, then diff the result. Expect churn
in keys that are genuinely machine-specific and add `ignore` rules for them
instead of accepting the churn.

## Open question, deliberately not guessed

`private_kded5rc` is named for **Plasma 5**. Nobara 43 ships **Plasma 6**,
which reads `kded6rc`. The file only contains:

```ini
[Module-device_automounter]
autoload=false
```

It was kept under its original name because that is what the old repo
shipped and there is no live Plasma to check against. At first boot, verify
which file Plasma actually reads and rename the chezmoi source entry to match
(`private_kded6rc`) if needed — otherwise the setting is inert and removable
media will auto-mount.

`ansible/roles/kde` (task 4.7) runs *before* `roles/chezmoi` in
`playbooks/linux.yml`, so there is no `kded*rc` on disk yet at the point the
`kde` role executes — this can only be checked after the first
`chezmoi apply`, i.e. at the same first-boot moment as the paragraph above,
not by anything in `roles/kde` itself.

## Task 4.7 addendum — day/night colour switch and Catppuccin asset discovery

Two findings from implementing `ansible/roles/kde` (task 4.7), the
replacement for `modules/home/theme-daemon.nix` / task 2.7's `darkman` +
`theme-switcher` daemon:

### The native day/night switch is per-user config, not `roles/kde`'s job

Plasma 6.5 (merged 2025-08, released 21 Oct 2025) added a built-in
"Switch to Dark Mode at Night" toggle under Global Theme settings, scheduled
in sync with Night Light. It is a single boolean:

```ini
[KDE]
AutomaticLookAndFeel=true
LookAndFeelPackageDay=<Global Theme id>
LookAndFeelPackageNight=<Global Theme id>
```

written into **`~/.config/kdeglobals`**, which is a per-user file — and one
of the 17 files already managed by chezmoi
(`chezmoi/dot_config/kdeglobals.src.ini`, edited through `modify_kdeglobals`).
That makes it chezmoi's responsibility, not `ansible/roles/kde`'s: nothing
was written into the Ansible role for it. Whoever owns the chezmoi side next
needs to add `AutomaticLookAndFeel=true` plus the two `LookAndFeelPackage{Day,
Night}` keys (values = the `X-KDE-PluginInfo-Name`/`Id` of the two Global
Theme packages to alternate between, e.g. `Catppuccin-Latte-Mauve` /
`Catppuccin-Mocha-Mauve` under `chezmoi/dot_local/share/plasma/look-and-feel/`)
to `kdeglobals.src.ini`.

Caveat, not yet independently verified: it requires the feature actually
being present in whatever Plasma version Nobara 43 ships (unconfirmed here —
check `plasmashell --version` at first boot; if it predates 6.5, this
feature does not exist yet and a scheduler like `kshift` or the `Day/Night
Switcher` Plasma widget would be the fallback). There is also an open KDE
upstream report (nix-community/plasma-manager#562) that enabling
`AutomaticLookAndFeel` makes the cursor/icon theme selection non-persistent
across logins — worth checking for at first boot given this repo also relies
on `catppuccin-cursors`/`graphite-cursors`/`catppuccin-papirus-folders`.

Separately: `kdeglobals.src.ini`'s existing `[KDE]` block currently reads
`DefaultDarkLookAndFeel=Custom moccha` / `DefaultLightLookAndFeel=Custom
latte` / `LookAndFeelPackage=light`, none of which match any `Id` actually
shipped under `dot_local/share/plasma/look-and-feel/` (`Custom dark`,
`Custom light`, `Catppuccin-Latte-Mauve`, `Catppuccin-Mocha-Mauve`) — flagged
here as an observation while reading that file for this task, not fixed
(out of this agent's file-ownership scope; see PLAN.MD task 4.7's report).

### Catppuccin theme/cursor assets may be undiscoverable at first boot

`inventory/group_vars/nobara.yml`'s `nix_profile_packages` installs
`catppuccin-kde`, `catppuccin-cursors`, `catppuccin-papirus-folders` and
`graphite-cursors` via `nix profile install`, which places them under
`~/.nix-profile/share/...`. A graphical session started by SDDM does not put
that path on `$XDG_DATA_DIRS` by default, so Plasma (and libXcursor's
theme lookup, which also walks `XDG_DATA_DIRS/icons`) may not see those
packages' look-and-feel/colour-scheme/cursor/icon-theme assets at all —
the chezmoi-managed `ColorScheme=CatppuccinLatteMauve` etc. would silently
fail to resolve and fall back to Breeze. `ansible/roles/kde`
(`tasks/xdg_data_dirs.yml`) now installs a system-wide
`/etc/environment.d/90-nix-profile-xdg-data-dirs.conf` drop-in (read by every
user's `systemd --user` session at login, the same path SDDM's login goes
through) setting `XDG_DATA_DIRS=%h/.nix-profile/share:/usr/local/share:/usr/share`.
Unverified against a live session — flag at first boot if theme/cursor
assets still don't appear in System Settings after a fresh login.
