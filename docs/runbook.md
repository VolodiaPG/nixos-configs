# Runbook

Operational notes: one-off fixes and procedures that are deliberately *not*
encoded in the configuration, because they are manual recovery steps or
host-state repairs.

## macOS / nix-darwin

Nix store ownership after a Determinate reinstall:

```sh
sudo chown -R volodia:staff /nix
```

Restart the Determinate nix daemon:

```sh
sudo launchctl kickstart -k system/systems.determinate.nix-daemon
# or, the long way:
sudo launchctl unload /Library/LaunchDaemons/systems.determinate.nix-daemon.plist
sudo launchctl load   /Library/LaunchDaemons/systems.determinate.nix-daemon.plist
```

Mount a btrfs root by label (rescue):

```sh
mount -o subvol=,ssd,compress-force=zstd:2,noatime,discard=async,space_cache=v2,autodefrag \
  /dev/disk/by-label/root /mnt
```

### Determinate: file descriptor limit

Linux builders need a raised limit, otherwise large builds fail:

```sh
ulimit -n 51200
```

Check what the builder actually sees:

```sh
nix build -v --system x86_64-linux --impure --expr \
  'with import <nixpkgs> { }; runCommand "check-ulimit" { } "ulimit -n > $out"' \
  && cat result
```

### Uninstalling

Uninstall nix-darwin first, then Nix itself.

### Desktop responsiveness defaults

Not managed by nix-darwin (they are per-user `defaults`):

```sh
# Remove the delay before the Dock begins to appear
defaults write com.apple.dock autohide-delay -float 0
# Speed up the slide-in animation to zero (instant pop)
defaults write com.apple.dock autohide-time-modifier -float 0
# Speed up drop-down sheets
defaults write NSGlobalDomain NSWindowResizeTime -float 0.001
# Very fast key repeat (lower is faster)
defaults write NSGlobalDomain KeyRepeat -int 1
# Short delay before a key starts repeating
defaults write NSGlobalDomain InitialKeyRepeat -int 10
```

## transcrypt

Patch transcrypt to silence the OpenSSL pbkdf2 warning spill:

```sh
curl https://github.com/elasticdog/transcrypt/compare/suppress-openssl-pbkdf2-warnings.patch \
  | patch -p1 .git/crypt/transcrypt
```

## BambuStudio

Install via flatpak, then use
[StudioBridge](https://github.com/Rdiger-36/StudioBridge) with `appimage-run` to
configure the printer in the slicer.

## Immich: restoring a dump that references the old `vectors` extension

1. Check what the dump actually references (decisive — do this first):

   ```sh
   zcat <your-dump>.sql.gz | grep -n 'vectors'
   ```

   - Only `CREATE EXTENSION IF NOT EXISTS vectors ...` and
     `COMMENT ON EXTENSION vectors ...` → purely vestigial, proceed.
   - Also `CREATE INDEX ... USING vectors (...)` (old pgvecto.rs indexes) → strip
     those lines too and re-index afterwards (Admin → Jobs → smart search
     re-index). Current immich does not need them.

2. Strip and re-create the dump file:

   ```sh
   zcat <your-dump>.sql.gz \
     | grep -vE 'CREATE EXTENSION IF NOT EXISTS vectors|COMMENT ON EXTENSION vectors' \
     | gzip > fixed.sql.gz
   ```

3. Restore it. Either upload `fixed.sql.gz` through the web UI (works now that
   immich is superuser), or do it by hand on a NixOS host:

   ```sh
   sudo systemctl stop immich-server
   sudo -u postgres dropdb --if-exists immich
   sudo -u postgres createdb -O immich immich
   gunzip -c fixed.sql.gz | sudo -u postgres psql -d immich -v ON_ERROR_STOP=on -q
   # hand ownership to the role the server connects as:
   sudo -u postgres psql -d immich -c 'REASSIGN OWNED BY postgres TO immich;'
   sudo systemctl start immich-server
   ```

   On the k3s deployment (see `kubernetes/immich/`):

   ```sh
   gunzip -c ~/Documents/fixed.sql.gz \
     | kubectl --kubeconfig ~/Documents/k3s.yaml -n immich exec -i database-1 -- \
       psql -d app -v ON_ERROR_STOP=on -q
   ```
