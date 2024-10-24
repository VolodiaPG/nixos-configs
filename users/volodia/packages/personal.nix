{
  pkgs,
  lib,
  inputs,
  ...
}: {
  home.packages = with pkgs;
    [
      neovide
      freecad
      inkscape
      neovide

      # Media
      tidal-hifi
      libsForQt5.qt5.qtwayland # Allow SVP to run on wayland
      # mpv
      vlc
      signal-desktop
      qbittorrent
      strawberry
    ]
    ++ (lib.optionals pkgs.stdenv.isx86_64 [
      code-cursor
      discord
      insomnia
      inputs.zen-browser.packages.${pkgs.stdenv.system}.specific
      (steam.override {extraPkgs = _: [mono gtk3 gtk3-x11 libgdiplus zlib];}).run
      popcorntime
    ])
    ++ (lib.optionals pkgs.stdenv.isAarch64 [
      inputs.codecursor.packages.${pkgs.stdenv.system}.default
    ]);

  # programs.steam.enable = true;
}
