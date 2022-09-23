{ config, pkgs, lib, ... }:

{
  boot.supportedFilesystems = [ "btrfs" ];
}
