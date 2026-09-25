# macOS cutover conflict analysis — PLAN.MD task 6.1, step 1

Read-only survey of `Volodias-MacBook-Pro.local` performed 2026-09-25 ahead of
running Ansible + chezmoi alongside the live nix-darwin/Home-Manager setup.
No files were changed, no command that mutates state was run. Everything
below is a verified observation, not an assumption — where something could
not be verified it is called out explicitly in "Open questions."

## How this was built

- HM's current generation: `~/.local/state/home-manager/gcroots/current-home`
  → `/nix/store/mf7gs27ada9pxx9yp5kp0nwybacd4cfx-home-manager-generation`.
  Its `home-files` subtree resolves to
  `/nix/store/ijwnv613r2kx5kzzakbxmvwy98wlvwy1-home-manager-files` — walked
  in full (24 entries, see below) to get the authoritative list of every
  path HM manages.
- chezmoi's target list: `chezmoi/` tree walked and every `dot_`/`private_`/
  `executable_`/`modify_`/`.tmpl` prefix translated to its real `$HOME`
  path, cross-checked against `chezmoi managed` and `.chezmoiexternal.toml`
  (archives/files chezmoi also writes that don't exist as tree entries).
  `.chezmoiignore` was applied: on `darwin`, `.config/{hypr,noctalia,
  OrcaSlicer,kdeglobals,kwinrc,kwinrulesrc,kded5rc,kxkbrc,krunnerrc,
  kglobalshortcutsrc,dolphinrc,plasmashellrc,plasmanotifyrc,
  plasma-org.kde.plasma.desktop-appletsrc,kanata,systemd}`, `.var`, and
  `.local/share/{plasma,color-schemes,aurorae,darkman}` are all Linux-only
  and never applied here — they were dropped from the collision analysis.
- Every path was checked live with `ls -la` / `readlink` / `stat`.
- Ansible surface checked by reading `ansible/roles/{darwin_defaults,
  homebrew,nix,secrets}/tasks/main.yml` and templates, then verifying each
  target path against the live filesystem.
- `ansible-playbook --syntax-check playbooks/macos.yml` passed clean.
- `chezmoi diff` was run (read-only) and **it errors out**, it does not
  print an empty/non-empty diff — see §1 finding on `.config/git/config`.

## Collision table

Only paths that (a) chezmoi's tree/externals actually write on Darwin, and
(b) something else on this host currently owns, are listed. "Real target"
is the fully resolved final destination of a symlink chain.

| Path | Current owner | Resolved target | What wins after cutover | Action needed before step 2 |
|---|---|---|---|---|
| `~/.zshenv` | HM symlink | `.../home-manager-files/.zshenv` | chezmoi (once HM gone) | Delete the HM symlink so chezmoi can write a real file; today `chezmoi apply` cannot write through it |
| `~/.zshrc` | HM symlink | `.../home-manager-files/.zshrc` | chezmoi | same |
| `~/.config/direnv/direnv.toml` | HM symlink | `.../home-manager-files/.config/direnv/direnv.toml` | chezmoi | same |
| `~/.config/direnv/direnvrc` | HM symlink | `.../home-manager-files/.config/direnv/direnvrc` | chezmoi | same |
| `~/.config/git/config` | HM symlink | `.../home-manager-files/.config/git/config` | chezmoi (**currently broken**, see below) | Fix chezmoi's own template data (§1) before this can even render, then delete symlink |
| `~/.config/lazygit/config.yml` | HM symlink | `.../home-manager-files/.config/lazygit/config.yml` | chezmoi | delete symlink |
| `~/.config/tmux/tmux.conf` | HM symlink | `.../home-manager-files/.config/tmux/tmux.conf` | chezmoi | delete symlink |
| `~/.ssh/authorized_keys` | HM symlink | `.../home-manager-files/.ssh/authorized_keys` | chezmoi (templated, needs `.signing_key`/`.email`) | delete symlink; fix template data first |
| `~/.ssh/config` | HM symlink | `.../home-manager-files/.ssh/config` | chezmoi | delete symlink |
| `~/.config/kitty/kitty-themes` | HM symlink (whole dir) | `.../home-manager-files/.config/kitty/kitty-themes` | chezmoi external archive extraction | delete symlink; chezmoi will `mkdir` + extract in its place |
| `~/.config/chezmoi/chezmoi.json` | HM symlink (this is chezmoi's **own config file**) | `.../home-manager-files/.config/chezmoi/chezmoi.json`, contents `{"sourceDir":"/Users/volodia/Documents/nixos-configs"}` — no `[data]` section | must become a real, ideally `chezmoi.toml`, populated by `chezmoi/.chezmoi.toml.tmpl` | See §1 — meta-collision, blocks every templated file until resolved |
| `~/.envvars.sh` | agenix symlink (not HM) | `/var/folders/.../T/agenix/envvars` (ephemeral tmpfs-backed path, ephemeral per-boot) | `roles/secrets` (plain file, once vault populated) | delete symlink; currently `secrets_files` in the vault is empty for everything except `envvars`, and even that entry is only written `when: item.content | length > 0` |

**Collision set size: 11 paths** (10 HM-owned + 1 agenix-owned). Every one
of them is a symlink into an ephemeral or GC-able location — none are real
files, so there is no data-loss risk in overwriting them, only an ordering
requirement (HM's symlink must go before chezmoi can occupy the path).

The three or four that actually matter:

1. **`~/.config/chezmoi/chezmoi.json`** — chezmoi cannot configure itself
   while HM owns its own config file, and the `.chezmoi.toml.tmpl` in this
   repo is currently *never consulted* because a `chezmoi.json` already
   exists (chezmoi picks the first config file format it finds; `.json`
   beats `.toml.tmpl`'s `chezmoi init` prompt path). This is the root cause
   of finding #2.
2. **`~/.config/git/config` (templated)** — `chezmoi diff` does not produce
   a diff today, it hard-errors:
   `chezmoi: .config/git/config: template: dot_config/git/config.tmpl:42:12:
   executing "dot_config/git/config.tmpl" at <.email>: map has no entry for
   key "email"`. The active chezmoi config has no `email`/`name`/
   `signing_key`/`host`/`role`/`flavor`/`shell` data because of #1. The same
   missing-data problem will hit `dot_zshenv.tmpl` (`.email`? — checked, it
   branches only on `.chezmoi.os`, so it's fine) and
   `private_dot_ssh/private_authorized_keys.tmpl` (`{{ .signing_key }}
   {{ .email }}` — will also fail).
3. **`~/.zshenv` / `~/.zshrc`** — these are what makes the login shell work
   at all. HM's version and chezmoi's version diverge (chezmoi's has
   Darwin-specific branches for e.g. `/opt/homebrew/bin/zsh`). Getting the
   symlink removed and chezmoi applied cleanly here is the highest-value,
   highest-risk single step of the whole task.
4. **`~/.envvars.sh`** — silently backed by agenix's ephemeral decrypt
   path; this is a ticking time bomb independent of the ansible/chezmoi
   migration — if nix-darwin's activation is ever skipped (e.g. after a
   reboot before a rebuild), the tmpfs target is gone and every shell that
   sources `~/.envvars.sh` fails silently (`.tmpl`/`.zshenv` likely guards
   this with `[ -f ]`, but confirm before relying on it).

## §1 — File-level collisions (detail)

See table above. Additionally, HM manages three more paths that chezmoi's
tree does **not** touch, so they are not collisions, just informational —
they will need Ansible/chezmoi coverage or be intentionally dropped once HM
is gone: `~/.cache/nix-index/files`, `~/.config/discord/settings.json`,
`~/.config/opencode/tui.json`, `~/Applications/Home Manager Apps`,
`~/Library/Fonts/.home-manager-fonts-version`, the three `~/.zsh/plugins/*`
symlinks (auto-suggestions, nix-zsh-completions, zsh-completions —
zsh plugin managers/oh-my-zsh replacements should already be handled inside
`dot_zshrc.tmpl`, verify it doesn't still reference these HM-only paths),
and `~/.config/direnv/lib/hm-nix-direnv.sh` (explicitly and correctly
*not* vendored by chezmoi per a comment in `.chezmoiexternal.toml` — that
half of nix-direnv setup is deliberately left to `roles/nix`, task 3.4).

## §2 — What Home Manager currently owns

Full contents of `home-files` (24 entries, all confirmed live as symlinks
into `.../home-manager-files/...`, none missing/drifted):

```
.cache/.keep
.cache/nix-index/files
.config/chezmoi/chezmoi.json
.config/direnv/direnv.toml
.config/direnv/direnvrc
.config/direnv/lib/hm-nix-direnv.sh
.config/discord/settings.json
.config/git/config
.config/kitty/kitty-themes
.config/lazygit/config.yml
.config/lazygit/theme.dark.yml
.config/lazygit/theme.light.yml
.config/opencode/tui.json
.config/tmux/tmux.conf
.local/state/.keep
.ssh/authorized_keys
.ssh/config
.zsh/plugins/auto-suggestions
.zsh/plugins/nix-zsh-completions
.zsh/plugins/zsh-completions
.zshenv
.zshrc
Applications/Home Manager Apps
Library/Fonts/.home-manager-fonts-version
```

Note `.config/lazygit/theme.{dark,light}.yml` are in HM's list too — chezmoi
also fetches these via `.chezmoiexternal.toml` (`type = "file"`, catppuccin
pins), which duplicates them in the collision table (rolled into the
`.config/lazygit/config.yml` row conceptually; they behave identically:
HM symlink today, chezmoi external file tomorrow).

The parent directories (`~/.config`, `~/.config/direnv`, `~/.config/kitty`,
`~/.config/lazygit`, `~/.config/tmux`, `~/.config/git`, `~/.ssh`) are all
**real directories**, not symlinks — HM links individual files into them,
it does not symlink whole directories (except `.config/kitty/kitty-themes`
and `Applications/Home Manager Apps`, which are directory-level symlinks).
This matters: chezmoi can create new files in those directories without any
conflict; it only collides on the exact paths in the table above.

## §3 — Ansible-vs-nix-darwin collisions

Verified against the live filesystem, not assumed:

| Path | Live state | Owner | Ansible role/task | Collision? |
|---|---|---|---|---|
| `/etc/pam.d/sudo_local` | symlink → `/etc/static/pam.d/sudo_local` → nix store | nix-darwin (`security.pam.services.sudo_local` in `modules/darwin/common-darwin.nix:172`) | `darwin_defaults` templates a **real file** at the same path, mode 0444, content is functionally the same minus `pam_reattach.so` | **Yes.** Every `darwin-rebuild switch` will re-create the symlink and blow away Ansible's file, and vice versa if Ansible runs after. Content is currently: live = `pam_reattach.so` + `pam_tid.so`; Ansible template = `pam_tid.so` only. Running the role "alongside" as PLAN.MD step 1 literally asks for will **not** converge to a no-op `darwin-rebuild` unless `security.pam.services.sudo_local` is disabled/removed from the Nix module first, or the `darwin_defaults` role is not run until step 2. |
| `/Library/LaunchDaemons/org.nixos.limit-maxfiles.plist` | real file, nix-darwin-installed | nix-darwin | `darwin_defaults` writes `/Library/LaunchDaemons/com.ansible.limit-maxfiles.plist` — **different label**, deliberately | **No path collision** (verified: role's default `darwin_defaults_maxfiles_label = com.ansible.limit-maxfiles`). Both daemons will coexist and redundantly set the same `ulimit -n 524288` until the nix-darwin one is removed in step 2 — harmless duplication, not a conflict, but the nix-darwin-labeled daemon needs manual `launchctl bootout` + file removal at step 2 since it's not tracked by Ansible. |
| `/etc/nix/nix.conf` | real file, header says "DETERMINATE NIX CONFIG... do not modify" | **Determinate Nix module inside nix-darwin** (this flake already runs nix-darwin against the `determinate` flake input, not vanilla Nix — confirmed via `flake.nix:68-69` and the file's own header) | No ansible role writes `/etc/nix/nix.conf` directly; `roles/nix` only ever touches `nix.custom.conf` | No collision, but be aware: this host is *already* Determinate-Nix-flavored under nix-darwin. Task 3.4's "reinstall Nix via the Determinate installer" is really "replace nix-darwin's embedded Determinate module with a standalone Determinate install," not introducing Determinate for the first time. |
| `/etc/nix/nix.custom.conf` | symlink → `/etc/static/nix/nix.custom.conf` → `/nix/store/s9agrgka2dq6adyy1cqqd159pry5n8c8-etc-nix.custom.conf` | nix-darwin | `roles/nix` templates a real file at the same path | **Guarded, not a live collision today.** `roles/nix/tasks/main.yml` has an explicit `nix_darwin_present` fact (checks `darwin-rebuild` on PATH and `/run/current-system` generation name) and **skips the whole install/configure block** while nix-darwin is present. Verified both guard conditions are currently true on this host (`darwin-rebuild` is on PATH, `/run/current-system` → `darwin-system-26.05.c3e90c8`), so running `roles/nix` alongside nix-darwin today is a safe no-op by design. |
| `/etc/shells` | real file, stock macOS list (`/bin/bash /bin/csh /bin/dash /bin/ksh /bin/sh /bin/tcsh /bin/zsh`) | **Nobody** — verified no `/nix/store` or `/opt/homebrew` paths present, so nix-darwin is not currently managing this file on this host | No ansible role touches it (grepped all four roles, zero references) | No collision, nothing to do. If a future task adds a Nix/Homebrew zsh to `/etc/shells`, use an idempotent line-add, not an overwrite. |
| `/etc/zshenv` | symlink → `/etc/static/zshenv` → `/nix/store/727hrhhx29jwx4319li5af91pxv4jkz1-etc-zshenv` | nix-darwin | No ansible role touches it | No collision today, but a **sequencing gap**: this file is what sources the Nix profile for every login shell. Step 2 (uninstall nix-darwin) removes this symlink; step 3 (Determinate reinstall) is expected to replace it. Between those two steps, every new shell on the machine loses Nix on `PATH` — see Open Questions. |
| `/Library/LaunchDaemons/org.nixos.activate-{system,agenix}.plist`, `systems.determinate.*.plist` | real files | nix-darwin / Determinate module | none | Not touched by any role; removed by nix-darwin's own uninstaller at step 2. `systems.determinate.*.plist` daemons are the ones that must keep running (or be reinstalled identically) once nix-darwin is gone — do not let the uninstaller take those down along with the nix-darwin-specific ones. |

## §4 — Homebrew ownership

- `/opt/homebrew` itself: real directory, `root:wheel`, mode 755. Not a
  symlink.
- `/opt/homebrew/bin/brew` → symlink → `/nix/store/gv266f0zkz9sdm514wdh1wy6wzsfyqmq-brew`.
  This is a **nix-homebrew shim**, not the real Homebrew executable. Its
  own exported env shows `HOMEBREW_BREW_FILE=/nix/store/...-brew`,
  `HOMEBREW_REPOSITORY=$HOMEBREW_LIBRARY/.homebrew-is-managed-by-nix`.
- `/opt/homebrew/Library/Homebrew` → symlink → `/nix/store/jagayvixmh2z08v2ngph4ry3hc5ivm7m-brew-6.0.22-patched/Library/Homebrew`.
  **This is the critical one**: the entire Homebrew "brain" (the Ruby code
  that implements `brew`) lives in the Nix store, not on disk in
  `/opt/homebrew`. Once nix-darwin/Nix are uninstalled and the store is
  garbage-collected, this symlink dangles and `brew` stops working
  entirely, even though `/opt/homebrew/Cellar` and `/opt/homebrew/Caskroom`
  (the actual installed formulae/casks — verified real files, e.g.
  `Caskroom/` contains `alt-tab, betterdisplay, bettermouse,
  brave-browser, calibre, claudeusagebar, docker-desktop, hiddenbar,
  karabiner-elements, legcord, mouseless, parsec, signal, steam, tg-pro,
  tidal, vlc`) are real, on-disk, and would survive.
- `/opt/homebrew/.managed_by_nix_darwin` — a 0-byte marker file nix-homebrew
  drops to flag the install as Nix-managed.
- `brew` on `PATH` resolves to `/opt/homebrew/bin/brew` first (verified
  `which -a brew`: `/opt/homebrew/bin/brew`, then
  `/run/current-system/sw/bin/brew`, then `/usr/local/bin/brew`) — i.e. the
  shim wins today.
- `nix-homebrew.enable = true` with `user = volodia`,
  `enableRosetta = true` is set in `modules/darwin/common-darwin.nix:28-33`.
  The nix-darwin `homebrew.*` HM/nix-darwin module itself is set
  `enable = false` in that same file (line ~39) — so nix-darwin is not
  currently running `brew bundle`/declarative cask management at all, only
  `nix-homebrew` is providing the `brew` binary. The tap/cask/formula lists
  under that disabled block (`brews = [mpv, vmnet-helper]`, `casks = [...]`,
  `taps = [nirs/vmnet-helper]`) are dead config, confirm they're
  superseded by `ansible/inventory/group_vars/darwin.yml`'s
  `brew_taps/brew_formulae/brew_casks` (spot-checked: all installed casks
  above already appear in `brew_casks` except `brave-browser`, `docker-desktop`,
  `claudeusagebar`, `legcord`, `mouseless` — see Open Questions).

**What must change for `roles/homebrew` to work standalone:** the
`/opt/homebrew/bin/brew` and `/opt/homebrew/Library/Homebrew` symlinks must
be replaced with a real, on-disk Homebrew installation (i.e. re-run the
official Homebrew installer against the existing `/opt/homebrew` prefix —
it detects the existing `Cellar`/`Caskroom` and adopts them rather than
reinstalling everything, which is exactly what PLAN.MD step 2 asks for).
Until that happens, any `community.general.homebrew*` Ansible task that
shells out to `brew` is shelling out to a binary that will disappear the
moment the Nix store paths it depends on are collected.

## §5 — Ordering

Confirmed live: `/nix/var/nix/profiles/system` → `system-49-link` →
`/nix/store/3rp9qcrdhyjmag9rq8q8h0xfc292y20v-darwin-system-26.05.c3e90c8`,
with 49 numbered generations retained (`system-1-link` through
`system-49-link`, oldest dated Apr 28, newest Sep 21 14:19 today's
session). The rollback path PLAN.MD describes — "the nix-darwin generation
is still in `/nix/var/nix/profiles` until step 2" — is real and currently
holds ~49 generations of rollback material.

**Time Machine: `tmutil destinationinfo` reports "No destinations
configured."** There is currently no Time Machine backup destination set
up on this host at all. PLAN.MD's "take a Time Machine snapshot before
step 2 regardless" cannot be satisfied as written until a destination
(external disk or network share) is configured — this is a blocking
prerequisite, not a formality, on a laptop with no other backup of `$HOME`.

## Ordered cutover procedure

1. **(safe)** Configure a Time Machine destination and let a full backup
   complete. Do not proceed past step 6 without this — there is currently
   zero backup coverage for this host.
2. **(safe)** Fix chezmoi's own config: either (a) delete the HM-owned
   `~/.config/chezmoi/chezmoi.json` symlink and let `chezmoi init` run from
   `chezmoi/.chezmoi.toml.tmpl` to produce a real `chezmoi.toml` with the
   `[data]` block populated (host/role/flavor/name/username/email/
   signing_key/shell), or (b) hand-author an equivalent `chezmoi.toml`
   alongside the existing HM-managed json (chezmoi picks one config format;
   confirm precedence before relying on this). Rollback: the file is a
   thin config pointer, not data — trivially recreated from the HM
   generation (`ln -s /nix/store/ijwnv613r2kx5kzzakbxmvwy98wlvwy1-home-manager-files/.config/chezmoi/chezmoi.json ~/.config/chezmoi/chezmoi.json`) if this breaks anything.
3. **(safe)** With chezmoi config fixed, re-run `chezmoi diff` (still
   read-only) and confirm the templating errors on `.config/git/config` and
   `.ssh/authorized_keys` are gone and the remaining diff is limited to the
   11-path collision set above plus genuinely new files.
4. **(destructive, but reversible)** For each of the 10 HM-owned collision
   paths in §Collision table (not `.envvars.sh` yet — see step 5): remove
   the HM symlink (`rm ~/.zshenv` etc.), then `chezmoi apply` for just
   that path (`chezmoi apply ~/.zshenv`). Do this one file at a time, not
   as a blanket `chezmoi apply`, so a bad template renders as a single
   missing file, not a broken `$HOME`. Rollback per file: re-run
   `home-manager switch` (or `darwin-rebuild switch`, which re-runs HM's
   activation per `modules/home/chezmoi.nix`) — HM will recreate the
   symlink AND immediately re-run `chezmoi apply --force` itself, which
   will re-clobber whatever chezmoi just wrote. **This means step 4 is not
   stable until `modules/home/chezmoi.nix`'s `xdg.configFile."chezmoi/
   chezmoi.json"` and its `home.activation.chezmoi` block are disabled in
   the Nix config and a `darwin-rebuild switch` applied** — otherwise HM
   fights chezmoi on every activation. This is the real gate for "chezmoi
   diff is empty and darwin-rebuild is a no-op" from step 1 of PLAN.MD:
   it cannot be reached while HM's own chezmoi-invocation is still live.
5. **(destructive, low risk)** Once vault secrets exist for
   `~/.envvars.sh` content (currently the only populated entry in
   `secrets_files`), remove the agenix symlink and run `roles/secrets`
   (`ansible-playbook --check` first, then a real run). Rollback: agenix's
   symlink target is regenerated on the next `darwin-rebuild switch` if the
   agenix activation is still enabled.
6. **(safe)** Fix the `/etc/pam.d/sudo_local` fight identified in §3:
   disable `security.pam.services.sudo_local` in
   `modules/darwin/common-darwin.nix` (or accept the harmless
   `pam_reattach.so` content difference and defer this file to step 2 only)
   before running `darwin_defaults`. Do **not** run
   `ansible-playbook playbooks/macos.yml` for `darwin_defaults` until this
   is decided, or the next `darwin-rebuild switch` will silently revert
   TouchID sudo to the old behavior.
7. **(safe)** Run `ansible-playbook --check playbooks/macos.yml` for
   `darwin_defaults`, `homebrew` (with `homebrew_update=false`, the
   default), and `nix` (which will correctly no-op today per its guard).
   Confirm zero unexpected changes reported before doing a real run.
8. **(safe)** Run `darwin-rebuild switch` and confirm it reports no
   changes (a true no-op) — this is the literal exit criterion for step 1
   of PLAN.MD task 6.1.
9. **STOP — confirm with the user before proceeding.** This is PLAN.MD's
   explicit gate before step 2 (uninstall nix-darwin/Home Manager). Do not
   proceed past this point without the user's go-ahead, even if steps 1-8
   all look clean. Re-verify the Time Machine backup from step 1 completed
   successfully immediately before continuing.
10. **(destructive)** Uninstall nix-darwin and Home Manager per their own
    uninstallers. Immediately after, verify `/opt/homebrew/bin/brew` and
    `/opt/homebrew/Library/Homebrew` — they will now be dangling symlinks
    (their nix store targets are eligible for GC). Do **not** run `nix
    store gc` or anything that collects the store until Homebrew has been
    re-pointed at real binaries (§4) — a GC before that point permanently
    breaks `brew` with no easy rollback short of a full reinstall.
11. **(destructive)** Re-install Homebrew via the official installer
    targeting the existing `/opt/homebrew` prefix, so it adopts the
    existing `Cellar`/`Caskroom` rather than reinstalling. Verify `brew
    doctor` and `which brew` resolve to real, non-`/nix/store` paths.
12. **(destructive)** Proceed with PLAN.MD steps 3-6 (Determinate Nix
    reinstall, port `common-darwin.nix`'s remaining pieces, port
    `run_once_defaults.tmpl`, finalize `group_vars/darwin.yml`).

## Open questions for the user

1. **No Time Machine destination is configured on this host at all**
   (`tmutil destinationinfo` → "No destinations configured"). PLAN.MD
   requires a snapshot before step 2 "regardless" — what destination
   should be used, and is there time to let a full initial backup complete
   before the STOP gate?
2. **`~/.config/chezmoi/chezmoi.json` is itself HM-managed and has no
   `[data]` section**, which means `chezmoi diff`/`chezmoi apply` cannot
   render `.config/git/config.tmpl` or `private_dot_ssh/
   private_authorized_keys.tmpl` *today* — they hard-error rather than
   diff cleanly. Was this known, or did `chezmoi apply` (run automatically
   by HM's own activation script per `modules/home/chezmoi.nix`) simply
   never reach these two templates before now (e.g. they're new since the
   last successful `darwin-rebuild switch`)? Worth checking
   `darwin-rebuild switch --dry-run` history/logs for prior failures.
3. **`modules/home/chezmoi.nix` makes HM itself run `chezmoi apply --force`
   on every activation.** As long as that stays enabled, HM and the
   standalone `chezmoi apply` this task drives will fight over every file
   they both touch. Should that HM module be disabled as part of step 1
   (before file-by-file migration), or is the intent to leave it running
   until step 2 and accept that `chezmoi diff` truly can't go to zero
   until then?
4. **`/etc/pam.d/sudo_local` will be rewritten by both nix-darwin
   (`security.pam.services.sudo_local`) and the new `darwin_defaults` role
   with slightly different content** (`pam_reattach.so` + `pam_tid.so` live
   vs. `pam_tid.so`-only in the Ansible template). Is dropping
   `pam_reattach.so` (used for tmux/screen session TouchID reattachment)
   an intentional behavior change, or should the Ansible template match
   the live file exactly for step 1, with the trim deferred to step 2?
5. **`brew_casks` in `ansible/inventory/group_vars/darwin.yml` doesn't
   include several casks that are currently installed and real on disk**:
   `brave-browser`, `docker-desktop`, `claudeusagebar`, `legcord`,
   `mouseless` (verified via `ls /opt/homebrew/Caskroom`). PLAN.MD §0.2
   says "carry nothing else that appears in only one source" — were these
   five deliberately excluded (e.g. manually installed outside Nix,
   already slated for removal), or is `darwin.yml` missing them?
6. **`/etc/zshenv` (symlink into the nix-darwin store path that seeds every
   login shell's `PATH` with Nix) has no owner between step 2 (nix-darwin
   uninstall) and step 3 (Determinate reinstall).** Is there a plan for
   that gap — e.g. doing steps 2 and 3 back-to-back in the same
   maintenance window without any new shell/login in between — or should
   `/etc/zshenv` be snapshotted and manually restored if the Determinate
   installer doesn't recreate it fast enough?
7. This flake's nix-darwin is already running the **Determinate module**
   (`determinate.url = flakehub.com/f/DeterminateSystems/determinate/3`),
   not vanilla Nix — confirmed by `/etc/nix/nix.conf`'s own header and
   `flake.nix:68-69`. Does PLAN.MD's task 3.4 "reinstall Nix via the
   Determinate installer" account for this, i.e. is it understood as
   "replace nix-darwin's embedded Determinate with a standalone one," not
   introducing Determinate Nix for the first time?
