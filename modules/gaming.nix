{pkgs-unstable, ...}: {
  environment.systemPackages = with pkgs-unstable; [
    # Steam
    (steam.override {extraPkgs = _: [mono gtk3 gtk3-x11 libgdiplus zlib];}).run
    popcorntime
    qbittorrent
    # obs-studio
    # obs-studio-plugins.wlrobs
    # obs-studio-plugins.obs-pipewire-audio-capture
    # zoom-us
  ];

  programs.steam.enable = true;
}
