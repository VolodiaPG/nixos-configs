final: prev: {
  mpv-unwrapped = (prev.mpv-unwrapped.overrideAttrs (old: {
    version = "git";
    src = prev.fetchFromGitHub {
      owner = "mpv-player";
      repo = "mpv";
      rev = "cdcbd73";
      sha256 = "sha256-8GB4VdogBjhcvFKazQV93rF9j5/dA9HQ+S32+kt/Brc=";
    };
  })).override { vapoursynthSupport = true; };

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
