# gui.nix / syncthing.nix leftovers — phase 3/4 spec (task 2.10)

What `modules/home/{gui,syncthing}.nix` did that could **not** become a file
in `chezmoi/`, recorded here per rule 6 instead of being invented later.

## gui.nix — `$HOME` content

| `home.file` entry | Disposition |
| --- | --- |
| `.config/kitty/kitty-themes` → `${pkgs.kitty-themes}/share/kitty-themes` | **Done, not duplicated.** Vendored by task 2.1 in `chezmoi/.chezmoiexternal.toml` (`[".config/kitty/kitty-themes"]`, kitty-themes rev `c467f3e`). |
| `.config/discord/settings.json` | **Dropped, deliberately.** (a) Discord itself is in no surviving package list — `gui.nix` installs `legcord` on Linux, and the only `pkgs.discord` is in `modules/home/gnome.nix`, dropped with GNOME (§0). (b) Its content is runtime state Discord rewrites on every quit (`IS_MINIMIZED`, `WINDOW_BOUNDS`); Home Manager could own it only because a store symlink is read-only. A chezmoi-owned copy would produce a permanent `chezmoi diff` — the same failure mode `claude.nix` was written to avoid. If Discord is ever installed and `SKIP_HOST_UPDATE` is wanted again, re-add it as a `run_onchange_` merge, not as a managed file. |

`fonts.fontconfig.enable = pkgs.stdenv.isLinux` has **no successor and needs
none**: it only generated `~/.config/fontconfig/conf.d/10-hm-fonts.conf`,
which points fontconfig at the Home Manager profile's font dirs. On Nobara
fonts come from RPMs into `/usr/share/fonts`, already on fontconfig's path.

### Not chezmoi's — package lists (task 3.1)

From `gui.nix`'s `home.packages`, all platforms unless noted. Cross-check
against `docs/migration/package-map.md`, which already carries them:

- both: `signal-desktop`, `qbittorrent`, `kitty` (+ `kitty-themes`, now an
  external, so no package)
- Linux only: `gparted`, `filezilla`, `libnotify`, `legcord`,
  `notify-desktop`, `fontconfig`, `distrobox`, `distrobox-tui`, `high-tide`,
  `inkscape`, `gimp`
- commented out in the module and therefore **not** to be installed:
  `drawio`, `vlc` (but `vlc` survives via the macOS cask list, §0.2),
  `easyeffects`, `libreoffice-qt-fresh`, `freerdp`, `sone`, `calibre` (also
  kept via §0.2), `freecad`, `bambu-studio`, `orca-slicer`

`gparted` needs root to *run*, not to install — nothing special for Ansible.

## syncthing.nix — native service (§0)

**Nothing goes into chezmoi.** `modules/home/syncthing.nix` sets no files at
all; it only tunes `services.syncthing`, and Syncthing's own state
(`~/.local/state/syncthing/`, Syncthing 2.x) is a device key + certificates +
`config.xml`, i.e. per-machine identity that must not be templated.
Peers/folders are configured by hand after cutover (§0; msi currently has
neither).

### What the Ansible role must reproduce

Settings from the module, plus the exact command line Home Manager generated
on the macOS host (read out of the generated `syncthing-wrapper`, so these
flags are copied, not guessed):

```
syncthing serve --no-browser --no-restart --no-upgrade \
  --gui-address=0.0.0.0:8384 --allow-newer-config
```

- `--gui-address=0.0.0.0:8384` — `guiAddress` in the module. Listening on all
  interfaces is intentional (GUI reachable over Tailscale).
- `--allow-newer-config` — module `extraOptions`.
- `--no-upgrade` — the package manager owns updates.
- `overrideDevices = false` / `overrideFolders = false` mean Home Manager's
  declarative device/folder API was **off**: the role must likewise never
  rewrite `config.xml`. Only start the service.

**Linux (msi).** Per the split rule's systemd carve-out, the unit is
Ansible's. Fedora's `syncthing` RPM already ships
`/usr/lib/systemd/user/syncthing.service`; prefer
`systemctl --user enable --now syncthing.service` plus a drop-in
(`~/.config/systemd/user/syncthing.service.d/override.conf`, written by
Ansible — note `chezmoi/.chezmoiignore` already excludes `.config/systemd`
from chezmoi) overriding `ExecStart` with the line above, over a hand-written
unit. `loginctl enable-linger volodia` is required for it to run without a
session. Firewall: TCP 8384 (GUI), TCP/UDP 22000, UDP 21027 — msi's current
rules already open these (`msi-facts.md`).

**macOS.** `brew services start syncthing` (Homebrew's plist) or an
Ansible-written `~/Library/LaunchAgents/` plist with the same ExecStart;
today's HM agents are `org.nix-community.home.syncthing{,-init}` and both go
away with Home Manager. The `-init` agent only ran
`merge-syncthing-config`/`syncthing-copy-keys`, which exist solely to feed the
declarative API that is switched off here — **no successor needed**.

**Backup first.** `~/.local/state/syncthing/` (116 K on msi) holds the device
ID; restore it if the same identity is wanted after the reinstall
(`msi-backup-checklist.md`).
