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
