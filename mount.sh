#!/usr/bin/env bash

swapon /dev/disk/by-label/swap

# Mount the directories
OPTS="ssd,compress-force=zstd:2,noatime,discard=async,space_cache=v2,autodefrag"

mount -o subvol=root,$OPTS /dev/disk/by-label/root /mnt

mkdir /mnt/nix
mount -o subvol=nix,$OPTS /dev/disk/by-label/root /mnt/nix

mkdir /mnt/persistent
mount -o subvol=persistent,$OPTS /dev/disk/by-label/root /mnt/persistent

# don't forget this!
mkdir /mnt/boot
mount /dev/disk/by-label/BOOT /mnt/boot
