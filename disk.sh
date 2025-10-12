#!/usr/bin/env bash

# Then create subvolumes
mount -t btrfs /dev/disk/by-label/root /mnt

# We first create the subvolumes outlined above:
btrfs subvolume create /mnt/root
btrfs subvolume create /mnt/nix
btrfs subvolume create /mnt/persistent

umount /mnt
