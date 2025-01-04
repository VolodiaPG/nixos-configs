{
  pkgs,
  lib,
  inputs,
  ...
}:
# let
#   stable-pkgs = import inputs.nixpkgs-stable {
#     config.allowUnfree = true;
#     inherit (pkgs.stdenv) system;
#   };
# in
{
  # programs.obs-studio = {
  #   enable = true;
  #   plugins = with stable-pkgs.obs-studio-plugins; [
  #     wlrobs
  #     obs-backgroundremoval
  #     obs-pipewire-audio-capture
  #     obs-ndi
  #   ];
  # };
  home.packages = with pkgs;
    [
      inkscape
      signal-desktop
      qbittorrent
      lazygit
    ]
    ++ (lib.optionals pkgs.stdenv.isLinux [
      neovide
      vlc
      freecad
      strawberry
      tidal-hifi
      # Media
      libsForQt5.qt5.qtwayland # Allow SVP to run on wayland
    ])
    ++ (lib.optionals (pkgs.stdenv.isx86_64 && pkgs.stdenv.isLinux) [
      code-cursor
      discord
      insomnia
      inputs.zen-browser.packages.${pkgs.stdenv.system}.default
      (steam.override {extraPkgs = _: [mono gtk3 gtk3-x11 libgdiplus zlib];}).run
      popcorntime
    ])
    ++ (lib.optionals (pkgs.stdenv.isAarch64 && pkgs.stdenv.isLinux) [
      inputs.codecursor.packages.${pkgs.stdenv.system}.default
    ]);

  # programs.steam.enable = true;
}
