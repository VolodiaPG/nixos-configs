{
  python313Packages,
  python313,
  vapoursynth,
  mpv,
  mpv-unwrapped,
}:
let
  # ponytail: torch-tensorrt 2.10.0 wheel was compiled against torch 2.10.0;
  # nixpkgs torch is 2.12.0 and the Library::def ABI changed, so libtorchtrt.so
  # fails to dlopen. Pin torch to 2.10.0+cu129 (matches the trt wheel) for both
  # vsrife and torchtensorrt so they share one torch in the env.
  torch210 = python313Packages.callPackage ./_torch.nix { };
  vsrife = python313Packages.callPackage ./_vsrife.nix {
    torch = torch210;
  };
  torchtensorrt = python313Packages.callPackage ./_torchtensorrt.nix {
    torch = torch210;
  };
  vsrifePythonEnv = python313.withPackages (ps: [
    ps.vapoursynth
    vsrife
    torchtensorrt
    ps.tensorrt
    ps.packaging
    ps.psutil
  ]);
in
mpv.override {
  mpv-unwrapped = mpv-unwrapped.override {
    # x11Support = false;
    vapoursynthSupport = true;
    python3 = python313;
    # ponytail: vapoursynth embeds its python3 at build time; must match the
    # 3.13 toolchain below or the 3.14 default embeds a CPython that can't
    # load our 3.13 numpy/torch ABI (.so "cpython-313" vs interpreter 3.14).
    vapoursynth = vapoursynth.override { python3 = python313; };
  };
  # https://github.com/TheTabbingMan/nixos-configs/blob/0d1a114871948b5fc74faca192a3adf9f3332c2f/modules/programs/mpv.nix#L7
  extraMakeWrapperArgs = [
    "--prefix"
    "PYTHONPATH"
    ":"
    "${vsrifePythonEnv}/${python313.sitePackages}"
    # "/home/jonah/persist/vsrife/venv_vsrife/lib/python3.13/site-packages" # NOTE: This is made imperatively

    # # NOTE: This is only required when using imperitive venv
    # "--prefix"
    # "LD_LIBRARY_PATH"
    # ":"
    # "/run/opengl-driver/lib:/run/opengl-driver-32/lib"
  ];

  youtubeSupport = true;
}
