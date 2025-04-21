{
  src,
  lib,
  stdenv,
  installShellFiles,
}: let
  replace =
    {
      "aarch64-darwin" = "--replace '-arch x86_64' ''";
      "x86_64-darwin" = "--replace '-arch arm64e' '' --replace '-arch arm64' ''";
    }
    .${
      stdenv.system
    };
in
  stdenv.mkDerivation (finalAttrs: {
    inherit src;
    pname = "yabai";
    version = "7.1.14";
    env = {
      # silence service.h error
      NIX_CFLAGS_COMPILE = "-Wno-implicit-function-declaration";
    };

    nativeBuildInputs = [
      installShellFiles
    ];
    postPatch = ''
      substituteInPlace makefile ${replace};
    '';

    buildPhase = ''
      PATH=/usr/bin:/bin /usr/bin/make install
    '';

    dontConfigure = true;
    enableParallelBuilding = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/{bin,share/icons/hicolor/scalable/apps}

      cp ./bin/yabai $out/bin/yabai
      cp ./assets/icon/icon.svg $out/share/icons/hicolor/scalable/apps/yabai.svg
      installManPage ./doc/yabai.1

      runHook postInstall
    '';
    meta = {
      description = "Tiling window manager for macOS based on binary space partitioning";
      longDescription = ''
        yabai is a window management utility that is designed to work as an extension to the built-in
        window manager of macOS. yabai allows you to control your windows, spaces and displays freely
        using an intuitive command line interface and optionally set user-defined keyboard shortcuts
        using skhd and other third-party software.
      '';
      homepage = "https://github.com/koekeishiya/yabai";
      changelog = "https://github.com/koekeishiya/yabai/blob/v${finalAttrs.version}/CHANGELOG.md";
      license = lib.licenses.mit;
      #platforms = builtins.attrNames finalAttrs.passthru.sources;
      mainProgram = "yabai";
      maintainers = with lib.maintainers; [
        cmacrae
        shardy
        khaneliman
      ];
      sourceProvenance = with lib.sourceTypes;
        lib.optionals stdenv.isx86_64 [fromSource] ++ lib.optionals stdenv.isAarch64 [binaryNativeCode];
    };
  })
