final: prev: {
  # mpv-unwrapped = (super.mpv-unwrapped.overrideAttrs (old: {
  #   version = "git";
  #   src = super.fetchFromGitHub {
  #     owner = "mpv-player";
  #     repo = "mpv";
  #     rev = "ba81e4ed88433b021282ca435c80361418d66999";
  #     sha256 =  "sha256-10y4fNLDqVgfxackx98gD3xetC3dzMVNgE1Gd+7NaZE=";
  #   };
  # })).override { vapoursynthSupport = true; };
  # vapoursynth-rife = prev.callPackage ../pkgs/vapoursynth-rife { };
  # vapoursynth = prev.vapoursynth.withPlugins [
  #   prev.vapoursynth-rife
  # ];
  # mpv-unwrapped = prev.mpv-unwrapped.override { vapoursynthSupport = true; vapoursynth = final.vapoursynth-pluginned; };
  # python3 = prev.python3.withPackages (python-packages: [
  #   python-packages.libxml2
  #   final.vs-rife
  # ]);
  mpv-unwrapped = prev.mpv-unwrapped.override {
    vapoursynthSupport = true;
    # vapoursynth = prev.vapoursynth {
    #   python3 = (prev.python3.withPackages (ps: with ps; [ sphinx cython numpy pytorch ]));
    # };
    # .withPlugins [
    #   # final.vapoursynthPlugins.
    #   # prev.vs-rife
    #   #  prev.vs-overlay.packages.x86_64-linux
    # ];
  };
  mpv = final.wrapMpv final.mpv-unwrapped { youtubeSupport = true; };
}
