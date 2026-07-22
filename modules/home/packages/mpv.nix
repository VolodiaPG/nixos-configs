{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.mpv;
  # inherit (lib) mkEnableOption mkIf;
  #
  # # mpv with vapoursynth support enabled (needed for vsrife to load).
  # mpvVapoursynth = pkgs.mpv-unwrapped.override {
  #   vapoursynth = true;
  # };
  # mpvWrapped = pkgs.symlinkJoin {
  #   name = "mpv";
  #   paths = [ mpvVapoursynth pkgs.vapoursynth ];
  #   buildInputs = [ pkgs.makeWrapper ];
  #   postBuild = ''
  #     wrapProgram $out/bin/mpv \
  #       --prefix LD_LIBRARY_PATH : "${pkgs.lib.makeLibraryPath [ pkgs.vapoursynth ]}" \
  #       --prefix PYTHONPATH : "${pkgs.vsrife}/${pkgs.python3.sitePackages}"
  #   '';
  #   meta = mpvVapoursynth.meta // { outputsToInstall = [ "out" ]; }; # ponytail: symlinkJoin has no `man` output; inherited meta would crash buildenv
  # };
in
{
  options = {
    mpv = {
      enable = lib.mkEnableOption "MPV configuration";
    };
  };

  config = lib.mkIf cfg.enable {
    # programs.mpv.enable = true;
    home.packages = [
      pkgs.mpv-rife
      # pkgs.mpv-handler
      # pkgs.vapoursynth
      # # pkgs.vapoursynth-mvtools
      # pkgs.python3Packages.vapoursynth
      # # pkgs.python3Packages.guessit
      # (pkgs.writeShellScriptBin "mpv-python" ''
      #   exec ${
      #     pkgs.python3.withPackages (
      #       ps: with ps; [
      #         guessit
      #         requests
      #         subliminal
      #       ]
      #     )
      #   }/bin/python3 "$@"
      # '')
      # pkgs.socat
    ];

    #   # file = {
    #   #   ".config/mpv" = {
    #   #     source = ./mpv;
    #   #     recursive = true;
    #   #   };
    #   # };
  };
}
