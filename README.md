# nixos-configs

NixOS, nix-darwin and Home Manager configurations for my machines, plus the
dotfiles they deploy (via [chezmoi](https://www.chezmoi.io/)).

## Machines

| Host                   | System          | Role                                                       |
| ---------------------- | --------------- | ---------------------------------------------------------- |
| `msi`                  | `x86_64-linux`  | Desktop/workstation: NVIDIA + CUDA, Hyprland, gaming, HyperHDR |
| `home-server`          | `x86_64-linux`  | Headless laptop: NAS, k3s, restic backups                  |
| `m1`                   | `aarch64-linux` | MacBook on Asahi, Hyprland                                 |
| `installer`            | `x86_64-linux`  | Bootable installer ISO                                     |
| `Volodias-MacBook-Pro` | `aarch64-darwin`| nix-darwin laptop                                          |

Hosts are declared in one place — the `nixosHosts` / `darwinHosts` attrsets at
the top of [`flake.nix`](flake.nix) — which is also where the `(system, cuda)`
nixpkgs variant for each of them is chosen.

## Layout

```
flake.nix               inputs, host inventory, builders, flake outputs
config.nix              personal constants (`me`): name, keys, caches, tailnet…
lib/nixpkgs-config.nix  the nixpkgs `config` shared by every pkgs instance

configurations/
  nixos/<host>/         per-host NixOS: default.nix (switches) + configuration,
                        hardware-configuration, disk (disko), home
  darwin/<host>/        per-host nix-darwin

modules/
  nixos/                reusable NixOS modules   -> options under `my.*`
  darwin/               reusable darwin modules  -> options under `my.*`
  home/                 reusable Home Manager modules -> options under `my.*`

overlays/default.nix    repo overlay: in-repo packages + attrs from unstable
packages/               in-repo packages, also exposed as flake `packages`
secrets/                agenix-encrypted secrets + the modules that wire them
static/                 files consumed verbatim (kanata config, cachix push…)
chezmoi/                dotfiles applied by chezmoi during home activation
kubernetes/             manifests for the k3s workloads on home-server
docs/                   runbook and references
```

## Conventions

### `my.*` versus upstream options

Every option this repo defines lives under **`my.`**. Anything else is an
upstream NixOS / nix-darwin / Home Manager option. So in a host file:

```nix
my.base.enable = true;        # modules/nixos/base.nix
services.caddy.enable = true; # upstream nixpkgs module
```

A few modules deliberately have no options of their own and instead *extend* an
upstream service when it is enabled — `modules/nixos/{caddy,samba,immich,
recyclarr}.nix` key off `services.<name>.enable`. Their host-side switch is
therefore the upstream one, which is why host files keep a small `services`
block next to the `my` block.

To find where an option comes from:

```sh
just option msi my.impermanence.fsType
```

### Module arguments

Every module in this repo receives three extra arguments, set in `flake.nix`:

| Argument        | What it is                                                     |
| --------------- | -------------------------------------------------------------- |
| `flake`         | `self` plus `inputs`, and `config` = [`config.nix`](config.nix) |
| `pkgs-unstable` | nixpkgs-unstable for this host's `(system, cuda)` pair          |
| `overlay`       | the repo overlay, applied by `common-overlays.nix`              |

`flake.config.me` is the single source of truth for username, SSH keys, email,
tailnet name and the binary caches.

### Home Manager

The wiring (`useGlobalPkgs`, `extraSpecialArgs`, `sharedModules`, secrets) lives
once in `modules/{nixos,darwin}/home-manager.nix`. Host files only say what to
enable for the user.

## Everyday commands

Everything runs through [`just`](justfile); `nix develop` (or direnv) provides
the tools.

```sh
just build [host]     # build, don't activate
just boot [host]      # build + activate on next boot   (default recipe)
just switch [host]    # build + activate now
just dry-build [host] # build + show what would change (nvd diff)
just deploy           # deploy home-server over SSH (deploy-rs)

just mac-build        # build the darwin system + diff
just mac-switch       # activate it

just installer        # build the installer ISO
just installer-burn /dev/sdX

just update           # flake update + boot + flatpak + deploy
```

`host` defaults to `$(hostname)`.

## Checking and debugging

```sh
just check            # nix flake check: lint hooks + evaluate every host
just fmt              # nix fmt (nixfmt) over the tree
just lint             # run the pre-commit hooks over all files

just eval [host]      # evaluate a host to a .drv — fastest "does it break?"
just eval-all         # same for every host, including the darwin one
just trace [host]     # evaluate with --show-trace for a full stack

just option msi services.caddy.enable   # print one evaluated option
just repl msi                           # nix repl with that host's config
```

Notes that have saved time before:

- `just eval-all` catches evaluation errors on *all* hosts, including the ones
  you are not sitting in front of. Cross-platform evaluation works fine from
  macOS; only building needs the right system.
- In `just repl <host>`, `config`, `options` and `pkgs` are in scope:
  `config.my.impermanence`, `options.my.base.enable.definitionsWithLocations`
  (this last one tells you *which file* set a value).
- Because the hosts run a `post-build-hook`, failed cachix pushes are logged to
  `/var/log/nix-push-hook.log`, not to the build output.
- New files must be `git add`ed (at least `git add -N`) before Nix sees them:
  flakes only read tracked files.

## Secrets

Secrets are [agenix](https://github.com/ryantm/agenix) files in `secrets/`,
declared in `secrets/secrets.nix` and wired into hosts by `secrets/nixos.nix`
and `secrets/home-manager.nix`.

```sh
just secret-edit          # pick one from a menu and edit it
just secret-new NAME.age  # create a new one
```

A handful of files (SSH keys, licensed fonts) are encrypted in-tree with
[transcrypt](https://github.com/elasticdog/transcrypt) instead — see
`.gitattributes` and the transcrypt pre-commit hook.

## CI

`.github/workflows/` holds the active workflows:

- `deploy.yaml` — on push to `main`: deploy `home-server`, and build `msi` and
  push its closure to cachix.
- `installer-iso.yaml` — build the installer ISO.

`.github/workflows-disabled/` holds workflows that are intentionally parked
(GitHub only runs what is directly inside `.github/workflows/`).

## Further reading

- [`docs/runbook.md`](docs/runbook.md) — manual recovery procedures.
- [`docs/references.md`](docs/references.md) — prior art and documentation links.
