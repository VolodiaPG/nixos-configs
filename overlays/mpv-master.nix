final: prev: {
  mpv-unwrapped = (
    prev.mpv-unwrapped
    #.overrideAttrs (old: {
    #version = "git";
    #src = prev.fetchFromGitHub {
    #  owner = "mpv-player";
    #  repo = "mpv";
    # rev = "d3a28f1";
    #  sha256 = "sha256-2lEItmVl2jRZY1RVcsNNODixK2OWreqCdPYJR0V15ic=";
    #};
    #})
  ).override { vapoursynthSupport = true; };

  # vapoursynth-rife = prev.callPackage ../pkgs/vapoursynth-rife { };
  # vapoursynth = prev.vapoursynth.withPlugins [
  #   prev.vapoursynth-rife
  # ];
  #mpv-unwrapped = prev.mpv-unwrapped.override { vapoursynthSupport = true; };
  # python3 = prev.python3.withPackages (python-packages: [
  #   python-packages.libxml2
  #   final.vs-rife
  # ]);
  # mpv-unwrapped = prev.mpv-unwrapped.override {
  #   vapoursynthSupport = true;
  #   # vapoursynth = prev.vapoursynth {
  #   #   python3 = (prev.python3.withPackages (ps: with ps; [ sphinx cython numpy pytorch ]));
  #   # };
  #   # .withPlugins [
  #   #   # final.vapoursynthPlugins.
  #   #   # prev.vs-rife
  #   #   #  prev.vs-overlay.packages.x86_64-linux
  #   # ];
  # };
  mpv = final.wrapMpv final.mpv-unwrapped { youtubeSupport = true; };
}
