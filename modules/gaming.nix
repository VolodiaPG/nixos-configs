{ config, pkgs, ... }:

{
  nixpkgs.overlays = import ../lib/overlays.nix;

  environment.systemPackages = with pkgs; [
    # Steam
    (steam.override { extraPkgs = pkgs: [ mono gtk3 gtk3-x11 libgdiplus zlib ]; }).run
    popcorntime
    qbittorrent

    bottles
  ];

  programs.steam.enable = true;
}
