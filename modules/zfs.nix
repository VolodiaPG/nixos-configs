{ config, pkgs, lib, ... }:

{
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.requestEncryptionCredentials = true;
}
