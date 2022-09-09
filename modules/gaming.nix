{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Steam
    (steam.override { extraPkgs = pkgs: [ mono gtk3 gtk3-x11 libgdiplus zlib ]; }).run
  ];

  programs.steam.enable = true;
}
