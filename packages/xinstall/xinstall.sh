#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/volodiapg/nixos-configs"
# ponytail: XOS_REPO points at a local checkout to skip the clone (testing / reinstall from an existing repo)
REPO="${XOS_REPO:-}"

if [ -z "$REPO" ]; then
  REPO=$(mktemp -d)
  trap 'rm -rf "$REPO"' EXIT
  echo Cloning "$REPO_URL"...
  git clone --depth=1 "$REPO_URL" "$REPO"
fi

TARGET=$(
  nix eval --json "$REPO"#nixosConfigurations --apply 'cfg: builtins.attrNames cfg' 2>/dev/null |
    jq -r '.[] | select(. != "installer")' |
    gum choose --header "Select which configuration to install:"
)

if [ "$(nix eval --json "$REPO"#nixosConfigurations.\""$TARGET"\".config.services.impermanence.disko)" != "true" ]; then
  echo "disko installation is disabled because services.impermanence.disko is false for $TARGET." >&2
  exit 1
fi

if gum confirm --default=false "This will wipe data to install $TARGET:"; then
  echo building disko script for "$TARGET"...
  DISKO=$(nix build "$REPO"#nixosConfigurations.\""$TARGET"\".config.system.build.destroyFormatMount --no-link --print-out-paths)
  echo executing disko script for "$TARGET"... in 10 seconds...
  sleep 10
  sudo "$(echo "$DISKO"/bin/*)" --yes-wipe-all-disks
elif gum confirm --default=false "Install $TARGET without wiping (mount existing system only)?"; then
  echo building disko mount script for "$TARGET"...
  MOUNT=$(nix build "$REPO"#nixosConfigurations.\""$TARGET"\".config.system.build.mount --no-link --print-out-paths)
  echo mounting system for "$TARGET"...
  sudo "$(echo "$MOUNT"/bin/*)"
else
  exit 1
fi
echo building system for "$TARGET", and saving path to system.var.log...
SYSTEM=$(nix build --store /mnt "$REPO"#nixosConfigurations.\""$TARGET"\".config.system.build.toplevel --no-link --print-out-paths)
echo "$SYSTEM" > system.var.log
echo installing system for "$TARGET"...
# No need to specify /mnt before SYSTEM
sudo nixos-install --root /mnt --no-channel-copy --no-root-passwd --system "$SYSTEM"

# --- Populate /persistent with decrypted persistent data ---
# The persistent/ tree in the repo is transcrypt-encrypted. In a fresh clone the
# crypt filter is not initialized, so the working tree holds encrypted blobs and
# must be decrypted (transcrypt init forces a checkout -> smudge-decrypts) before
# copying onto the installed system's /persistent.
PERSISTENT_SRC="$REPO/persistent"
if [ -d "$PERSISTENT_SRC" ]; then
  is_encrypted() {
    # transcrypt stores OpenSSL "Salted__" output, base64 encoded -> starts with U2FsdGVkX1
    head -c 13 "$1" 2>/dev/null | grep -q '^U2FsdGVkX1'
  }

  NEEDS_DECRYPT=0
  while IFS= read -r -d '' f; do
    if is_encrypted "$f"; then NEEDS_DECRYPT=1; break; fi
  done < <(find "$PERSISTENT_SRC" -type f -not -path '*/.git/*' -print0)

  if [ "$NEEDS_DECRYPT" = 1 ]; then
    echo "Persistent files are encrypted; configuring transcrypt to decrypt them..."
    CIPHER=$(gum input --header "transcrypt cipher" --value "aes-256-cbc" --placeholder "aes-256-cbc")
    PASSWORD=$(gum input --password --header "transcrypt password" --placeholder "password")
    # Init transcrypt in the cloned repo; this re-checkouts encrypted files, decrypting them.
    # Use the flake's devShell so the transcrypt version matches the repo (avoids
    # unstable-vs-stable breaking changes from nixpkgs#transcrypt on the installer).
    ( cd "$REPO" && nix develop "$REPO" -c transcrypt -c "$CIPHER" -p "$PASSWORD" -y )

    # Verify decryption actually happened (wrong password leaves files encrypted).
    STILL_ENCRYPTED=0
    while IFS= read -r -d '' f; do
      if is_encrypted "$f"; then STILL_ENCRYPTED=1; break; fi
    done < <(find "$PERSISTENT_SRC" -type f -not -path '*/.git/*' -print0)
    if [ "$STILL_ENCRYPTED" = 1 ]; then
      echo "transcrypt decryption failed (wrong cipher/password?); aborting persistent copy." >&2
      exit 1
    fi
  fi

  echo "Copying persistent data to /mnt/persistent..."
  sudo mkdir -p /mnt/persistent
  sudo rsync -a -p --exclude='.git' --exclude='.DS_Store' "$PERSISTENT_SRC"/ /mnt/persistent/
fi
