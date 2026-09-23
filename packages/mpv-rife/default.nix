{
  callPackage,
  cudaPackages,
  fetchFromGitHub,
  python313Packages,
  python313,
  vapoursynth,
  mpv,
  mpv-unwrapped,
  mpvScripts,
  stdenv,
  lib,
}:
let
  vsmlrtVersion = "15.16";
  vsmlrtSrc = fetchFromGitHub {
    owner = "AmusementClub";
    repo = "vs-mlrt";
    tag = "v${vsmlrtVersion}";
    hash = "sha256-mcIPNrPsVNgtGSSzLpwm7QYEbFOcB6IH2pepS9pVGCc=";
  };

  # ponytail: nixpkgs marks every tensorrt older than 10.16.1 insecure
  # (CVE-2026-24188) and 10.14.1 is the newest it packages. flake.nix already
  # allows the insecure tensorrt for pkgs-unstable, so drop the marker here
  # instead of widening nixpkgs.config for every host.
  # tensorrt = cudaPackages.tensorrt.overrideAttrs (prev: {
  #   meta = prev.meta // {
  #     knownVulnerabilities = [ ];
  #   };
  # });

  inherit (cudaPackages) tensorrt;

  # ponytail: vapoursynth embeds its python3 at build time; must match the
  # 3.13 toolchain below or the 3.14 default embeds a CPython that cannot
  # import our 3.13 site-packages (.so "cpython-313" vs interpreter 3.14).
  vapoursynth313 = vapoursynth.override { python3 = python313; };

  # The TensorRT VapourSynth filter (core.trt.Model); the heavy lifting.
  vstrt = callPackage ./_vstrt.nix {
    inherit tensorrt;
    vapoursynth = vapoursynth313;
    src = vsmlrtSrc;
    version = vsmlrtVersion;
  };

  # core.misc.SCDetect: nixpkgs vapoursynth ships no plugin providing it, and
  # the pure-Python std.ModifyFrame fallback in rife.py serializes frame
  # production on the GIL, starving vs-mlrt's multi-stream TRT pipeline and
  # stuttering playback.
  miscfilters = callPackage ./_miscfilters.nix {
    vapoursynth = vapoursynth313;
  };

  # The python wrapper (vsmlrt.RIFE) plus the RIFE onnx models.
  vsmlrt = python313Packages.callPackage ./_vsmlrt.nix {
    inherit tensorrt vstrt miscfilters;
    src = vsmlrtSrc;
    version = vsmlrtVersion;
  };

  vsmlrtPythonEnv = python313.withPackages (ps: [
    ps.vapoursynth
    vsmlrt
  ]);

  # ponytail: autosub defaults to English; swap first language to French so
  # subliminal downloads fr subs automatically (key 'n' still grabs 2nd lang).
  autosub = mpvScripts.autosub.overrideAttrs (prev: {
    preInstall = (prev.preInstall or "") + ''
      substituteInPlace autosub.lua --replace-fail \
        "{ 'English', 'en', 'eng' }," \
        "{ 'French', 'fr', 'fre' },"
    '';
  });
in
mpv.override {
  mpv-unwrapped = mpv-unwrapped.override {
    # x11Support = false;
    vapoursynthSupport = true;
    python3 = python313;
    vapoursynth = vapoursynth313;
  };
  # https://github.com/TheTabbingMan/nixos-configs/blob/0d1a114871948b5fc74faca192a3adf9f3332c2f/modules/programs/mpv.nix#L7
  extraMakeWrapperArgs = lib.optionals stdenv.isLinux [
    "--prefix"
    "PYTHONPATH"
    ":"
    "${vsmlrtPythonEnv}/${python313.sitePackages}"
  ];

  youtubeSupport = true;

  scripts = [
    autosub
    mpvScripts.modernz
    # mpvScripts.autosubsync-mpv
    # mpvScripts.builtins.autocrop
    # mpvScripts.eisa01.smartskip
  ]
  ++ (lib.optionals stdenv.isLinux [
    mpvScripts.mpris
  ]);
}
