{ flake, ... }:
let
  inherit (flake) inputs;
in
final: prev: {
  nix = inputs.nixpkgs.legacyPackages.${prev.stdenv.system}.nixVersions.latest;

  inherit (inputs.llm-agents.packages.${prev.stdenv.hostPlatform.system})
    opencode
    ;

  inherit (inputs.high-tide.packages.${prev.stdenv.hostPlatform.system})
    high-tide
    ;

  inherit (inputs.self.packages.${prev.stdenv.hostPlatform.system})
    theme-switcher
    tmux-session-color
    openrouter-credits
    xinstall
    # vs-rife
    ;

  inherit (inputs.vim.packages.${prev.stdenv.hostPlatform.system}) nvim;

  noctalia = inputs.noctalia.packages.${prev.stdenv.hostPlatform.system}.default;

  # ponytail: nix-cache-proxy input is commented out in flake.nix — removed dead overlay attr.

  mosh = prev.mosh.overrideAttrs (
    old:
    let
      patches = inputs.nixpkgs.lib.lists.remove (prev.fetchpatch {
        url = "https://github.com/mobile-shell/mosh/commit/eee1a8cf413051c2a9104e8158e699028ff56b26.patch";
        hash = "sha256-CouLHWSsyfcgK3k7CvTK3FP/xjdb1pfsSXYYQj3NmCQ=";
      }) old.patches;
    in
    {
      inherit patches;
      src = inputs.mosh;
      # remove perl diag to fix build on determinate nix builder
      preBuild = ''
        sed -i 's/perl -Mdiagnostics -c /perl -c /g' scripts/Makefile.am
      '';
    }
  );
  signal-desktop = prev.symlinkJoin {
    name = "signal-desktop";
    paths = [ prev.signal-desktop ];
    buildInputs = [ prev.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/signal-desktop\
         --add-flags '--password-store=gnome-libsecret'\
         --add-flags '--enable-features=UseOzonePlatform'\
         --add-flags '--ozone-platform=wayland'
    '';
  };
  strawberry = prev.symlinkJoin {
    name = "strawberry";
    paths = [
      prev.strawberry
    ];
    buildInputs = [ prev.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/strawberry \
      --run "systemctl --user restart pipewire pipewire-pulse wireplumber tidal-to-strawberry"
    '';
  };
  brave = prev.symlinkJoin {
    name = "brave";
    paths = [ prev.brave ];
    buildInputs = [ prev.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/brave \
         --add-flags '--enable-features=UseOzonePlatform'\
         --add-flags '--ozone-platform=wayland'
    '';
  };

  # vsrife: HolyWu's RIFE frame interpolation as a VapourSynth Python plugin.
  # Not in nixpkgs. Wheel-only on PyPI (no sdist). Pulls in PyTorch (CUDA) — heavy build.
  # vsrife = prev.stdenv.mkDerivation {
  #   pname = "vsrife";
  #   version = "5.7.0";
  #   src = prev.fetchurl {
  #     url = "https://files.pythonhosted.org/packages/89/28/44d9a0d093f6ebb342f1aa616021b1284029156d99fb816327c6d44f3d6a/vsrife-5.7.0-py3-none-any.whl";
  #     hash = "sha256-Z8gMiGBeqcAAMANDqJX0r4UQWXgXcWUYSUq6383Zx6E=";
  #   };
  #   dontUnpack = true;
  #   nativeBuildInputs = [ prev.unzip ];
  #   propagatedBuildInputs = [
  #     prev.python3Packages.vapoursynth
  #     prev.python3Packages.torch
  #   ];
  #   installPhase = ''
  #     mkdir -p $out/${prev.python3.sitePackages}
  #     unzip -o $src -d $out/${prev.python3.sitePackages}
  #   '';
  #   meta = {
  #     description = "RIFE (Real-Time Intermediate Flow Estimation) VapourSynth plugin";
  #     homepage = "https://github.com/HolyWu/vs-rife";
  #     license = prev.lib.licenses.mit;
  #   };
  # };
  mpv-rife =
    let
      vsrife = prev.python313Packages.callPackage ./_vsrife.nix {
        # lib = prev.lib;
        # inherit (prev.python313Packages)
        #   hatchling
        #   vapoursynth
        #   numpy
        #   tqdm
        #   torch
        #   requests
        #   ;
      };
      torchtensorrt = prev.python313Packages.callPackage ./_torchtensorrt.nix { };
      vsrifePythonEnv = final.python313.withPackages (ps: [
        ps.vapoursynth
        vsrife
        torchtensorrt
        ps.tensorrt
      ]);
    in
    prev.mpv.override {
      mpv-unwrapped = prev.mpv-unwrapped.override {
        # x11Support = false;
        vapoursynthSupport = true;
        python3 = final.python313;
        # ponytail: vapoursynth embeds its python3 at build time; must match the
        # 3.13 toolchain below or the 3.14 default embeds a CPython that can't
        # load our 3.13 numpy/torch ABI (.so "cpython-313" vs interpreter 3.14).
        vapoursynth = prev.vapoursynth.override { python3 = prev.python313; };
      };
      # https://github.com/TheTabbingMan/nixos-configs/blob/0d1a114871948b5fc74faca192a3adf9f3332c2f/modules/programs/mpv.nix#L7
      extraMakeWrapperArgs = [
        "--prefix"
        "PYTHONPATH"
        ":"
        "${vsrifePythonEnv}/${final.python313.sitePackages}"
        # "/home/jonah/persist/vsrife/venv_vsrife/lib/python3.13/site-packages" # NOTE: This is made imperatively

        # # NOTE: This is only required when using imperitive venv
        # "--prefix"
        # "LD_LIBRARY_PATH"
        # ":"
        # "/run/opengl-driver/lib:/run/opengl-driver-32/lib"
      ];

      youtubeSupport = true;
    };

  # Override the wrapped mpv so it links against vapoursynth+vsrife, not plain vapoursynth.
  # mpv = prev.symlinkJoin {
  #   name = "mpv-with-vsrife";
  #   paths = [ final.mpv-unwrapped final.vapoursynth.withPlugins [ final.vsrife ] ];
  #   buildInputs = [ prev.makeWrapper ];
  #   postBuild = ''
  #     wrapProgram $out/bin/mpv \
  #       --prefix LD_LIBRARY_PATH : "${prev.lib.makeLibraryPath [ final.vapoursynth ]}" \
  #       --prefix PYTHONPATH : "${final.vsrife}/${final.python3.sitePackages}"
  #   '';
  #   meta = final.mpv-unwrapped.meta // { outputsToInstall = [ "out" ]; };
  # };

}
