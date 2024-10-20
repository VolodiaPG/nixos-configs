{
  pkgs,
  inputs,
  lib,
  ...
}: {
  home.packages =
    (lib.optional pkgs.stdenv.isx86_64 ./x68_64.nix)
    ++ (
      with pkgs; [
        inputs.codecursor.packages.${pkgs.stdenv.system}.default
        freecad
        inkscape

        # Media
        tidal-hifi
        libsForQt5.qt5.qtwayland # Allow SVP to run on wayland
        # mpv
        vlc
        signal-desktop
        qbittorrent
      ]
    );

  # programs.steam.enable = true;
}
