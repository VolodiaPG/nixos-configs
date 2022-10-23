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

  gnome = prev.gnome.overrideScope' (gself: gsuper: {
    mutter = gsuper.mutter.overrideAttrs (oldAttrs: {
      src = prev.fetchgit {
        url = "https://gitlab.gnome.org/GNOME/mutter";
        rev = "184055b2bb7119566cada1eb632a5ab9471fe558";
        sha256 = "sha256-hMzPzZEJPyF1H47y2X4uSVnDPbtyMkELNZxV2c1RPck=";
      };

      patches = [
        # Fix build with separate sysprof.
        # https://gitlab.gnome.org/GNOME/mutter/-/merge_requests/2572
        (prev.fetchpatch {
          url = "https://gitlab.gnome.org/GNOME/mutter/-/commit/285a5a4d54ca83b136b787ce5ebf1d774f9499d5.patch";
          sha256 = "/npUE3idMSTVlFptsDpZmGWjZ/d2gqruVlJKq4eF4xU=";
        })
        # https://salsa.debian.org/gnome-team/mutter/-/blob/ubuntu/master/debian/patches/x11-Add-support-for-fractional-scaling-using-Randr.patch
        ./1441-main.patch
      ];
    });
  });

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
